--------------------------------------------------------------------------------
-- Arithmetic Unit Lab                                      top/arith_unit.vhd
-- Author : Nitish Sundarraj
--
-- Generic arithmetic unit (all additional requirements except serial I/O,
-- which wraps this unit in top/arith_unit_serial.vhd):
--
--   fsel = '0' :  P = A*B / 2^C + D
--   fsel = '1' :  P = A*B / C^2 + D        (err = '1' and P = 0 when C = 0)
--
--   sgn  = '0' :  A, B, D unsigned        sgn = '1' : A, B, D two's complement
--   C is always unsigned.  Division rounds toward zero (like VHDL "/").
--   N, CW, DW (widths of A/B, C, D) are generics; P is 2N bits.
--   ovf = '1' if A*B/k + D does not fit in P (impossible while DW <= N).
--
-- Handshake (same as the minimum unit): load = '1' on a rising edge latches
-- all inputs and clears status; status = '1' once P is valid, and P, status,
-- err and ovf hold until the next load.  A load while busy restarts.
-- reset_n = '0' clears every register and the outputs.
--
-- Datapath (one shared multiplier):
--
--   SQR   : dv <= C*C                       (fsel = 1 only)
--   MUL   : x  <= A*B
--   SHIFT : q  <= floor(x / 2^C), rnd <= "negative and bits lost"
--   DIV   : q  <= |x| / dv (restoring, 2N cycles), then q <= not q, rnd <= 1
--           when x < 0  (so q + rnd = -|x|/dv)
--   ADD   : P  <= q + D + rnd               (the rounding needs no extra adder)
--
-- Latency after the load edge: 3 cycles (fsel = 0), 2N + 5 cycles (fsel = 1).
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

entity arith_unit is
  generic (
    N         : positive := 8;          -- A, B width
    CW        : positive := 8;          -- C width (CW <= N)
    DW        : positive := 8;          -- D width (DW <= 2N)
    MULT_ARCH : string   := "DADDA";
    CPA_ARCH  : string   := "KOGGE_STONE"
  );
  port (
    clk     : in  std_logic;
    reset_n : in  std_logic;
    load    : in  std_logic;
    A, B    : in  std_logic_vector(N - 1 downto 0);
    C       : in  std_logic_vector(CW - 1 downto 0);
    D       : in  std_logic_vector(DW - 1 downto 0);
    sgn     : in  std_logic;
    fsel    : in  std_logic;
    status  : out std_logic;
    err     : out std_logic;
    ovf     : out std_logic;
    P       : out std_logic_vector(2 * N - 1 downto 0)
  );
end entity arith_unit;

architecture structural of arith_unit is
  constant W : natural := 2 * N;

  type state_t is (S_IDLE, S_SQR, S_MUL, S_SHIFT, S_DIV_GO, S_DIV_WAIT, S_ADD);
  signal state : state_t;

  -- operand registers
  signal a_r, b_r   : std_logic_vector(N - 1 downto 0);
  signal c_r        : std_logic_vector(CW - 1 downto 0);
  signal d_r        : std_logic_vector(DW - 1 downto 0);
  signal sgn_r, fsel_r : std_logic;

  -- shared multiplier
  signal m_a, m_b   : std_logic_vector(N - 1 downto 0);
  signal m_sgn      : std_logic;
  signal m_p        : std_logic_vector(W - 1 downto 0);

  -- intermediate registers
  signal x_r        : std_logic_vector(W - 1 downto 0);
  signal dv_r       : std_logic_vector(2 * CW - 1 downto 0);
  signal q_r, q_d   : std_logic_vector(W - 1 downto 0);
  signal rnd_r, rnd_d : std_logic;

  -- shift path
  signal sh_q       : std_logic_vector(W - 1 downto 0);
  signal sh_rnd     : std_logic;

  -- divide path
  signal neg        : std_logic;
  signal negmask    : std_logic_vector(W - 1 downto 0);
  signal x_flip, zero_w, x_mag : std_logic_vector(W - 1 downto 0);
  signal div_q      : std_logic_vector(W - 1 downto 0);
  signal div_start, div_done : std_logic;
  signal c_zero     : std_logic;

  -- final adder (one guard bit for overflow detection)
  signal fa_x, fa_y, fa_s : std_logic_vector(W downto 0);
  signal p_d        : std_logic_vector(W - 1 downto 0);
  signal ovf_d, err_d, ovf_n, err_n : std_logic;

  -- enables
  signal en_dv, en_x, en_q, en_p : std_logic;
  signal status_r, status_en, status_d : std_logic;

  function any_one (s : std_logic_vector) return std_logic is
    variable r : std_logic := '0';
  begin
    for i in s'range loop r := r or s(i); end loop;
    return r;
  end function;
