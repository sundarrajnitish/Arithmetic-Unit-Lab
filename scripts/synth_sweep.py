#!/usr/bin/env python3
"""Arithmetic Unit Lab - open-source synthesis sweep.

Author: Nitish Sundarraj

For every configuration:
  * yosys + ghdl plugin -> synth_ice40 : LUT4, flip-flop and carry counts
  * nextpnr-ice40 (HX8K, ct256), 3 seeds : register-to-register fmax (median)
  * yosys synth -noabc + ltp            : as-written logic depth in gates
                                           (combinational multipliers only)

Results go to results/synthesis.json and results/synthesis.md; the website
reads docs/data/synthesis.json (a copy).

    python3 scripts/synth_sweep.py            # full sweep (a few minutes)
    python3 scripts/synth_sweep.py --quick    # N = 8 only
"""
from __future__ import annotations

import argparse
import json
import re
import shutil
import statistics
import subprocess
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
RTL = [ROOT / p for p in (ROOT / "rtl" / "files.f").read_text().split()]
LEG_SUB = ROOT / "legacy" / "Submission" / "Minimal Requirement"
LEG_V3 = ROOT / "legacy" / "Additional Requirement v3 8-bit"
SEEDS = (1, 2, 3)


def sh(cmd: list[str], cwd: Path) -> str:
    r = subprocess.run(cmd, cwd=cwd, capture_output=True, text=True)
    if r.returncode != 0:
        raise RuntimeError(f"{cmd[0]} failed:\n{r.stdout[-3000:]}\n{r.stderr[-3000:]}")
    return r.stdout + r.stderr


def legacy_sources(tmp: Path) -> list[Path]:
    """2023 files needed by the harnesses; entity 'synthesis' renamed where needed."""
    files = [LEG_SUB / f"{n}.vhd" for n in ("half_adder", "full_adder", "multiplier",
                                            "array_multiplier_8", "wallace_tree_multiplier",
                                            "divider_unit", "full_adder_16")]
    sync = (LEG_SUB / "sync_arithmetic_hw.vhd").read_text()
    sync = (sync.replace("entity synthesis is", "entity legacy_sync_unit is")
                .replace("end synthesis;", "end legacy_sync_unit;")
                .replace("architecture Behavioral of synthesis", "architecture Behavioral of legacy_sync_unit"))
    (tmp / "legacy_sync.vhd").write_text(sync)
    bw = (LEG_V3 / "generic_array_baugh.vhd").read_text()
    bw = (bw.replace("entity synthesis is", "entity generic_array_multiplier is")
            .replace("end synthesis;", "end generic_array_multiplier;")
            .replace("structural_generic of synthesis", "structural_generic of generic_array_multiplier"))
    (tmp / "legacy_bw.vhd").write_text(bw)
    local = []
    for f in files:                      # the yosys ghdl command cannot take paths with spaces
        dst = tmp / f"legacy_{f.name}"
        shutil.copy(f, dst)
        local.append(dst)
    return local + [tmp / "legacy_sync.vhd", tmp / "legacy_bw.vhd", ROOT / "syn" / "harness_legacy.vhd"]


def ghdl_cmd(top: str, generics: dict, legacy: bool, tmp: Path) -> str:
    gen = " ".join(f"-g{k}={v}" for k, v in generics.items())
    if legacy:
        files = " ".join(str(p) for p in legacy_sources(tmp))
        return f"ghdl --std=08 -fsynopsys --latches {gen} {files} -e {top}"
    files = " ".join(str(p) for p in RTL + [ROOT / "syn" / "harness_mult.vhd"])
    return f"ghdl --std=08 {gen} {files} -e {top}"


