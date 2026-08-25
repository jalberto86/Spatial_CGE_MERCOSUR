#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
analyze_allocator.py
====================
Quantitative and spatial-pattern analysis of one allocator result.

Input
-----
defor_<sim>.parquet
    Full allocator baseline-native pool with:
      pixel_id, row, col, r, aez, biome, p_hat, convert_year
    convert_year == 0 means still native at the end of the simulation.

    The baseline year is NOT hard-coded. It is read from
    defor_<sim>_meta.json (base_year).

Optional companions, auto-detected beside the parquet:
    unmet_<sim>.csv
    defor_<sim>_meta.json

Outputs
-------
Written under:
    <allocator_root>/analysis/<sim>/

tables/
    run_audit.csv
    annual_total.csv
    annual_by_biome.csv
    annual_by_region.csv
    annual_by_region_biome.csv
    annual_by_region_aez.csv
    annual_by_region_aez_biome.csv
    cumulative_by_biome.csv
    unmet_by_reason.csv
        Reconstructed terminal-year unmet/reserved stock, by reason.
    unmet_by_year.csv
        Reconstructed end-of-year unmet/reserved stock.
    unmet_by_region_aez_year.csv
        Reconstructed end-of-year unmet/reserved stock by region/AEZ/reason.
    terminal_unmet_by_region_aez.csv
        Reconstructed terminal-year unmet/reserved stock by region/AEZ/reason.
    unmet_ledger_by_reason.csv
        Raw allocator-ledger sum by reason, with each reason's record
        semantics stated explicitly.
    annual_front_summary.csv
    front_patches.csv
    front_size_distribution.csv

analysis_method.json
    Machine-readable statement of area conversions, connectivity and the
    model-relative front limitation.

derived/
    front_pixels_<sim>.parquet
        Converted pixels only, augmented with annual_patch_id, front_type,
        and annual_patch_size_px.

Front definition
----------------
For each conversion year, all pixels converted in that year are grouped into
8-neighbour connected annual patches (4-neighbour is optional).

An annual patch is classified as:
  - model_expansion: at least one pixel in the patch touches a pixel converted
                     in an earlier MODEL year;
  - new_model_front: no pixel in the patch touches any pixel converted in an
                     earlier MODEL year.

IMPORTANT: defor_<sim>.parquet contains only pixels that were native in the
allocator BASE YEAR. It does not contain the already-anthropic baseline landscape.
Therefore the first simulated conversion year cannot be tested for adjacency to
pre-existing deforestation from this parquet alone. These front metrics describe
the topology of the SIMULATED conversion sequence only.

This patch-level definition avoids splitting one same-year connected clearing
into a mixture of "new front" and "expansion" pixels simply because only part
of the patch touches previous clearing.

The script reports all front sizes. It does NOT impose an arbitrary minimum
front size; that threshold can be chosen later after inspecting the empirical
size distribution.

Usage from allocator root
-------------------------
    python src\\analyze_allocator.py --defor outputs\\defor_Rdyn.parquet

