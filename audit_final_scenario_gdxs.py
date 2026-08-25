#!/usr/bin/env python
"""
audit_final_scenario_gdxs.py
============================

Read-only audit of the 8 B/T/C/TC scenario GDX files.

Checks:
1. imptx shock structure.
2. lndtfp shock structure.
3. Main endogenous responses in xw and xft.

Run from:
    C:/Users/JesusMERCADO/GAMSProjects/GTAP_AEZ/rdyn

Command:
    python .\audit_final_scenario_gdxs.py
"""

from __future__ import annotations

import glob
import io
import shutil
import subprocess
from pathlib import Path

try:
    import pandas as pd
except Exception as exc:
    raise SystemExit(f"pandas is required: {exc}")

ROOT = Path.cwd()
OUTDIR = ROOT / "output"

FILES = {
    "SSP126_B":  OUTDIR / "SSP126_B.gdx",
    "SSP126_T":  OUTDIR / "SSP126_T.gdx",
    "SSP126_C":  OUTDIR / "SSP126_C.gdx",
    "SSP126_TC": OUTDIR / "SSP126_TC.gdx",
    "SSP370_B":  OUTDIR / "SSP370_B.gdx",
    "SSP370_T":  OUTDIR / "SSP370_T.gdx",
    "SSP370_C":  OUTDIR / "SSP370_C.gdx",
    "SSP370_TC": OUTDIR / "SSP370_TC.gdx",
}

SYMBOLS = ["imptx", "lndtfp", "xw", "xft"]
TOL = 1e-10
END_YEAR = 2040


def find_gdxdump():
    exe = shutil.which("gdxdump")
    if exe:
        return exe

    hits = []
    for pat in (
        r"C:\GAMS\*\gdxdump.exe",
        r"C:\Program Files\GAMS\*\gdxdump.exe",
        r"C:\GAMS\*\*\gdxdump.exe",
        r"C:\Program Files\GAMS\*\*\gdxdump.exe",
    ):
        hits.extend(glob.glob(pat))

    if not hits:
        raise SystemExit("gdxdump.exe not found.")

    return sorted(hits)[-1]


def dump_symbol(exe, gdx, symbol):
    proc = subprocess.run(
        [exe, str(gdx), f"Symb={symbol}", "Format=csv"],
        capture_output=True,
        text=True,
        encoding="utf-8",
        errors="replace",
    )

    if not proc.stdout.strip():
        return None

    try:
        df = pd.read_csv(io.StringIO(proc.stdout))
    except Exception:
        return None

    if df.empty:
        return None

    lower = {str(c).strip().lower(): c for c in df.columns}

    if "l" in lower:
        value_col = lower["l"]
    elif "level" in lower:
        value_col = lower["level"]
    elif "value" in lower:
        value_col = lower["value"]
    elif "val" in lower:
        value_col = lower["val"]
    else:
        numeric_cols = []
        for c in df.columns:
            z = pd.to_numeric(df[c], errors="coerce")
            if z.notna().any():
                numeric_cols.append(c)
        if not numeric_cols:
            return None
        value_col = numeric_cols[-1]

    attr_names = {
        "l", "level", "m", "marginal", "lo", "lower",
        "up", "upper", "scale", "value", "val"
    }

    keys = [
        c for c in df.columns
        if str(c).strip().lower() not in attr_names and c != value_col
    ]

    out = df[keys + [value_col]].copy()
    out[value_col] = pd.to_numeric(out[value_col], errors="coerce")
    out = out[out[value_col].notna()].copy()
    out = out.rename(columns={value_col: "value"})

    for c in keys:
        out[c] = out[c].astype(str)

    return out, keys


def identify_year_col(df, keys):
    best = None
    best_share = 0.0

    for c in keys:
        vals = pd.to_numeric(df[c], errors="coerce")
        share = float(vals.between(2010, 2100).mean()) if len(vals) else 0.0
        if share > best_share:
            best = c
            best_share = share

    return best if best_share > 0.5 else None