begin
  assert CW <= N report "arith_unit: CW must be <= N (C*C uses the shared multiplier)" severity failure;
  assert DW <= W report "arith_unit: DW must be <= 2N" severity failure;

  ------------------------------------------------------------------ operands
  reg_a : entity work.reg_en generic map (W => N)
    port map (clk => clk, reset_n => reset_n, en => load, d => A, q => a_r);
  reg_b : entity work.reg_en generic map (W => N)
    port map (clk => clk, reset_n => reset_n, en => load, d => B, q => b_r);
  reg_c : entity work.reg_en generic map (W => CW)
    port map (clk => clk, reset_n => reset_n, en => load, d => C, q => c_r);
  reg_d : entity work.reg_en generic map (W => DW)
    port map (clk => clk, reset_n => reset_n, en => load, d => D, q => d_r);
  ff_sgn : entity work.dff_en
    port map (clk => clk, reset_n => reset_n, en => load, d => sgn, q => sgn_r);
  ff_fsel : entity work.dff_en
    port map (clk => clk, reset_n => reset_n, en => load, d => fsel, q => fsel_r);

  ------------------------------------------------------- shared multiplier
  -- S_SQR multiplies C by itself (unsigned), every other state A by B.
  m_c : for i in 0 to N - 1 generate
    lo : if i < CW generate
      m_a(i) <= c_r(i) when state = S_SQR else a_r(i);
      m_b(i) <= c_r(i) when state = S_SQR else b_r(i);
    end generate lo;
    hi : if i >= CW generate
      m_a(i) <= '0' when state = S_SQR else a_r(i);
      m_b(i) <= '0' when state = S_SQR else b_r(i);
    end generate hi;
  end generate m_c;
  m_sgn <= '0' when state = S_SQR else sgn_r;

  mult : entity work.multiplier generic map (N => N, ARCH => MULT_ARCH, CPA => CPA_ARCH)
    port map (a => m_a, b => m_b, sgn => m_sgn, p => m_p);

  reg_dv : entity work.reg_en generic map (W => 2 * CW)
    port map (clk => clk, reset_n => reset_n, en => en_dv, d => m_p(2 * CW - 1 downto 0), q => dv_r);
  reg_x : entity work.reg_en generic map (W => W)
    port map (clk => clk, reset_n => reset_n, en => en_x, d => m_p, q => x_r);

  --------------------------------------------------------------- shift path
  shifter : entity work.shift_divider generic map (W => W, CW => CW)
    port map (x => x_r, c => c_r, sgn => sgn_r, q => sh_q, round_up => sh_rnd);

  ---------------------------------------------------------------- C^2 path
  neg     <= sgn_r and x_r(W - 1);
  negmask <= (others => neg);
  x_flip  <= x_r xor negmask;
  zero_w  <= (others => '0');
  absval : entity work.cpa generic map (W => W, ARCH => CPA_ARCH)     -- |x| = (x xor s) + s
    port map (x => x_flip, y => zero_w, ci => neg, s => x_mag, co => open);

  divider : entity work.restoring_divider generic map (W => W, DW => 2 * CW, CPA => CPA_ARCH)
    port map (clk => clk, reset_n => reset_n, start => div_start,
              dividend => x_mag, divisor => dv_r, quotient => div_q,
              busy => open, done => div_done);

  c_zero <= not any_one(c_r);

  -- q register: shift result, or (possibly negated) quotient
  q_d   <= sh_q when state = S_SHIFT else div_q xor negmask;
  rnd_d <= sh_rnd when state = S_SHIFT else neg;
  reg_q : entity work.reg_en generic map (W => W)
    port map (clk => clk, reset_n => reset_n, en => en_q, d => q_d, q => q_r);
  ff_rnd : entity work.dff_en
    port map (clk => clk, reset_n => reset_n, en => en_q, d => rnd_d, q => rnd_r);

  ------------------------------------------------------------- final adder
  -- q + D + rnd in W+1 bits; D and q sign-extended when sgn = '1'
  fa_x <= (q_r(W - 1) and sgn_r) & q_r;
  ext : for i in 0 to W generate
    in_d : if i < DW generate
      fa_y(i) <= d_r(i);
    end generate in_d;
    above : if i >= DW generate
      fa_y(i) <= d_r(DW - 1) and sgn_r;
    end generate above;
  end generate ext;

  add : entity work.cpa generic map (W => W + 1, ARCH => CPA_ARCH)
    port map (x => fa_x, y => fa_y, ci => rnd_r, s => fa_s, co => open);

  err_d <= fsel_r and c_zero;
  p_d   <= (others => '0') when err_d = '1' else fa_s(W - 1 downto 0);
  ovf_d <= '0' when err_d = '1' else
           (fa_s(W) xor fa_s(W - 1)) when sgn_r = '1' else
           fa_s(W);

  reg_p : entity work.reg_en generic map (W => W)
    port map (clk => clk, reset_n => reset_n, en => en_p, d => p_d, q => P);
  ff_err : entity work.dff_en
    port map (clk => clk, reset_n => reset_n, en => status_en, d => err_n, q => err);
  ff_ovf : entity work.dff_en
    port map (clk => clk, reset_n => reset_n, en => status_en, d => ovf_n, q => ovf);

  err_n     <= err_d and not load;
  ovf_n     <= ovf_d and not load;
  status_en <= load or en_p;
  status_d  <= not load;
  ff_status : entity work.dff_en
    port map (clk => clk, reset_n => reset_n, en => status_en, d => status_d, q => status_r);
  status <= status_r;

  --------------------------------------------------------------- control
  en_dv     <= '1' when state = S_SQR and load = '0' else '0';
  en_x      <= '1' when state = S_MUL and load = '0' else '0';
  en_q      <= '1' when load = '0' and (state = S_SHIFT or (state = S_DIV_WAIT and div_done = '1')) else '0';
  en_p      <= '1' when state = S_ADD and load = '0' else '0';
  div_start <= '1' when state = S_DIV_GO and load = '0' else '0';

  fsm : process (clk, reset_n)
  begin
    if reset_n = '0' then
      state <= S_IDLE;
    elsif rising_edge(clk) then
      if load = '1' then
        if fsel = '1' then
          state <= S_SQR;
        else
          state <= S_MUL;
        end if;
      else
        case state is
          when S_IDLE  => null;
          when S_SQR   => state <= S_MUL;
          when S_MUL   =>
            if fsel_r = '0' then
              state <= S_SHIFT;
            elsif c_zero = '1' then
              state <= S_ADD;                   -- divide by zero: skip the divider
            else
              state <= S_DIV_GO;
            end if;
          when S_SHIFT    => state <= S_ADD;
          when S_DIV_GO   => state <= S_DIV_WAIT;
          when S_DIV_WAIT =>
            if div_done = '1' then
              state <= S_ADD;
            end if;
          when S_ADD   => state <= S_IDLE;
        end case;
      end if;
    end if;
  end process fsm;

end architecture structural;
