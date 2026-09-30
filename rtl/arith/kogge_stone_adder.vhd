--------------------------------------------------------------------------------
-- Arithmetic Unit Lab                             arith/kogge_stone_adder.vhd
-- Author : Nitish Sundarraj
--
-- W-bit Kogge-Stone parallel-prefix adder.
--
-- Position 0 of the prefix network holds the carry-in (g = ci, p = 0) and
-- positions 1..W hold the operand bits, so after clog2(W+1) levels of black
-- cells G(i) is the carry into bit i and G(W) is the carry-out.
-- Delay grows with log2(W) instead of W.
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use work.au_pkg.all;

entity kogge_stone_adder is
  generic (W : positive := 16);
  port (
    x, y : in  std_logic_vector(W - 1 downto 0);
    ci   : in  std_logic;
    s    : out std_logic_vector(W - 1 downto 0);
    co   : out std_logic
  );
end entity kogge_stone_adder;

architecture structural of kogge_stone_adder is
  constant M : natural := W + 1;          -- prefix positions
  constant NLEV : natural := clog2(M);    -- prefix levels
  -- level l, position i  ->  index l*M + i
  signal g, p : std_logic_vector((NLEV + 1) * M - 1 downto 0);
  signal hp   : std_logic_vector(W - 1 downto 0);   -- bitwise propagate (sum xor)
begin

  g(0) <= ci;
  p(0) <= '0';
  pg : for i in 0 to W - 1 generate
    ha : entity work.half_adder
      port map (a => x(i), b => y(i), s => hp(i), co => g(i + 1));
    p(i + 1) <= hp(i);
  end generate pg;

  levels : for lv in 1 to NLEV generate
    cols : for i in 0 to M - 1 generate
      combine : if i >= 2 ** (lv - 1) generate
        bc : entity work.pg_black
          port map (g_hi => g((lv - 1) * M + i), p_hi => p((lv - 1) * M + i),
                    g_lo => g((lv - 1) * M + i - 2 ** (lv - 1)),
                    p_lo => p((lv - 1) * M + i - 2 ** (lv - 1)),
                    g => g(lv * M + i), p => p(lv * M + i));
      end generate combine;
      pass : if i < 2 ** (lv - 1) generate
        g(lv * M + i) <= g((lv - 1) * M + i);
        p(lv * M + i) <= p((lv - 1) * M + i);
      end generate pass;
    end generate cols;
  end generate levels;

  sums : for i in 0 to W - 1 generate
    s(i) <= hp(i) xor g(NLEV * M + i);
  end generate sums;
  co <= g(NLEV * M + W);

end architecture structural;
