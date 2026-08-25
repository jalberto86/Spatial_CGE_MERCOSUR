#!/usr/bin/env python3
# -*- coding: utf-8 -*-
r"""
build_allocator_pixels.py
=========================
Build the canonical allocator baseline-native pixel pool from the accepted
CONTINUOUS fitted OOS scores.

Pool definition
---------------
A pixel is retained iff:

    1. it appears in the accepted biome-specific *_oos_scores.parquet;
    2. native_2018 == 1 at that row/column;
    3. country_aez decodes to a supported MERCOSUR country; and
    4. AEZ is in 1..18.

IMPORTANT
---------
- p_hat comes directly from the accepted *_oos_scores.parquet files.
- oos_pred_<biome>.tif is NOT used. Those rasters are binary OOS evaluation
  maps, not fitted probabilities.
- native_2023 is NOT used. Filtering on a future land-cover endpoint would
  leak future information into the forward allocator.
- p_hat is preserved as float64 so the ranking is not degraded by a float32
  cast.

Reads (under allocator root)
----------------------------
inputs/grid/country_aez.tif
inputs/grid/grid_meta.json
inputs/landcover/native_2018.tif
inputs/scores/amazonia_slx_nodap_cc_oos_scores.parquet
inputs/scores/cerrado_slx_nodap_oos_scores.parquet
inputs/scores/chaco_slx_nodap_oos_scores.parquet
inputs/scores/pantanal_noslx_nodap_oos_scores.parquet

Writes
------
allocator_pixels.parquet
allocator_pixels_meta.json

The output parquet contains:

    pixel_id, row, col, r, aez, biome, p_hat

Validation
----------
The frozen project inputs are expected to reproduce exactly:

    amazonia   3,749,738
    cerrado    1,002,510
    chaco        866,087
    pantanal     158,356
    TOTAL      5,776,691

The script also requires:
- unique pixel_id;
- finite p_hat in [0,1];
- p_hat dtype float64;
- all retained p_hat values unique.

Usage from allocator root
-------------------------
Dry run:
    python src\build_allocator_pixels.py --dry-run

Canonical write:
    python src\build_allocator_pixels.py --force

--force is required when canonical outputs already exist. It explicitly
authorizes replacement of the previous allocator_pixels.parquet and metadata.
"""

from __future__ import annotations

import argparse
import json
import sys
from datetime import datetime, timezone
from pathlib import Path

import numpy as np
import pandas as pd
import rasterio


DEFAULT_ROOT = Path(r"C:\Users\JesusMERCADO\GAMSProjects\GTAP_AEZ\rdyn\allocator")

REGION_MAP = {
    1: "BRA",
    2: "ARG",
    3: "PRY",
    4: "URY",
    5: "BOL",
}

ACCEPTED_SCORES = {
    "amazonia": "amazonia_slx_nodap_cc_oos_scores.parquet",
    "cerrado": "cerrado_slx_nodap_oos_scores.parquet",
    "chaco": "chaco_slx_nodap_oos_scores.parquet",
    "pantanal": "pantanal_noslx_nodap_oos_scores.parquet",
}

EXPECTED_BIOME_COUNTS = {
    "amazonia": 3_749_738,
    "cerrado": 1_002_510,
    "chaco": 866_087,
    "pantanal": 158_356,
}
EXPECTED_TOTAL = sum(EXPECTED_BIOME_COUNTS.values())

REQUIRED_SCORE_COLUMNS = {"row", "col", "p_hat"}


def fail(msg: str) -> "NoReturn":
    raise SystemExit(msg)


def read_raster(path: Path, label: str):
    if not path.is_file():
        fail(f"missing {label}: {path}")

    with rasterio.open(path) as ds:
        arr = ds.read(1)
        shape = ds.shape
        transform = ds.transform
        crs = str(ds.crs)
        nodata = ds.nodata

    return arr, shape, transform, crs, nodata


def validate_alignment(
    ca_shape,
    ca_transform,
    ca_crs,
    n18_shape,
    n18_transform,
    n18_crs,
):
    if n18_shape != ca_shape:
        fail(
            "native_2018.tif shape does not match country_aez.tif: "
            f"{n18_shape} vs {ca_shape}"
        )

    if n18_transform != ca_transform:
        fail("native_2018.tif transform does not match country_aez.tif")

    if n18_crs != ca_crs:
        fail("native_2018.tif CRS does not match country_aez.tif")


