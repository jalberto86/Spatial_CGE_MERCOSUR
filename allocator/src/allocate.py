#!/usr/bin/env python3
# -*- coding: utf-8 -*-
r"""
allocate.py
===========
Canonical XFT native-conversion allocator.

The allocator converts a CGE land-factor path into per-pixel native-to-
agriculture conversion years by replaying the continuous fitted p_hat ranking
stored in allocator_pixels.parquet.

Canonical inputs
----------------
<alloc-root>/allocator_pixels.parquet
    Baseline-native allocator pool built by build_allocator_pixels.py:
      pixel_id, row, col, r, aez, biome, p_hat

    The canonical pool must be the verified continuous-p_hat pool:
      rows        = 5,776,691
      p_hat dtype = float64
      p_hat finite and in [0,1]
      p_hat unique for every retained pixel
      pixel_id unique

GDX xft(r,fp,t)
    Land-factor quantity path. The allocator uses base year 2018 and allocates
    every year present after 2018, unless --end-year truncates the horizon.

LCOV17.csv
    GTAP-LULC cropland + pastureland base area by region x AEZ.

biome_aez_coverage.csv
    cover_native by region x AEZ. The covered fraction is directed to the four
    modeled biomes; the complement is recorded as outside_biome.

Allocation rule
---------------
For each region x AEZ:

  cumulative whole-AEZ demand at year t
      = A_base_px(r,aez) * (xft[r,aez,t] - xft[r,aez,2018])

  in-biome cumulative target
      = floor(whole_AEZ_demand * cover_native)

  period allocation demand
      = floor(in-biome cumulative target - realized cumulative allocation)

Within each region x AEZ x biome, pixels are ordered by descending continuous
p_hat. Each year's demand is distributed across biomes by CURRENT remaining
native capacity, with residual demand spilling to other biomes in the same
region x AEZ.

Conversion is irreversible: once a pixel receives convert_year > 0, it is
never available again.

Unmet ledger semantics
----------------------
The CSV records reason-specific allocator ledger entries:

  no_pool
      incremental increase in cumulative demand for region x AEZ cells with no
      modeled-biome pool.

  outside_biome
      incremental increase in cumulative demand reserved outside the four
      modeled biomes according to 1 - cover_native.

  exhausted
      current in-biome deficit when the modeled native pool cannot absorb the
      requested demand.

Therefore rows in unmet_<sim>.csv do NOT all have identical stock/flow
semantics. Downstream analysis must reconstruct reason-specific end-of-year
stocks rather than treating every row as an outstanding stock.

Integrated health check
-----------------------
After allocation, the script reconciles peak in-biome demand, available native
pool, expected allocation, and realized allocation. An accounting mismatch is
an ERROR. Pool exhaustion with otherwise consistent accounting is REVIEW.

Canonical outputs
-----------------
<alloc-root>/outputs/
    defor_<sim>.parquet
    unmet_<sim>.csv
    demand_check_<sim>.csv
    defor_<sim>_meta.json

Safety
------
--dry-run
    Execute the complete allocation and health check in memory. Write nothing.

--force
    Required to replace any existing canonical output file for the same
    simulation tag.

Usage from allocator root
-------------------------
Dry run:
    python src\allocate.py --gdx ..\output\Rdyn.gdx --dry-run

Canonical write, intentionally replacing an old result:
    python src\allocate.py --gdx ..\output\Rdyn.gdx --force
"""

from __future__ import annotations

import argparse
import glob
import io
import json
import math
import shutil
import subprocess
import sys
from collections import defaultdict
from datetime import datetime, timezone
from pathlib import Path

import numpy as np
import pandas as pd


# -----------------------------------------------------------------------------
# Fixed project configuration
# -----------------------------------------------------------------------------
BASE_YEAR = 2018
HA_PER_PIXEL = 100.0
LCOV_KHA_TO_HA = 1000.0
GTAP_AGLAND_COVS = ("cropland", "pastureland")

NAME_TO_REG = {
    "brazil": "BRA",
    "argentina": "ARG",
    "paraguay": "PRY",
    "uruguay": "URY",
    "bolivia": "BOL",
}
MERCOSUR = set(NAME_TO_REG.values())

DEFAULT_ROOT = Path(
    r"C:\Users\JesusMERCADO\GAMSProjects\GTAP_AEZ\rdyn\allocator"
)
DEFAULT_LCOV = Path(
    r"C:\Users\JesusMERCADO\GAMSProjects\GTAP_AEZ\rdyn\Input\Etaf_calcu\LCOV17.csv"
)
DEFAULT_COVERAGE = "biome_aez_coverage.csv"

EXPECTED_CANONICAL_POOL_ROWS = 5_776_691
REQUIRED_POOL_COLUMNS = {
    "pixel_id", "row", "col", "r", "aez", "biome", "p_hat"
}


