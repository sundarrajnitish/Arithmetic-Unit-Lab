--------------------------------------------------------------------------------
-- Arithmetic Unit Lab                                     tb/tb_multiplier.vhd
-- Author : Nitish Sundarraj
--
-- Self-checking test of multiplier (ARRAY / DADDA x RIPPLE / KOGGE_STONE).
--   N <= 8 : every operand pair, unsigned and signed  (2 * 4^N products)
--   N  > 8 : corner operands x corner operands, then RANDOM random pairs
-- The reference is numeric_std's "*", independent of the design.
-- Ends with "PASS" or "FAIL" and a count; exits non-zero on failure.
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity tb_multiplier is
  generic (
    N      : positive := 8;
    ARCH   : string   := "DADDA";
    CPA    : string   := "KOGGE_STONE";
    RANDOM : natural  := 20000;
    SEED   : positive := 1
  );
end entity tb_multiplier;

architecture sim of tb_multiplier is
  signal a, b : std_logic_vector(N - 1 downto 0) := (others => '0');
  signal sgn  : std_logic := '0';
  signal p    : std_logic_vector(2 * N - 1 downto 0);
begin
  dut : entity work.multiplier
    generic map (N => N, ARCH => ARCH, CPA => CPA)
    port map (a => a, b => b, sgn => sgn, p => p);

  stim : process
    variable errors, checks : natural := 0;
    variable s1 : positive := SEED;
    variable s2 : positive := 7919;
    variable r  : real;
    variable va, vb : std_logic_vector(N - 1 downto 0);
    type corners_t is array (0 to 7) of std_logic_vector(N - 1 downto 0);
    variable corners : corners_t;

    procedure check (ma, mb : std_logic_vector; mode : std_logic) is
      variable expected : std_logic_vector(2 * N - 1 downto 0);
    begin
      a <= ma; b <= mb; sgn <= mode;
      wait for 1 ns;
      if mode = '1' then
        expected := std_logic_vector(signed(ma) * signed(mb));
      else
        expected := std_logic_vector(unsigned(ma) * unsigned(mb));
      end if;
      checks := checks + 1;
      if p /= expected then
        errors := errors + 1;
        if errors <= 10 then
          report "mismatch sgn=" & std_logic'image(mode) & " a=" & integer'image(to_integer(unsigned(ma)))
               & " b=" & integer'image(to_integer(unsigned(mb))) severity error;
        end if;
      end if;
    end procedure;

    impure function rand_vec return std_logic_vector is
      variable v : std_logic_vector(N - 1 downto 0);
    begin
      for i in 0 to N - 1 loop
        uniform(s1, s2, r);
        if r > 0.5 then v(i) := '1'; else v(i) := '0'; end if;
      end loop;
      return v;
    end function;
  begin
    if N <= 8 then
      for mode in 0 to 1 loop
        for i in 0 to 2 ** N - 1 loop
          for j in 0 to 2 ** N - 1 loop
            va := std_logic_vector(to_unsigned(i, N));
            vb := std_logic_vector(to_unsigned(j, N));
            if mode = 1 then check(va, vb, '1'); else check(va, vb, '0'); end if;
          end loop;
        end loop;
      end loop;
    else
      corners(0) := (others => '0');
      corners(1) := (others => '1');
      corners(2) := (others => '0'); corners(2)(0) := '1';
      corners(3) := (others => '0'); corners(3)(N - 1) := '1';
      corners(4) := (others => '1'); corners(4)(N - 1) := '0';
      corners(5) := (others => '0'); corners(5)(N - 1) := '1'; corners(5)(0) := '1';
      for i in 0 to N - 1 loop
        if i mod 2 = 0 then corners(6)(i) := '1'; corners(7)(i) := '0';
        else corners(6)(i) := '0'; corners(7)(i) := '1'; end if;
      end loop;
      for i in corners'range loop
        for j in corners'range loop
          check(corners(i), corners(j), '0');
          check(corners(i), corners(j), '1');
        end loop;
      end loop;
      for k in 1 to RANDOM loop
        va := rand_vec; vb := rand_vec;
        check(va, vb, '0');
        check(va, vb, '1');
      end loop;
    end if;

    if errors = 0 then
      report "PASS tb_multiplier N=" & integer'image(N) & " " & ARCH & "/" & CPA
           & " checks=" & integer'image(checks);
    else
      report "FAIL tb_multiplier N=" & integer'image(N) & " " & ARCH & "/" & CPA
           & " errors=" & integer'image(errors) & " of " & integer'image(checks) severity failure;
    end if;
    wait;
  end process;
end architecture sim;
