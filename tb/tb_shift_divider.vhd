--------------------------------------------------------------------------------
-- Arithmetic Unit Lab                                tb/tb_shift_divider.vhd
-- Author : Nitish Sundarraj
--
-- Barrel-shift divider: q + round_up must equal x / 2^C rounded toward zero,
-- for unsigned and signed x and every C that fits in CW bits (including
-- C >= W).  W <= 10: every x.  Larger W: corners plus random x.
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity tb_shift_divider is
  generic (
    W      : positive := 8;
    CW     : positive := 5;
    RANDOM : natural  := 3000
  );
end entity tb_shift_divider;

architecture sim of tb_shift_divider is
  signal x, q   : std_logic_vector(W - 1 downto 0) := (others => '0');
  signal c      : std_logic_vector(CW - 1 downto 0) := (others => '0');
  signal sgn, rnd_up : std_logic := '0';
begin
  dut : entity work.shift_divider generic map (W => W, CW => CW)
    port map (x => x, c => c, sgn => sgn, q => q, round_up => rnd_up);

  process
    variable errors, checks : natural := 0;
    variable s1 : positive := 17;
    variable s2 : positive := 23;
    variable r  : real;

    procedure check (vx : std_logic_vector; mode : std_logic) is
      variable got, want : signed(W + 1 downto 0);     -- room for unsigned values
      variable sh : natural;
      variable xi : signed(W + 1 downto 0);
    begin
      for ci in 0 to 2 ** CW - 1 loop
        x <= vx; c <= std_logic_vector(to_unsigned(ci, CW)); sgn <= mode;
        wait for 1 ns;
        if mode = '1' then
          xi  := resize(signed(vx), W + 2);
          got := resize(signed(q), W + 2);
        else
          xi  := signed(resize(unsigned(vx), W + 2));
          got := signed(resize(unsigned(q), W + 2));
        end if;
        if rnd_up = '1' then got := got + 1; end if;
        -- round toward zero: shift the magnitude, restore the sign
        sh := ci;
        if sh > W + 1 then sh := W + 1; end if;
        if xi < 0 then
          want := -signed(shift_right(unsigned(-xi), sh));
        else
          want := signed(shift_right(unsigned(xi), sh));
        end if;
        checks := checks + 1;
        if got /= want then
          errors := errors + 1;
          if errors < 8 then
            report "x=" & integer'image(to_integer(xi)) & " C=" & integer'image(ci) & " got "
                 & integer'image(to_integer(got)) & " want " & integer'image(to_integer(want)) severity error;
          end if;
        end if;
      end loop;
    end procedure;

    impure function rndv return std_logic_vector is
      variable v : std_logic_vector(W - 1 downto 0);
    begin
      for i in 0 to W - 1 loop
        uniform(s1, s2, r);
        if r > 0.5 then v(i) := '1'; else v(i) := '0'; end if;
      end loop;
      return v;
    end function;
  begin
    if W <= 10 then
      for i in 0 to 2 ** W - 1 loop
        check(std_logic_vector(to_unsigned(i, W)), '0');
        check(std_logic_vector(to_unsigned(i, W)), '1');
      end loop;
    else
      for k in 1 to RANDOM loop
        check(rndv, '0');
        check(rndv, '1');
      end loop;
    end if;
    if errors = 0 then
      report "PASS tb_shift_divider W=" & integer'image(W) & " CW=" & integer'image(CW) & " checks=" & integer'image(checks);
    else
      report "FAIL tb_shift_divider errors=" & integer'image(errors) severity failure;
    end if;
    wait;
  end process;
end architecture sim;