def _norm(s) -> str:
    return "".join(ch for ch in str(s).lower() if ch.isalnum())


# -----------------------------------------------------------------------------
# GDX: read xft
# -----------------------------------------------------------------------------
def _find_gdxdump() -> "str | None":
    exe = shutil.which("gdxdump")
    if exe:
        return exe

    for pat in (
        r"C:\GAMS\*\gdxdump.exe",
        r"C:\Program Files\GAMS\*\gdxdump.exe",
        r"C:\GAMS\*\*\gdxdump.exe",
        r"C:\Program Files\GAMS\*\*\gdxdump.exe",
    ):
        hits = glob.glob(pat)
        if hits:
            return sorted(hits)[-1]

    return None


def read_xft(gdx: Path) -> pd.DataFrame:
    """
    Return DataFrame[r, aez, t, x] for MERCOSUR land factors.
    """
    exe = _find_gdxdump()
    if not exe:
        sys.exit(
            "gdxdump.exe not found (PATH or common GAMS dirs). "
            "Needed to read xft."
        )

    result = subprocess.run(
        [exe, str(gdx), "Symb=xft", "Format=csv"],
        capture_output=True,
        text=True,
    )

    if not result.stdout.strip():
        sys.exit(
            "gdxdump returned no data for xft "
            f"(stderr: {result.stderr[:300]})"
        )

    df = pd.read_csv(io.StringIO(result.stdout))
    df.columns = [str(c).strip() for c in df.columns]

    need = {"r", "fp", "t"}
    if not need.issubset({c.lower() for c in df.columns}):
        sys.exit(
            f"unexpected xft columns {list(df.columns)}; "
            "expected r, fp, t, Val"
        )

    cols = {c.lower(): c for c in df.columns}
    val = [
        c
        for c in df.columns
        if c.lower() not in ("r", "fp", "t")
    ][-1]

    out = pd.DataFrame(
        {
            "r": df[cols["r"]].map(
                lambda v: NAME_TO_REG.get(_norm(v))
            ),
            "fp": df[cols["fp"]].astype(str),
            "t": pd.to_numeric(
                df[cols["t"]], errors="coerce"
            ).astype("Int64"),
            "x": pd.to_numeric(df[val], errors="coerce"),
        }
    )

    out = out[
        out["fp"].str.upper().str.startswith("AEZ")
    ].copy()

    out["aez"] = pd.to_numeric(
        out["fp"].str.extract(r"(\d+)", expand=False),
        errors="coerce",
    ).astype("Int64")

    out = out.dropna(subset=["r", "aez", "t", "x"])
    out["aez"] = out["aez"].astype(int)
    out["t"] = out["t"].astype(int)

    return out[["r", "aez", "t", "x"]]


# -----------------------------------------------------------------------------
# LCOV base agricultural area
# -----------------------------------------------------------------------------
def read_lcov_agbase(path: Path) -> dict:
    """
    GTAP-LULC LCOV17 -> {(REG, aez): ag base area in ha},
    cropland + pastureland, converting kha to ha.
    """
    df = pd.read_csv(path)
    df.columns = [str(c).strip() for c in df.columns]

    val = [
        c
        for c in df.columns
        if pd.api.types.is_numeric_dtype(df[c])
    ][-1]
    dims = [c for c in df.columns if c != val]

    def score(col, probe):
        return sum(
            bool(probe(str(v)))
            for v in df[col].dropna().unique()
        )

    import re

    aez_col = max(
        dims,
        key=lambda c: score(
            c,
            lambda v: re.fullmatch(
                r"(AEZ)?\d{1,2}", v.strip(), re.I
            )
            is not None,
        ),
    )

    cov_names = {
        _norm(x)
        for x in [
            "Cropland",
            "Pastureland",
            "Forest",
            "SavnGrasslnd",
            "Shrubland",
        ]
    }

    cov_col = max(
        dims,
        key=lambda c: score(
            c,
            lambda v: _norm(v) in cov_names,
        ),
    )

    reg_col = max(
        [c for c in dims if c not in (aez_col, cov_col)],
        key=lambda c: score(
            c,
            lambda v: re.fullmatch(
                r"[A-Za-z]{3}", v.strip()
            )
            is not None,
        ),
    )

    want = {_norm(x) for x in GTAP_AGLAND_COVS}

    sub = df[
        df[cov_col].map(lambda v: _norm(v) in want)
    ].copy()

    sub["reg"] = (
        sub[reg_col]
        .astype(str)
        .str.upper()
        .str.strip()
    )

    sub["aez"] = pd.to_numeric(
        sub[aez_col]
        .astype(str)
        .str.extract(r"(\d+)", expand=False),
        errors="coerce",
    )

    sub["ha"] = (
        pd.to_numeric(sub[val], errors="coerce")
        * LCOV_KHA_TO_HA
    )

    sub = sub.dropna(subset=["reg", "aez"])
    grouped = sub.groupby(["reg", "aez"])["ha"].sum()

    return {
        (r, int(a)): float(h)
        for (r, a), h in grouped.items()
    }


