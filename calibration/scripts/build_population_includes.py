#!/usr/bin/env python
"""
build_population_includes.py

Very small builder for the SSP population/labor-supply paths.

INPUT
-----
calibration/processed/ssp/ssp_model_region_annual_2017_2050.csv

OUTPUT
------
calibration/output/inc/ssp1_population_2018_2040.inc
calibration/output/inc/ssp3_population_2018_2040.inc

Each include contains ONLY:
    pop.fx(...)
    aft(...,l,...)

Both use the same annual SSP population growth factor.

Run from:
    C:/Users/JesusMERCADO/GAMSProjects/GTAP_AEZ/rdyn

Command:
    python .\calibration\scripts\build_population_includes.py
"""

from __future__ import annotations

import csv
import math
from pathlib import Path

ROOT = Path.cwd()
INPUT = ROOT / "calibration" / "processed" / "ssp" / "ssp_model_region_annual_2017_2050.csv"
OUTDIR = ROOT / "calibration" / "output" / "inc"

SCENARIOS = {
    "SSP1": OUTDIR / "ssp1_population_2018_2040.inc",
    "SSP3": OUTDIR / "ssp3_population_2018_2040.inc",
}

START_YEAR = 2018
END_YEAR = 2040

EXPECTED_REGIONS = {
    "Brazil",
    "Argentina",
    "Paraguay",
    "Uruguay",
    "Bolivia",
    "EU27",
    "China",
    "US",
    "RestLatAm",
    "ROW",
}


def fmt(x: float) -> str:
    return f"{x:.12g}"


def main() -> None:
    if ROOT.name.lower() != "rdyn":
        raise SystemExit(
            "Run this script from the rdyn directory.\n"
            f"Current directory: {ROOT}"
        )

    if not INPUT.exists():
        raise SystemExit(f"Input not found: {INPUT}")

    OUTDIR.mkdir(parents=True, exist_ok=True)

    with INPUT.open("r", encoding="utf-8-sig", newline="") as f:
        rows = list(csv.DictReader(f))

    required = {"Scenario", "target_region", "year", "population_million", "population_growth"}
    missing = required - set(rows[0].keys())
    if missing:
        raise SystemExit("Missing required columns: " + ", ".join(sorted(missing)))

    # Index the processed population panel.
    data = {}
    for row in rows:
        scen = row["Scenario"].strip()
        reg = row["target_region"].strip()
        year = int(row["year"])

        if scen not in SCENARIOS:
            continue
        if reg not in EXPECTED_REGIONS:
            continue
        if not (2017 <= year <= END_YEAR):
            continue

        pop = float(row["population_million"])
        growth = float(row["population_growth"])

        if not math.isfinite(pop) or pop <= 0:
            raise SystemExit(f"Invalid population: {scen} / {reg} / {year}")
        if not math.isfinite(growth) or growth <= 0:
            raise SystemExit(f"Invalid population growth: {scen} / {reg} / {year}")

        data[(scen, reg, year)] = (pop, growth)

    # Validate full coverage and verify the stored growth factor.
    for scen in SCENARIOS:
        regions = {
            reg for (s, reg, y) in data
            if s == scen
        }
        if regions != EXPECTED_REGIONS:
            raise SystemExit(
                f"{scen}: region coverage mismatch.\n"
                f"Missing: {sorted(EXPECTED_REGIONS - regions)}"
            )

        for reg in sorted(EXPECTED_REGIONS):
            for year in range(2017, END_YEAR + 1):
                if (scen, reg, year) not in data:
                    raise SystemExit(f"Missing row: {scen} / {reg} / {year}")

            for year in range(START_YEAR, END_YEAR + 1):
                pop, stored_growth = data[(scen, reg, year)]
                prev_pop, _ = data[(scen, reg, year - 1)]
                calc_growth = pop / prev_pop

                if abs(stored_growth - calc_growth) > 1e-10:
                    raise SystemExit(
                        f"Growth mismatch: {scen} / {reg} / {year}\n"
                        f"stored={stored_growth}, calculated={calc_growth}"
                    )

    # Write one self-contained include per SSP.
    for scen, outpath in SCENARIOS.items():
        lines = [
            "* =============================================================================",
            f"* {scen} population-driven socioeconomic path",
            "*",
            "* Population and labor supply grow at the same annual SSP population rate.",
            "* No GDP target. No afeall. No DynCal.",
            "* Include inside loop(tsim,...) after iterloop.gms.",
            "* Base year 2017 remains fixed in model.gms.",
            "* =============================================================================",
            "",
        ]

        for year in range(START_YEAR, END_YEAR + 1):
            prev = year - 1
            lines.append(f"* --- {year} ---")

            for reg in sorted(EXPECTED_REGIONS):
                _, growth = data[(scen, reg, year)]
                g = fmt(growth)

                lines.append(
                    f'pop.fx("{reg}",tsim)$sameas(tsim,"{year}")'
                    f' = pop.l("{reg}","{prev}") * {g};'
                )
                lines.append(
                    f'aft("{reg}",l,tsim)$sameas(tsim,"{year}")'
                    f' = aft("{reg}",l,"{prev}") * {g};'
                )

            lines.append("")

        outpath.write_text("\n".join(lines) + "\n", encoding="utf-8")

    print("=" * 92)
    print("SSP POPULATION INCLUDE BUILD")
    print("=" * 92)
    print(f"input: {INPUT}")
    print(f"regions: {len(EXPECTED_REGIONS)}")
    print(f"years_written: {START_YEAR}..{END_YEAR}")
    print("growth source: population_growth")
    print("AFT rule: same annual growth as population")
    print()
    for scen, outpath in SCENARIOS.items():
        print(f"{scen}: {outpath}")
    print("=" * 92)


if __name__ == "__main__":
    main()