def align(a, b):
    dfa, ka = a
    dfb, kb = b

    if ka != kb:
        raise RuntimeError(f"Key mismatch: {ka} vs {kb}")

    m = dfa.merge(dfb, on=ka, how="outer", suffixes=("_a", "_b"))
    m["value_a"] = m["value_a"].fillna(0.0)
    m["value_b"] = m["value_b"].fillna(0.0)
    m["diff"] = m["value_b"] - m["value_a"]
    m["absdiff"] = m["diff"].abs()

    return m, ka


def compare(a, b):
    m, keys = align(a, b)
    changed = m["absdiff"] > TOL
    yc = identify_year_col(m, keys)

    first_year = None
    if yc and changed.any():
        yy = pd.to_numeric(m.loc[changed, yc], errors="coerce").dropna()
        if len(yy):
            first_year = int(yy.min())

    return {
        "changed": int(changed.sum()),
        "total": int(len(m)),
        "first_year": first_year,
        "max_abs": float(m["absdiff"].max()) if len(m) else 0.0,
        "merged": m,
        "keys": keys,
    }


def endpoint_stats(a, b):
    m, keys = align(a, b)
    yc = identify_year_col(m, keys)

    if not yc:
        return None

    yy = pd.to_numeric(m[yc], errors="coerce")
    sub = m[yy == END_YEAR].copy()
    if sub.empty:
        return None

    denom = sub["value_a"].abs()
    mask = denom > 1e-12
    if not mask.any():
        return None

    pct = 100.0 * sub.loc[mask, "diff"] / sub.loc[mask, "value_a"]
    ap = pct.abs()

    return {
        "median": float(ap.median()),
        "p95": float(ap.quantile(0.95)),
        "max": float(ap.max()),
    }


def show(label, result, expected=None):
    fy = "NONE" if result["first_year"] is None else str(result["first_year"])

    status = ""
    if expected == "same":
        status = "PASS" if result["changed"] == 0 else "FAIL"
    elif isinstance(expected, int):
        status = "PASS" if result["first_year"] == expected else "CHECK"

    suffix = f" [{status}]" if status else ""

    print(
        f"{label:30s} "
        f"changed={result['changed']:8d}/{result['total']:<8d} "
        f"first_year={fy:>4s} "
        f"max_abs={result['max_abs']:.8g}"
        f"{suffix}"
    )