# -----------------------------------------------------------------------------
# Allocation helper
# -----------------------------------------------------------------------------
def distribute_int(D: int, caps: dict) -> dict:
    """
    Distribute D integer pixels across biomes by current remaining-native share.

    caps = {biome: remaining capacity}

    Residual demand spills to biomes that still have capacity.
    """
    caps = {k: c for k, c in caps.items() if c > 0}
    placed = {k: 0 for k in caps}

    while (
        D - sum(placed.values()) > 0
        and any(
            caps[k] - placed[k] > 0
            for k in caps
        )
    ):
        D_left = D - sum(placed.values())

        active = {
            k: caps[k] - placed[k]
            for k in caps
            if caps[k] - placed[k] > 0
        }

        tot = sum(active.values())

        alloc = {
            k: min(
                active[k],
                (D_left * active[k]) // tot,
            )
            for k in active
        }

        leftover = D_left - sum(alloc.values())

        for k in sorted(
            active,
            key=lambda k: active[k] - alloc[k],
            reverse=True,
        ):
            if leftover <= 0:
                break

            add = min(
                active[k] - alloc[k],
                leftover,
            )
            alloc[k] += add
            leftover -= add

        progressed = sum(alloc.values())

        for k, amount in alloc.items():
            placed[k] += amount

        if progressed == 0:
            break

    return {
        k: v
        for k, v in placed.items()
        if v > 0
    }


