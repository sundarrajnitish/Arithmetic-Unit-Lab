-- Random audit of the 2023 "additional requirements" unit: P = A*B/2^C + D, unsigned and signed
library ieee; use ieee.std_logic_1164.all; use ieee.numeric_std.all; use ieee.math_real.all;
entity tb_audit_v3 is generic (SGNI : natural := 0; NCASES : natural := 2000); end;
architecture a of tb_audit_v3 is
  function tosl(i : natural) return std_logic is begin if i = 1 then return '1'; else return '0'; end if; end;
  constant SGN : std_logic := tosl(SGNI);
  signal clk : std_logic := '0';
  signal reset, load, status : std_logic := '0';
  signal A, B, C, D : std_logic_vector(7 downto 0);
  signal P : std_logic_vector(15 downto 0);
begin
  dut : entity work.sync_arithmetic_hw_ar port map (clk => clk, reset => reset, load => load, A => A, B => B, C => C, D => D,
                                                  mode => SGN, mode_d => '0', status => status, P => P);
  clk <= not clk after 10 ns;
  process
    variable s1, s2 : positive := 7;
    variable r : real;
    variable ia, ib, ic, id, prod, exp_t, exp_f, got : integer;
    variable bad_t, bad_f, bad_x : natural := 0;
    impure function rnd(n : natural) return natural is begin uniform(s1, s2, r); return natural(floor(r * real(n))); end;
  begin
    reset <= '0'; wait until falling_edge(clk); reset <= '1';
    for k in 1 to NCASES loop
      ic := rnd(9);            -- shift amounts 0..8
      if SGN = '0' then ia := rnd(256); ib := rnd(256); id := rnd(256);
      else ia := rnd(256) - 128; ib := rnd(256) - 128; id := rnd(256) - 128; end if;
      A <= std_logic_vector(to_signed(ia, 9)(7 downto 0)); B <= std_logic_vector(to_signed(ib, 9)(7 downto 0));
      C <= std_logic_vector(to_unsigned(ic, 8)); D <= std_logic_vector(to_signed(id, 9)(7 downto 0));
      load <= '1'; wait until falling_edge(clk); wait until falling_edge(clk); load <= '0';   -- 2-cycle load (1-cycle latches 'Z')
      for w in 1 to 10 loop wait until falling_edge(clk); exit when status = '1'; end loop;
      prod := ia * ib;
      exp_t := prod / (2**ic) + id;                                   -- round toward zero
      exp_f := integer(floor(real(prod) / real(2**ic))) + id;         -- round toward -inf
      if is_x(P) then bad_x := bad_x + 1; bad_t := bad_t + 1; bad_f := bad_f + 1;
      else
        if SGN = '0' then got := to_integer(unsigned(P)); else got := to_integer(signed(P)); end if;
        if got /= exp_t mod 2**16 and got /= exp_t then bad_t := bad_t + 1; end if;
        if got /= exp_f mod 2**16 and got /= exp_f then bad_f := bad_f + 1; end if;
      end if;
      wait until falling_edge(clk);
    end loop;
    report "RESULT v3 sgn=" & std_logic'image(SGN) & " wrong(trunc)=" & integer'image(bad_t) & " wrong(floor)=" & integer'image(bad_f)
           & " X=" & integer'image(bad_x) & " of " & integer'image(NCASES);
    std.env.stop;
  end process;
end;
