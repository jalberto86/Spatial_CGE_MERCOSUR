#!/usr/bin/env python3
# -*- coding: utf-8 -*-
r"""
build_biome_aez_coverage.py
===========================
Build the country x AEZ coverage table used by allocate.py to downscale whole-AEZ
CGE land demand into the four modeled biomes.

Why native@2017 is used here
----------------------------
The allocator's CGE land-area anchor is LCOV17.csv. Therefore the coverage factor
used to split whole-AEZ demand is the share of native@2017 land that falls inside
the four modeled biomes:

    native_ratio(r,aez,biome)
      = native@2017 pixels in that biome
        / all native@2017 pixels in the country x AEZ cell

and:

    cover_native(r,aez)
      = sum_b native_ratio(r,aez,b)

This is distinct from the allocator pixel-eligibility baseline. The canonical
allocator pool is native@2018 because that is the baseline used by the OOS/pixel
allocation stage. The two dates serve different accounting roles.

Canonical inputs
----------------
Under --alloc-root:
  inputs/grid/country_aez.tif
  inputs/grid/biome.tif
  allocator_pixels.parquet

External source:
  --native-2017 <path>
      Upstream MERCOSUR2 processed native@2017 raster. It is intentionally not
      copied into allocator runtime inputs.

Output
------
  biome_aez_coverage.csv

Columns:
  r, aez, biome,
  area_ratio,
  native_ratio,
  pool_px,
  aez_total_px,
  aez_native_px,
  biome_code,
  cover_area,
  cover_native,
  overalloc_area,
  overalloc_native

Only cover_native is consumed by allocate.py. The other columns are retained for
auditability and diagnostics. Component ratios are rounded to 4 decimals, exactly
as in the original builder; cover_area and cover_native are then summed without a
second rounding step so the frozen arithmetic is reproduced exactly.

Usage from allocator root
-------------------------
  python src\build_biome_aez_coverage.py ^
      --native-2017 "C:\...\MERCOSUR2\data\processed\landcover\native_2017.tif" ^
      --force

For a non-destructive comparison build:
  python src\build_biome_aez_coverage.py ^
      --native-2017 "C:\...\MERCOSUR2\data\processed\landcover\native_2017.tif" ^
      --output biome_aez_coverage_probe.csv ^
      --force
"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

import numpy as np
import pandas as pd
import rasterio


BIOMES = ["cerrado", "chaco", "amazonia", "pantanal"]
REGION_MAP = {1: "BRA", 2: "ARG", 3: "PRY", 4: "URY", 5: "BOL"}
NATIVE_VALUE = 1
DEFAULT_ROOT = Path(r"C:\Users\JesusMERCADO\GAMSProjects\GTAP_AEZ\rdyn\allocator")


def read_band_with_profile(path: Path):
    with rasterio.open(path) as ds:
        arr = ds.read(1)
        profile = {
            "shape": (ds.height, ds.width),
            "transform": ds.transform,
            "crs": str(ds.crs),
        }
    return arr, profile


def assert_same_grid(label_a: str, pa: dict, label_b: str, pb: dict) -> None:
    if pa["shape"] != pb["shape"]:
        sys.exit(
            f"grid mismatch: {label_a} shape={pa['shape']} vs "
            f"{label_b} shape={pb['shape']}"
        )
    if pa["transform"] != pb["transform"]:
        sys.exit(f"grid mismatch: {label_a} and {label_b} transforms differ")
    if pa["crs"] != pb["crs"]:
        sys.exit(f"grid mismatch: {label_a} crs={pa['crs']} vs {label_b} crs={pb['crs']}")


def main() -> int:
    ap = argparse.ArgumentParser(
        description="Build canonical country-AEZ biome/native coverage table."
    )
    ap.add_argument("--alloc-root", type=Path, default=DEFAULT_ROOT)
    ap.add_argument(
        "--native-2017",
        required=True,
        type=Path,
        help="upstream MERCOSUR2 data/processed/landcover/native_2017.tif",
    )
    ap.add_argument(
        "--output",
        type=Path,
        default=None,
        help="output CSV; default: <alloc-root>/biome_aez_coverage.csv",
    )
    ap.add_argument(
        "--force",
        action="store_true",
        help="replace output CSV if it already exists",
    )
    ap.add_argument(
        "--dry-run",
        action="store_true",
        help="build and validate in memory; write nothing",
    )
    args = ap.parse_args()

    root = args.alloc_root.resolve()
    ca_path = root / "inputs" / "grid" / "country_aez.tif"
    biome_path = root / "inputs" / "grid" / "biome.tif"
    pool_path = root / "allocator_pixels.parquet"
    native_path = args.native_2017.resolve()
    out_path = (
        args.output.resolve()
        if args.output is not None
        else root / "biome_aez_coverage.csv"
    )

    for p, label in [
        (ca_path, "country-AEZ raster"),
        (biome_path, "biome raster"),
        (pool_path, "canonical allocator pool"),
        (native_path, "native@2017 raster"),
    ]:
        if not p.exists():
            sys.exit(f"missing {label}: {p}")

    if out_path.exists() and not args.force and not args.dry_run:
        sys.exit(f"refusing to overwrite existing output: {out_path}\nUse --force to replace it.")

    ca, ca_prof = read_band_with_profile(ca_path)
    bio, bio_prof = read_band_with_profile(biome_path)
    nat, nat_prof = read_band_with_profile(native_path)

    assert_same_grid("country_aez", ca_prof, "biome", bio_prof)
    assert_same_grid("country_aez", ca_prof, "native_2017", nat_prof)

    ca = ca.ravel()
    bio = bio.ravel()
    nat = nat.ravel()

    pool = pd.read_parquet(
        pool_path,
        columns=["pixel_id", "r", "aez", "biome"],
    )

    if pool["pixel_id"].duplicated().any():
        sys.exit("allocator_pixels.parquet: pixel_id is not unique")

    pids_all = pool["pixel_id"].to_numpy(dtype=np.int64, copy=False)
    if len(pids_all) and (pids_all.min() < 0 or pids_all.max() >= len(bio)):
        sys.exit("allocator pool pixel_id falls outside raster grid")

    # Infer biome raster codes from the canonical pool, avoiding hard-coded
    # assumptions about the integer coding of biome.tif.
    code_of: dict[str, int] = {}
    print("=== build_biome_aez_coverage ===")
    print(f"allocator root : {root}")
    print(f"native@2017    : {native_path}")
    print(f"canonical pool : {pool_path}")
    print(f"output         : {out_path}")
    print()
    print("inferred biome.tif codes from canonical allocator pool:")

    for b in BIOMES:
        pids = pool.loc[pool["biome"] == b, "pixel_id"].to_numpy(dtype=np.int64)
        if len(pids) == 0:
            sys.exit(f"canonical allocator pool contains no pixels for biome '{b}'")

        codes, counts = np.unique(bio[pids], return_counts=True)
        code = int(codes[counts.argmax()])
        share = float(counts.max() / counts.sum())
        code_of[b] = code
        print(f"  {b:9s} -> code {code:<3d} ({share:.4%} of pool pixels)")

    if len(set(code_of.values())) != len(BIOMES):
        sys.exit("two modeled biomes inferred the same biome.tif code")

    # Country x AEZ raster convention: country code in hundreds + AEZ 1..18.
    incountry = ca != 0
    df = pd.DataFrame(
        {
            "caez": ca[incountry].astype(np.int64),
            "bcode": bio[incountry].astype(np.int64),
            "isnat": nat[incountry] == NATIVE_VALUE,
        }
    )
    df["r"] = (df["caez"] // 100).map(REGION_MAP)
    df["aez"] = (df["caez"] % 100).astype(np.int16)
    df = df.dropna(subset=["r"])
    df = df[df["aez"].between(1, 18)].copy()

    aez_total = df.groupby(["r", "aez"]).size().rename("aez_total_px")
    aez_native = (
        df[df["isnat"]]
        .groupby(["r", "aez"])
        .size()
        .rename("aez_native_px")
    )

    code_to_biome = {code: biome for biome, code in code_of.items()}
    df["biome"] = df["bcode"].map(code_to_biome)
    in_biome = df[df["biome"].notna()]

    area_b = (
        in_biome.groupby(["r", "aez", "biome"])
        .size()
        .rename("area_px")
    )
    native_b = (
        in_biome[in_biome["isnat"]]
        .groupby(["r", "aez", "biome"])
        .size()
        .rename("native_b_px")
    )
    pool_cnt = (
        pool.groupby(["r", "aez", "biome"])
        .size()
        .rename("pool_px")
    )

    rows = []
    for (r, a), total_px in aez_total.items():
        native_total_px = int(aez_native.get((r, a), 0))
        for b in BIOMES:
            area_px = int(area_b.get((r, a, b), 0))
            native_b_px = int(native_b.get((r, a, b), 0))
            pool_px = int(pool_cnt.get((r, a, b), 0))

            # Keep rows that matter either geometrically or to the canonical pool.
            if area_px == 0 and pool_px == 0:
                continue

            rows.append(
                {
                    "r": r,
                    "aez": int(a),
                    "biome": b,
                    "area_ratio": round(area_px / int(total_px), 4) if total_px else 0.0,
                    "native_ratio": (
                        round(native_b_px / native_total_px, 4)
                        if native_total_px
                        else 0.0
                    ),
                    "pool_px": pool_px,
                    "aez_total_px": int(total_px),
                    "aez_native_px": native_total_px,
                    "biome_code": code_of[b],
                }
            )

    cov = pd.DataFrame(rows)
    if cov.empty:
        sys.exit("coverage table is empty; check grid inputs and biome-code inference")

    # Preserve the original coverage-table arithmetic exactly:
    # component ratios are rounded to 4 decimals above, then summed as-is.
    # Do NOT round cover_area / cover_native again; the frozen CSV therefore
    # legitimately contains binary floating representations such as
    # 0.8770000000000001. allocate.py consumes these summed values directly.
    summary = (
        cov.groupby(["r", "aez"], as_index=False)
        .agg(
            cover_area=("area_ratio", "sum"),
            cover_native=("native_ratio", "sum"),
        )
    )
    summary["overalloc_area"] = (
        (1.0 / summary["cover_area"])
        .replace([np.inf, -np.inf], np.nan)
        .round(2)
    )
    summary["overalloc_native"] = (
        (1.0 / summary["cover_native"])
        .replace([np.inf, -np.inf], np.nan)
        .round(2)
    )

    cov = cov.merge(summary, on=["r", "aez"], how="left")
    cov = cov.sort_values(["r", "aez", "biome"]).reset_index(drop=True)

    if not cov["cover_native"].between(0, 1.0001).all():
        bad = cov.loc[~cov["cover_native"].between(0, 1.0001), ["r", "aez", "cover_native"]]
        sys.exit(f"cover_native outside [0,1]:\n{bad.drop_duplicates().to_string(index=False)}")

    print()
    print("--- canonical coverage summary ---")
    print(f"rows                 : {len(cov):,}")
    print(f"country x AEZ cells  : {len(summary):,}")
    print(f"cover_native min     : {summary['cover_native'].min():.4f}")
    print(f"cover_native max     : {summary['cover_native'].max():.4f}")
    print(f"canonical pool pixels: {int(cov['pool_px'].sum()):,}")
    print()
    print("cover_native is the allocation-driving field.")
    print("pool_px is diagnostic and is rebuilt from the current canonical native@2018 pool.")

    if args.dry_run:
        print("\n[DRY RUN COMPLETE] No files written.")
        return 0

    out_path.parent.mkdir(parents=True, exist_ok=True)
    cov.to_csv(out_path, index=False)
    print(f"\nWROTE {out_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