# -----------------------------------------------------------------------------
# Integrated post-allocation health check
# -----------------------------------------------------------------------------
def build_demand_pool_check(
    X: dict,
    agbase: dict,
    pool: pd.DataFrame,
    cover_native: dict,
    years: list[int],
    convert: np.ndarray,
) -> tuple[pd.DataFrame, dict]:
    """
    Reconcile allocator demand against available native pool and realized
    allocation.

    Mirrors allocator semantics:
      * conversion is irreversible, so the relevant horizon demand is the
        PEAK cumulative target;
      * integer targets use floor(), as in the allocator;
      * pooled cells split whole-AEZ demand using cover_native;
      * no-pool cells have zero modeled-biome capacity.
    """
    pool_by_cell = (
        pool.groupby(["r", "aez"], observed=True)
        .size()
        .to_dict()
    )

    work = pool[["r", "aez"]].copy()
    work["convert_year"] = convert

    allocated_by_cell = (
        work.loc[work["convert_year"] > 0]
        .groupby(["r", "aez"], observed=True)
        .size()
        .to_dict()
    )

    rows = []
    all_cells = sorted(
        set(X)
        | set(agbase)
        | set(pool_by_cell)
    )

    for (r, a) in all_cells:
        xcell = X.get((r, a))
        ag_ha = agbase.get((r, a))

        if not xcell or not ag_ha:
            continue

        base = xcell.get(BASE_YEAR)
        if base is None:
            continue

        usable_years = [
            y
            for y in years
            if xcell.get(y) is not None
        ]

        if not usable_years:
            continue

        end = usable_years[-1]
        xend = xcell[end]
        ag_px = ag_ha / HA_PER_PIXEL
        pool_px = int(
            pool_by_cell.get((r, a), 0)
        )
        allocated_px = int(
            allocated_by_cell.get((r, a), 0)
        )

        whole_path = {
            y: ag_px * (xcell[y] - base)
            for y in usable_years
        }

        growth_pct = (
            100.0 * (xend - base) / base
            if base
            else float("nan")
        )

        if pool_px == 0:
            peak_no_pool_px = max(
                [0]
                + [
                    int(
                        math.floor(
                            max(0.0, v) + 1e-9
                        )
                    )
                    for v in whole_path.values()
                ]
            )

            rows.append(
                {
                    "r": r,
                    "aez": a,
                    "growth_pct_end": round(
                        growth_pct, 2
                    ),
                    "cover_nat": 0.0,
                    "whole_demand_end_px": int(
                        math.floor(
                            max(
                                0.0,
                                whole_path[end],
                            )
                            + 1e-9
                        )
                    ),
                    "peak_whole_demand_px":
                        peak_no_pool_px,
                    "end_in_biome_target_px": 0,
                    "peak_in_biome_target_px": 0,
                    "outside_biome_peak_px": 0,
                    "no_pool_peak_px":
                        peak_no_pool_px,
                    "pool_px": 0,
                    "allocated_px": allocated_px,
                    "expected_allocated_px": 0,
                    "allocation_gap_px":
                        allocated_px,
                    "demand/pool": float("nan"),
                    "native_share": 0.0,
                    "status": (
                        "no_pool"
                        if allocated_px == 0
                        else "accounting_mismatch"
                    ),
                }
            )
            continue

        cov = float(
            cover_native.get((r, a), 1.0)
        )

        in_path = {
            y: int(
                math.floor(
                    max(
                        0.0,
                        whole_path[y] * cov,
                    )
                    + 1e-9
                )
            )
            for y in usable_years
        }

        outside_path = {
            y: int(
                math.floor(
                    max(
                        0.0,
                        whole_path[y] * (1.0 - cov),
                    )
                    + 1e-9
                )
            )
            for y in usable_years
        }

        end_in = in_path[end]
        peak_in = max(
            [0] + list(in_path.values())
        )
        peak_outside = max(
            [0] + list(outside_path.values())
        )

        expected_allocated = min(
            peak_in,
            pool_px,
        )
        allocation_gap = (
            expected_allocated - allocated_px
        )

        ratio = (
            peak_in / pool_px
            if pool_px > 0
            else float("inf")
        )

        native_share = (
            pool_px / (pool_px + ag_px)
            if (pool_px + ag_px) > 0
            else 0.0
        )

        if allocation_gap != 0:
            status = "accounting_mismatch"
        elif peak_in > pool_px:
            status = "exhausts"
        else:
            status = "ok"

        rows.append(
            {
                "r": r,
                "aez": a,
                "growth_pct_end": round(
                    growth_pct, 2
                ),
                "cover_nat": round(cov, 4),
                "whole_demand_end_px": int(
                    math.floor(
                        max(
                            0.0,
                            whole_path[end],
                        )
                        + 1e-9
                    )
                ),
                "peak_whole_demand_px": max(
                    [0]
                    + [
                        int(
                            math.floor(
                                max(0.0, v)
                                + 1e-9
                            )
                        )
                        for v
                        in whole_path.values()
                    ]
                ),
                "end_in_biome_target_px":
                    end_in,
                "peak_in_biome_target_px":
                    peak_in,
                "outside_biome_peak_px":
                    peak_outside,
                "no_pool_peak_px": 0,
                "pool_px": pool_px,
                "allocated_px": allocated_px,
                "expected_allocated_px":
                    expected_allocated,
                "allocation_gap_px":
                    allocation_gap,
                "demand/pool": round(
                    ratio, 4
                ),
                "native_share": round(
                    native_share, 4
                ),
                "status": status,
            }
        )

    df = pd.DataFrame(rows)

    if len(df):
        df = (
            df.sort_values(
                [
                    "r",
                    "growth_pct_end",
                    "aez",
                ],
                ascending=[
                    True,
                    False,
                    True,
                ],
                na_position="last",
            )
            .reset_index(drop=True)
        )

    pooled = (
        df[df["pool_px"] > 0]
        if len(df)
        else df
    )
    mismatches = (
        df[
            df["status"]
            == "accounting_mismatch"
        ]
        if len(df)
        else df
    )
    exhausts = (
        df[df["status"] == "exhausts"]
        if len(df)
        else df
    )
    no_pool = (
        df[df["status"] == "no_pool"]
        if len(df)
        else df
    )

    summary = {
        "cells": int(len(df)),
        "ok_cells": (
            int(
                (df["status"] == "ok").sum()
            )
            if len(df)
            else 0
        ),
        "exhausting_cells":
            int(len(exhausts)),
        "no_pool_cells":
            int(len(no_pool)),
        "accounting_mismatch_cells":
            int(len(mismatches)),
        "pooled_peak_in_biome_target_px":
            int(
                pooled[
                    "peak_in_biome_target_px"
                ].sum()
            )
            if len(pooled)
            else 0,
        "pooled_expected_allocated_px":
            int(
                pooled[
                    "expected_allocated_px"
                ].sum()
            )
            if len(pooled)
            else 0,
        "pooled_actual_allocated_px":
            int(
                pooled[
                    "allocated_px"
                ].sum()
            )
            if len(pooled)
            else 0,
        "pooled_allocation_gap_px":
            int(
                pooled[
                    "allocation_gap_px"
                ].sum()
            )
            if len(pooled)
            else 0,
        "outside_biome_peak_px":
            int(
                df[
                    "outside_biome_peak_px"
                ].sum()
            )
            if len(df)
            else 0,
        "no_pool_peak_px":
            int(
                df[
                    "no_pool_peak_px"
                ].sum()
            )
            if len(df)
            else 0,
        "native_pool_px":
            int(df["pool_px"].sum())
            if len(df)
            else 0,
        "health": (
            "ERROR"
            if len(mismatches)
            else (
                "REVIEW"
                if len(exhausts)
                else "OK"
            )
        ),
    }

    return df, summary


def ensure_new(
    paths: list[Path],
    force: bool,
) -> None:
    existing = [
        p
        for p in paths
        if p.exists()
    ]

    if existing and not force:
        msg = "\n".join(
            f"  {p}"
            for p in existing
        )

        sys.exit(
            "refusing to overwrite existing canonical output(s):\n"
            f"{msg}\n"
            "Use --force only when you intentionally want to "
            "replace the canonical outputs for this simulation."
        )