def load_one_biome(
    biome: str,
    score_path: Path,
    country_aez: np.ndarray,
    native_2018: np.ndarray,
    nrows: int,
    ncols: int,
) -> tuple[pd.DataFrame, dict]:
    if not score_path.is_file():
        fail(f"missing accepted score parquet for {biome}: {score_path}")

    scores = pd.read_parquet(score_path)

    missing = REQUIRED_SCORE_COLUMNS - set(scores.columns)
    if missing:
        fail(
            f"{score_path.name} missing required columns: "
            f"{sorted(missing)}"
        )

    source_n = len(scores)

    # Preserve the accepted fitted ranking at its stored precision.
    p_hat = pd.to_numeric(scores["p_hat"], errors="coerce").to_numpy(dtype=np.float64)
    row = pd.to_numeric(scores["row"], errors="coerce").to_numpy(dtype=np.float64)
    col = pd.to_numeric(scores["col"], errors="coerce").to_numpy(dtype=np.float64)

    finite_coord = np.isfinite(row) & np.isfinite(col)
    if not finite_coord.all():
        fail(
            f"{biome}: score parquet contains "
            f"{int((~finite_coord).sum()):,} invalid row/col value(s)"
        )

    # Require integer-valued raster coordinates.
    if not np.equal(row, np.floor(row)).all():
        fail(f"{biome}: row contains non-integer coordinate values")
    if not np.equal(col, np.floor(col)).all():
        fail(f"{biome}: col contains non-integer coordinate values")

    row = row.astype(np.int64)
    col = col.astype(np.int64)

    in_bounds = (
        (row >= 0)
        & (row < nrows)
        & (col >= 0)
        & (col < ncols)
    )
    if not in_bounds.all():
        fail(
            f"{biome}: {int((~in_bounds).sum()):,} score row(s) "
            "fall outside the allocator grid"
        )

    finite_p = np.isfinite(p_hat)
    in_unit = (p_hat >= 0.0) & (p_hat <= 1.0)
    if not finite_p.all():
        fail(f"{biome}: p_hat contains non-finite values")
    if not in_unit.all():
        fail(
            f"{biome}: p_hat outside [0,1]; "
            f"min={np.nanmin(p_hat)} max={np.nanmax(p_hat)}"
        )

    n18_at_score = native_2018[row, col]
    ca_at_score = country_aez[row, col].astype(np.int64, copy=False)

    keep_native = n18_at_score == 1

    country_code = ca_at_score // 100
    aez = ca_at_score % 100

    supported_country = np.isin(
        country_code,
        np.fromiter(REGION_MAP.keys(), dtype=np.int64),
    )
    valid_aez = (aez >= 1) & (aez <= 18)
    valid_country_aez = supported_country & valid_aez

    keep = keep_native & valid_country_aez

    kept_code = country_code[keep]
    kept_region = np.fromiter(
        (REGION_MAP[int(x)] for x in kept_code),
        dtype=object,
        count=int(keep.sum()),
    )

    pixel_id = row[keep] * np.int64(ncols) + col[keep]

    frame = pd.DataFrame(
        {
            "pixel_id": pixel_id.astype(np.int64, copy=False),
            "row": row[keep].astype(np.int32, copy=False),
            "col": col[keep].astype(np.int32, copy=False),
            "r": kept_region,
            "aez": aez[keep].astype(np.int16, copy=False),
            "biome": biome,
            "p_hat": p_hat[keep].astype(np.float64, copy=False),
        }
    )

    drop_native = int((~keep_native).sum())
    drop_bad_caez_after_native = int((keep_native & ~valid_country_aez).sum())

    audit = {
        "source_rows": int(source_n),
        "dropped_native_2018_not_1": drop_native,
        "dropped_invalid_country_aez_after_native_filter": drop_bad_caez_after_native,
        "final_rows": int(len(frame)),
        "p_hat_min": float(frame["p_hat"].min()) if len(frame) else None,
        "p_hat_max": float(frame["p_hat"].max()) if len(frame) else None,
        "p_hat_unique": int(frame["p_hat"].nunique()),
    }

    return frame, audit


