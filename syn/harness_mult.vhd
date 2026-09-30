--------------------------------------------------------------------------------
-- Arithmetic Unit Lab                                  syn/harness_mult.vhd
-- Author : Nitish Sundarraj
--
-- Timing harness for combinational multipliers: registered inputs and
-- outputs, so place-and-route reports a register-to-register fmax that
-- measures only the multiplier.
--   IMPL = "V2"          multiplier (ARCH, CPA generics)
--   IMPL = "BEHAVIORAL"  numeric_std "*" (the synthesis tool builds it)
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity harness_mult is
  generic (
    N    : positive := 8;
    IMPL : string   := "V2";
    ARCH : string   := "DADDA";
    CPA  : string   := "KOGGE_STONE"
  );
  port (
    clk  : in  std_logic;
    a, b : in  std_logic_vector(N - 1 downto 0);
    sgn  : in  std_logic;
    p    : out std_logic_vector(2 * N - 1 downto 0)
  );
end entity harness_mult;

architecture rtl of harness_mult is
  signal a_r, b_r : std_logic_vector(N - 1 downto 0);
  signal s_r      : std_logic;
  signal prod     : std_logic_vector(2 * N - 1 downto 0);
begin
  process (clk)
  begin
    if rising_edge(clk) then
      a_r <= a; b_r <= b; s_r <= sgn;
      p   <= prod;
    end if;
  end process;

  v2 : if IMPL = "V2" generate
    u : entity work.multiplier generic map (N => N, ARCH => ARCH, CPA => CPA)
      port map (a => a_r, b => b_r, sgn => s_r, p => prod);
  end generate v2;

  beh : if IMPL = "BEHAVIORAL" generate
    prod <= std_logic_vector(signed(a_r) * signed(b_r)) when s_r = '1'
            else std_logic_vector(unsigned(a_r) * unsigned(b_r));
  end generate beh;
end architecture rtl;