def synth(top: str, generics: dict, legacy: bool = False, depth_top: str | None = None) -> dict:
    with tempfile.TemporaryDirectory() as td:
        tmp = Path(td)
        json_path = tmp / "net.json"
        log = sh(["yosys", "-m", "ghdl", "-p",
                  f"{ghdl_cmd(top, generics, legacy, tmp)}; synth_ice40 -top {top} -json {json_path}; stat"], tmp)
        cells = dict(re.findall(r"^\s+(SB_\w+)\s+(\d+)\s*$", log.split("Printing statistics")[-1], re.M))
        luts = int(cells.get("SB_LUT4", 0))
        ffs = sum(int(v) for k, v in cells.items() if k.startswith("SB_DFF"))
        carry = int(cells.get("SB_CARRY", 0))
        fmax, note = [], ""
        for seed in SEEDS:
            cmd = ["nextpnr-ice40", "--hx8k", "--package", "ct256", "--json", str(json_path),
                   "--freq", "40", "--seed", str(seed), "--timing-allow-fail"]
            try:
                out = sh(cmd, tmp)
            except RuntimeError:
                # the 2023 sync unit has a latch -> combinational loop; time it with the loop cut
                out = sh(cmd + ["--ignore-loops"], tmp)
                note = "combinational loop (inferred latch) ignored for timing"
            m = re.findall(r"Max frequency for clock[^:]*: ([\d.]+) MHz", out)
            if m:
                fmax.append(float(m[-1]))
        res = {"lut4": luts, "ff": ffs, "carry": carry,
               "fmax_mhz": round(statistics.median(fmax), 1) if fmax else None,
               "fmax_seeds": fmax}
        if note:
            res["note"] = note
        if depth_top:
            dg = dict(generics)
            dg.pop("IMPL", None)
            log = sh(["yosys", "-m", "ghdl", "-p",
                      f"{ghdl_cmd(depth_top, dg, legacy, tmp)}; synth -top {depth_top} -flatten -noabc; "
                      f"opt_clean; ltp -noff; stat"], tmp)
            m = re.search(r"Longest topological path.*?\(length=(\d+)\)", log)
            res["gate_depth"] = int(m.group(1)) if m else None
            g = re.findall(r"^\s+\$_(\w+)_\s+(\d+)\s*$", log.split("Printing statistics")[-1], re.M)
            res["gates"] = sum(int(n) for _, n in g)
        return res


