#!/usr/bin/env python
"""
build_trade_tariff_input.py
==============================

Build the compact tariff input used by the recursive-dynamic GTAP-AEZ model.

SOURCE
------
Input/Trade_Barrier_Inputs_2019_2050.xlsx

Only the eight policy sheets are imported:
    BRA-EU27
    ARG-EU27
    PRY-EU27
    URY-EU27
    BOL-EU27
    Mercosur-CHN
    Mercosur-USA
    Mercosur-ROW

OUTPUT
------
Input/trade_tariffs_2019_2050_long.csv

Columns:
    exporter
    sector
    importer
    tradecase
    year
    tariff_rate
    present

tariff_rate is a DECIMAL ad-valorem rate:
    workbook 10.75  ->  0.1075

present is always 1 and deliberately preserves explicitly supplied zero tariffs
when the CSV is later converted to GDX.

AUDIT
-----
calibration/audit/trade_tariff_input_audit.csv

RUN FROM
--------
C:/Users/JesusMERCADO/GAMSProjects/GTAP_AEZ/rdyn

    python .\build_trade_tariff_input.py
"""

from __future__ import annotations

import csv
import math
from collections import Counter, defaultdict
from pathlib import Path

from openpyxl import load_workbook


# Resolve the repository layout from this script's location:
#   rdyn/calibration/scripts/build_trade_tariff_input.py
SCRIPT_DIR = Path(__file__).resolve().parent
CALIBRATION_DIR = SCRIPT_DIR.parent
RDYN_ROOT = CALIBRATION_DIR.parent

WORKBOOK = RDYN_ROOT / "Input" / "Trade_Barrier_Inputs_2019_2050.xlsx"
OUTPUT = RDYN_ROOT / "Input" / "trade_tariffs_2019_2050_long.csv"
AUDIT = CALIBRATION_DIR / "output" / "trade_tariff_input_audit.csv"

POLICY_SHEETS = [
    "BRA-EU27",
    "ARG-EU27",
    "PRY-EU27",
    "URY-EU27",
    "BOL-EU27",
    "Mercosur-CHN",
    "Mercosur-USA",
    "Mercosur-ROW",
]

TRADECASES = [
    "baseline_no_cooperation",
    "cooperation_eu_mercosur",
]

YEARS = list(range(2019, 2051))

EXPECTED_SECTORS = {
    "c_PDR",
    "c_WHT",
    "c_GRO",
    "c_V_F",
    "c_OSD",
    "c_C_B",
    "c_PFB",
    "c_OCR",
    "c_CTL",
    "c_OAP",
    "c_RMK",
    "c_WOL",
    "c_FRS",
    "c_Extraction",
    "c_ProcFood",
    "c_TextWapp",
    "c_LightMnfc",
    "c_HeavyMnfc",
    "c_Util_Cons",
    "c_TransComm",
    "c_OthService",
}

EXPECTED_REGIONS = {
    "Brazil",
    "Argentina",
    "Paraguay",
    "Uruguay",
    "Bolivia",
    "EU27",
    "China",
    "US",
    "ROW",
}

MERCOSUR = {
    "Brazil",
    "Argentina",
    "Paraguay",
    "Uruguay",
    "Bolivia",
}


def fail(message: str) -> None:
    raise SystemExit(f"\nERROR: {message}\n")


def as_float(value, context: str) -> float:
    try:
        x = float(value)
    except (TypeError, ValueError):
        fail(f"Non-numeric tariff value at {context}: {value!r}")

    if not math.isfinite(x):
        fail(f"Non-finite tariff value at {context}: {value!r}")

    if x < 0:
        fail(f"Negative tariff value at {context}: {x}")

    return x


