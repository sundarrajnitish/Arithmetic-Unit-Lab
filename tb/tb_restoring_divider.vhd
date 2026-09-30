--------------------------------------------------------------------------------
-- Arithmetic Unit Lab                            tb/tb_restoring_divider.vhd
-- Author : Nitish Sundarraj
--
-- Restoring divider: quotient = dividend / divisor after exactly W cycles,
-- busy high meanwhile, done a one-cycle pulse.  Small widths: every pair.
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity tb_restoring_divider is
  generic (
    W      : positive := 8;
    DW     : positive := 6;
    CPA    : string   := "RIPPLE";
    RANDOM : natural  := 4000
  );
end entity tb_restoring_divider;

architecture sim of tb_restoring_divider is
  constant T : time := 10 ns;
  signal clk      : std_logic := '0';
  signal reset_n  : std_logic := '0';
  signal start    : std_logic := '0';
  signal dividend : std_logic_vector(W - 1 downto 0) := (others => '0');
  signal divisor  : std_logic_vector(DW - 1 downto 0) := (others => '0');
  signal quotient : std_logic_vector(W - 1 downto 0);
  signal busy, done_s : std_logic;
  signal fin : boolean := false;
begin
  clk <= not clk after T / 2 when not fin;
  dut : entity work.restoring_divider generic map (W => W, DW => DW, CPA => CPA)
    port map (clk => clk, reset_n => reset_n, start => start, dividend => dividend,
              divisor => divisor, quotient => quotient, busy => busy, done => done_s);

  process
    variable errors, checks : natural := 0;
    variable s1 : positive := 41;
    variable s2 : positive := 43;
    variable r  : real;

    procedure run (x : unsigned; y : unsigned) is
      variable want : unsigned(W - 1 downto 0);
    begin
      dividend <= std_logic_vector(x); divisor <= std_logic_vector(y);
      start <= '1';
      wait until falling_edge(clk);
      start <= '0';
      for k in 1 to W loop
        if busy /= '1' or done_s /= '0' then errors := errors + 1; end if;
        wait until falling_edge(clk);
      end loop;
      if y = 0 then want := (others => '1'); else want := resize(x / y, W); end if;
      checks := checks + 1;
      if done_s /= '1' or busy /= '0' or unsigned(quotient) /= want then
        errors := errors + 1;
        if errors < 8 then
          report integer'image(to_integer(x)) & "/" & integer'image(to_integer(y)) & " -> "
               & integer'image(to_integer(unsigned(quotient))) severity error;
        end if;
      end if;
    end procedure;

    impure function rnd (bits : positive) return unsigned is
      variable v : unsigned(bits - 1 downto 0);
    begin
      for i in 0 to bits - 1 loop
        uniform(s1, s2, r);
        if r > 0.5 then v(i) := '1'; else v(i) := '0'; end if;
      end loop;
      return v;
    end function;
  begin
    wait until falling_edge(clk);
    reset_n <= '1';
    if W + DW <= 14 then
      for i in 0 to 2 ** W - 1 loop
        for j in 0 to 2 ** DW - 1 loop
          run(to_unsigned(i, W), to_unsigned(j, DW));
        end loop;
      end loop;
    else
      for k in 1 to RANDOM loop
        run(rnd(W), rnd(DW));
      end loop;
    end if;
    if errors = 0 then
      report "PASS tb_restoring_divider W=" & integer'image(W) & " DW=" & integer'image(DW) & " " & CPA & " checks=" & integer'image(checks);
    else
      report "FAIL tb_restoring_divider errors=" & integer'image(errors) severity failure;
    end if;
    fin <= true;
    wait;
  end process;
end architecture sim;
