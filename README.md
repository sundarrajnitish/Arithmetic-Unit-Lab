# Arithmetic Unit Lab

**A synchronous arithmetic unit in structural VHDL, built up from full adders.** Two operands are latched into registers, a multiplier forms the product, a divider scales it and an adder finishes the formula:

```
P = A·B/4 + 1            minimum requirement (8-bit unsigned A, B; 16-bit P)
P = A·B/2^C + D          generic N, signed or unsigned, C and D run-time inputs
P = A·B/C² + D           same, with a restoring divider
```

**Interactive site:** https://sundarrajnitish.github.io/Arithmetic-Unit-Lab/

On the site you can:

- load operands into a cycle-accurate model of the unit and clock it one edge at a time, with the datapath, state machine, registers and a waveform viewer;
- watch the 8×8 partial-product matrix go through the Dadda reduction stages, or through the carry-save array cell by cell, signed or unsigned, for N from 3 to 16;
- run the four multiplier netlists side by side in a unit-delay simulation and see the carries ripple and settle;
- shift a negative number and see why an arithmetic shift is not division, and step a restoring divider bit by bit;
- see the serial frames that bring the pin count from 56 down to 8;
- browse the regression, the synthesis results and the audit of the 2023 code.

This is v2 of a COEN 6501 (Digital Systems Design, Concordia University) final project from Fall 2023. The 2023 multipliers were correct, but the design around them did not compile as submitted, lost the operands when `load` lasted one clock, got signed division wrong and was never measured for speed. The details are under [What v2 fixes](#what-v2-fixes). The original files are kept unchanged in [`legacy/`](legacy/).

```
            ┌────────┐   ┌──────────────┐   ┌─────────┐   ┌────────────┐   ┌──────────────┐   ┌────────┐
 A, B ─────►│ A, B   ├──►│ multiplier   ├──►│ x = A·B ├──►│ ÷2^C shift │──►│ q + D + rnd  ├──►│ P reg  ├──► P
 C ────────►│ C, D   │   │ array/Dadda  │   │ dv = C² ├──►│ ÷C² divide │   │ (one adder)  │   │ status │──► status
 D ────────►│ regs   │──►│ (shared: C·C)│   └─────────┘   └────────────┘   └──────────────┘   └────────┘
            └────────┘   └──────────────┘         control: IDLE → SQR → MUL → SHIFT | DIV → ADD
```

## Quick start

Needs GHDL; the synthesis sweep also needs yosys with the GHDL plugin and nextpnr-ice40. On Ubuntu 24.04:

```bash
sudo apt install ghdl ghdl-mcode python3-pytest yosys yosys-plugin-ghdl nextpnr-ice40 nodejs
git clone https://github.com/sundarrajnitish/Arithmetic-Unit-Lab
cd Arithmetic-Unit-Lab

scripts/run_tests.sh              # full regression: 83 runs, about 2 minutes
legacy/audit/run_audit.sh         # reproduce every finding about the 2023 code
python3 scripts/synth_sweep.py    # LUTs, flip-flops, fmax and gate depth (about 4 minutes)
python3 scripts/build_site_data.py  # refresh the numbers the website shows
```

`scripts/run_tests.sh quick` runs one configuration per testbench. ModelSim or Questa users can start from `sim/modelsim/compile.do`; a Quartus project for the course's MAX 10 (10M08DAF484C8G) with a clock constraint is in `syn/quartus/`.

## The designs

| Top level | What it does | Ports |
|---|---|---|
| `arith_unit_min` | P = A·B/4 + 1, unsigned, generic N; optional product register (`PIPELINE`) | `clk reset_n load A B` → `status P` |
| `arith_unit` | both formulas, signed or unsigned, generic N, CW, DW; divide-by-zero and overflow flags | `clk reset_n load A B C D sgn fsel` → `status err ovf P` |
| `arith_unit_serial` | `arith_unit` with serial frames in and out | `clk reset_n sin sin_en start` → `sout sout_valid busy` |

**Handshake.** `load = '1'` on a rising edge latches every input and clears `status`. When the result is in the P register, `status` goes high, and P, `status`, `err` and `ovf` hold until the next load. A load while busy restarts with the new operands. `reset_n = '0'` clears every register and the outputs asynchronously. Latency after the load edge: 1 clock for `arith_unit_min` (2 with `PIPELINE`), 3 clocks for `A·B/2^C + D`, 2N + 5 clocks for `A·B/C² + D`.

**Arithmetic.**

- *Multipliers.* `ARCH = "ARRAY"` is a carry-save array: carries go down, not sideways, so each row costs one full-adder delay and only the last adder propagates. `ARCH = "DADDA"` builds the partial-product matrix column by column and reduces it through the Dadda heights (… 9, 6, 4, 3, 2) with the fewest adders; the plan is computed at elaboration by `au_pkg.dadda_plan`. Both are generic in N and signed at run time with the modified Baugh-Wooley scheme: the partial products with exactly one sign bit are complemented and 2^N + 2^(2N−1) is added, the first through the final adder's carry-in and the second through an unused adder input, so signed mode costs no extra row.
- *Final adders.* `CPA_ARCH = "RIPPLE"`, `"KOGGE_STONE"` (parallel prefix, log₂ depth) or `"INFERRED"` (numeric_std `+`, which lets the FPGA tool use its carry chain). The first two are structural.
- *Division by 2^C* is a logarithmic barrel shifter with sign fill. A shift rounds negative numbers down, but integer division rounds toward zero, so the shifter also reports whether a negative value lost any 1s, and the final adder adds that bit through its carry-in. Shifts wider than the word are exact.
- *Division by C²* reuses the multiplier for C·C, takes |A·B| with a two's-complement incrementer, and runs a restoring divider (one quotient bit per clock). A negative quotient is negated through the same final adder: invert, carry-in 1. C = 0 sets `err` and P = 0.
- *Overflow.* The final adder has a guard bit; `ovf` rises if q + D does not fit in 2N bits. With `DW ≤ N` this cannot happen, which the golden model checks exhaustively for N = 4.

Everything under `rtl/` is plain VHDL-93 (the regression analyses it as both VHDL-93 and VHDL-2008). There are no tri-states and no latches.

## Verification

`model/au_model.py` is the specification in executable form: P, `err`, `ovf` and the exact latency for any input, plus bit-level models of both multipliers and the Dadda plan. It writes the vector files in `tb/vectors/`; the VHDL testbenches drive the real handshake with them, and the website's JavaScript model (`docs/js/model.js`) is tested against the same files.

| Testbench | What it checks |
|---|---|
| `tb_cells` | truth tables of the leaf cells |
| `tb_cpa` | every adder architecture: every input up to 8 bits, carry-chain corners and random words to 64 bits |
| `tb_multiplier` | array and Dadda with every final adder, signed and unsigned: every operand pair up to N = 8 (131,072 products each), corners and random pairs up to N = 32 |
| `tb_shift_divider` | x / 2^C rounded toward zero for every x (W ≤ 10) and every C |
| `tb_restoring_divider` | quotient, `busy` and `done` timing, every pair at 8/6 bits |
| `tb_arith_unit_min` | all 65,536 (A, B) pairs through load/status, held and back-to-back loads, reset in flight |
| `tb_arith_unit_vectors` | 11,344 golden-model vectors over four width configurations: both formulas, signed and unsigned, `err`, `ovf`, exact latency, result hold, one-cycle loads, loads that interrupt a computation, reset in flight |
| `tb_arith_unit_serial` | the serial frames against the same vectors |

The last full run: 83 runs, 2,139,194 checks, no failures (`results/tests.log`). A deliberately broken rounding bit, overflow flag or divide-by-zero path makes `tb_arith_unit_vectors` fail.

## Results

Open-source flow for a Lattice iCE40 HX8K (yosys `synth_ice40`, nextpnr, median fmax of three seeds). Each multiplier sits between registers so fmax measures only the multiplier. "Gate depth" is the longest path in logic gates as the VHDL writes it, before synthesis restructures it. Full table: [`results/synthesis.md`](results/synthesis.md).

| 8×8 multiplier | LUT4 | fmax (MHz) | gate depth |
|---|---:|---:|---:|
| 2023 array | 141 | 48.8 | 54 |
| 2023 "Wallace tree" | 159 | 60.2 | 51 |
| 2023 Baugh-Wooley array | 137 | 72.5 | – |
| v2 array + ripple | 132 | 69.4 | 42 |
| v2 Dadda + Kogge-Stone | 145 | 77.7 | 21 |
| **v2 Dadda + carry chain** | **134** | **122.2** | 22 |
| numeric_std `*` (tool-built) | 211 | 97.8 | – |

| Complete unit, N = 8 | LUT4 | FF | fmax (MHz) |
|---|---:|---:|---:|
| 2023 synchronous unit (renamed so it binds; latch cut for timing) | 199 | 62 | 57.0 |
| `arith_unit_min`, Dadda + carry chain, pipelined | 147 | 48 | 107.3 |
| `arith_unit`, Dadda + carry chain | 420 | 163 | 86.1 |
| `arith_unit_serial`, Dadda + Kogge-Stone | 485 | 221 | 63.3 |

What the numbers say:

- A real reduction tree halves the logic depth (Dadda + Kogge-Stone: 21 gates against 42 for the array and 51 for the 2023 "Wallace tree", which is a reordered array).
- On a LUT FPGA, depth on paper is not the whole story. The tool re-maps the logic, and a structural prefix adder in LUTs gains little, while the dedicated carry chain nearly doubles fmax at N = 16 (37 → 75 MHz). The fastest build pairs the Dadda tree with an inferred final adder: 2.5× the 2023 array at N = 8, in fewer LUTs than the tool's own `*`.
- The full unit adds the shifter, the divider's subtractor and the final adder around the multiplier; the same `CPA_ARCH` choice speeds all of them up (55 → 86 MHz from array + ripple to Dadda + carry chain).

## What v2 fixes

Each item is reproduced by `legacy/audit/run_audit.sh` against the untouched 2023 files (output in `results/legacy_audit.txt`).

| 2023 | v2 |
|---|---|
| `arithmetic_hw.vhd` declares `arithmeitc_hw` and does not compile; 7 of 97 files fail to analyse | every file analyses as VHDL-93 and VHDL-2008, CI builds the tree |
| `sync_arithmetic_hw.vhd` and `generic_array_baugh.vhd` declare an entity called `synthesis`, so the testbench and the v3 top cannot bind them | one entity per file, entity instantiation |
| operand registers load on `load`, but their tri-state gate opens a clock later: with `load` high for one edge (the specification) A and B latch `'Z'` and P is `X`; it only works with a two-cycle load | registers load on the load edge; one-cycle, held and back-to-back loads are all tested |
| P is `'Z'` except for one clock, `status` is a one-clock pulse, and `P_end` is a latch | P, `status`, `err`, `ovf` are registers that hold until the next load |
| internal tri-states throughout the datapath | none |
| `tb_array_multiplier`, `tb_divider_unit` and `tb_full_adder_16` leave `start` open, so 254/256, 65,532/65,536 and 65,535/65,536 assertions fail, and the first still prints "All Test Cases Passed"; it tried 256 of 65,536 operand pairs | benches count failures, end in PASS or FAIL with an exit code, and are exhaustive where possible |
| signed `divider_2c` pads with 1s regardless of the sign, so every one of 98,304 non-negative inputs comes out wrong; the data analyser then one's-complements the quotient and zero-extends D: the signed formula was wrong in 1,996 of 2,000 random cases | sign-filled shift, rounding toward zero through the carry-in, D sign-extended |
| adder and divider hard-wired to 32 internal bits (`K = 32`), C read as 5 bits: N = 17 does not elaborate | sized from the generics; tested from N = 2 to 32 and with shifts wider than the word |
| "Wallace tree" is a reordered array (51 gates deep vs 54) | a real Dadda tree (21 gates with the prefix adder) |
| A·B/C² + D, serial I/O and speed optimisation missing; no clock constraint, so no fmax was ever reported | restoring C² divider sharing the multiplier, 8-pin serial wrapper, architecture choices measured for area and fmax, SDC for Quartus |

What was already right, and kept: the array multiplier, the reorganised array and the generic Baugh-Wooley array give the right product for all 65,536 operand pairs, and the unsigned 2^C formula is right once the load is held for two clocks.

## Repository

```
rtl/au_pkg.vhd        clog2, Dadda plan
rtl/cells/            half_adder full_adder pp_cell pg_black reg_en dff_en
rtl/arith/            ripple_adder kogge_stone_adder cpa
                      array_multiplier dadda_multiplier multiplier
                      shift_divider restoring_divider
rtl/top/              arith_unit_min arith_unit arith_unit_serial
rtl/files.f           compile order
tb/                   self-checking testbenches, vectors/ from the golden model
model/au_model.py     golden model          tests/  pytest + node checks
scripts/              run_tests.sh synth_sweep.py build_site_data.py
syn/                  timing harnesses, quartus/ (MAX 10 project + SDC)
sim/modelsim/         compile.do
results/              regression log, audit output, synthesis tables
docs/                 the website (GitHub Pages: main branch, /docs)
legacy/               the 2023 sources, unchanged; audit/ reproduces the findings
```

## Licence

Apache-2.0, see [LICENSE](LICENSE). The files in `legacy/` are the original 2023 course submission, kept for reference.
