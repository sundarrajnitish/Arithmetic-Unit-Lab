# Arithmetic Unit Lab - timing constraints (Nitish Sundarraj)
# The 2023 runs had no clock constraint, so the timing analyser reported
# "No paths to report".  Constrain the clock so fmax is actually analysed.
create_clock -name clk -period 10.000 [get_ports clk]
derive_clock_uncertainty
set_input_delay  -clock clk 2.000 [remove_from_collection [all_inputs] [get_ports {clk reset_n}]]
set_output_delay -clock clk 2.000 [all_outputs]
set_false_path -from [get_ports reset_n]
