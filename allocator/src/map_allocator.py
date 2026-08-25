#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
map_allocator.py
================
Build GIS-ready rasters from one allocator result.

The script is simulation- and base-year-generic:
  - simulation tag is inferred from defor_<sim>.parquet;
  - base year is read from defor_<sim>_meta.json;
  - grid shape / transform / CRS are read from the metadata belonging to
    the actual allocator pool used by the run.

Required input
--------------
outputs/defor_<sim>.parquet
    Full allocator pool with:
      pixel_id, row, col, r, aez, biome, p_hat, convert_year

Required grid metadata
----------------------
Resolved automatically from allocator run metadata:
    run meta "pool" -> sibling <pool_stem>_meta.json
with allocator_pixels_meta.json retained as the canonical fallback.

The grid metadata must contain:
    grid_shape, grid_transform, grid_crs
and, when n_pixels is present, it must match the defor parquet row count.

Optional input
--------------
analysis/<sim>/derived/front_pixels_<sim>.parquet
    Written by analyze_allocator.py. If present, annual front-type rasters are
    produced. If absent, the core maps are still written.

Outputs
-------
analysis/<sim>/rasters/

  conversion_year_<sim>.tif
      Eligible baseline-native pixels:
        0          = still native at end of simulation
        YYYY       = allocated conversion year
        65535      = outside allocator baseline-native pool (NoData)

  annual/defor_<YYYY>.tif
      0 = baseline-native pixel not converted in YYYY
      1 = converted in YYYY
      255 = outside allocator baseline-native pool (NoData)

  cumulative/defor_through_<YYYY>.tif
      0 = baseline-native pixel still unconverted through YYYY
      1 = converted by YYYY
      255 = outside allocator baseline-native pool (NoData)

  hotspots/annual_hotspot_<YYYY>.tif
      Converted km2 in each coarse analysis block for that year.

  hotspots/cumulative_hotspot_through_<YYYY>.tif
      Cumulative converted km2 in each coarse analysis block through that year.

  fronts/front_type_<YYYY>.tif    [if front_pixels exists]
      0 = not converted in YYYY
      1 = new_model_front
      2 = model_expansion
      255 = outside allocator baseline-native pool (NoData)

  map_layers.csv
      Manifest describing every raster written.

  map_method.json
      Machine-readable provenance and raster coding.

Important interpretation
------------------------
Front maps are MODEL-RELATIVE. They distinguish expansion next to earlier
simulated conversion from new disconnected simulated patches. They do not
identify adjacency to deforestation that already existed before the allocator
base year unless that historical anthropic footprint is separately introduced.

Hotspots aggregate the allocator's 1-km2 pixels into N x N source-pixel blocks.
Default N=10, i.e. nominal 10 km x 10 km blocks on the allocator grid.

Usage from allocator root
-------------------------
    python src\\map_allocator.py --defor outputs\\defor_Rdyn.parquet

