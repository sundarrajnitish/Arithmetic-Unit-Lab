--------------------------------------------------------------------------------
-- Arithmetic Unit Lab                                        tb/tb_cells.vhd
-- Author : Nitish Sundarraj
--
-- Truth tables of the leaf cells: half_adder, full_adder, pp_cell, pg_black.
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_cells is
end entity tb_cells;

architecture sim of tb_cells is
  signal a, b, c, d : std_logic := '0';
  signal ha_s, ha_c, fa_s, fa_c, pp, g, p : std_logic;
begin
  u_ha : entity work.half_adder port map (a => a, b => b, s => ha_s, co => ha_c);
  u_fa : entity work.full_adder port map (a => a, b => b, ci => c, s => fa_s, co => fa_c);
  u_pp : entity work.pp_cell    port map (a => a, b => b, inv => c, p => pp);
  u_pg : entity work.pg_black   port map (g_hi => a, p_hi => b, g_lo => c, p_lo => d, g => g, p => p);

  process
    variable v : unsigned(3 downto 0);
    variable errors : natural := 0;
    variable x, y, z, w, sum : natural;
  begin
    for i in 0 to 15 loop
      v := to_unsigned(i, 4);
      a <= v(0); b <= v(1); c <= v(2); d <= v(3);
      wait for 1 ns;
      x := i mod 2; y := (i / 2) mod 2; z := (i / 4) mod 2; w := i / 8;
      sum := x + y;
      if ha_s /= to_unsigned(sum, 2)(0) or ha_c /= to_unsigned(sum, 2)(1) then errors := errors + 1; end if;
      sum := x + y + z;
      if fa_s /= to_unsigned(sum, 2)(0) or fa_c /= to_unsigned(sum, 2)(1) then errors := errors + 1; end if;
      if pp /= ((v(0) and v(1)) xor v(2)) then errors := errors + 1; end if;
      if g /= (v(0) or (v(1) and v(2))) or p /= (v(1) and v(3)) then errors := errors + 1; end if;
    end loop;
    if errors = 0 then
      report "PASS tb_cells";
    else
      report "FAIL tb_cells errors=" & integer'image(errors) severity failure;
    end if;
    wait;
  end process;
end architecture sim;
