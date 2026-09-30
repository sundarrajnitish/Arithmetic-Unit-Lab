#!/usr/bin/env bash
# Arithmetic Unit Lab - reproduce every finding about the 2023 code.
# Author: Nitish Sundarraj
#
# Needs GHDL (any backend).  Legacy sources are never modified: where a file
# has to be renamed to bind at all, a renamed copy goes into the build dir.
# Usage (from the repo root):  legacy/audit/run_audit.sh [build-dir]
set -u
ROOT=$(cd "$(dirname "$0")/../.." && pwd)
L="$ROOT/legacy"
A="$ROOT/legacy/audit"
B=${1:-"$ROOT/build/legacy_audit"}
rm -rf "$B"; mkdir -p "$B"/{sub,v3,chk}
G93="ghdl -a --std=93c -fsynopsys -fexplicit -frelaxed"
G08="ghdl -a --std=08 -fsynopsys"
SUB="$L/Submission/Minimal Requirement"
V3="$L/Additional Requirement v3 8-bit"
say() { printf '%s\n' "$*"; }

say "== 1. Does every 2023 file compile? (GHDL, VHDL-93, Synopsys packages, ModelSim-style -fexplicit)"
fails=0; total=0
while IFS= read -r f; do
  total=$((total + 1))
  d="$B/chk/$(printf '%s' "$f" | md5sum | cut -c1-8)"; mkdir -p "$d"
  if ! out=$($G93 --workdir="$d" "$f" 2>&1); then
    fails=$((fails + 1))
    say "   FAIL  ${f#"$L"/}: $(printf '%s\n' "$out" | grep -m1 error | sed 's/.*error: //')"
  fi
done < <(find "$L" -name '*.vhd' -not -path '*/audit/*' | sort)
say "   $fails of $total files do not analyse on their own."

say "== 2. Submitted combinational multipliers, all 65,536 operand pairs"
for f in half_adder full_adder multiplier array_multiplier_8 wallace_tree_multiplier divider_unit full_adder_16; do
  $G08 --workdir="$B/sub" "$SUB/$f.vhd"
done
$G08 --workdir="$B/sub" "$A/tb_audit_mult.vhd"
ghdl -e --std=08 -fsynopsys --workdir="$B/sub" tb_audit_mult
ghdl -r --std=08 -fsynopsys --workdir="$B/sub" tb_audit_mult 2>&1 | grep -o 'RESULT.*' | sed 's/^/   /'

say "== 3. Submitted testbenches as written"
mkdir -p "$B/tbs"
for f in half_adder full_adder multiplier array_multiplier_8 divider_unit full_adder_16; do
  $G93 --workdir="$B/tbs" "$SUB/$f.vhd"
done
for tb in tb_array_multiplier tb_divider_unit tb_full_adder_16 tb_half_adder tb_full_adder tb_multiplier; do
  ent=$(grep -i -m1 '^entity' "$L/Submission/Testbenches/$tb.vhd" | awk '{print $2}')
  $G93 --workdir="$B/tbs" "$L/Submission/Testbenches/$tb.vhd" 2>/dev/null
  ghdl -e --std=93c -fsynopsys -fexplicit --workdir="$B/tbs" "$ent" >/dev/null 2>&1
  log=$(ghdl -r --std=93c -fsynopsys -fexplicit --workdir="$B/tbs" "$ent" 2>&1)
  nfail=$(printf '%s\n' "$log" | grep -c 'assertion error')
  passed=$(printf '%s\n' "$log" | grep -c 'All Test Cases Passed')
  say "   $tb: $nfail failed assertions; prints 'All Test Cases Passed': $([ "$passed" -gt 0 ] && echo yes || echo no)"
done
say "   (tb_arithmetic_hw cannot run: arithmetic_hw.vhd does not compile, see 1.)"

say "== 4. Submitted synchronous unit (entity 'synthesis' renamed so it can bind), A=200 B=100"
sed 's/entity synthesis is/entity sync_arithmetic_hw is/; s/end synthesis;/end sync_arithmetic_hw;/; s/architecture Behavioral of synthesis/architecture Behavioral of sync_arithmetic_hw/' \
  "$SUB/sync_arithmetic_hw.vhd" > "$B/sub/sync_renamed.vhd"
$G08 --workdir="$B/sub" "$B/sub/sync_renamed.vhd" "$A/tb_audit_sync.vhd"
ghdl -e --std=08 -fsynopsys --workdir="$B/sub" tb_audit_sync
for n in 1 2; do
  say "   load high for $n clock(s):"
  ghdl -r --std=08 -fsynopsys --workdir="$B/sub" tb_audit_sync -gLOAD_CYCLES=$n 2>&1 | grep -o 'TRACE.*\|EXPECTED.*' | sed 's/^/     /'
done

say "== 5. 2023 generic Baugh-Wooley array (N=8, all pairs) and signed 2^C divider"
for f in full_adder adder_d data_analyzer divider_2c; do $G08 --workdir="$B/v3" "$V3/$f.vhd"; done
sed 's/entity synthesis is/entity generic_array_multiplier is/; s/end synthesis;/end generic_array_multiplier;/; s/structural_generic of synthesis/structural_generic of generic_array_multiplier/' \
  "$V3/generic_array_baugh.vhd" > "$B/v3/baugh_renamed.vhd"
$G08 --workdir="$B/v3" "$B/v3/baugh_renamed.vhd" "$V3/sync_arithmetic_hw_ar.vhd" "$A/tb_audit_bw.vhd" "$A/tb_audit_v3.vhd"
ghdl -e --std=08 -fsynopsys --workdir="$B/v3" tb_audit_bw
ghdl -r --std=08 -fsynopsys --workdir="$B/v3" tb_audit_bw 2>&1 | grep -o 'RESULT.*' | sed 's/^/   /'

say "== 6. 2023 additional-requirements unit, P = A*B/2^C + D, 2000 random vectors each"
ghdl -e --std=08 -fsynopsys --workdir="$B/v3" tb_audit_v3
for s in 0 1; do
  ghdl -r --std=08 -fsynopsys --workdir="$B/v3" tb_audit_v3 -gSGNI=$s 2>&1 | grep -o 'RESULT.*' | sed 's/^/   /'
done

say "== 7. Generic sizes: does the 2023 generic adder elaborate for N = 17 (a 34-bit product)?"
cat > "$B/v3/tb_n17.vhd" <<'VHDL'
library ieee; use ieee.std_logic_1164.all;
entity tb_n17 is end;
architecture a of tb_n17 is
  signal x, y, s : std_logic_vector(33 downto 0);
begin
  u : entity work.generic_adder generic map (N => 17, K => 32) port map (A => x, B => y, start => '1', P_out => s);
end;
VHDL
$G08 --workdir="$B/v3" "$B/v3/tb_n17.vhd"
if ghdl -e --std=08 -fsynopsys --workdir="$B/v3" tb_n17 >/dev/null 2>&1 && \
   ghdl -r --std=08 -fsynopsys --workdir="$B/v3" tb_n17 --stop-time=1ns >/dev/null 2>&1; then
  say "   elaborates"
else
  say "   does not elaborate (hard-coded 32-bit internals, K = 32)"
fi
say "== done"