def tool_version(t: str) -> str:
    r = subprocess.run([t, "-V" if t == "yosys" else "--version"], capture_output=True, text=True)
    lines = (r.stdout + r.stderr).strip().splitlines()
    return lines[0].strip() if lines else "?"


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--quick", action="store_true")
    args = ap.parse_args()
    for tool in ("yosys", "nextpnr-ice40", "ghdl"):
        if not shutil.which(tool):
            print(f"{tool} not found", file=sys.stderr)
            return 1

    ns = [8] if args.quick else [4, 6, 8, 12, 16]
    rows = []

    def add(group, name, **kw):
        print(f"  {group:10s} {name:40s}", end="", flush=True)
        r = synth(**kw)
        r.update(group=group, name=name)
        rows.append(r)
        print(f" LUT4 {r['lut4']:5d}  FF {r['ff']:4d}  fmax {r['fmax_mhz']} MHz"
              + (f"  depth {r['gate_depth']}" if "gate_depth" in r else ""))

    print("== multipliers (register harness)")
    for n in ns:
        for arch in ("ARRAY", "DADDA"):
            for cpa in ("RIPPLE", "KOGGE_STONE", "INFERRED"):
                add("mult", f"v2 {arch}/{cpa} N={n}", top="harness_mult",
                    generics={"N": n, "IMPL": "V2", "ARCH": arch, "CPA": cpa},
                    depth_top="multiplier")
                rows[-1].update(n=n, arch=arch, cpa=cpa)
        add("mult", f"numeric_std '*' N={n}", top="harness_mult",
            generics={"N": n, "IMPL": "BEHAVIORAL"})
        rows[-1].update(n=n, arch="BEHAVIORAL", cpa="-")

    print("== 2023 multipliers (same harness, same flow)")
    for impl in ("ARRAY", "WALLACE", "BAUGH"):
        add("legacy", f"2023 {impl} N=8", top="harness_legacy", generics={"IMPL": impl}, legacy=True)
        rows[-1].update(n=8, arch=f"2023-{impl}", cpa="RIPPLE")
    # as-written depth of the 2023 multipliers
    for impl, ent in (("ARRAY", "array_multiplier"), ("WALLACE", "wallace_tree_multiplier")):
        with tempfile.TemporaryDirectory() as td:
            tmp = Path(td)
            log = sh(["yosys", "-m", "ghdl", "-p",
                      f"{ghdl_cmd(ent, {}, True, tmp)}; synth -top {ent} -flatten -noabc; opt_clean; ltp -noff; stat"], tmp)
            m = re.search(r"Longest topological path.*?\(length=(\d+)\)", log)
            g = re.findall(r"^\s+\$_(\w+)_\s+(\d+)\s*$", log.split("Printing statistics")[-1], re.M)
            for r in rows:
                if r["name"] == f"2023 {impl} N=8":
                    r["gate_depth"] = int(m.group(1)) if m else None
                    r["gates"] = sum(int(n) for _, n in g)

    print("== complete units (N = 8)")
    add("unit", "2023 sync unit (Wallace, tri-states)", top="legacy_sync_unit", generics={}, legacy=True)
    for arch, cpa, pipe in (("ARRAY", "RIPPLE", "false"), ("DADDA", "KOGGE_STONE", "false"),
                            ("DADDA", "KOGGE_STONE", "true"), ("DADDA", "INFERRED", "true")):
        add("unit", f"arith_unit_min {arch}/{cpa} PIPELINE={pipe}", top="arith_unit_min",
            generics={"N": 8, "MULT_ARCH": arch, "CPA_ARCH": cpa, "PIPELINE": pipe})
    for arch, cpa in (("ARRAY", "RIPPLE"), ("DADDA", "KOGGE_STONE"), ("DADDA", "INFERRED")):
        add("unit", f"arith_unit {arch}/{cpa}", top="arith_unit",
            generics={"N": 8, "MULT_ARCH": arch, "CPA_ARCH": cpa})
    add("unit", "arith_unit_serial DADDA/KOGGE_STONE", top="arith_unit_serial",
        generics={"N": 8, "MULT_ARCH": "DADDA", "CPA_ARCH": "KOGGE_STONE"})

    out = {"flow": "yosys synth_ice40 + nextpnr-ice40 --hx8k ct256, fmax = median of seeds "
                   + ", ".join(map(str, SEEDS)),
           "tools": {t: tool_version(t) for t in ("yosys", "nextpnr-ice40", "ghdl")},
           "rows": rows}
    res = ROOT / "results"
    res.mkdir(exist_ok=True)
    (res / "synthesis.json").write_text(json.dumps(out, indent=1))
    (ROOT / "docs" / "data").mkdir(parents=True, exist_ok=True)
    (ROOT / "docs" / "data" / "synthesis.json").write_text(json.dumps(out))

    md = ["# Synthesis results", "", f"Flow: {out['flow']}.", "",
          "| group | design | LUT4 | FF | carry | fmax (MHz) | gate depth | gates |",
          "|---|---|---:|---:|---:|---:|---:|---:|"]
    for r in rows:
        md.append(f"| {r['group']} | {r['name']} | {r['lut4']} | {r['ff']} | {r['carry']} | "
                  f"{r['fmax_mhz']} | {r.get('gate_depth', '')} | {r.get('gates', '')} |")
    (res / "synthesis.md").write_text("\n".join(md) + "\n")
    print(f"wrote {res / 'synthesis.json'} and synthesis.md")
    return 0


if __name__ == "__main__":
    sys.exit(main())