def main() -> int:
    ap = argparse.ArgumentParser(
        description="Build canonical allocator pixel pool from continuous fitted p_hat."
    )
    ap.add_argument(
        "--alloc-root",
        type=Path,
        default=DEFAULT_ROOT,
        help="allocator root directory",
    )
    ap.add_argument(
        "--dry-run",
        action="store_true",
        help="run all checks and print counts; write nothing",
    )
    ap.add_argument(
        "--force",
        action="store_true",
        help="replace existing canonical allocator_pixels outputs",
    )
    args = ap.parse_args()

    root = args.alloc_root.resolve()
    grid_dir = root / "inputs" / "grid"
    lc_dir = root / "inputs" / "landcover"
    scores_dir = root / "inputs" / "scores"

    ca_path = grid_dir / "country_aez.tif"
    grid_meta_path = grid_dir / "grid_meta.json"
    n18_path = lc_dir / "native_2018.tif"

    out_parquet = root / "allocator_pixels.parquet"
    out_meta = root / "allocator_pixels_meta.json"

    print("=" * 104)
    print("BUILD CANONICAL ALLOCATOR PIXEL POOL | continuous p_hat | native_2018")
    print("=" * 104)
    print(f"allocator root : {root}")
    print(f"country_aez    : {ca_path}")
    print(f"native_2018    : {n18_path}")
    print(f"scores dir     : {scores_dir}")
    print(f"output parquet : {out_parquet}")
    print(f"output meta    : {out_meta}")
    print(f"mode           : {'DRY RUN' if args.dry_run else 'WRITE'}")
    print()

    country_aez, ca_shape, ca_transform, ca_crs, ca_nodata = read_raster(
        ca_path, "country_aez raster"
    )
    native_2018, n18_shape, n18_transform, n18_crs, n18_nodata = read_raster(
        n18_path, "native_2018 raster"
    )

    validate_alignment(
        ca_shape,
        ca_transform,
        ca_crs,
        n18_shape,
        n18_transform,
        n18_crs,
    )

    nrows, ncols = ca_shape

    print("--- grid ---")
    print(f"shape              : {ca_shape}")
    print(f"CRS                : {ca_crs}")
    print(f"country_aez nodata : {ca_nodata}")
    print(f"native_2018 nodata : {n18_nodata}")

    if grid_meta_path.is_file():
        try:
            grid_meta = json.loads(grid_meta_path.read_text(encoding="utf-8"))
        except Exception as exc:
            fail(f"could not parse {grid_meta_path}: {exc}")
    else:
        grid_meta = {}
        print(f"WARNING: grid_meta.json not found: {grid_meta_path}")

    frames: list[pd.DataFrame] = []
    biome_audit: dict[str, dict] = {}

    print("\n--- biome pool construction ---")
    for biome, filename in ACCEPTED_SCORES.items():
        score_path = scores_dir / filename
        frame, audit = load_one_biome(
            biome=biome,
            score_path=score_path,
            country_aez=country_aez,
            native_2018=native_2018,
            nrows=nrows,
            ncols=ncols,
        )
        frames.append(frame)
        biome_audit[biome] = audit

        expected = EXPECTED_BIOME_COUNTS[biome]
        match = len(frame) == expected

        print(
            f"{biome:9} "
            f"source={audit['source_rows']:>10,}  "
            f"drop n18!=1={audit['dropped_native_2018_not_1']:>6,}  "
            f"drop bad country_aez={audit['dropped_invalid_country_aez_after_native_filter']:>6,}  "
            f"FINAL={len(frame):>10,}  "
            f"expected={expected:>10,}  "
            f"match={match}"
        )

        if not match:
            fail(
                f"{biome}: final pool count {len(frame):,} does not match "
                f"frozen expected count {expected:,}"
            )

    pool = pd.concat(frames, ignore_index=True)

    print("\n--- ranking / identity integrity ---")
    duplicate_pixel_id = int(pool["pixel_id"].duplicated().sum())
    p = pool["p_hat"]

    checks = {
        "rows_match_expected_total": len(pool) == EXPECTED_TOTAL,
        "duplicate_pixel_id_zero": duplicate_pixel_id == 0,
        "p_hat_float64": str(p.dtype) == "float64",
        "p_hat_finite": bool(np.isfinite(p.to_numpy(dtype=np.float64)).all()),
        "p_hat_in_0_1": bool(p.between(0, 1).all()),
        "p_hat_all_unique": int(p.nunique()) == len(pool),
    }

    for name, passed in checks.items():
        print(f"{name:30s}: {passed}")

    print(f"pool rows                     : {len(pool):,}")
    print(f"expected rows                 : {EXPECTED_TOTAL:,}")
    print(f"duplicate pixel_id            : {duplicate_pixel_id:,}")
    print(f"p_hat dtype                   : {p.dtype}")
    print(f"p_hat unique                  : {int(p.nunique()):,}")
    print(f"p_hat min                     : {float(p.min())}")
    print(f"p_hat max                     : {float(p.max())}")

    if not all(checks.values()):
        fail("integrity gate failed; canonical allocator pool will not be written")

    print("\n--- pixels per region ---")
    per_region = pool.groupby("r", observed=True).size().sort_index()
    print(per_region.to_string())

    print("\n--- pixels per biome ---")
    per_biome = pool.groupby("biome", observed=True).size()
    print(per_biome.to_string())

    print("\n--- pixels per (region, biome) ---")
    per_region_biome = pool.groupby(["r", "biome"], observed=True).size()
    print(per_region_biome.to_string())

    if args.dry_run:
        print("\n[DRY RUN VERIFIED] Canonical continuous-score pool passes all frozen checks.")
        print("No files written.")
        return 0

    existing = [p for p in (out_parquet, out_meta) if p.exists()]
    if existing and not args.force:
        print("\nCanonical output(s) already exist:")
        for pth in existing:
            print(f"  {pth}")
        print("\nRefusing to overwrite without --force.")
        return 2

    # Write parquet only after all checks pass.
    pool.to_parquet(out_parquet, index=False)

    meta = {
        "built_utc": datetime.now(timezone.utc).isoformat(),
        "base_year": 2018,
        "pool_definition": (
            "accepted continuous fitted p_hat row exists AND native_2018 == 1 "
            "AND country_aez decodes to supported MERCOSUR country AND AEZ in 1..18"
        ),
        "future_landcover_filter_used": False,
        "p_hat_source": "accepted biome-specific *_oos_scores.parquet",
        "p_hat_storage_dtype": "float64",
        "region_map": {str(k): v for k, v in REGION_MAP.items()},
        "grid_shape": [int(nrows), int(ncols)],
        "grid_transform": list(ca_transform)[:6],
        "grid_crs": ca_crs,
        "grid_meta_source": str(grid_meta_path),
        "grid_meta": grid_meta,
        "n_pixels": int(len(pool)),
        "expected_n_pixels": int(EXPECTED_TOTAL),
        "per_biome": {
            str(k): int(v)
            for k, v in pool.groupby("biome", observed=True).size().items()
        },
        "per_region": {
            str(k): int(v)
            for k, v in pool.groupby("r", observed=True).size().items()
        },
        "per_region_biome": {
            f"{r}|{b}": int(n)
            for (r, b), n
            in pool.groupby(["r", "biome"], observed=True).size().items()
        },
        "biome_build_audit": biome_audit,
        "sources": {
            "country_aez": str(ca_path),
            "native_2018": str(n18_path),
            "scores": {
                biome: str(scores_dir / filename)
                for biome, filename in ACCEPTED_SCORES.items()
            },
        },
        "integrity": {
            "duplicate_pixel_id": duplicate_pixel_id,
            "p_hat_finite": True,
            "p_hat_in_0_1": True,
            "p_hat_all_unique": True,
        },
    }

    out_meta.write_text(json.dumps(meta, indent=2), encoding="utf-8")

    print(f"\nWROTE {out_parquet}  ({len(pool):,} pixels)")
    print(f"WROTE {out_meta}")
    print("[CANONICAL POOL WRITTEN] Continuous fitted ranking is now canonical.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
