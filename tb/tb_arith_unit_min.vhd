--------------------------------------------------------------------------------
-- Arithmetic Unit Lab                               tb/tb_arith_unit_min.vhd
-- Author : Nitish Sundarraj
--
-- Minimum-requirement unit, P = A*B/4 + 1, through its handshake.
--   N <= 8 : every (A, B) pair           (65 536 for N = 8)
--   N  > 8 : corners plus RANDOM pairs
-- For each pair: one-cycle load, status low after the load edge, status high
-- after exactly LAT cycles (1, or 2 with PIPELINE), P correct and held.
-- Protocol cases: load held for several cycles (the last operands win),
-- loads on consecutive cycles, asynchronous reset in flight.
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity tb_arith_unit_min is
  generic (
    N         : positive := 8;
    MULT_ARCH : string   := "DADDA";
    CPA_ARCH  : string   := "KOGGE_STONE";
    PIPELINE  : boolean  := false;
    RANDOM    : natural  := 20000
  );
end entity tb_arith_unit_min;

architecture sim of tb_arith_unit_min is
  constant T   : time := 10 ns;
  signal clk     : std_logic := '0';
  signal reset_n : std_logic := '0';
  signal load    : std_logic := '0';
  signal A, B    : std_logic_vector(N - 1 downto 0) := (others => '0');
  signal status  : std_logic;
  signal P       : std_logic_vector(2 * N - 1 downto 0);
  signal done    : boolean := false;

  function lat return natural is
  begin
    if PIPELINE then return 2; else return 1; end if;
  end function;

  function expected (x, y : unsigned) return unsigned is
    variable prod : unsigned(2 * N - 1 downto 0);
  begin
    prod := x * y;
    return shift_right(prod, 2) + 1;
  end function;
begin
  clk <= not clk after T / 2 when not done;

  dut : entity work.arith_unit_min
    generic map (N => N, MULT_ARCH => MULT_ARCH, CPA_ARCH => CPA_ARCH, PIPELINE => PIPELINE)
    port map (clk => clk, reset_n => reset_n, load => load, A => A, B => B, status => status, P => P);

  stim : process
    variable errors, count : natural := 0;
    variable s1 : positive := 11;
    variable s2 : positive := 97;
    variable r  : real;

    procedure fail (msg : string) is
    begin
      errors := errors + 1;
      if errors <= 12 then report msg severity error; end if;
    end procedure;

    procedure run (x, y : unsigned(N - 1 downto 0)) is
      variable e : unsigned(2 * N - 1 downto 0);
    begin
      e := expected(x, y);
      A <= std_logic_vector(x); B <= std_logic_vector(y);
      load <= '1';
      wait until falling_edge(clk);
      load <= '0';
      A <= (others => 'X'); B <= (others => 'X');
      if status /= '0' then fail("status not cleared by load"); end if;
      for k in 1 to lat - 1 loop
        wait until falling_edge(clk);
        if status /= '0' then fail("status early"); end if;
      end loop;
      wait until falling_edge(clk);
      count := count + 1;
      if status /= '1' then
        fail("status not set after " & integer'image(lat) & " cycle(s), A=" & integer'image(to_integer(x))
             & " B=" & integer'image(to_integer(y)));
      elsif unsigned(P) /= e then
        fail("A=" & integer'image(to_integer(x)) & " B=" & integer'image(to_integer(y)) & " P="
             & integer'image(to_integer(unsigned(P))) & " expected " & integer'image(to_integer(e)));
      end if;
    end procedure;

    impure function rnd return unsigned is
      variable v : unsigned(N - 1 downto 0);
    begin
      for i in 0 to N - 1 loop
        uniform(s1, s2, r);
        if r > 0.5 then v(i) := '1'; else v(i) := '0'; end if;
      end loop;
      return v;
    end function;

    variable x, y : unsigned(N - 1 downto 0);
    variable e    : unsigned(2 * N - 1 downto 0);
  begin
    wait for 3 * T;
    wait until falling_edge(clk);
    if status /= '0' or unsigned(P) /= 0 then fail("reset did not clear P/status"); end if;
    reset_n <= '1';
    wait until falling_edge(clk);

    if N <= 8 then
      for i in 0 to 2 ** N - 1 loop
        for j in 0 to 2 ** N - 1 loop
          run(to_unsigned(i, N), to_unsigned(j, N));
        end loop;
      end loop;
    else
      run((others => '1'), (others => '1'));
      run((others => '0'), (others => '1'));
      run(to_unsigned(1, N), to_unsigned(3, N));
      for k in 1 to RANDOM loop
        run(rnd, rnd);
      end loop;
    end if;

    -- result holds while inputs wiggle and load stays low
    x := rnd; y := rnd;
    run(x, y);
    e := expected(x, y);
    for k in 1 to 5 loop
      A <= std_logic_vector(rnd); B <= std_logic_vector(rnd);
      wait until falling_edge(clk);
      if status /= '1' or unsigned(P) /= e then fail("result did not hold"); end if;
    end loop;

    -- load held high for 4 cycles with changing operands: the last ones win
    for k in 1 to 4 loop
      x := rnd; y := rnd;
      A <= std_logic_vector(x); B <= std_logic_vector(y);
      load <= '1';
      wait until falling_edge(clk);
      if status /= '0' then fail("status high while load held"); end if;
    end loop;
    load <= '0';
    for k in 1 to lat loop
      wait until falling_edge(clk);
    end loop;
    if status /= '1' or unsigned(P) /= expected(x, y) then fail("held load: wrong result"); end if;

    -- reset while a result is in flight
    A <= std_logic_vector(rnd); B <= (others => '1');
    load <= '1';
    wait until falling_edge(clk);
    load <= '0';
    reset_n <= '0';
    wait for 1 ns;
    if status /= '0' or unsigned(P) /= 0 then fail("async reset did not clear outputs"); end if;
    wait until falling_edge(clk);
    reset_n <= '1';
    for k in 1 to 4 loop
      wait until falling_edge(clk);
      if status /= '0' then fail("result appeared after reset"); end if;
    end loop;

    if errors = 0 then
      report "PASS tb_arith_unit_min N=" & integer'image(N) & " " & MULT_ARCH & "/" & CPA_ARCH
           & " PIPELINE=" & boolean'image(PIPELINE) & " results=" & integer'image(count);
    else
      report "FAIL tb_arith_unit_min errors=" & integer'image(errors) severity failure;
    end if;
    done <= true;
    wait;
  end process;
end architecture sim;