def validate_pool(
    pool: pd.DataFrame,
) -> dict:
    missing = (
        REQUIRED_POOL_COLUMNS
        - set(pool.columns)
    )

    if missing:
        sys.exit(
            "allocator pool missing required columns: "
            f"{sorted(missing)}"
        )

    p = pool["p_hat"]

    checks = {
        "rows_match_canonical_target":
            len(pool)
            == EXPECTED_CANONICAL_POOL_ROWS,
        "p_hat_float64":
            str(p.dtype) == "float64",
        "p_hat_finite":
            bool(
                np.isfinite(
                    p.to_numpy(dtype=np.float64)
                ).all()
            ),
        "p_hat_in_0_1":
            bool(
                p.between(
                    0.0,
                    1.0,
                ).all()
            ),
        "p_hat_all_unique":
            int(p.nunique()) == len(pool),
        "pixel_id_unique":
            not bool(
                pool[
                    "pixel_id"
                ].duplicated().any()
            ),
    }

    print("--- canonical pool gate ---")
    for name, passed in checks.items():
        print(f"{name:31s}: {passed}")

    if not all(checks.values()):
        sys.exit(
            "canonical pool integrity gate failed; "
            "allocator not executed"
        )

    print(
        f"pool rows : {len(pool):,}"
    )
    print(
        f"p_hat min : "
        f"{p.min():.15g}"
    )
    print(
        f"p_hat max : "
        f"{p.max():.15g}"
    )
    print()

    return checks


