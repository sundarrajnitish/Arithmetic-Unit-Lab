--------------------------------------------------------------------------------
-- Arithmetic Unit Lab                                    arith/multiplier.vhd
-- Author : Nitish Sundarraj
--
-- N x N multiplier with a selectable architecture:
--   ARCH = "ARRAY"  carry-save array   (regular, compact, ~2N FA delays)
--   ARCH = "DADDA"  Dadda tree         (fastest, O(log N) reduction depth)
--   CPA  = "RIPPLE" | "KOGGE_STONE"    final carry-propagate adder
-- sgn = '1' treats a and b as two's complement.  p is always exact.
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

entity multiplier is
  generic (
    N    : positive := 8;
    ARCH : string   := "DADDA";
    CPA  : string   := "KOGGE_STONE"
  );
  port (
    a, b : in  std_logic_vector(N - 1 downto 0);
    sgn  : in  std_logic;
    p    : out std_logic_vector(2 * N - 1 downto 0)
  );
end entity multiplier;

architecture structural of multiplier is
begin
  assert ARCH = "ARRAY" or ARCH = "DADDA"
    report "multiplier: ARCH must be ARRAY or DADDA" severity failure;

  arr : if ARCH = "ARRAY" generate
    u : entity work.array_multiplier generic map (N => N, CPA => CPA)
      port map (a => a, b => b, sgn => sgn, p => p);
  end generate arr;

  dad : if ARCH = "DADDA" generate
    u : entity work.dadda_multiplier generic map (N => N, CPA => CPA)
      port map (a => a, b => b, sgn => sgn, p => p);
  end generate dad;
end architecture structural;