Using the established project venv:
    & "C:\\Users\\JesusMERCADO\\QGISProjects\\MERCOSUR2\\.venv\\Scripts\\python.exe" `
        src\\analyze_allocator.py --defor outputs\\defor_Rdyn.parquet
"""

from __future__ import annotations

import argparse
import json
import shutil
import sys
from collections import Counter, defaultdict
from pathlib import Path

import numpy as np
import pandas as pd

HA_PER_PIXEL = 100.0
KM2_PER_PIXEL = 1.0
REQUIRED_COLUMNS = {
    "pixel_id", "row", "col", "r", "aez", "biome", "convert_year"
}


def infer_sim(defor_path: Path) -> str:
    stem = defor_path.stem
    if stem.startswith("defor_"):
        return stem[len("defor_"):]
    return stem


def infer_allocator_root(defor_path: Path) -> Path:
    """
    Infer allocator root from an allocator output directory.

    Canonical example:
      allocator/outputs/defor_Rdyn.parquet
    """
    if defor_path.parent.name.lower().startswith("outputs"):
        return defor_path.parent.parent
    return defor_path.parent


def resolve_base_year(meta: dict, conversion_years: list[int], unmet_years: list[int]) -> int:
    """Resolve allocator baseline year without hard-coding 2017/2018."""
    raw = meta.get("base_year")
    if raw is not None:
        try:
            return int(raw)
        except Exception:
            pass

    meta_years = meta.get("years")
    if isinstance(meta_years, list) and meta_years:
        try:
            return min(int(y) for y in meta_years) - 1
        except Exception:
            pass

    observed = sorted(set(conversion_years) | set(unmet_years))
    if observed:
        inferred = observed[0] - 1
        print(f"WARNING: base_year missing from metadata; inferring {inferred} from first modeled year.")
        return inferred

    sys.exit("base_year missing from metadata and cannot be inferred from model years.")


INCREMENT_UNMET_REASONS = {"no_pool", "outside_biome"}
STOCK_UNMET_REASONS = {"exhausted"}
KNOWN_UNMET_REASONS = INCREMENT_UNMET_REASONS | STOCK_UNMET_REASONS


def reconstruct_unmet_stocks(
    unmet: pd.DataFrame,
    allocation_years: list[int],
):
    """
    Convert allocator unmet ledger records into comparable end-of-year stocks.

    allocate.py uses two different record semantics:

      no_pool, outside_biome
          Rows are INCREMENTS to cumulative demand tracked internally by
          nopool/resv. Their end-of-year stock must therefore be reconstructed
          with a cumulative sum within each (r,aez,reason).

      exhausted
          Rows are the CURRENT outstanding in-biome deficit after attempting
          that year's allocation. They are already a stock, not an increment.

    Returns
    -------
    stock_cell_year
        One row per (r,aez,year,reason), with reconstructed outstanding_px.
    stock_by_year
        Total reconstructed end-of-year outstanding stock.
    terminal_reason
        Terminal-year stock by reason.
    terminal_cell
        Terminal-year stock by (r,aez,reason).
    ledger_summary
        Raw allocator-ledger sums by reason, with record semantics stated.
    """
    empty_cell_year = pd.DataFrame(columns=[
        "r", "aez", "year", "reason", "record_semantics",
        "ledger_px", "outstanding_px", "outstanding_km2", "outstanding_ha"
    ])
    empty_year = pd.DataFrame(columns=[
        "year", "outstanding_unmet_px", "outstanding_unmet_km2",
        "outstanding_unmet_ha"
    ])
    empty_reason = pd.DataFrame(columns=[
        "terminal_year", "reason", "terminal_unmet_px",
        "terminal_unmet_km2", "terminal_unmet_ha"
    ])
    empty_cell = pd.DataFrame(columns=[
        "terminal_year", "r", "aez", "reason", "terminal_unmet_px",
        "terminal_unmet_km2", "terminal_unmet_ha"
    ])
    empty_ledger = pd.DataFrame(columns=[
        "reason", "record_semantics", "ledger_sum_px",
        "ledger_sum_km2", "ledger_sum_ha"
    ])

    if unmet.empty or not allocation_years:
        return empty_cell_year, empty_year, empty_reason, empty_cell, empty_ledger

    unknown = sorted(set(unmet["reason"].astype(str)) - KNOWN_UNMET_REASONS)
    if unknown:
        raise ValueError(
            "unrecognized unmet reason(s); cannot infer ledger semantics safely: "
            + ", ".join(unknown)
        )

    ledger = (
        unmet.groupby(["r", "aez", "year", "reason"], dropna=False)["unmet_px"]
        .sum()
        .reset_index()
        .rename(columns={"unmet_px": "ledger_px"})
    )

    parts = []
    year_grid = pd.DataFrame({"year": allocation_years})

    for (r, aez, reason), grp in ledger.groupby(
        ["r", "aez", "reason"], dropna=False, sort=False
    ):
        g = year_grid.merge(
            grp[["year", "ledger_px"]],
            on="year",
            how="left",
        )
        g["ledger_px"] = g["ledger_px"].fillna(0).astype("int64")
        g.insert(0, "reason", reason)
        g.insert(0, "aez", aez)
        g.insert(0, "r", r)

        if reason in INCREMENT_UNMET_REASONS:
            g["record_semantics"] = "increment_to_cumulative_stock"
            g["outstanding_px"] = g["ledger_px"].cumsum()
        else:
            g["record_semantics"] = "current_outstanding_stock"
            g["outstanding_px"] = g["ledger_px"]

        parts.append(g)

    stock = pd.concat(parts, ignore_index=True)
    stock["outstanding_px"] = stock["outstanding_px"].astype("int64")
    stock["outstanding_km2"] = stock["outstanding_px"] * KM2_PER_PIXEL
    stock["outstanding_ha"] = stock["outstanding_px"] * HA_PER_PIXEL

    by_year = (
        stock.groupby("year", dropna=False)[
            ["outstanding_px", "outstanding_km2", "outstanding_ha"]
        ]
        .sum()
        .reset_index()
        .rename(columns={
            "outstanding_px": "outstanding_unmet_px",
            "outstanding_km2": "outstanding_unmet_km2",
            "outstanding_ha": "outstanding_unmet_ha",
        })
    )

    terminal_year = allocation_years[-1]
    terminal = stock.loc[stock["year"] == terminal_year].copy()

    terminal_reason = (
        terminal.groupby("reason", dropna=False)[
            ["outstanding_px", "outstanding_km2", "outstanding_ha"]
        ]
        .sum()
        .reset_index()
        .rename(columns={
            "outstanding_px": "terminal_unmet_px",
            "outstanding_km2": "terminal_unmet_km2",
            "outstanding_ha": "terminal_unmet_ha",
        })
    )
    terminal_reason.insert(0, "terminal_year", terminal_year)

    terminal_cell = terminal[[
        "r", "aez", "reason",
        "outstanding_px", "outstanding_km2", "outstanding_ha"
    ]].rename(columns={
        "outstanding_px": "terminal_unmet_px",
        "outstanding_km2": "terminal_unmet_km2",
        "outstanding_ha": "terminal_unmet_ha",
    })
    terminal_cell.insert(0, "terminal_year", terminal_year)

    raw_summary = (
        ledger.groupby("reason", dropna=False)["ledger_px"]
        .sum()
        .reset_index()
        .rename(columns={"ledger_px": "ledger_sum_px"})
    )
    raw_summary["record_semantics"] = raw_summary["reason"].map(
        lambda x: (
            "increment_to_cumulative_stock"
            if x in INCREMENT_UNMET_REASONS
            else "current_outstanding_stock"
        )
    )
    raw_summary["ledger_sum_km2"] = raw_summary["ledger_sum_px"] * KM2_PER_PIXEL
    raw_summary["ledger_sum_ha"] = raw_summary["ledger_sum_px"] * HA_PER_PIXEL
    raw_summary = raw_summary[
        ["reason", "record_semantics", "ledger_sum_px",
         "ledger_sum_km2", "ledger_sum_ha"]
    ]

    return stock, by_year, terminal_reason, terminal_cell, raw_summary


def add_area_columns(df: pd.DataFrame, count_col: str = "converted_px") -> pd.DataFrame:
    out = df.copy()
    out["converted_km2"] = out[count_col].astype("int64") * KM2_PER_PIXEL
    out["converted_ha"] = out[count_col].astype("int64") * HA_PER_PIXEL
    return out


def grouped_conversion(converted: pd.DataFrame, group_cols: list[str]) -> pd.DataFrame:
    cols = ["convert_year"] + group_cols
    out = (
        converted.groupby(cols, dropna=False)
        .size()
        .rename("converted_px")
        .reset_index()
        .rename(columns={"convert_year": "year"})
    )
    out = add_area_columns(out)
    year_tot = out.groupby("year")["converted_px"].transform("sum")
    out["share_of_year_pct"] = np.where(
        year_tot > 0, 100.0 * out["converted_px"] / year_tot, np.nan
    )
    sort_cols = ["year"] + group_cols
    return out.sort_values(sort_cols).reset_index(drop=True)


class UnionFind:
    __slots__ = ("parent", "size")

    def __init__(self, n: int):
        self.parent = np.arange(n, dtype=np.int64)
        self.size = np.ones(n, dtype=np.int64)

    def find(self, x: int) -> int:
        parent = self.parent
        while parent[x] != x:
            parent[x] = parent[parent[x]]
            x = int(parent[x])
        return x

    def union(self, a: int, b: int) -> None:
        ra = self.find(a)
        rb = self.find(b)
        if ra == rb:
            return
        if self.size[ra] < self.size[rb]:
            ra, rb = rb, ra
        self.parent[rb] = ra
        self.size[ra] += self.size[rb]


def neighbour_offsets(connectivity: int):
    if connectivity == 4:
        prior = [(-1, 0), (0, -1)]
        all_neigh = [(-1, 0), (1, 0), (0, -1), (0, 1)]
    elif connectivity == 8:
        prior = [(-1, -1), (-1, 0), (-1, 1), (0, -1)]
        all_neigh = [
            (-1, -1), (-1, 0), (-1, 1),
            (0, -1),             (0, 1),
            (1, -1),  (1, 0),    (1, 1),
        ]
    else:
        raise ValueError("connectivity must be 4 or 8")
    return prior, all_neigh


def analyze_fronts(converted: pd.DataFrame, connectivity: int):
    """
    Cluster each year's converted pixels into annual connected patches.
    Classify whole patches as expansion/new_front depending on adjacency
    to any earlier converted pixel.
    """
    base_cols = ["pixel_id", "row", "col", "r", "aez", "biome", "convert_year"]
    if converted.empty:
        empty_pixels = converted[base_cols].copy()
        empty_pixels["annual_patch_id"] = pd.Series(dtype="string")
        empty_pixels["front_type"] = pd.Series(dtype="string")
        empty_pixels["annual_patch_size_px"] = pd.Series(dtype="int64")
        empty_patches = pd.DataFrame(columns=[
            "year", "annual_patch_id", "front_type", "size_px", "size_km2", "size_ha",
            "dominant_region", "dominant_biome", "n_regions", "n_biomes", "regions", "biomes"
        ])
        empty_summary = pd.DataFrame(columns=[
            "year", "annual_converted_px", "annual_converted_km2", "annual_patch_count",
            "model_expansion_patch_count", "new_model_front_count", "model_expansion_px", "model_expansion_km2",
            "new_model_front_px", "new_model_front_km2", "model_expansion_share_pct", "new_model_front_share_pct",
            "mean_new_model_front_size_km2", "median_new_model_front_size_km2", "largest_new_model_front_km2"
        ])
        empty_dist = pd.DataFrame(columns=["year", "front_type", "size_class_km2", "patches", "pixels", "km2"])
        return empty_pixels, empty_patches, empty_summary, empty_dist

    prior_offsets, all_offsets = neighbour_offsets(connectivity)

    max_col = int(converted["col"].max())
    stride = max_col + 3
    if stride <= 2:
        raise ValueError("invalid column coordinates")

    prior_keys: set[int] = set()
    pixel_frames = []
    patch_rows = []
    annual_rows = []

    for year in sorted(int(y) for y in converted["convert_year"].unique()):
        ydf = converted.loc[converted["convert_year"] == year, base_cols].copy().reset_index(drop=True)

        rows = ydf["row"].to_numpy(dtype=np.int64, copy=False)
        cols = ydf["col"].to_numpy(dtype=np.int64, copy=False)
        n = len(ydf)

        keys = (rows * stride + cols).astype(np.int64)
        key_to_idx = {int(k): i for i, k in enumerate(keys)}
        uf = UnionFind(n)

        # Build connected components within the current year's clearing.
        for i in range(n):
            r0 = int(rows[i])
            c0 = int(cols[i])
            for dr, dc in prior_offsets:
                rr, cc = r0 + dr, c0 + dc
                if rr < 0 or cc < 0:
                    continue
                j = key_to_idx.get(rr * stride + cc)
                if j is not None:
                    uf.union(i, j)

        roots = np.fromiter((uf.find(i) for i in range(n)), dtype=np.int64, count=n)

        # Stable local patch numbering: sort components by smallest pixel_id.
        root_min_pixel = {}
        pixel_ids = ydf["pixel_id"].to_numpy(dtype=np.int64, copy=False)
        for i, root in enumerate(roots):
            root = int(root)
            pid = int(pixel_ids[i])
            prev = root_min_pixel.get(root)
            if prev is None or pid < prev:
                root_min_pixel[root] = pid
        ordered_roots = sorted(root_min_pixel, key=lambda root: root_min_pixel[root])
        root_to_local = {root: i + 1 for i, root in enumerate(ordered_roots)}

        # Determine whether each current-year pixel touches any earlier clearing.
        touches_prior = np.zeros(n, dtype=bool)
        if prior_keys:
            for i in range(n):
                r0 = int(rows[i])
                c0 = int(cols[i])
                for dr, dc in all_offsets:
                    rr, cc = r0 + dr, c0 + dc
                    if rr < 0 or cc < 0:
                        continue
                    if rr * stride + cc in prior_keys:
                        touches_prior[i] = True
                        break

        root_touches_prior = defaultdict(bool)
        root_size = Counter()
        root_regions = defaultdict(Counter)
        root_biomes = defaultdict(Counter)

        rvals = ydf["r"].astype(str).to_numpy()
        bvals = ydf["biome"].astype(str).to_numpy()
        for i, root in enumerate(roots):
            root = int(root)
            root_size[root] += 1
            root_touches_prior[root] = root_touches_prior[root] or bool(touches_prior[i])
            root_regions[root][rvals[i]] += 1
            root_biomes[root][bvals[i]] += 1

        local_ids = np.fromiter((root_to_local[int(root)] for root in roots), dtype=np.int64, count=n)
        patch_ids = np.array([f"{year}_{x:06d}" for x in local_ids], dtype=object)
        front_types = np.array(
            ["model_expansion" if root_touches_prior[int(root)] else "new_model_front" for root in roots],
            dtype=object
        )
        patch_sizes = np.fromiter((root_size[int(root)] for root in roots), dtype=np.int64, count=n)

        ydf["annual_patch_id"] = patch_ids
        ydf["front_type"] = front_types
        ydf["annual_patch_size_px"] = patch_sizes
        pixel_frames.append(ydf)

        for root in ordered_roots:
            local = root_to_local[root]
            reg_counts = root_regions[root]
            biome_counts = root_biomes[root]
            size_px = int(root_size[root])
            front_type = "model_expansion" if root_touches_prior[root] else "new_model_front"
            patch_rows.append({
                "year": year,
                "annual_patch_id": f"{year}_{local:06d}",
                "front_type": front_type,
                "size_px": size_px,
                "size_km2": size_px * KM2_PER_PIXEL,
                "size_ha": size_px * HA_PER_PIXEL,
                "dominant_region": reg_counts.most_common(1)[0][0],
                "dominant_biome": biome_counts.most_common(1)[0][0],
                "n_regions": len(reg_counts),
                "n_biomes": len(biome_counts),
                "regions": "|".join(sorted(reg_counts)),
                "biomes": "|".join(sorted(biome_counts)),
            })

        new_roots = [root for root in ordered_roots if not root_touches_prior[root]]
        exp_roots = [root for root in ordered_roots if root_touches_prior[root]]
        new_sizes = [root_size[root] for root in new_roots]
        exp_px = sum(root_size[root] for root in exp_roots)
        new_px = sum(new_sizes)

        annual_rows.append({
            "year": year,
            "annual_converted_px": n,
            "annual_converted_km2": n * KM2_PER_PIXEL,
            "annual_patch_count": len(ordered_roots),
            "model_expansion_patch_count": len(exp_roots),
            "new_model_front_count": len(new_roots),
            "model_expansion_px": int(exp_px),
            "model_expansion_km2": float(exp_px) * KM2_PER_PIXEL,
            "new_model_front_px": int(new_px),
            "new_model_front_km2": float(new_px) * KM2_PER_PIXEL,
            "model_expansion_share_pct": 100.0 * exp_px / n if n else np.nan,
            "new_model_front_share_pct": 100.0 * new_px / n if n else np.nan,
            "mean_new_model_front_size_km2": float(np.mean(new_sizes)) if new_sizes else 0.0,
            "median_new_model_front_size_km2": float(np.median(new_sizes)) if new_sizes else 0.0,
            "largest_new_model_front_km2": float(max(new_sizes)) if new_sizes else 0.0,
        })

        prior_keys.update(int(k) for k in keys)

    front_pixels = pd.concat(pixel_frames, ignore_index=True)
    front_patches = pd.DataFrame(patch_rows)
    annual_summary = pd.DataFrame(annual_rows)

    if not front_patches.empty:
        bins = [0, 1, 5, 10, 25, 50, 100, np.inf]
        labels = ["1", "2-5", "6-10", "11-25", "26-50", "51-100", ">100"]
        fp = front_patches.copy()
        fp["size_class_km2"] = pd.cut(
            fp["size_km2"], bins=bins, labels=labels, right=True, include_lowest=True
        )
        size_dist = (
            fp.groupby(["year", "front_type", "size_class_km2"], observed=True)
            .agg(patches=("annual_patch_id", "size"), pixels=("size_px", "sum"), km2=("size_km2", "sum"))
            .reset_index()
        )
    else:
        size_dist = pd.DataFrame(columns=["year", "front_type", "size_class_km2", "patches", "pixels", "km2"])

    return front_pixels, front_patches, annual_summary, size_dist


def main() -> int:
    ap = argparse.ArgumentParser(description="Analyze one allocator defor_<sim>.parquet result.")
    ap.add_argument("--defor", required=True, type=Path, help="path to defor_<sim>.parquet")
    ap.add_argument("--unmet", default=None, type=Path, help="optional unmet_<sim>.csv override")
    ap.add_argument("--meta", default=None, type=Path, help="optional defor_<sim>_meta.json override")
    ap.add_argument("--analysis-root", default=None, type=Path, help="default: <allocator_root>/analysis")
    ap.add_argument("--connectivity", type=int, choices=(4, 8), default=8,
                    help="pixel connectivity for annual patches/fronts (default: 8)")
    ap.add_argument("--no-fronts", action="store_true", help="skip connected-front analysis")
    ap.add_argument(
        "--force",
        action="store_true",
        help="replace existing canonical analysis tables/derived outputs for this simulation",
    )
    args = ap.parse_args()

    defor_path = args.defor.resolve()
    if not defor_path.exists():
        sys.exit(f"missing defor parquet: {defor_path}")

    sim = infer_sim(defor_path)
    allocator_root = infer_allocator_root(defor_path)
    analysis_root = args.analysis_root.resolve() if args.analysis_root else allocator_root / "analysis"
    sim_dir = analysis_root / sim
    tables_dir = sim_dir / "tables"
    derived_dir = sim_dir / "derived"

    owned_existing = []
    if tables_dir.exists() and any(tables_dir.iterdir()):
        owned_existing.append(tables_dir)
    if derived_dir.exists() and any(derived_dir.iterdir()):
        owned_existing.append(derived_dir)
    method_existing = sim_dir / "analysis_method.json"
    if method_existing.exists():
        owned_existing.append(method_existing)

    if owned_existing and not args.force:
        sys.exit(
            "refusing to overwrite existing canonical analysis outputs:\n  "
            + "\n  ".join(str(p) for p in owned_existing)
            + "\nUse --force only if you intentionally want to replace this "
              "simulation's analysis tables/derived products."
        )

    # When explicitly forced, rebuild only the analyzer-owned products cleanly.
    # Leave sim_dir/rasters untouched; raster promotion is handled separately
    # by map_allocator.py (File 6).
    if args.force:
        if tables_dir.exists():
            shutil.rmtree(tables_dir)
        if derived_dir.exists():
            shutil.rmtree(derived_dir)
        if method_existing.exists():
            method_existing.unlink()

    tables_dir.mkdir(parents=True, exist_ok=True)
    derived_dir.mkdir(parents=True, exist_ok=True)

    unmet_path = args.unmet.resolve() if args.unmet else defor_path.parent / f"unmet_{sim}.csv"
    meta_path = args.meta.resolve() if args.meta else defor_path.parent / f"defor_{sim}_meta.json"

    meta = {}
    if meta_path.exists():
        try:
            meta = json.loads(meta_path.read_text(encoding="utf-8"))
        except Exception as e:
            print(f"WARNING: could not parse meta JSON: {e}")

    pool = pd.read_parquet(defor_path, columns=sorted(REQUIRED_COLUMNS))
    missing = REQUIRED_COLUMNS - set(pool.columns)
    if missing:
        sys.exit(f"defor parquet missing required columns: {sorted(missing)}")

    pool["convert_year"] = pd.to_numeric(pool["convert_year"], errors="coerce")
    if pool["convert_year"].isna().any():
        sys.exit("convert_year contains non-numeric/null values")
    pool["convert_year"] = pool["convert_year"].astype(int)

    if (pool["convert_year"] < 0).any():
        sys.exit("convert_year contains negative values")
    dup = int(pool["pixel_id"].duplicated().sum())
    if dup:
        sys.exit(f"pixel_id is not unique ({dup:,} duplicates)")

    converted = pool[pool["convert_year"] > 0].copy()
    still_native_n = int((pool["convert_year"] == 0).sum())
    conversion_years = sorted(int(y) for y in converted["convert_year"].unique())

    unmet = pd.DataFrame(columns=["r", "aez", "year", "unmet_px", "reason"])
    if unmet_path.exists():
        unmet = pd.read_csv(unmet_path)
        expected_unmet = {"r", "aez", "year", "unmet_px", "reason"}
        miss = expected_unmet - set(unmet.columns)
        if miss:
            print(f"WARNING: unmet file missing columns {sorted(miss)}; unmet summaries skipped.")
            unmet = pd.DataFrame(columns=["r", "aez", "year", "unmet_px", "reason"])

    if len(unmet):
        unmet["year"] = pd.to_numeric(unmet["year"], errors="coerce")
        unmet["unmet_px"] = pd.to_numeric(unmet["unmet_px"], errors="coerce")
        bad = unmet["year"].isna() | unmet["unmet_px"].isna()
        if bad.any():
            print(f"WARNING: dropping {int(bad.sum()):,} invalid unmet record(s).")
            unmet = unmet.loc[~bad].copy()
        unmet["year"] = unmet["year"].astype(int)
        unmet["unmet_px"] = unmet["unmet_px"].astype("int64")
        unmet["unmet_km2"] = unmet["unmet_px"] * KM2_PER_PIXEL
        unmet["unmet_ha"] = unmet["unmet_px"] * HA_PER_PIXEL

    unmet_years = sorted(int(y) for y in unmet["year"].unique()) if len(unmet) else []

    base_year = resolve_base_year(meta, conversion_years, unmet_years)

    meta_years = meta.get("years")
    if isinstance(meta_years, list):
        declared_years = sorted(int(y) for y in meta_years if int(y) > base_year)
    else:
        declared_years = []

    allocation_years = sorted(set(declared_years) | set(conversion_years) | set(unmet_years))
    terminal_year = allocation_years[-1] if allocation_years else None

    print("=== analyze_allocator ===")
    print(f"sim          : {sim}")
    print(f"base year    : {base_year}")
    print(f"defor        : {defor_path}")
    print(f"unmet        : {unmet_path if unmet_path.exists() else '(not found)'}")
    print(f"meta         : {meta_path if meta_path.exists() else '(not found)'}")
    print(f"analysis dir : {sim_dir}")
    print(f"fronts       : {'skipped' if args.no_fronts else f'{args.connectivity}-neighbour'}")
    print()

    # Reconstruct comparable end-of-year unmet/reserved stocks from the allocator
    # ledger. no_pool/outside_biome are increments; exhausted is already a stock.
    try:
        (
            unmet_stock_cell_year,
            unmet_stock_by_year,
            terminal_unmet_reason,
            terminal_unmet_cell,
            unmet_ledger_summary,
        ) = reconstruct_unmet_stocks(unmet, allocation_years)
    except ValueError as e:
        sys.exit(str(e))

    terminal_unmet_px = (
        int(terminal_unmet_reason["terminal_unmet_px"].sum())
        if len(terminal_unmet_reason)
        else 0
    )
    unmet_ledger_sum_px = int(unmet["unmet_px"].sum()) if len(unmet) else 0

    audit = {
        "sim": sim,
        "defor_file": str(defor_path),
        "base_year": base_year,
        "baseline_label": f"native@{base_year}",
        "pool_px_baseline_native": int(len(pool)),
        "pool_km2_baseline_native": float(len(pool)) * KM2_PER_PIXEL,
        "converted_px": int(len(converted)),
        "converted_km2": float(len(converted)) * KM2_PER_PIXEL,
        "still_native_px": still_native_n,
        "still_native_km2": float(still_native_n) * KM2_PER_PIXEL,
        "first_conversion_year": conversion_years[0] if conversion_years else np.nan,
        "last_conversion_year": conversion_years[-1] if conversion_years else np.nan,
        "first_allocation_year": allocation_years[0] if allocation_years else np.nan,
        "last_allocation_year": terminal_year if terminal_year is not None else np.nan,
        "terminal_unmet_px": terminal_unmet_px,
        "terminal_unmet_km2": terminal_unmet_px * KM2_PER_PIXEL,
        "unmet_ledger_sum_px": unmet_ledger_sum_px,
        "meta_converted_px": meta.get("converted_px", np.nan),
        "meta_reported_unmet_px": meta.get("unmet_px", np.nan),
        "meta_base_year": meta.get("base_year", np.nan),
        "meta_years": "|".join(str(x) for x in meta.get("years", []))
                      if isinstance(meta.get("years"), list) else meta.get("years", ""),
        "front_reference": (
            f"prior simulated conversion only; land already anthropic at baseline {base_year} "
            "is absent from defor parquet"
        ),
    }
    audit["converted_matches_meta"] = (
        int(audit["converted_px"]) == int(audit["meta_converted_px"])
        if not pd.isna(audit["meta_converted_px"]) else np.nan
    )
    audit["meta_reported_unmet_matches_ledger_sum"] = (
        int(audit["unmet_ledger_sum_px"]) == int(audit["meta_reported_unmet_px"])
        if not pd.isna(audit["meta_reported_unmet_px"]) else np.nan
    )
    pd.DataFrame([audit]).to_csv(tables_dir / "run_audit.csv", index=False)

    annual_total = grouped_conversion(converted, [])
    if allocation_years:
        full_years = pd.DataFrame({"year": allocation_years})
        annual_total = full_years.merge(
            annual_total.drop(columns=["share_of_year_pct"], errors="ignore"),
            on="year", how="left"
        )
        annual_total["converted_px"] = annual_total["converted_px"].fillna(0).astype("int64")
        annual_total["converted_km2"] = annual_total["converted_km2"].fillna(0.0)
        annual_total["converted_ha"] = annual_total["converted_ha"].fillna(0.0)
        annual_total["share_of_year_pct"] = np.where(
            annual_total["converted_px"] > 0, 100.0, 0.0
        )
    annual_total.to_csv(tables_dir / "annual_total.csv", index=False)

    table_specs = [
        ("annual_by_biome.csv", ["biome"]),
        ("annual_by_region.csv", ["r"]),
        ("annual_by_region_biome.csv", ["r", "biome"]),
        ("annual_by_region_aez.csv", ["r", "aez"]),
        ("annual_by_region_aez_biome.csv", ["r", "aez", "biome"]),
    ]
    for filename, groups in table_specs:
        grouped_conversion(converted, groups).to_csv(tables_dir / filename, index=False)

    baseline = pool.groupby("biome").size().rename("baseline_native_px").reset_index()
    if allocation_years:
        annual_b = grouped_conversion(converted, ["biome"])[["year", "biome", "converted_px"]]
        grid = pd.MultiIndex.from_product(
            [allocation_years, sorted(pool["biome"].dropna().astype(str).unique())],
            names=["year", "biome"]
        ).to_frame(index=False)
        cum = grid.merge(annual_b, on=["year", "biome"], how="left")
        cum["converted_px"] = cum["converted_px"].fillna(0).astype("int64")
        cum = cum.merge(baseline, on="biome", how="left")
        cum["base_year"] = base_year
        cum["cumulative_converted_px"] = cum.groupby("biome")["converted_px"].cumsum()
        cum["remaining_native_px"] = cum["baseline_native_px"] - cum["cumulative_converted_px"]
        cum["annual_converted_km2"] = cum["converted_px"] * KM2_PER_PIXEL
        cum["cumulative_converted_km2"] = cum["cumulative_converted_px"] * KM2_PER_PIXEL
        cum["remaining_native_km2"] = cum["remaining_native_px"] * KM2_PER_PIXEL
        cum["cumulative_share_of_baseline_native_pct"] = np.where(
            cum["baseline_native_px"] > 0,
            100.0 * cum["cumulative_converted_px"] / cum["baseline_native_px"],
            np.nan,
        )
    else:
        cum = pd.DataFrame(columns=[
            "year", "biome", "converted_px", "baseline_native_px", "base_year",
            "cumulative_converted_px", "remaining_native_px", "annual_converted_km2",
            "cumulative_converted_km2", "remaining_native_km2",
            "cumulative_share_of_baseline_native_pct"
        ])
    cum.to_csv(tables_dir / "cumulative_by_biome.csv", index=False)

    # Authoritative unmet/reserved-demand tables reconstructed using the
    # reason-specific ledger semantics documented above.
    unmet_stock_by_year.to_csv(tables_dir / "unmet_by_year.csv", index=False)
    unmet_stock_cell_year.to_csv(
        tables_dir / "unmet_by_region_aez_year.csv",
        index=False,
    )
    terminal_unmet_reason.to_csv(
        tables_dir / "unmet_by_reason.csv",
        index=False,
    )
    terminal_unmet_cell.to_csv(
        tables_dir / "terminal_unmet_by_region_aez.csv",
        index=False,
    )
    unmet_ledger_summary.to_csv(
        tables_dir / "unmet_ledger_by_reason.csv",
        index=False,
    )

    if not args.no_fronts:
        print("Computing annual connected patches/fronts...")
        front_pixels, front_patches, front_summary, size_dist = analyze_fronts(converted, args.connectivity)
        front_pixels.to_parquet(derived_dir / f"front_pixels_{sim}.parquet", index=False)
        front_patches.to_csv(tables_dir / "front_patches.csv", index=False)

        if allocation_years:
            front_summary = pd.DataFrame({"year": allocation_years}).merge(
                front_summary, on="year", how="left"
            )
            numeric_cols = [c for c in front_summary.columns if c != "year"]
            front_summary[numeric_cols] = front_summary[numeric_cols].fillna(0)

        front_summary.to_csv(tables_dir / "annual_front_summary.csv", index=False)
        size_dist.to_csv(tables_dir / "front_size_distribution.csv", index=False)

    method = {
        "sim": sim,
        "base_year": base_year,
        "baseline_label": f"native@{base_year}",
        "allocation_years": allocation_years,
        "pixel_area_km2": KM2_PER_PIXEL,
        "pixel_area_ha": HA_PER_PIXEL,
        "front_connectivity": None if args.no_fronts else args.connectivity,
        "front_definition": (
            "Annual same-year connected patch. model_expansion if any patch pixel is adjacent "
            "to a pixel converted in an earlier simulated year; otherwise new_model_front."
        ),
        "front_limitation": (
            f"The defor parquet contains only pixels native at allocator baseline {base_year}. "
            f"Land already anthropic at baseline {base_year} is absent, so adjacency to "
            "pre-existing deforestation cannot be evaluated. Front metrics are model-relative, "
            "not an observed-landscape frontier classification."
        ),
        "unmet_interpretation": (
            "The allocator unmet CSV is a mixed-semantics ledger. no_pool and outside_biome "
            "records are annual increments to cumulative stocks; exhausted records are the "
            "current outstanding in-biome deficit. This analysis reconstructs comparable "
            "end-of-year stocks reason-by-reason before reporting terminal unmet/reserved area."
        ),
        "allocator_meta_unmet_note": (
            "The allocator metadata unmet_px field is the raw sum of unmet ledger records. "
            "run_audit.csv compares it to unmet_ledger_sum_px. It is not automatically interpreted "
            "as terminal outstanding area; terminal_unmet_px is reconstructed separately."
        ),
    }
    (sim_dir / "analysis_method.json").write_text(json.dumps(method, indent=2), encoding="utf-8")

    print("--- run summary ---")
    print(f"native@{base_year} pool : {len(pool):>12,} px = {len(pool)*KM2_PER_PIXEL:,.0f} km2")
    print(f"converted        : {len(converted):>12,} px = {len(converted)*KM2_PER_PIXEL:,.0f} km2")
    print(f"still native     : {still_native_n:>12,} px = {still_native_n*KM2_PER_PIXEL:,.0f} km2")
    if terminal_year is not None:
        print(
            f"terminal unmet   : {terminal_unmet_px:>12,} px = "
            f"{terminal_unmet_px*KM2_PER_PIXEL:,.0f} km2  (year {terminal_year})"
        )
    else:
        print("terminal unmet   :            0 px = 0 km2")
    print(f"unmet ledger sum : {unmet_ledger_sum_px:>12,} px-records")
    print(
        f"allocation years : {allocation_years[0]}..{allocation_years[-1]}"
        if allocation_years else "allocation years : none"
    )

    if not args.no_fronts and len(front_summary):
        print("\n--- annual front summary ---")
        cols = [
            "year", "annual_converted_km2", "new_model_front_count", "new_model_front_km2",
            "model_expansion_km2", "largest_new_model_front_km2"
        ]
        print(front_summary[cols].to_string(index=False))

    print(f"\nWROTE analysis to: {sim_dir}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