def main():
    if ROOT.name.lower() != "rdyn":
        raise SystemExit(
            "Run from the rdyn directory.\n"
            f"Current: {ROOT}"
        )

    missing = [str(p) for p in FILES.values() if not p.exists()]
    if missing:
        raise SystemExit("Missing GDX:\n  " + "\n  ".join(missing))

    exe = find_gdxdump()

    print("=" * 112)
    print("FINAL SCENARIO GDX AUDIT")
    print("=" * 112)
    print(f"gdxdump: {exe}")
    print(f"output_dir: {OUTDIR.resolve()}")

    data = {}
    for run, gdx in FILES.items():
        data[run] = {}
        for sym in SYMBOLS:
            data[run][sym] = dump_symbol(exe, gdx, sym)

    print()
    print("=" * 112)
    print("SYMBOL AVAILABILITY")
    print("=" * 112)
    for sym in SYMBOLS:
        runs = [r for r in FILES if data[r][sym] is not None]
        print(f"{sym:8s}: {len(runs)}/8")

    for sym in ("imptx", "lndtfp"):
        if any(data[r][sym] is None for r in FILES):
            raise SystemExit(
                f"{sym} is not available in all eight GDXs."
            )

    print()
    print("=" * 112)
    print("1. TRADE SHOCK — imptx")
    print("=" * 112)

    for ssp in ("SSP126", "SSP370"):
        print(f"\n[{ssp}]")
        show(
            "B -> T",
            compare(data[f"{ssp}_B"]["imptx"], data[f"{ssp}_T"]["imptx"]),
            2026,
        )
        show(
            "B -> C should be same",
            compare(data[f"{ssp}_B"]["imptx"], data[f"{ssp}_C"]["imptx"]),
            "same",
        )
        show(
            "T -> TC should be same",
            compare(data[f"{ssp}_T"]["imptx"], data[f"{ssp}_TC"]["imptx"]),
            "same",
        )

    print("\n[Cross SSP]")
    show(
        "SSP126_B -> SSP370_B",
        compare(data["SSP126_B"]["imptx"], data["SSP370_B"]["imptx"]),
        "same",
    )
    show(
        "SSP126_T -> SSP370_T",
        compare(data["SSP126_T"]["imptx"], data["SSP370_T"]["imptx"]),
        "same",
    )

    print()
    print("=" * 112)
    print("2. CLIMATE SHOCK — lndtfp")
    print("=" * 112)

    for ssp in ("SSP126", "SSP370"):
        print(f"\n[{ssp}]")
        show(
            "B -> C",
            compare(data[f"{ssp}_B"]["lndtfp"], data[f"{ssp}_C"]["lndtfp"]),
            2021,
        )
        show(
            "T -> TC",
            compare(data[f"{ssp}_T"]["lndtfp"], data[f"{ssp}_TC"]["lndtfp"]),
            2021,
        )
        show(
            "B -> T should be same",
            compare(data[f"{ssp}_B"]["lndtfp"], data[f"{ssp}_T"]["lndtfp"]),
            "same",
        )
        show(
            "C -> TC should be same",
            compare(data[f"{ssp}_C"]["lndtfp"], data[f"{ssp}_TC"]["lndtfp"]),
            "same",
        )

    print("\n[Cross SSP]")
    show(
        "SSP126_B -> SSP370_B",
        compare(data["SSP126_B"]["lndtfp"], data["SSP370_B"]["lndtfp"]),
        "same",
    )
    show(
        "SSP126_C -> SSP370_C",
        compare(data["SSP126_C"]["lndtfp"], data["SSP370_C"]["lndtfp"]),
    )

    print()
    print("=" * 112)
    print("3. MAIN ENDOGENOUS RESPONSE")
    print("=" * 112)

    for sym in ("xw", "xft"):
        if any(data[r][sym] is None for r in FILES):
            print(f"\n[{sym}] not present in all 8 GDXs; skipped.")
            continue

        print(f"\n[{sym}]")

        for ssp in ("SSP126", "SSP370"):
            print(f"  {ssp}")

            for label, base, alt in (
                ("T-B", f"{ssp}_B", f"{ssp}_T"),
                ("C-B", f"{ssp}_B", f"{ssp}_C"),
                ("TC-B", f"{ssp}_B", f"{ssp}_TC"),
            ):
                c = compare(data[base][sym], data[alt][sym])
                e = endpoint_stats(data[base][sym], data[alt][sym])

                fy = "NONE" if c["first_year"] is None else str(c["first_year"])

                if e:
                    print(
                        f"    {label:5s} first_year={fy:>4s} "
                        f"changed={c['changed']:8d} "
                        f"| 2040 abs% median={e['median']:.4f} "
                        f"p95={e['p95']:.4f} max={e['max']:.4f}"
                    )
                else:
                    print(
                        f"    {label:5s} first_year={fy:>4s} "
                        f"changed={c['changed']:8d}"
                    )

        print("  Cross SSP")
        show(
            "SSP126_B -> SSP370_B",
            compare(data["SSP126_B"][sym], data["SSP370_B"][sym]),
        )
        show(
            "SSP126_T -> SSP370_T",
            compare(data["SSP126_T"][sym], data["SSP370_T"][sym]),
        )
        show(
            "SSP126_C -> SSP370_C",
            compare(data["SSP126_C"][sym], data["SSP370_C"][sym]),
        )

    print()
    print("=" * 112)
    print("EXPECTED PATTERN")
    print("=" * 112)
    print("imptx:   B->T starts in 2026; B=C; T=TC.")
    print("lndtfp:  B->C and T->TC start in 2021; B=T; C=TC.")
    print("Climate: SSP126_C should differ from SSP370_C.")
    print("If SSP126_B == SSP370_B also for xw/xft, the current SSP distinction")
    print("is only the climate factor, not a separate socioeconomic baseline.")
    print("=" * 112)


if __name__ == "__main__":
    main()