Using the established project venv:
    & "C:\\Users\\JesusMERCADO\\QGISProjects\\MERCOSUR2\\.venv\\Scripts\\python.exe" `
        src\\map_allocator.py --defor outputs\\defor_Rdyn.parquet

Optional:
    --hotspot-block-px 20
    --no-hotspots
    --no-fronts
"""

from __future__ import annotations

import argparse
import csv
import json
import math
import shutil
import sys
from pathlib import Path

import numpy as np
import pandas as pd
import rasterio
from affine import Affine


YEAR_NODATA = np.uint16(65535)
BYTE_NODATA = np.uint8(255)
FLOAT_NODATA = np.float32(-9999.0)
KM2_PER_PIXEL = 1.0

REQUIRED_COLUMNS = {"pixel_id", "row", "col", "convert_year"}


def infer_sim(defor_path: Path) -> str:
    stem = defor_path.stem
    return stem[len("defor_"):] if stem.startswith("defor_") else stem


def infer_allocator_root(defor_path: Path) -> Path:
    """
    Infer allocator root from an allocator output directory.
    """
    if defor_path.parent.name.lower().startswith("outputs"):
        return defor_path.parent.parent
    return defor_path.parent


def read_json(path: Path, label: str) -> dict:
    if not path.exists():
        sys.exit(f"missing {label}: {path}")
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except Exception as e:
        sys.exit(f"could not parse {label} {path}: {e}")


def resolve_grid_meta_path(
    run_meta: dict,
    allocator_root: Path,
    explicit: Path | None,
) -> Path:
    """
    Resolve the grid metadata that belongs to the actual allocator pool.

    Priority:
      1. explicit --grid-meta;
      2. run metadata "pool" -> sibling <pool_stem>_meta.json;
      3. canonical allocator_pixels_meta.json fallback.

    This ensures the mapper uses the grid metadata associated with the
    allocator pool recorded by the run, rather than silently borrowing
    unrelated grid provenance.
    """
    if explicit is not None:
        return explicit.resolve()

    raw_pool = run_meta.get("pool")
    if raw_pool:
        pool_path = Path(str(raw_pool))
        if not pool_path.is_absolute():
            pool_path = allocator_root / pool_path
        candidate = pool_path.with_name(pool_path.stem + "_meta.json")
        if candidate.exists():
            return candidate.resolve()

    return (allocator_root / "allocator_pixels_meta.json").resolve()


def resolve_base_year(meta: dict, pool: pd.DataFrame) -> int:
    raw = meta.get("base_year")
    if raw is not None:
        try:
            return int(raw)
        except Exception:
            pass

    years = sorted(int(y) for y in pool.loc[pool["convert_year"] > 0, "convert_year"].unique())
    if years:
        inferred = years[0] - 1
        print(f"WARNING: base_year missing from metadata; inferring {inferred} from first conversion year.")
        return inferred

    sys.exit("base_year missing from metadata and cannot be inferred because no conversion years exist.")


def validate_grid_meta(grid_meta: dict):
    shape = grid_meta.get("grid_shape")
    tr = grid_meta.get("grid_transform")
    crs = grid_meta.get("grid_crs")

    if not isinstance(shape, (list, tuple)) or len(shape) != 2:
        sys.exit("allocator_pixels_meta.json: grid_shape must contain [rows, cols]")
    if not isinstance(tr, (list, tuple)) or len(tr) < 6:
        sys.exit("allocator_pixels_meta.json: grid_transform must contain at least 6 affine coefficients")
    if not crs:
        sys.exit("allocator_pixels_meta.json: grid_crs is missing")

    height, width = int(shape[0]), int(shape[1])
    transform = Affine(*[float(x) for x in tr[:6]])
    return height, width, transform, crs


def raster_profile(height, width, transform, crs, dtype, nodata):
    return {
        "driver": "GTiff",
        "height": int(height),
        "width": int(width),
        "count": 1,
        "dtype": np.dtype(dtype).name,
        "crs": crs,
        "transform": transform,
        "nodata": nodata,
        "compress": "DEFLATE",
        "predictor": 2 if np.issubdtype(np.dtype(dtype), np.integer) else 3,
        "tiled": True,
        "blockxsize": 512,
        "blockysize": 512,
        "BIGTIFF": "IF_SAFER",
    }


def write_raster(path: Path, arr: np.ndarray, transform, crs, nodata, tags: dict | None = None):
    path.parent.mkdir(parents=True, exist_ok=True)
    profile = raster_profile(arr.shape[0], arr.shape[1], transform, crs, arr.dtype, nodata)
    with rasterio.open(path, "w", **profile) as dst:
        dst.write(arr, 1)
        if tags:
            dst.update_tags(**{str(k): str(v) for k, v in tags.items()})


def add_manifest_row(rows, path, layer_type, year, units, nodata, coding, base_year, sim):
    rows.append({
        "sim": sim,
        "base_year": base_year,
        "layer_type": layer_type,
        "year": "" if year is None else int(year),
        "units": units,
        "nodata": nodata,
        "coding": coding,
        "path": str(path),
    })


def coarse_geometry(height: int, width: int, transform: Affine, block: int):
    coarse_h = math.ceil(height / block)
    coarse_w = math.ceil(width / block)
    coarse_transform = transform * Affine.scale(block, block)
    return coarse_h, coarse_w, coarse_transform


def coarse_counts(rows: np.ndarray, cols: np.ndarray, coarse_w: int, block: int, coarse_size: int):
    rr = rows // block
    cc = cols // block
    idx = rr.astype(np.int64) * coarse_w + cc.astype(np.int64)
    return np.bincount(idx, minlength=coarse_size)


def main() -> int:
    ap = argparse.ArgumentParser(description="Build GIS rasters from one allocator result.")
    ap.add_argument("--defor", required=True, type=Path, help="outputs/defor_<sim>.parquet")
    ap.add_argument("--meta", default=None, type=Path,
                    help="defor_<sim>_meta.json override")
    ap.add_argument("--grid-meta", default=None, type=Path,
                    help="allocator_pixels_meta.json override")
    ap.add_argument("--front-pixels", default=None, type=Path,
                    help="front_pixels_<sim>.parquet override")
    ap.add_argument("--analysis-root", default=None, type=Path,
                    help="default: <allocator_root>/analysis")
    ap.add_argument("--hotspot-block-px", type=int, default=10,
                    help="coarse hotspot block width in source pixels (default: 10)")
    ap.add_argument("--no-hotspots", action="store_true",
                    help="skip annual/cumulative hotspot rasters")
    ap.add_argument("--no-fronts", action="store_true",
                    help="skip front-type rasters even if front_pixels exists")
    ap.add_argument(
        "--force",
        action="store_true",
        help="replace existing canonical rasters for this simulation",
    )
    args = ap.parse_args()

    defor_path = args.defor.resolve()
    if not defor_path.exists():
        sys.exit(f"missing defor parquet: {defor_path}")

    if args.hotspot_block_px < 1:
        sys.exit("--hotspot-block-px must be >= 1")

    sim = infer_sim(defor_path)
    allocator_root = infer_allocator_root(defor_path)
    analysis_root = args.analysis_root.resolve() if args.analysis_root else allocator_root / "analysis"
    sim_dir = analysis_root / sim
    raster_dir = sim_dir / "rasters"
    annual_dir = raster_dir / "annual"
    cumulative_dir = raster_dir / "cumulative"
    hotspot_dir = raster_dir / "hotspots"
    front_dir = raster_dir / "fronts"

    meta_path = args.meta.resolve() if args.meta else defor_path.parent / f"defor_{sim}_meta.json"
    meta = read_json(meta_path, "allocator run metadata")

    grid_meta_path = resolve_grid_meta_path(
        run_meta=meta,
        allocator_root=allocator_root,
        explicit=args.grid_meta,
    )
    grid_meta = read_json(grid_meta_path, "allocator pixel grid metadata")

    front_path = (
        args.front_pixels.resolve()
        if args.front_pixels
        else sim_dir / "derived" / f"front_pixels_{sim}.parquet"
    )

    height, width, transform, crs = validate_grid_meta(grid_meta)

    pool = pd.read_parquet(defor_path, columns=sorted(REQUIRED_COLUMNS))
    missing = REQUIRED_COLUMNS - set(pool.columns)
    if missing:
        sys.exit(f"defor parquet missing required columns: {sorted(missing)}")

    for col in ("row", "col", "convert_year"):
        pool[col] = pd.to_numeric(pool[col], errors="coerce")
        if pool[col].isna().any():
            sys.exit(f"{col} contains null/non-numeric values")
        pool[col] = pool[col].astype(np.int64)

    if pool["pixel_id"].duplicated().any():
        sys.exit("pixel_id is not unique in defor parquet")

    if ((pool["row"] < 0) | (pool["row"] >= height)).any():
        sys.exit("row values fall outside grid_shape")
    if ((pool["col"] < 0) | (pool["col"] >= width)).any():
        sys.exit("col values fall outside grid_shape")
    if (pool["convert_year"] < 0).any():
        sys.exit("convert_year contains negative values")
    if (pool["convert_year"] >= int(YEAR_NODATA)).any():
        sys.exit(f"convert_year must be < {int(YEAR_NODATA)}")

    base_year = resolve_base_year(meta, pool)
    data_years = sorted(int(y) for y in pool.loc[pool["convert_year"] > 0, "convert_year"].unique())

    # Prefer the declared simulation horizon from allocator metadata so years with
    # zero conversion still receive annual/cumulative rasters. Always retain any
    # positive conversion year present in the parquet as a safeguard.
    meta_years = meta.get("years")
    if isinstance(meta_years, list):
        declared_years = sorted(int(y) for y in meta_years if int(y) > base_year)
        years = sorted(set(declared_years) | set(data_years))
        if data_years != declared_years:
            print(
                f"NOTE: positive-conversion years in parquet are {data_years}; "
                f"declared allocation horizon is {declared_years}. "
                "Maps will cover the full declared horizon."
            )
    else:
        years = data_years

    grid_meta_n = grid_meta.get("n_pixels")
    if grid_meta_n is not None:
        try:
            if int(grid_meta_n) != len(pool):
                sys.exit(
                    "grid metadata belongs to a different allocator pool: "
                    f"meta n_pixels={int(grid_meta_n):,}, defor rows={len(pool):,}"
                )
        except (TypeError, ValueError):
            sys.exit("grid metadata n_pixels is present but not an integer")

    rows = pool["row"].to_numpy(dtype=np.int64, copy=False)
    cols = pool["col"].to_numpy(dtype=np.int64, copy=False)
    cyear = pool["convert_year"].to_numpy(dtype=np.int64, copy=False)

    if raster_dir.exists() and any(raster_dir.rglob("*")) and not args.force:
        sys.exit(
            f"refusing to overwrite existing canonical map outputs under {raster_dir}\n"
            "Use --force only if you intentionally want to replace this "
            "simulation's raster set."
        )

    # Explicit --force means rebuild the mapper-owned raster tree cleanly.
    # This prevents stale TIFFs/manifests from surviving a changed simulation
    # horizon, hotspot setting, or front-map setting.
    if args.force and raster_dir.exists():
        shutil.rmtree(raster_dir)

    raster_dir.mkdir(parents=True, exist_ok=True)
    manifest = []

    print("=== map_allocator ===")
    print(f"sim          : {sim}")
    print(f"base year    : {base_year}")
    print(f"defor        : {defor_path}")
    print(f"grid meta    : {grid_meta_path}")
    print(f"grid         : {height} x {width}")
    print(f"crs          : {crs}")
    print(f"years        : {years if years else '(no converted pixels)'}")
    print(f"raster dir   : {raster_dir}")
    print(f"hotspot      : {'skipped' if args.no_hotspots else f'{args.hotspot_block_px} x {args.hotspot_block_px} source pixels'}")
    print(f"front source : {'skipped' if args.no_fronts else (front_path if front_path.exists() else '(not found; front maps skipped)')}")
    print()

    # ------------------------------------------------------------------
    # 1. Conversion-year raster
    # ------------------------------------------------------------------
    conv_arr = np.full((height, width), YEAR_NODATA, dtype=np.uint16)
    conv_arr[rows, cols] = cyear.astype(np.uint16)

    conv_path = raster_dir / f"conversion_year_{sim}.tif"
    write_raster(
        conv_path, conv_arr, transform, crs, int(YEAR_NODATA),
        tags={
            "sim": sim,
            "base_year": base_year,
            "definition": f"0=still baseline-native; positive value=allocated conversion year; baseline=native@{base_year}",
        },
    )
    add_manifest_row(
        manifest, conv_path, "conversion_year", None, "year",
        int(YEAR_NODATA),
        f"0=still native relative to native@{base_year}; YYYY=conversion year",
        base_year, sim,
    )
    print(f"WROTE {conv_path}")

    # Reusable baseline-pool mask for annual/cumulative maps.
    baseline_valid = np.zeros((height, width), dtype=bool)
    baseline_valid[rows, cols] = True

    # ------------------------------------------------------------------
    # 2. Annual and cumulative binary conversion rasters
    # ------------------------------------------------------------------
    for year in years:
        annual = np.full((height, width), BYTE_NODATA, dtype=np.uint8)
        annual[baseline_valid] = 0
        mask_y = cyear == year
        annual[rows[mask_y], cols[mask_y]] = 1

        p = annual_dir / f"defor_{year}.tif"
        write_raster(
            p, annual, transform, crs, int(BYTE_NODATA),
            tags={
                "sim": sim,
                "base_year": base_year,
                "year": year,
                "definition": f"1=converted in {year}; 0=baseline-native pixel not converted in {year}",
            },
        )
        add_manifest_row(
            manifest, p, "annual_conversion", year, "binary",
            int(BYTE_NODATA),
            "0=not converted that year; 1=converted that year",
            base_year, sim,
        )

        cumulative = np.full((height, width), BYTE_NODATA, dtype=np.uint8)
        cumulative[baseline_valid] = 0
        mask_c = (cyear > 0) & (cyear <= year)
        cumulative[rows[mask_c], cols[mask_c]] = 1

        p = cumulative_dir / f"defor_through_{year}.tif"
        write_raster(
            p, cumulative, transform, crs, int(BYTE_NODATA),
            tags={
                "sim": sim,
                "base_year": base_year,
                "through_year": year,
                "definition": f"1=converted after base {base_year} and by {year}; 0=still unconverted through {year}",
            },
        )
        add_manifest_row(
            manifest, p, "cumulative_conversion", year, "binary",
            int(BYTE_NODATA),
            f"0=still unconverted since native@{base_year}; 1=converted by {year}",
            base_year, sim,
        )

    # ------------------------------------------------------------------
    # 3. Hotspot rasters: coarse converted km2
    # ------------------------------------------------------------------
    if not args.no_hotspots and years:
        block = int(args.hotspot_block_px)
        coarse_h, coarse_w, coarse_transform = coarse_geometry(height, width, transform, block)
        coarse_size = coarse_h * coarse_w

        baseline_count = coarse_counts(rows, cols, coarse_w, block, coarse_size)
        valid_coarse = baseline_count > 0

        for year in years:
            mask_y = cyear == year
            annual_count = coarse_counts(rows[mask_y], cols[mask_y], coarse_w, block, coarse_size)

            hot = np.full(coarse_size, FLOAT_NODATA, dtype=np.float32)
            hot[valid_coarse] = (annual_count[valid_coarse] * KM2_PER_PIXEL).astype(np.float32)
            hot = hot.reshape(coarse_h, coarse_w)

            p = hotspot_dir / f"annual_hotspot_{year}.tif"
            write_raster(
                p, hot, coarse_transform, crs, float(FLOAT_NODATA),
                tags={
                    "sim": sim,
                    "base_year": base_year,
                    "year": year,
                    "block_source_pixels": block,
                    "units": "km2 converted in coarse block",
                },
            )
            add_manifest_row(
                manifest, p, "annual_hotspot", year, "km2 per coarse block",
                float(FLOAT_NODATA),
                f"value=converted km2 in {block}x{block} source-pixel block",
                base_year, sim,
            )

            mask_c = (cyear > 0) & (cyear <= year)
            cum_count = coarse_counts(rows[mask_c], cols[mask_c], coarse_w, block, coarse_size)

            hot_c = np.full(coarse_size, FLOAT_NODATA, dtype=np.float32)
            hot_c[valid_coarse] = (cum_count[valid_coarse] * KM2_PER_PIXEL).astype(np.float32)
            hot_c = hot_c.reshape(coarse_h, coarse_w)

            p = hotspot_dir / f"cumulative_hotspot_through_{year}.tif"
            write_raster(
                p, hot_c, coarse_transform, crs, float(FLOAT_NODATA),
                tags={
                    "sim": sim,
                    "base_year": base_year,
                    "through_year": year,
                    "block_source_pixels": block,
                    "units": "cumulative km2 converted in coarse block",
                },
            )
            add_manifest_row(
                manifest, p, "cumulative_hotspot", year, "km2 per coarse block",
                float(FLOAT_NODATA),
                f"value=cumulative converted km2 in {block}x{block} source-pixel block",
                base_year, sim,
            )

    # ------------------------------------------------------------------
    # 4. Front-type rasters, if analyze_allocator.py output exists
    # ------------------------------------------------------------------
    front_written = False
    if not args.no_fronts:
        if front_path.exists():
            need_front = {"row", "col", "convert_year", "front_type"}
            fp = pd.read_parquet(front_path, columns=sorted(need_front))
            miss = need_front - set(fp.columns)
            if miss:
                print(f"WARNING: front pixel parquet missing {sorted(miss)}; front maps skipped.")
            else:
                fp["row"] = pd.to_numeric(fp["row"], errors="coerce")
                fp["col"] = pd.to_numeric(fp["col"], errors="coerce")
                fp["convert_year"] = pd.to_numeric(fp["convert_year"], errors="coerce")
                if fp[["row", "col", "convert_year"]].isna().any().any():
                    print("WARNING: front pixel parquet has invalid row/col/year values; front maps skipped.")
                else:
                    fp["row"] = fp["row"].astype(np.int64)
                    fp["col"] = fp["col"].astype(np.int64)
                    fp["convert_year"] = fp["convert_year"].astype(np.int64)

                    allowed_types = {"new_model_front", "model_expansion"}
                    unknown = sorted(set(fp["front_type"].astype(str)) - allowed_types)
                    if unknown:
                        print(f"WARNING: unknown front_type values ignored: {unknown}")

                    fr = fp["row"].to_numpy(dtype=np.int64, copy=False)
                    fc = fp["col"].to_numpy(dtype=np.int64, copy=False)
                    fy = fp["convert_year"].to_numpy(dtype=np.int64, copy=False)
                    ft = fp["front_type"].astype(str).to_numpy()

                    if ((fr < 0) | (fr >= height)).any() or ((fc < 0) | (fc >= width)).any():
                        print("WARNING: front pixel coordinates fall outside grid_shape; front maps skipped.")
                    else:
                        for year in years:
                            front = np.full((height, width), BYTE_NODATA, dtype=np.uint8)
                            front[baseline_valid] = 0

                            ymask = fy == year
                            new_mask = ymask & (ft == "new_model_front")
                            exp_mask = ymask & (ft == "model_expansion")

                            front[fr[new_mask], fc[new_mask]] = 1
                            front[fr[exp_mask], fc[exp_mask]] = 2

                            p = front_dir / f"front_type_{year}.tif"
                            write_raster(
                                p, front, transform, crs, int(BYTE_NODATA),
                                tags={
                                    "sim": sim,
                                    "base_year": base_year,
                                    "year": year,
                                    "front_code_0": "not converted in this year",
                                    "front_code_1": "new_model_front",
                                    "front_code_2": "model_expansion",
                                    "interpretation": "model-relative; relative to earlier simulated conversion only",
                                },
                            )
                            add_manifest_row(
                                manifest, p, "front_type", year, "categorical",
                                int(BYTE_NODATA),
                                "0=not converted that year; 1=new_model_front; 2=model_expansion",
                                base_year, sim,
                            )
                        front_written = True
        else:
            print(f"NOTE: front pixel file not found; front maps skipped: {front_path}")

    # ------------------------------------------------------------------
    # Manifest + method sidecar
    # ------------------------------------------------------------------
    manifest_path = raster_dir / "map_layers.csv"
    with manifest_path.open("w", newline="", encoding="utf-8") as f:
        fields = ["sim", "base_year", "layer_type", "year", "units", "nodata", "coding", "path"]
        w = csv.DictWriter(f, fieldnames=fields)
        w.writeheader()
        w.writerows(manifest)

    method = {
        "sim": sim,
        "base_year": base_year,
        "first_conversion_year": years[0] if years else None,
        "last_conversion_year": years[-1] if years else None,
        "defor_source": str(defor_path),
        "allocator_run_meta": str(meta_path),
        "grid_meta": str(grid_meta_path),
        "front_pixels_source": str(front_path) if front_path.exists() else None,
        "grid_shape": [height, width],
        "grid_transform": [transform.a, transform.b, transform.c, transform.d, transform.e, transform.f],
        "grid_crs": str(crs),
        "source_pixel_area_km2": KM2_PER_PIXEL,
        "conversion_year_nodata": int(YEAR_NODATA),
        "binary_nodata": int(BYTE_NODATA),
        "hotspot_nodata": float(FLOAT_NODATA),
        "hotspot_block_source_pixels": None if args.no_hotspots else int(args.hotspot_block_px),
        "hotspot_definition": (
            None if args.no_hotspots
            else "sum of converted 1-km2 allocator pixels within each coarse block"
        ),
        "front_maps_written": front_written,
        "front_definition": (
            "model-relative annual patch classification from analyze_allocator.py: "
            "new_model_front if disconnected from all earlier simulated conversion; "
            "model_expansion if touching earlier simulated conversion"
        ) if front_written else None,
        "baseline_interpretation": (
            f"all 0/1/year map states are relative to the allocator baseline-native pool for {base_year}; "
            "pixels outside that pool are NoData"
        ),
    }
    method_path = raster_dir / "map_method.json"
    method_path.write_text(json.dumps(method, indent=2), encoding="utf-8")

    print()
    print(f"WROTE {len(manifest):,} raster layer(s)")
    print(f"WROTE {manifest_path}")
    print(f"WROTE {method_path}")
    print(f"OUTPUT {raster_dir}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
