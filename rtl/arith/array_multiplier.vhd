--------------------------------------------------------------------------------
-- Arithmetic Unit Lab                              arith/array_multiplier.vhd
-- Author : Nitish Sundarraj
--
-- Generic N x N carry-save array multiplier, unsigned or two's complement
-- (modified Baugh-Wooley) selected at run time by sgn.
--
--   row 0      : partial products a(i)b(0)                      (no adders)
--   row j >= 1 : cell (j,i) adds a(i)b(j), the sum from cell (j-1,i+1) and
--                the carry from cell (j-1,i).  Carries move down, never
--                sideways, so each row costs one full-adder delay.
--   last row   : an N-bit carry-propagate adder joins the remaining sums and
--                carries (ripple or Kogge-Stone, generic CPA).
--
-- Signed mode complements the partial products with exactly one sign bit
-- and adds 2^N + 2^(2N-1).  2^N enters as the CPA carry-in and 2^(2N-1) as
-- the unused top bit of the CPA's x operand, so no extra adder row is needed.
-- p is the product modulo 2^(2N), which is exact for both modes.
--
-- Cells: N*N pp_cell, (N-1) half adders in row 1, (N-1)(N-2) full adders and
-- N-2 half adders in rows 2..N-1, plus the N-bit CPA.
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

entity array_multiplier is
  generic (
    N   : positive := 8;                -- operand width, N >= 2
    CPA : string   := "RIPPLE"
  );
  port (
    a, b : in  std_logic_vector(N - 1 downto 0);
    sgn  : in  std_logic;               -- '1' = two's complement operands
    p    : out std_logic_vector(2 * N - 1 downto 0)
  );
end entity array_multiplier;

architecture structural of array_multiplier is
  -- pp(i + N*j) = a(i) b(j)   (possibly complemented)
  signal pp : std_logic_vector(N * N - 1 downto 0);
  -- sum / carry of cell (j,i) -> index j*N + i
  signal sv, cv : std_logic_vector(N * N - 1 downto 0);
  signal x, y, hi : std_logic_vector(N - 1 downto 0);
begin
  assert N >= 2 report "array_multiplier: N must be at least 2" severity failure;

  -- partial products -----------------------------------------------------
  pp_rows : for j in 0 to N - 1 generate
    pp_cols : for i in 0 to N - 1 generate
      plain : if (i = N - 1) = (j = N - 1) generate      -- zero or two sign bits
        c : entity work.pp_cell port map (a => a(i), b => b(j), inv => '0', p => pp(i + N * j));
      end generate plain;
      mixed : if (i = N - 1) /= (j = N - 1) generate     -- exactly one sign bit
        c : entity work.pp_cell port map (a => a(i), b => b(j), inv => sgn, p => pp(i + N * j));
      end generate mixed;
    end generate pp_cols;
  end generate pp_rows;

  -- row 0 -----------------------------------------------------------------
  row0 : for i in 0 to N - 1 generate
    sv(i) <= pp(i);
    cv(i) <= '0';
  end generate row0;

  -- rows 1 .. N-1 ---------------------------------------------------------
  rows : for j in 1 to N - 1 generate
    cols : for i in 0 to N - 1 generate
      -- row 1: no incoming carries -> half adders
      r1_inner : if j = 1 and i < N - 1 generate
        ha : entity work.half_adder
          port map (a => pp(i + N * j), b => sv((j - 1) * N + i + 1),
                    s => sv(j * N + i), co => cv(j * N + i));
      end generate r1_inner;
      r1_edge : if j = 1 and i = N - 1 generate
        sv(j * N + i) <= pp(i + N * j);
        cv(j * N + i) <= '0';
      end generate r1_edge;
      -- rows >= 2
      rn_inner : if j >= 2 and i < N - 1 generate
        fa : entity work.full_adder
          port map (a => pp(i + N * j), b => sv((j - 1) * N + i + 1), ci => cv((j - 1) * N + i),
                    s => sv(j * N + i), co => cv(j * N + i));
      end generate rn_inner;
      rn_edge : if j >= 2 and i = N - 1 generate
        ha : entity work.half_adder
          port map (a => pp(i + N * j), b => cv((j - 1) * N + i),
                    s => sv(j * N + i), co => cv(j * N + i));
      end generate rn_edge;
    end generate cols;
    p(j) <= sv(j * N);
  end generate rows;
  p(0) <= sv(0);

  -- final carry-propagate adder over columns N .. 2N-1 --------------------
  cpa_in : for m in 0 to N - 2 generate
    x(m) <= sv((N - 1) * N + m + 1);
  end generate cpa_in;
  x(N - 1) <= sgn;                          -- Baugh-Wooley 2^(2N-1)
  cpa_carry : for m in 0 to N - 1 generate
    y(m) <= cv((N - 1) * N + m);
  end generate cpa_carry;

  final : entity work.cpa generic map (W => N, ARCH => CPA)
    port map (x => x, y => y, ci => sgn,    -- Baugh-Wooley 2^N
              s => hi, co => open);
  p(2 * N - 1 downto N) <= hi;

end architecture structural;
