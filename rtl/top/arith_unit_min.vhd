--------------------------------------------------------------------------------
-- Arithmetic Unit Lab                                  top/arith_unit_min.vhd
-- Author : Nitish Sundarraj
--
-- Minimum requirement:   P = A*B/4 + 1     (A, B unsigned N-bit, P 2N-bit)
--
--   load = '1' on a rising edge latches A and B and clears status.
--   On the next edge (PIPELINE = false) or the one after (PIPELINE = true)
--   the result is written to the P register and status goes to '1'.
--   P and status then hold until the next load.  reset_n = '0' clears
--   every register, P and status at once.
--
--   A -->[A reg]--+                      +---------------+
--                 +--> multiplier --> >>2 --> +1 (CPA, ci=1) -->[P reg]--> P
--   B -->[B reg]--+   (ARRAY/DADDA)       +---------------+
--
-- Structural: registers, multiplier and adder are instantiated entities;
-- dividing by 4 is wiring (drop the two low product bits).
-- The largest result, (2^N-1)^2/4 + 1, needs 2N-2 bits, so P never overflows.
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

entity arith_unit_min is
  generic (
    N         : positive := 8;
    MULT_ARCH : string   := "DADDA";
    CPA_ARCH  : string   := "KOGGE_STONE";
    PIPELINE  : boolean  := false       -- register the product (2-cycle latency, higher fmax)
  );
  port (
    clk     : in  std_logic;
    reset_n : in  std_logic;            -- active low, asynchronous
    load    : in  std_logic;
    A, B    : in  std_logic_vector(N - 1 downto 0);
    status  : out std_logic;
    P       : out std_logic_vector(2 * N - 1 downto 0)
  );
end entity arith_unit_min;

architecture structural of arith_unit_min is
  constant W : natural := 2 * N;
  signal a_r, b_r        : std_logic_vector(N - 1 downto 0);
  signal prod, prod_s    : std_logic_vector(W - 1 downto 0);
  signal quarter, zero   : std_logic_vector(W - 1 downto 0);
  signal result          : std_logic_vector(W - 1 downto 0);
  signal v1, v2, p_en    : std_logic;
  signal status_d, status_r, status_en : std_logic;
begin

  reg_a : entity work.reg_en generic map (W => N)
    port map (clk => clk, reset_n => reset_n, en => load, d => A, q => a_r);
  reg_b : entity work.reg_en generic map (W => N)
    port map (clk => clk, reset_n => reset_n, en => load, d => B, q => b_r);

  mult : entity work.multiplier generic map (N => N, ARCH => MULT_ARCH, CPA => CPA_ARCH)
    port map (a => a_r, b => b_r, sgn => '0', p => prod);

  -- valid pipeline: v1 = operands latched last edge, v2 = product latched last edge
  ff_v1 : entity work.dff_en
    port map (clk => clk, reset_n => reset_n, en => '1', d => load, q => v1);

  comb : if not PIPELINE generate
    prod_s <= prod;
    v2     <= v1;
  end generate comb;

  piped : if PIPELINE generate
    reg_p : entity work.reg_en generic map (W => W)
      port map (clk => clk, reset_n => reset_n, en => v1, d => prod, q => prod_s);
    ff_v2 : entity work.dff_en
      port map (clk => clk, reset_n => reset_n, en => '1', d => v1, q => v2);
  end generate piped;

  -- divide by 4: shift right by two (wiring)
  quarter <= "00" & prod_s(W - 1 downto 2);
  zero    <= (others => '0');

  -- plus 1: carry-in of a carry-propagate adder
  inc : entity work.cpa generic map (W => W, ARCH => CPA_ARCH)
    port map (x => quarter, y => zero, ci => '1', s => result, co => open);

  -- a new load cancels a result still in flight
  p_en <= v2 and not load and not v1 when PIPELINE else v2 and not load;

  reg_out : entity work.reg_en generic map (W => W)
    port map (clk => clk, reset_n => reset_n, en => p_en, d => result, q => P);

  -- status: cleared by load, set when P is written
  status_en <= load or p_en;
  status_d  <= not load;
  ff_status : entity work.dff_en
    port map (clk => clk, reset_n => reset_n, en => status_en, d => status_d, q => status_r);
  status <= status_r;

end architecture structural;
