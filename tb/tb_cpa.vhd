--------------------------------------------------------------------------------
-- Arithmetic Unit Lab                                          tb/tb_cpa.vhd
-- Author : Nitish Sundarraj
--
-- Carry-propagate adders.  W <= 8: every x, y and carry-in.
-- W > 8: carry-chain corners plus random operands.
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity tb_cpa is
  generic (
    W      : positive := 8;
    ARCH   : string   := "KOGGE_STONE";
    RANDOM : natural  := 20000
  );
end entity tb_cpa;

architecture sim of tb_cpa is
  signal x, y, s : std_logic_vector(W - 1 downto 0) := (others => '0');
  signal ci, co  : std_logic := '0';
begin
  dut : entity work.cpa generic map (W => W, ARCH => ARCH)
    port map (x => x, y => y, ci => ci, s => s, co => co);

  process
    variable errors, checks : natural := 0;
    variable s1 : positive := 3;
    variable s2 : positive := 5;
    variable r  : real;

    procedure check (vx, vy : unsigned; vc : std_logic) is
      variable e : unsigned(W downto 0);
    begin
      x <= std_logic_vector(vx); y <= std_logic_vector(vy); ci <= vc;
      wait for 1 ns;
      e := resize(vx, W + 1) + resize(vy, W + 1);
      if vc = '1' then e := e + 1; end if;
      checks := checks + 1;
      if unsigned(s) /= e(W - 1 downto 0) or co /= e(W) then errors := errors + 1; end if;
    end procedure;

    impure function rnd return unsigned is
      variable v : unsigned(W - 1 downto 0);
    begin
      for i in 0 to W - 1 loop
        uniform(s1, s2, r);
        if r > 0.5 then v(i) := '1'; else v(i) := '0'; end if;
      end loop;
      return v;
    end function;

    variable ones : unsigned(W - 1 downto 0) := (others => '1');
  begin
    if W <= 8 then
      for i in 0 to 2 ** W - 1 loop
        for j in 0 to 2 ** W - 1 loop
          check(to_unsigned(i, W), to_unsigned(j, W), '0');
          check(to_unsigned(i, W), to_unsigned(j, W), '1');
        end loop;
      end loop;
    else
      check(ones, to_unsigned(0, W), '1');          -- full-length carry chain
      check(ones, ones, '1');
      check(ones, to_unsigned(1, W), '0');
      for k in 1 to RANDOM loop
        check(rnd, rnd, '0');
        check(rnd, rnd, '1');
      end loop;
    end if;
    if errors = 0 then
      report "PASS tb_cpa W=" & integer'image(W) & " " & ARCH & " checks=" & integer'image(checks);
    else
      report "FAIL tb_cpa W=" & integer'image(W) & " " & ARCH & " errors=" & integer'image(errors) severity failure;
    end if;
    wait;
  end process;
end architecture sim;
