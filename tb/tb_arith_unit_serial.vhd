--------------------------------------------------------------------------------
-- Arithmetic Unit Lab                            tb/tb_arith_unit_serial.vhd
-- Author : Nitish Sundarraj
--
-- Serial wrapper: shifts golden-model vectors in bit by bit, pulses start,
-- collects the output frame and compares P, err and ovf.
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;

entity tb_arith_unit_serial is
  generic (
    N       : positive := 8;
    CW      : positive := 8;
    DW      : positive := 8;
    VECTORS : string   := "tb/vectors/arith_unit_n8.txt";
    LIMIT   : natural  := 600
  );
end entity tb_arith_unit_serial;

architecture sim of tb_arith_unit_serial is
  constant T  : time := 10 ns;
  constant FI : natural := 2 * N + CW + DW + 2;
  constant FO : natural := 2 * N + 2;
  signal clk, reset_n, sin, sin_en, start, sout, sout_valid, busy : std_logic := '0';
  signal done : boolean := false;

  procedure read_hex (l : inout line; v : out unsigned) is
    variable ch  : character;
    variable acc : unsigned(v'length + 3 downto 0) := (others => '0');
    variable dig : natural;
  begin
    loop read(l, ch); exit when ch /= ' '; end loop;
    loop
      case ch is
        when '0' to '9' => dig := character'pos(ch) - character'pos('0');
        when 'A' to 'F' => dig := character'pos(ch) - character'pos('A') + 10;
        when others     => exit;
      end case;
      acc := shift_left(acc, 4) + dig;
      exit when l'length = 0;
      read(l, ch);
    end loop;
    v := acc(v'length - 1 downto 0);
  end procedure;
begin
  clk <= not clk after T / 2 when not done;

  dut : entity work.arith_unit_serial
    generic map (N => N, CW => CW, DW => DW)
    port map (clk => clk, reset_n => reset_n, sin => sin, sin_en => sin_en, start => start,
              sout => sout, sout_valid => sout_valid, busy => busy);

  stim : process
    file f      : text;
    variable l  : line;
    variable ua, ub : unsigned(N - 1 downto 0);
    variable uc : unsigned(CW - 1 downto 0);
    variable ud : unsigned(DW - 1 downto 0);
    variable up : unsigned(2 * N - 1 downto 0);
    variable u1 : unsigned(0 downto 0);
    variable frame : std_logic_vector(FI - 1 downto 0);
    variable want, got : std_logic_vector(FO - 1 downto 0);
    variable lat, count, errors, k : natural := 0;
  begin
    file_open(f, VECTORS, read_mode);
    wait for 2 * T;
    wait until falling_edge(clk);
    reset_n <= '1';
    while not endfile(f) and count < LIMIT loop
      readline(f, l);
      next when l'length = 0 or l(l'low) = '#';
      read_hex(l, ua); read_hex(l, ub); read_hex(l, uc); read_hex(l, ud);
      read_hex(l, u1); frame(FI - 2) := u1(0);
      read_hex(l, u1); frame(FI - 1) := u1(0);
      frame(N - 1 downto 0) := std_logic_vector(ua);
      frame(2 * N - 1 downto N) := std_logic_vector(ub);
      frame(2 * N + CW - 1 downto 2 * N) := std_logic_vector(uc);
      frame(2 * N + CW + DW - 1 downto 2 * N + CW) := std_logic_vector(ud);
      read_hex(l, up);
      want(2 * N - 1 downto 0) := std_logic_vector(up);
      read_hex(l, u1); want(FO - 2) := u1(0);
      read_hex(l, u1); want(FO - 1) := u1(0);
      count := count + 1;

      for i in 0 to FI - 1 loop                -- LSB first
        sin <= frame(i); sin_en <= '1';
        wait until falling_edge(clk);
      end loop;
      sin_en <= '0'; sin <= 'X';
      start <= '1';
      wait until falling_edge(clk);
      start <= '0';
      if busy /= '1' then errors := errors + 1; report "busy not raised" severity error; end if;
      k := 0;
      while sout_valid /= '1' and k < 8 * N + 20 loop
        wait until falling_edge(clk); k := k + 1;
      end loop;
      for i in 0 to FO - 1 loop
        if sout_valid /= '1' then errors := errors + 1; report "sout_valid dropped" severity error; exit; end if;
        got(i) := sout;
        wait until falling_edge(clk);
      end loop;
      if got /= want then
        errors := errors + 1;
        if errors < 10 then report "frame mismatch at vector " & integer'image(count) severity error; end if;
      end if;
      if busy /= '0' or sout_valid /= '0' then errors := errors + 1; report "busy/valid stuck" severity error; end if;
    end loop;
    if errors = 0 then
      report "PASS tb_arith_unit_serial frames=" & integer'image(count) & " (in " & integer'image(FI)
           & " bits, out " & integer'image(FO) & " bits)";
    else
      report "FAIL tb_arith_unit_serial errors=" & integer'image(errors) severity failure;
    end if;
    done <= true;
    wait;
  end process;
end architecture sim;