def main() -> int:
    # The script is intentionally location-based rather than cwd-based.
    # This makes the build reproducible even if invoked from another directory.
    if SCRIPT_DIR.name.lower() != "scripts" or CALIBRATION_DIR.name.lower() != "calibration":
        fail(
            "Unexpected script location. Save this file under:\n"
            "  rdyn/calibration/scripts/build_trade_tariff_input.py\n"
            f"Current script location: {Path(__file__).resolve()}"
        )

    workbook = WORKBOOK.resolve()

    if not workbook.exists():
        fail(f"Workbook not found: {workbook}")

    AUDIT.parent.mkdir(parents=True, exist_ok=True)
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)

    wb = load_workbook(
        workbook,
        read_only=True,
        data_only=True,
    )

    missing_sheets = [
        s for s in POLICY_SHEETS
        if s not in wb.sheetnames
    ]

    if missing_sheets:
        fail(
            "Missing required policy sheets: "
            + " | ".join(missing_sheets)
        )

    long_rows = []
    audit_rows = []
    wide_key_counter = Counter()

    # Used for cross-scenario QA.
    values = defaultdict(dict)

    for sheet_name in POLICY_SHEETS:
        ws = wb[sheet_name]

        rows = ws.iter_rows(
            values_only=True
        )

        try:
            header = next(rows)
        except StopIteration:
            fail(f"Empty policy sheet: {sheet_name}")

        headers = [
            str(x).strip() if x is not None else ""
            for x in header
        ]

        hmap = {
            name: idx
            for idx, name in enumerate(headers)
            if name
        }

        required = [
            "sector_code",
            "sector_name",
            "importer",
            "exporter",
            "scenario",
        ] + [
            str(y)
            for y in YEARS
        ]

        missing_headers = [
            h for h in required
            if h not in hmap
        ]

        if missing_headers:
            fail(
                f"{sheet_name}: missing headers: "
                + " | ".join(missing_headers)
            )

        sheet_sectors = set()
        sheet_importers = set()
        sheet_exporters = set()
        sheet_cases = set()
        sheet_wide_rows = 0
        sheet_min = None
        sheet_max = None

        for excel_row, row in enumerate(
            rows,
            start=2,
        ):
            # Skip wholly empty rows.
            if not any(
                cell is not None and str(cell).strip() != ""
                for cell in row
            ):
                continue

            def get(name: str):
                idx = hmap[name]
                return row[idx] if idx < len(row) else None

            sector = str(
                get("sector_code")
            ).strip()

            importer = str(
                get("importer")
            ).strip()

            exporter = str(
                get("exporter")
            ).strip()

            tradecase = str(
                get("scenario")
            ).strip()

            if sector not in EXPECTED_SECTORS:
                fail(
                    f"{sheet_name} row {excel_row}: "
                    f"unexpected sector {sector!r}"
                )

            if importer not in EXPECTED_REGIONS:
                fail(
                    f"{sheet_name} row {excel_row}: "
                    f"unexpected importer {importer!r}"
                )

            if exporter not in EXPECTED_REGIONS:
                fail(
                    f"{sheet_name} row {excel_row}: "
                    f"unexpected exporter {exporter!r}"
                )

            if tradecase not in TRADECASES:
                fail(
                    f"{sheet_name} row {excel_row}: "
                    f"unexpected scenario {tradecase!r}"
                )

            key = (
                sector,
                importer,
                exporter,
                tradecase,
            )

            wide_key_counter[key] += 1

            sheet_sectors.add(sector)
            sheet_importers.add(importer)
            sheet_exporters.add(exporter)
            sheet_cases.add(tradecase)
            sheet_wide_rows += 1

            for year in YEARS:
                pct = as_float(
                    get(str(year)),
                    (
                        f"{sheet_name} row {excel_row}, "
                        f"{sector}, {exporter}->{importer}, "
                        f"{tradecase}, {year}"
                    ),
                )

                rate = pct / 100.0

                long_rows.append(
                    {
                        "exporter": exporter,
                        "sector": sector,
                        "importer": importer,
                        "tradecase": tradecase,
                        "year": year,
                        "tariff_rate": f"{rate:.12g}",
                        "present": 1,
                    }
                )

                values[
                    (
                        sheet_name,
                        sector,
                        importer,
                        exporter,
                        year,
                    )
                ][tradecase] = pct

                sheet_min = (
                    pct
                    if sheet_min is None
                    else min(sheet_min, pct)
                )

                sheet_max = (
                    pct
                    if sheet_max is None
                    else max(sheet_max, pct)
                )

        if sheet_sectors != EXPECTED_SECTORS:
            fail(
                f"{sheet_name}: sector domain is not exactly "
                "the expected 21 model sectors."
            )

        if sheet_cases != set(TRADECASES):
            fail(
                f"{sheet_name}: tradecase domain mismatch."
            )

        audit_rows.append(
            {
                "sheet": sheet_name,
                "wide_rows": sheet_wide_rows,
                "sector_count": len(sheet_sectors),
                "importer_count": len(sheet_importers),
                "exporter_count": len(sheet_exporters),
                "tradecase_count": len(sheet_cases),
                "year_count": len(YEARS),
                "tariff_pct_min": sheet_min,
                "tariff_pct_max": sheet_max,
            }
        )

    wb.close()

    duplicates = [
        key
        for key, count in wide_key_counter.items()
        if count != 1
    ]

    if duplicates:
        preview = " | ".join(
            str(x)
            for x in duplicates[:10]
        )

        fail(
            "Duplicate or repeated wide keys across imported policy sheets. "
            f"Examples: {preview}"
        )

    # ------------------------------------------------------------------
    # Workbook-policy consistency checks documented in README
    # ------------------------------------------------------------------

    scenario_pairs_checked = 0

    for key, case_values in values.items():
        sheet_name, sector, importer, exporter, year = key

        if set(case_values) != set(TRADECASES):
            fail(
                "A policy key does not contain both scenarios: "
                f"{key}"
            )

        baseline = case_values[
            "baseline_no_cooperation"
        ]

        coop = case_values[
            "cooperation_eu_mercosur"
        ]

        scenario_pairs_checked += 1

        # Agreement path must never increase the tariff.
        if coop > baseline + 1e-10:
            fail(
                "Cooperation tariff exceeds baseline at "
                f"{sheet_name}, {sector}, {exporter}->{importer}, {year}: "
                f"baseline={baseline}, cooperation={coop}"
            )

        # No scenario divergence before implementation begins.
        if year <= 2025 and abs(coop - baseline) > 1e-10:
            fail(
                "Scenarios differ before 2026 at "
                f"{sheet_name}, {sector}, {exporter}->{importer}, {year}"
            )

        # Non-EU partner sheets are unchanged by the EU-Mercosur agreement.
        if sheet_name in {
            "Mercosur-CHN",
            "Mercosur-USA",
            "Mercosur-ROW",
        } and abs(coop - baseline) > 1e-10:
            fail(
                "Non-EU partner sheet changes across scenarios at "
                f"{sheet_name}, {sector}, {exporter}->{importer}, {year}"
            )

        # Bolivia is not an agreement party.
        if sheet_name == "BOL-EU27" and abs(coop - baseline) > 1e-10:
            fail(
                "BOL-EU27 changes across scenarios at "
                f"{sector}, {exporter}->{importer}, {year}"
            )

    # Baseline must be constant through time for every bilateral sector key.
    baseline_paths = defaultdict(list)

    for row in long_rows:
        if row[
            "tradecase"
        ] == "baseline_no_cooperation":
            baseline_paths[
                (
                    row["exporter"],
                    row["sector"],
                    row["importer"],
                )
            ].append(
                float(
                    row[
                        "tariff_rate"
                    ]
                )
            )

    for key, path in baseline_paths.items():
        if max(path) - min(path) > 1e-12:
            fail(
                "Baseline tariff path is not constant for "
                f"{key}"
            )

    # ------------------------------------------------------------------
    # Final output checks
    # ------------------------------------------------------------------

    expected_wide_rows = (
        84 * 5
        + 420 * 3
    )

    expected_long_rows = (
        expected_wide_rows
        * len(YEARS)
    )

    if len(wide_key_counter) != expected_wide_rows:
        fail(
            f"Expected {expected_wide_rows} wide keys, "
            f"found {len(wide_key_counter)}"
        )

    if len(long_rows) != expected_long_rows:
        fail(
            f"Expected {expected_long_rows} long rows, "
            f"found {len(long_rows)}"
        )

    long_key_counter = Counter(
        (
            row["exporter"],
            row["sector"],
            row["importer"],
            row["tradecase"],
            row["year"],
        )
        for row in long_rows
    )

    duplicate_long = [
        key
        for key, count in long_key_counter.items()
        if count != 1
    ]

    if duplicate_long:
        fail(
            "Duplicate long-format keys detected."
        )

    # Deterministic ordering.
    case_order = {
        case: idx
        for idx, case in enumerate(TRADECASES)
    }

    long_rows.sort(
        key=lambda row: (
            row["exporter"],
            row["importer"],
            row["sector"],
            case_order[row["tradecase"]],
            int(row["year"]),
        )
    )

    with OUTPUT.open(
        "w",
        newline="",
        encoding="utf-8",
    ) as f:
        writer = csv.DictWriter(
            f,
            fieldnames=[
                "exporter",
                "sector",
                "importer",
                "tradecase",
                "year",
                "tariff_rate",
                "present",
            ],
        )

        writer.writeheader()
        writer.writerows(long_rows)

    with AUDIT.open(
        "w",
        newline="",
        encoding="utf-8",
    ) as f:
        writer = csv.DictWriter(
            f,
            fieldnames=[
                "sheet",
                "wide_rows",
                "sector_count",
                "importer_count",
                "exporter_count",
                "tradecase_count",
                "year_count",
                "tariff_pct_min",
                "tariff_pct_max",
            ],
        )

        writer.writeheader()
        writer.writerows(audit_rows)

    tariff_rates = [
        float(row["tariff_rate"])
        for row in long_rows
    ]

    zero_rows = sum(
        1
        for x in tariff_rates
        if x == 0
    )

    print("=" * 108)
    print("TRADE TARIFF INPUT BUILD")
    print("=" * 108)

    print(f"rdyn_root: {RDYN_ROOT}")
    print(f"workbook: {WORKBOOK}")
    print(f"policy_sheets: {len(POLICY_SHEETS)}")
    print(f"wide_policy_keys: {len(wide_key_counter)}")
    print(f"long_rows: {len(long_rows)}")
    print(f"scenario_year_pairs_checked: {scenario_pairs_checked}")
    print(f"sector_count: {len(EXPECTED_SECTORS)}")
    print(f"year_range: {YEARS[0]}..{YEARS[-1]}")
    print(f"tradecases: {' | '.join(TRADECASES)}")
    print(f"tariff_rate_min_decimal: {min(tariff_rates):.6g}")
    print(f"tariff_rate_max_decimal: {max(tariff_rates):.6g}")
    print(f"explicit_zero_tariff_rows: {zero_rows}")

    print()
    print("QA")
    print("-" * 108)
    print("baseline_constant_2019_2050: PASS")
    print("scenarios_identical_through_2025: PASS")
    print("cooperation_never_above_baseline: PASS")
    print("non_EU_partner_sheets_unchanged: PASS")
    print("Bolivia_EU27_unchanged: PASS")
    print("duplicate_long_keys: 0")

    print()
    print("OUTPUT")
    print("-" * 108)
    print(f"tariff_file: {OUTPUT.resolve()}")
    print(f"audit_file: {AUDIT.resolve()}")
    print("=" * 108)

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