# -----------------------------------------------------------------------------
# Main
# -----------------------------------------------------------------------------
def main() -> int:
    ap = argparse.ArgumentParser(
        description=(
            "Canonical XFT native-conversion "
            "allocator using continuous p_hat."
        )
    )

    ap.add_argument(
        "--gdx",
        required=True,
        type=Path,
    )

    ap.add_argument(
        "--alloc-root",
        default=DEFAULT_ROOT,
        type=Path,
    )

    ap.add_argument(
        "--pool",
        default=None,
        type=Path,
        help=(
            "allocator pool parquet; default: "
            "<alloc-root>/allocator_pixels.parquet"
        ),
    )

    ap.add_argument(
        "--lcov",
        default=DEFAULT_LCOV,
        type=Path,
    )

    ap.add_argument(
        "--coverage",
        default=None,
        type=Path,
        help=(
            "biome_aez_coverage.csv; default: "
            "<alloc-root>/biome_aez_coverage.csv"
        ),
    )

    ap.add_argument(
        "--sim",
        default=None,
        help=(
            "simulation tag; default: GDX "
            "filename stem"
        ),
    )

    ap.add_argument(
        "--end-year",
        type=int,
        default=None,
        help=(
            "last year to allocate; default: "
            "last year present in GDX"
        ),
    )

    ap.add_argument(
        "--outdir",
        default=None,
        type=Path,
        help=(
            "output directory; default: "
            "<alloc-root>/outputs"
        ),
    )

    ap.add_argument(
        "--dry-run",
        action="store_true",
        help=(
            "run complete allocation and health "
            "check in memory; write nothing"
        ),
    )

    ap.add_argument(
        "--force",
        action="store_true",
        help=(
            "replace existing canonical outputs "
            "for this simulation"
        ),
    )

    args = ap.parse_args()

    root = Path(args.alloc_root).resolve()

    pool_path = (
        Path(args.pool)
        if args.pool is not None
        else root / "allocator_pixels.parquet"
    )

    cov_path = (
        Path(args.coverage)
        if args.coverage is not None
        else root / DEFAULT_COVERAGE
    )

    outdir = (
        Path(args.outdir)
        if args.outdir is not None
        else root / "outputs"
    )

    for p in (
        args.gdx,
        pool_path,
        args.lcov,
        cov_path,
    ):
        if not Path(p).exists():
            sys.exit(
                f"missing input: {p}"
            )

    sim = (
        args.sim
        or args.gdx.stem
    )

    print("=" * 104)
    print(
        "CANONICAL XFT NATIVE-CONVERSION ALLOCATOR"
    )
    print("=" * 104)
    print(
        "mode     : "
        + (
            "DRY RUN - writes nothing"
            if args.dry_run
            else "WRITE CANONICAL OUTPUTS"
        )
    )
    print(f"gdx      : {args.gdx}")
    print(f"pool     : {pool_path}")
    print(f"lcov     : {args.lcov}")
    print(f"coverage : {cov_path}")
    print(f"outdir   : {outdir}")
    print(f"sim      : {sim}")
    print()

    # ------------------------------------------------------------------
    # Load inputs.
    # ------------------------------------------------------------------
    xft = read_xft(args.gdx)

    X = {
        (r, a):
            grp.set_index("t")[
                "x"
            ].to_dict()
        for (r, a), grp
        in xft.groupby(
            ["r", "aez"]
        )
    }

    agbase = read_lcov_agbase(
        args.lcov
    )

    covdf = pd.read_csv(
        cov_path
    )

    required_cov = {
        "r",
        "aez",
        "cover_native",
    }

    missing_cov = (
        required_cov
        - set(covdf.columns)
    )

    if missing_cov:
        sys.exit(
            "coverage file missing columns: "
            f"{sorted(missing_cov)}"
        )

    cover_native = (
        covdf
        .drop_duplicates(
            ["r", "aez"]
        )
        .set_index(
            ["r", "aez"]
        )["cover_native"]
        .to_dict()
    )

    pool = pd.read_parquet(
        pool_path
    )

    pool_checks = validate_pool(
        pool
    )

    # ------------------------------------------------------------------
    # Allocation horizon.
    # ------------------------------------------------------------------
    all_years = sorted(
        int(y)
        for y in xft["t"].unique()
    )

    years = [
        y
        for y in all_years
        if (
            y > BASE_YEAR
            and (
                args.end_year is None
                or y <= args.end_year
            )
        )
    ]

    if not years:
        sys.exit(
            "no years to allocate "
            f"(gdx years {all_years}, "
            f"base {BASE_YEAR}, "
            f"end {args.end_year})"
        )

    print(
        f"xft land cells: {len(X)}   "
        f"LCOV ag-base cells: "
        f"{len(agbase)}   "
        f"pool pixels: {len(pool):,}"
    )

    print(
        f"horizon: "
        f"{years[0]}..{years[-1]} "
        f"({len(years)} periods), "
        f"base {BASE_YEAR}"
    )

    # ------------------------------------------------------------------
    # Sort pool by continuous p_hat and construct group pointers.
    # ------------------------------------------------------------------
    pool = (
        pool.sort_values(
            [
                "r",
                "aez",
                "biome",
                "p_hat",
            ],
            ascending=[
                True,
                True,
                True,
                False,
            ],
        )
        .reset_index(drop=True)
    )

    convert = np.zeros(
        len(pool),
        dtype=np.int16,
    )

    groups = {}
    cell_biomes = defaultdict(list)

    for (
        r,
        a,
        b,
    ), idx in pool.groupby(
        [
            "r",
            "aez",
            "biome",
        ],
        observed=True,
    ).indices.items():
        start = int(idx.min())
        end = int(idx.max()) + 1

        groups[(r, a, b)] = [
            start,
            end,
            start,
        ]

        cell_biomes[(r, a)].append(
            b
        )

    def convert_group(
        key,
        k,
        year,
    ):
        start, end, ptr = groups[key]

        take = min(
            k,
            end - ptr,
        )

        if take > 0:
            convert[
                ptr:ptr + take
            ] = year
            groups[key][2] = (
                ptr + take
            )

        return take

    # ------------------------------------------------------------------
    # Demand recursion and replay.
    # ------------------------------------------------------------------
    cum_def = defaultdict(int)
    reserved_outside = defaultdict(int)
    reserved_nopool = defaultdict(int)
    unmet = []
    missing_cov_cells = set()

    demand_cells = sorted(
        set(X.keys())
        | set(agbase.keys())
    )

    for year in years:
        for (r, a) in demand_cells:
            xcell = X.get((r, a))

            base = (
                xcell.get(BASE_YEAR)
                if xcell
                else None
            )

            xt = (
                xcell.get(year)
                if xcell
                else None
            )

            abase_ha = agbase.get(
                (r, a)
            )

            if (
                base is None
                or xt is None
                or not abase_ha
            ):
                continue

            whole_cum = (
                abase_ha
                / HA_PER_PIXEL
            ) * (
                xt - base
            )

            if whole_cum <= 0:
                continue

            biomes_here = (
                cell_biomes.get(
                    (r, a),
                    [],
                )
            )

            # Region x AEZ entirely outside the four modeled biomes.
            if not biomes_here:
                inc = (
                    int(
                        math.floor(
                            whole_cum
                        )
                    )
                    - reserved_nopool[
                        (r, a)
                    ]
                )

                if inc > 0:
                    unmet.append(
                        (
                            r,
                            a,
                            year,
                            inc,
                            "no_pool",
                        )
                    )

                    reserved_nopool[
                        (r, a)
                    ] += inc

                continue

            cov = cover_native.get(
                (r, a)
            )

            if cov is None:
                cov = 1.0
                missing_cov_cells.add(
                    (r, a)
                )

            # Incremental ledger entry for cumulative outside-biome reservation.
            reserved_target = int(
                math.floor(
                    whole_cum
                    * (1.0 - cov)
                )
            )

            reserved_inc = (
                reserved_target
                - reserved_outside[
                    (r, a)
                ]
            )

            if reserved_inc > 0:
                unmet.append(
                    (
                        r,
                        a,
                        year,
                        reserved_inc,
                        "outside_biome",
                    )
                )

                reserved_outside[
                    (r, a)
                ] += reserved_inc

            # In-biome target carried against realized cumulative allocation.
            demand_int = int(
                math.floor(
                    whole_cum * cov
                    - cum_def[(r, a)]
                    + 1e-9
                )
            )

            if demand_int <= 0:
                continue

            caps = {
                b: (
                    groups[
                        (r, a, b)
                    ][1]
                    - groups[
                        (r, a, b)
                    ][2]
                )
                for b in biomes_here
            }

            placed = distribute_int(
                demand_int,
                caps,
            )

            total = 0

            for b, k in placed.items():
                total += convert_group(
                    (r, a, b),
                    k,
                    year,
                )

            cum_def[(r, a)] += total

            # Current outstanding deficit for pooled cells that exhaust.
            if total < demand_int:
                unmet.append(
                    (
                        r,
                        a,
                        year,
                        demand_int - total,
                        "exhausted",
                    )
                )

    if missing_cov_cells:
        print(
            "WARNING: "
            f"{len(missing_cov_cells)} "
            "pool cell(s) had no coverage row "
            "-> used cover=1.0 (no downscaling): "
            f"{sorted(missing_cov_cells)[:10]}"
            f"{' ...' if len(missing_cov_cells) > 10 else ''}"
        )

    # ------------------------------------------------------------------
    # Construct outputs in memory first.
    # ------------------------------------------------------------------
    pool["convert_year"] = convert

    conv = pool[
        pool["convert_year"] > 0
    ]

    unmet_df = pd.DataFrame(
        unmet,
        columns=[
            "r",
            "aez",
            "year",
            "unmet_px",
            "reason",
        ],
    )

    check_df, health = (
        build_demand_pool_check(
            X=X,
            agbase=agbase,
            pool=pool,
            cover_native=cover_native,
            years=years,
            convert=convert,
        )
    )

    # ------------------------------------------------------------------
    # Summary.
    # ------------------------------------------------------------------
    print(
        "\n--- converted pixels (=km2) by biome x year ---"
    )

    if len(conv):
        print(
            conv.pivot_table(
                index="biome",
                columns="convert_year",
                values="pixel_id",
                aggfunc="count",
                fill_value=0,
            ).to_string()
        )
    else:
        print("  (none)")

    print(
        f"\ntotal converted: "
        f"{len(conv):,} px   "
        f"still native: "
        f"{int((convert == 0).sum()):,} px"
    )

    if len(unmet_df):
        by_reason = (
            unmet_df
            .groupby("reason")[
                "unmet_px"
            ]
            .sum()
        )

        print(
            "\n--- allocator unmet / reserved ledger (px) ---"
        )
        print(
            by_reason.to_string()
        )

        print(
            "  outside_biome = increments to cumulative "
            "reservation outside the four modeled biomes"
        )
        print(
            "  no_pool       = increments to cumulative "
            "demand in AEZs with no modeled-biome pool"
        )
        print(
            "  exhausted     = current pooled-cell deficit "
            "when native capacity is exhausted"
        )

        exh = unmet_df[
            unmet_df["reason"]
            == "exhausted"
        ]

        if len(exh):
            cells = sorted(
                {
                    f"{r}/aez{a}"
                    for r, a, *_ in
                    exh.itertuples(
                        index=False
                    )
                }
            )

            print(
                "  exhausted cells:"
            )
            print(
                "   "
                + ", ".join(cells)
            )
    else:
        print(
            "\nno unmet/reserved ledger entries."
        )

    print(
        "\n--- integrated demand vs native-pool health check ---"
    )

    if len(check_df):
        show_cols = [
            "r",
            "aez",
            "growth_pct_end",
            "cover_nat",
            "peak_in_biome_target_px",
            "pool_px",
            "allocated_px",
            "demand/pool",
            "native_share",
            "status",
        ]

        with pd.option_context(
            "display.max_rows",
            None,
            "display.width",
            220,
        ):
            print(
                check_df[
                    show_cols
                ].to_string(
                    index=False
                )
            )

    print(
        "\n=== health summary ==="
    )

    print(
        f"cells: {health['cells']}   "
        f"ok: {health['ok_cells']}   "
        f"exhausts: "
        f"{health['exhausting_cells']}   "
        f"no_pool: "
        f"{health['no_pool_cells']}   "
        f"accounting_mismatch: "
        f"{health['accounting_mismatch_cells']}"
    )

    print(
        f"pooled peak in-biome target : "
        f"{health['pooled_peak_in_biome_target_px']:,} px\n"
        f"expected allocatable        : "
        f"{health['pooled_expected_allocated_px']:,} px\n"
        f"actual allocated            : "
        f"{health['pooled_actual_allocated_px']:,} px\n"
        f"allocation accounting gap   : "
        f"{health['pooled_allocation_gap_px']:,} px\n"
        f"outside-biome reserved      : "
        f"{health['outside_biome_peak_px']:,} px\n"
        f"no-pool demand              : "
        f"{health['no_pool_peak_px']:,} px\n"
        f"native pool                 : "
        f"{health['native_pool_px']:,} px"
    )

    if health["health"] == "OK":
        print(
            "[health] OK: pooled in-biome demand is fully "
            "reconciled; no pool exhaustion."
        )
    elif health["health"] == "REVIEW":
        print(
            "[health] REVIEW: accounting reconciles, but one "
            "or more pooled cells exhaust native capacity."
        )
    else:
        print(
            "[health] ERROR: realized allocation does not "
            "reconcile with expected allocator accounting."
        )

    # ------------------------------------------------------------------
    # Dry-run gate: no files have been written above.
    # ------------------------------------------------------------------
    if args.dry_run:
        print(
            "\n[DRY RUN COMPLETE] "
            "Allocation and health check executed in memory."
        )
        print(
            "No files written."
        )

        return (
            2
            if health["health"] == "ERROR"
            else 0
        )

    # ------------------------------------------------------------------
    # Canonical write only after the health computation is complete.
    # ------------------------------------------------------------------
    defor_path = (
        outdir
        / f"defor_{sim}.parquet"
    )
    unmet_path = (
        outdir
        / f"unmet_{sim}.csv"
    )
    check_path = (
        outdir
        / f"demand_check_{sim}.csv"
    )
    meta_path = (
        outdir
        / f"defor_{sim}_meta.json"
    )

    ensure_new(
        [
            defor_path,
            unmet_path,
            check_path,
            meta_path,
        ],
        force=args.force,
    )

    outdir.mkdir(
        parents=True,
        exist_ok=True,
    )

    pool.to_parquet(
        defor_path,
        index=False,
    )

    unmet_df.to_csv(
        unmet_path,
        index=False,
    )

    check_df.to_csv(
        check_path,
        index=False,
    )

    ledger_sum = (
        int(
            unmet_df[
                "unmet_px"
            ].sum()
        )
        if len(unmet_df)
        else 0
    )

    meta = {
        "built_utc":
            datetime.now(
                timezone.utc
            ).isoformat(),
        "sim": sim,
        "gdx": str(
            Path(args.gdx).resolve()
        ),
        "pool": str(
            Path(pool_path).resolve()
        ),
        "base_year": BASE_YEAR,
        "years": years,
        "coverage_csv": str(
            Path(cov_path).resolve()
        ),
        "lcov_csv": str(
            Path(args.lcov).resolve()
        ),
        "downscale":
            "cover_native (native_ratio)",
        "ranking":
            "descending continuous p_hat within (r,aez,biome)",
        "pool_rows":
            int(len(pool)),
        "pool_integrity":
            pool_checks,
        "converted_px":
            int(len(conv)),
        "still_native_px":
            int(
                (convert == 0).sum()
            ),
        "unmet_px":
            ledger_sum,
        "unmet_ledger_sum_px":
            ledger_sum,
        "unmet_ledger_semantics": {
            "outside_biome":
                "increment to cumulative outside-biome reservation",
            "no_pool":
                "increment to cumulative no-pool demand",
            "exhausted":
                "current outstanding pooled-cell deficit",
        },
        "demand_check_csv":
            str(check_path.resolve()),
        "health":
            health["health"],
        "pooled_peak_in_biome_target_px":
            health[
                "pooled_peak_in_biome_target_px"
            ],
        "pooled_expected_allocated_px":
            health[
                "pooled_expected_allocated_px"
            ],
        "pooled_actual_allocated_px":
            health[
                "pooled_actual_allocated_px"
            ],
        "pooled_allocation_gap_px":
            health[
                "pooled_allocation_gap_px"
            ],
        "outside_biome_peak_px":
            health[
                "outside_biome_peak_px"
            ],
        "no_pool_peak_px":
            health[
                "no_pool_peak_px"
            ],
        "exhausting_cells":
            health[
                "exhausting_cells"
            ],
        "accounting_mismatch_cells":
            health[
                "accounting_mismatch_cells"
            ],
    }

    meta_path.write_text(
        json.dumps(
            meta,
            indent=2,
        ),
        encoding="utf-8",
    )

    print(
        f"\nWROTE {defor_path}"
    )
    print(
        f"WROTE {unmet_path}"
    )
    print(
        f"WROTE {check_path}"
    )
    print(
        f"WROTE {meta_path}"
    )

    return (
        2
        if health["health"] == "ERROR"
        else 0
    )


if __name__ == "__main__":
    raise SystemExit(main())
