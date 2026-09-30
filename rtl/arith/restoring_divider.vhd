--------------------------------------------------------------------------------
-- Arithmetic Unit Lab                             arith/restoring_divider.vhd
-- Author : Nitish Sundarraj
--
-- Unsigned restoring divider, one quotient bit per clock.
--
--   start  (1 cycle)  loads dividend and divisor, busy goes high
--   W cycles later    quotient = dividend / divisor (floor), done pulses
--
-- Each step shifts the next dividend bit into the partial remainder r and
-- tries r - divisor with a (DW+1)-bit subtractor (x + not y + 1, any CPA).
-- No borrow -> keep the difference and shift in a 1; borrow -> keep r and
-- shift in a 0.  With divisor = 0 every trial succeeds and the quotient is
-- all ones; the arithmetic unit flags that case before it gets here.
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use work.au_pkg.all;

entity restoring_divider is
  generic (
    W  : positive := 16;                -- dividend / quotient width
    DW  : positive := 16;               -- divisor width
    CPA : string   := "RIPPLE"          -- subtractor architecture
  );
  port (
    clk      : in  std_logic;
    reset_n  : in  std_logic;
    start    : in  std_logic;
    dividend : in  std_logic_vector(W - 1 downto 0);
    divisor  : in  std_logic_vector(DW - 1 downto 0);
    quotient : out std_logic_vector(W - 1 downto 0);
    busy     : out std_logic;
    done     : out std_logic
  );
end entity restoring_divider;

architecture rtl of restoring_divider is
  signal r      : std_logic_vector(DW - 1 downto 0);    -- partial remainder (< divisor)
  signal qd     : std_logic_vector(W - 1 downto 0);     -- dividend shifting out / quotient shifting in
  signal dv     : std_logic_vector(DW - 1 downto 0);
  signal cnt    : natural range 0 to W;
  signal run    : std_logic;
  signal trial  : std_logic_vector(DW downto 0);        -- r shifted with next dividend bit
  signal ndv    : std_logic_vector(DW downto 0);
  signal diff   : std_logic_vector(DW downto 0);
  signal no_borrow : std_logic;
begin
  trial <= r & qd(W - 1);
  ndv   <= not ('0' & dv);

  sub : entity work.cpa generic map (W => DW + 1, ARCH => CPA)
    port map (x => trial, y => ndv, ci => '1', s => diff, co => no_borrow);

  process (clk, reset_n)
  begin
    if reset_n = '0' then
      r    <= (others => '0');
      qd   <= (others => '0');
      dv   <= (others => '0');
      cnt  <= 0;
      run  <= '0';
      done <= '0';
    elsif rising_edge(clk) then
      done <= '0';
      if start = '1' then
        r   <= (others => '0');
        qd  <= dividend;
        dv  <= divisor;
        cnt <= W;
        run <= '1';
      elsif run = '1' then
        if no_borrow = '1' then
          r <= diff(DW - 1 downto 0);
        else
          r <= trial(DW - 1 downto 0);
        end if;
        qd <= qd(W - 2 downto 0) & no_borrow;
        if cnt = 1 then
          run  <= '0';
          done <= '1';
        end if;
        cnt <= cnt - 1;
      end if;
    end if;
  end process;

  quotient <= qd;
  busy     <= run;
end architecture rtl;
