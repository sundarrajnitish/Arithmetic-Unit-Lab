#!/usr/bin/env bash
# Arithmetic Unit Lab - full regression.
# Author: Nitish Sundarraj
#
#   scripts/run_tests.sh          everything (about a minute with GHDL mcode)
#   scripts/run_tests.sh quick    one configuration per testbench
#
# Needs GHDL >= 3 and python3.  Exit status is non-zero if anything fails.
set -u
cd "$(dirname "$0")/.."
MODE=${1:-full}
B=build/ghdl
rm -rf "$B"; mkdir -p "$B"
PASS=0; FAIL=0; FAILED=()

run() {                                   # run <entity> [-gX=Y ...]
  local ent=$1; shift
  local out
  out=$(ghdl -r --std=08 --workdir="$B" "$ent" "$@" --ieee-asserts=disable-at-0 2>&1)
  local line
  line=$(printf '%s\n' "$out" | grep -o 'PASS .*\|FAIL .*' | tail -1)
  if printf '%s' "$line" | grep -q '^PASS'; then
    PASS=$((PASS + 1)); printf '  ok    %s\n' "$line"
  else
    FAIL=$((FAIL + 1)); FAILED+=("$ent $*")
    printf '  FAIL  %s %s\n' "$ent" "$*"
    printf '%s\n' "$out" | grep -i 'error\|fail' | head -5 | sed 's/^/        /'
  fi
}

echo "== analyse (RTL as VHDL-93 and VHDL-2008, testbenches as VHDL-2008)"
mkdir -p "$B/v93"
ghdl -a --std=93 --workdir="$B/v93" $(cat rtl/files.f) || { echo "RTL is not VHDL-93 clean"; exit 1; }
ghdl -a --std=08 --workdir="$B" $(cat rtl/files.f) tb/*.vhd || exit 1
for tb in tb/*.vhd; do ghdl -e --std=08 --workdir="$B" "$(basename "$tb" .vhd)" || exit 1; done

echo "== golden model and website model"
if python3 -c 'import pytest' 2>/dev/null; then
  if python3 -m pytest -q tests >/tmp/au_pytest.log 2>&1; then
    PASS=$((PASS + 1)); echo "  ok    pytest: $(tail -1 /tmp/au_pytest.log)"
  else
    FAIL=$((FAIL + 1)); FAILED+=("pytest"); tail -20 /tmp/au_pytest.log
  fi
else
  echo "  (pytest not installed, skipped)"
fi
# the checked-in vectors must be what the model produces today
for spec in "8 8 8 4000 2023 n8" "4 4 4 1500 4 n4" "16 8 16 1500 16 n16" "8 8 16 1500 816 n8_dw16"; do
  set -- $spec
  if ! python3 -m model.au_model vectors --n "$1" --cw "$2" --dw "$3" --count "$4" --seed "$5" | cmp -s - "tb/vectors/arith_unit_$6.txt"; then
    FAIL=$((FAIL + 1)); FAILED+=("vectors $6 stale"); echo "  FAIL  tb/vectors/arith_unit_$6.txt differs from the model"
  fi
done

if command -v node >/dev/null; then
  if node tests/test_js_model.mjs >/tmp/au_node.log 2>&1; then
    PASS=$((PASS + 1)); echo "  ok    node: $(tail -1 /tmp/au_node.log)"
  else
    FAIL=$((FAIL + 1)); FAILED+=("node tests/test_js_model.mjs"); tail -20 /tmp/au_node.log
  fi
else
  echo "  (node not installed, website model check skipped)"
fi

echo "== cells and adders"
run tb_cells
for W in 1 4 8; do for A in RIPPLE KOGGE_STONE INFERRED; do run tb_cpa -gW=$W -gARCH=$A; done; done
[ "$MODE" = full ] && for W in 16 17 33 64; do for A in RIPPLE KOGGE_STONE; do run tb_cpa -gW=$W -gARCH=$A -gRANDOM=5000; done; done

echo "== multipliers"
NS="2 3 4 5 8"; [ "$MODE" = quick ] && NS="4 8"
for N in $NS; do for A in ARRAY DADDA; do for C in RIPPLE KOGGE_STONE; do
  run tb_multiplier -gN=$N -gARCH=$A -gCPA=$C
done; done; done
if [ "$MODE" = full ]; then
  for N in 12 16 24 32; do for A in ARRAY DADDA; do run tb_multiplier -gN=$N -gARCH=$A -gRANDOM=5000; done; done
fi
for A in ARRAY DADDA; do run tb_multiplier -gN=8 -gARCH=$A -gCPA=INFERRED; done

echo "== dividers"
run tb_shift_divider -gW=8 -gCW=5
run tb_shift_divider -gW=10 -gCW=4
[ "$MODE" = full ] && run tb_shift_divider -gW=16 -gCW=8 -gRANDOM=500
run tb_restoring_divider -gW=8 -gDW=6
run tb_restoring_divider -gW=8 -gDW=6 -gCPA=KOGGE_STONE
[ "$MODE" = full ] && run tb_restoring_divider -gW=16 -gDW=16 -gRANDOM=5000

echo "== minimum-requirement unit  P = A*B/4 + 1  (all 65,536 pairs for N = 8)"
for A in ARRAY DADDA; do for P in false true; do
  run tb_arith_unit_min -gMULT_ARCH=$A -gPIPELINE=$P
done; done
if [ "$MODE" = full ]; then
  run tb_arith_unit_min -gN=4 -gCPA_ARCH=RIPPLE
  run tb_arith_unit_min -gN=16 -gRANDOM=5000
  run tb_arith_unit_min -gN=16 -gMULT_ARCH=ARRAY -gCPA_ARCH=RIPPLE -gPIPELINE=true -gRANDOM=5000
fi

echo "== general unit  P = A*B/2^C + D  |  A*B/C^2 + D   (golden-model vectors)"
CFG="8,8,8,n8 4,4,4,n4 16,8,16,n16 8,8,16,n8_dw16"
[ "$MODE" = quick ] && CFG="8,8,8,n8"
for cfg in $CFG; do
  IFS=, read -r N CW DW V <<<"$cfg"
  for A in ARRAY DADDA; do for C in RIPPLE KOGGE_STONE; do
    [ "$MODE" = quick ] && [ "$C" = RIPPLE ] && continue
    run tb_arith_unit_vectors -gN=$N -gCW=$CW -gDW=$DW -gMULT_ARCH=$A -gCPA_ARCH=$C -gVECTORS=tb/vectors/arith_unit_$V.txt
  done; done
done

run tb_arith_unit_vectors -gMULT_ARCH=DADDA -gCPA_ARCH=INFERRED
run tb_arith_unit_min -gCPA_ARCH=INFERRED -gPIPELINE=true

echo "== serial I/O wrapper"
run tb_arith_unit_serial
[ "$MODE" = full ] && run tb_arith_unit_serial -gN=4 -gCW=4 -gDW=4 -gVECTORS=tb/vectors/arith_unit_n4.txt -gLIMIT=2000

echo
echo "== $PASS passed, $FAIL failed"
if [ "$FAIL" -ne 0 ]; then printf '   %s\n' "${FAILED[@]}"; exit 1; fi
