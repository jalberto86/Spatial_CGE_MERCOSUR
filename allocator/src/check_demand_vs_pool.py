#!/usr/bin/env python3
# -*- coding: utf-8 -*-
r"""
check_demand_vs_pool.py
=======================
Sanity check before trusting long-horizon runs: for each (r,aez), compare the CUMULATIVE demand
at the end year against the native pool the allocator can draw from. Answers whether the
exhaustion allocate.py reports is genuine depletion (the biome physically runs out of native) or
an LCOV-base over-demand artifact.

Reuses allocate.py's readers so the demand math is identical (no drift).

Per (r,aez) it prints:
  growth_pct    : land-index growth over the horizon, 100*(xft[end]/xft[2018] - 1)
  lcov_ag_kha   : LCOV17 cropland+pasture base (1000 ha) -- the demand scaler
  cum_demand_px : A_base_px * (xft[end]-xft[2018])  = cumulative new conversion demanded (km2)
  pool_px       : native@2018 pixels available in the cell (km2)
  demand/pool   : the key ratio (>1 => the cell exhausts)
  native_share  : pool_px / (pool_px + lcov_ag_px)  -- low => cell already mostly agricultural
  status        : ok | exhausts | no_pool

Reading it:
  - exhausts with demand/pool near 1 AND low native_share -> GENUINE depletion (mostly-converted
    cell, little native left; the CGE wants expansion there is no native for -> real leakage).
  - exhausts with demand/pool >> 1 while growth_pct is modest -> the LCOV base is over-demanding
    (suspect grazing-inflated ag base); worth revisiting the scaling for that cell.

Run (from the estimation .venv; allocate.py must sit next to this file):
    python check_demand_vs_pool.py --gdx "...\output\Rdyn.gdx"
    python check_demand_vs_pool.py --gdx "...\output\scenarioX.gdx" --end-year 2045
Read-only.
"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

import pandas as pd

try:
    import allocate as alc                      # reuse the exact readers + constants
except Exception as e:
    sys.exit(f"could not import allocate.py (must be in the same folder): {e}")


def main() -> int:
    ap = argparse.ArgumentParser(description="Compare cumulative demand vs native pool per (r,aez).")
    ap.add_argument("--gdx", required=True, type=Path)
    ap.add_argument("--alloc-root", default=alc.DEFAULT_ROOT, type=Path)
    ap.add_argument("--lcov", default=alc.DEFAULT_LCOV, type=Path)
    ap.add_argument("--coverage", default=None, help="biome_aez_coverage.csv (default under --alloc-root)")
    ap.add_argument("--end-year", type=int, default=None, help="default: last year in the gdx")
    args = ap.parse_args()

    pool_path = Path(args.alloc_root) / "allocator_pixels.parquet"
    for p in (args.gdx, pool_path, args.lcov):
        if not Path(p).exists():
            sys.exit(f"missing input: {p}")

    xft = alc.read_xft(args.gdx)
    X = {(r, a): grp.set_index("t")["x"].to_dict() for (r, a), grp in xft.groupby(["r", "aez"])}
    agbase = alc.read_lcov_agbase(args.lcov)
    pool = pd.read_parquet(pool_path)
    pool_by_cell = pool.groupby(["r", "aez"]).size().to_dict()
    cov_path = Path(args.coverage) if args.coverage else Path(args.alloc_root) / alc.DEFAULT_COVERAGE
    if not cov_path.exists():
        sys.exit(f"coverage file not found: {cov_path} (run probe_biome_aez_coverage.py first)")
    covdf = pd.read_csv(cov_path)
    cover_native = covdf.drop_duplicates(["r", "aez"]).set_index(["r", "aez"])["cover_native"].to_dict()

    all_years = sorted(int(y) for y in xft["t"].unique())
    end = args.end_year if args.end_year is not None else all_years[-1]
    print(f"=== demand vs pool ===  gdx={args.gdx.name}  base={alc.BASE_YEAR}  end={end}\n")

    rows = []
    for (r, a) in sorted(set(X) | set(agbase) | {k for k in pool_by_cell}):
        xcell = X.get((r, a))
        base = xcell.get(alc.BASE_YEAR) if xcell else None
        xend = xcell.get(end) if xcell else None
        ag_ha = agbase.get((r, a))
        pool_px = int(pool_by_cell.get((r, a), 0))
        if base is None or xend is None or not ag_ha:
            continue
        ag_px = ag_ha / alc.HA_PER_PIXEL
        growth = xend - base
        cov = cover_native.get((r, a), 1.0)
        whole_demand = ag_px * growth                     # whole-AEZ (pre-downscale)
        cum_demand = whole_demand * cov                   # what the allocator actually sends in-biome
        ratio = (cum_demand / pool_px) if pool_px > 0 else float("inf")
        native_share = pool_px / (pool_px + ag_px) if (pool_px + ag_px) > 0 else 0.0
        status = "no_pool" if pool_px == 0 else ("exhausts" if cum_demand > pool_px else "ok")
        rows.append({
            "r": r, "aez": a,
            "growth_pct": round(100 * growth / base, 2) if base else float("nan"),
            "cover_nat": round(cov, 4),
            "whole_demand_px": int(round(whole_demand)),
            "cum_demand_px": int(round(cum_demand)),          # downscaled
            "pool_px": pool_px,
            "demand/pool": round(ratio, 2) if pool_px else float("inf"),
            "native_share": round(native_share, 3),
            "status": status,
        })

    df = pd.DataFrame(rows).sort_values("demand/pool", ascending=False).reset_index(drop=True)
    with pd.option_context("display.max_rows", None, "display.width", 200):
        print(df.to_string(index=False))

    exh = df[df["status"] == "exhausts"]
    nop = df[df["status"] == "no_pool"]
    print("\n=== summary ===")
    print(f"cells: {len(df)}   ok: {int((df['status']=='ok').sum())}   "
          f"exhausts: {len(exh)}   no_pool: {len(nop)}")
    tot_demand = int(df.loc[df['pool_px'] > 0, 'cum_demand_px'].sum())
    tot_pool = int(df['pool_px'].sum())
    print(f"total cum demand (pooled cells): {tot_demand:,} px   total native pool: {tot_pool:,} px")
    if len(exh):
        print("\nexhausting cells (demand/pool, growth_pct, native_share):")
        for _, x in exh.iterrows():
            tag = ("depletion" if x['native_share'] < 0.10          # little native left -> genuine
                   else ("check-scaling" if x['demand/pool'] > 3    # has native, demand vastly exceeds
                         else "review"))
            print(f"  {x['r']}/aez{x['aez']:<3} demand/pool={x['demand/pool']:>6}  "
                  f"growth={x['growth_pct']:>6}%  native_share={x['native_share']:.3f}  -> {tag}")
        print("\n  depletion-plausible = little native left, genuine physical exhaustion;")
        print("  check-scaling       = demand far exceeds pool at modest growth -> revisit LCOV base.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
