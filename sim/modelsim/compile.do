# Arithmetic Unit Lab - ModelSim / Questa script (Nitish Sundarraj)
# From sim/modelsim:   vsim -c -do compile.do
# Compiles the RTL and testbenches and runs the minimum-requirement bench.
vlib work
vcom -2008 -work work ../../rtl/au_pkg.vhd
foreach f {half_adder full_adder pp_cell pg_black reg_en dff_en} { vcom -2008 -work work ../../rtl/cells/$f.vhd }
foreach f {ripple_adder kogge_stone_adder cpa array_multiplier dadda_multiplier multiplier shift_divider restoring_divider} { vcom -2008 -work work ../../rtl/arith/$f.vhd }
foreach f {arith_unit_min arith_unit arith_unit_serial} { vcom -2008 -work work ../../rtl/top/$f.vhd }
foreach f {tb_cells tb_cpa tb_multiplier tb_shift_divider tb_restoring_divider tb_arith_unit_min tb_arith_unit_vectors tb_arith_unit_serial} { vcom -2008 -work work ../../tb/$f.vhd }
vsim -c work.tb_arith_unit_min
run -all
quit -f
