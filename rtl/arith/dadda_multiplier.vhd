--------------------------------------------------------------------------------
-- Arithmetic Unit Lab                              arith/dadda_multiplier.vhd
-- Author : Nitish Sundarraj
--
-- Generic N x N Dadda-tree multiplier, unsigned or two's complement
-- (modified Baugh-Wooley) selected at run time by sgn.
--
-- 1. The partial-product matrix is built column by column.  Column k holds
--    every a(i)b(j) with i + j = k, plus sgn in columns N and 2N-1 (the
--    Baugh-Wooley constants 2^N + 2^(2N-1)).
-- 2. Reduction stages bring the tallest column down through the Dadda
--    sequence ... 13, 9, 6, 4, 3, 2 using the fewest full and half adders.
--    The plan (heights and adder counts per stage and column) comes from
--    au_pkg.dadda_plan at elaboration time.
-- 3. The two remaining rows go through a 2N-bit carry-propagate adder.
--
-- Bit order inside a column of stage s+1:
--    [ bits passed through | FA sums | HA sums | carries from column k-1 ]
-- FA t of column k takes positions 3t..3t+2, HA u takes 3F+2u..3F+2u+1 and
-- the rest pass through.
--
-- Stage depth for N = 4, 8, 16, 32: 2, 4, 6, 8 full-adder delays.
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use work.au_pkg.all;

entity dadda_multiplier is
  generic (
    N   : positive := 8;                -- operand width, N >= 2
    CPA : string   := "KOGGE_STONE"
  );
  port (
    a, b : in  std_logic_vector(N - 1 downto 0);
    sgn  : in  std_logic;
    p    : out std_logic_vector(2 * N - 1 downto 0)
  );
end entity dadda_multiplier;

architecture structural of dadda_multiplier is
  constant W  : natural := 2 * N;
  constant S  : natural := dadda_stage_count(N);
  constant HT : int_mat(0 to S, 0 to W) := dadda_plan(N, 0);
  constant FAN : int_mat(0 to S, 0 to W) := dadda_plan(N, 1);
  constant HAN : int_mat(0 to S, 0 to W) := dadda_plan(N, 2);
  constant D  : natural := N + 1;       -- slots per column (max height is N)

  -- bit matrix: stage s, column k, position q -> (s*(W+1) + k)*D + q
  signal m : std_logic_vector((S + 1) * (W + 1) * D - 1 downto 0);
  signal x, y : std_logic_vector(W - 1 downto 0);

  function ix (st, k, q : natural) return natural is
  begin
    return (st * (W + 1) + k) * D + q;
  end function;

  function n_pass (st, k : natural) return natural is
  begin
    return HT(st, k) - 3 * FAN(st, k) - 2 * HAN(st, k);
  end function;
begin
  assert N >= 2 report "dadda_multiplier: N must be at least 2" severity failure;

  -- stage 0: partial products ---------------------------------------------
  cols0 : for k in 0 to W - 1 generate
    terms : for i in 0 to N - 1 generate
      inrange : if k - i >= 0 and k - i <= N - 1 generate
        plain : if (i = N - 1) = (k - i = N - 1) generate
          c : entity work.pp_cell
            port map (a => a(i), b => b(k - i), inv => '0',
                      p => m(ix(0, k, i - max_int(0, k - N + 1))));
        end generate plain;
        mixed : if (i = N - 1) /= (k - i = N - 1) generate
          c : entity work.pp_cell
            port map (a => a(i), b => b(k - i), inv => sgn,
                      p => m(ix(0, k, i - max_int(0, k - N + 1))));
        end generate mixed;
      end generate inrange;
    end generate terms;
    bw_const : if k = N or k = W - 1 generate
      m(ix(0, k, HT(0, k) - 1)) <= sgn;
    end generate bw_const;
  end generate cols0;

  -- reduction stages --------------------------------------------------------
  stages : for st in 0 to S - 1 generate
    cols : for k in 0 to W - 1 generate

      fas : for t in 0 to FAN(st, k) - 1 generate
        u_fa : entity work.full_adder
          port map (a  => m(ix(st, k, 3 * t)),
                    b  => m(ix(st, k, 3 * t + 1)),
                    ci => m(ix(st, k, 3 * t + 2)),
                    s  => m(ix(st + 1, k, n_pass(st, k) + t)),
                    co => m(ix(st + 1, k + 1, n_pass(st, k + 1) + FAN(st, k + 1) + HAN(st, k + 1) + t)));
      end generate fas;

      has : for u in 0 to HAN(st, k) - 1 generate
        u_ha : entity work.half_adder
          port map (a  => m(ix(st, k, 3 * FAN(st, k) + 2 * u)),
                    b  => m(ix(st, k, 3 * FAN(st, k) + 2 * u + 1)),
                    s  => m(ix(st + 1, k, n_pass(st, k) + FAN(st, k) + u)),
                    co => m(ix(st + 1, k + 1, n_pass(st, k + 1) + FAN(st, k + 1) + HAN(st, k + 1) + FAN(st, k) + u)));
      end generate has;

      pass : for q in 0 to n_pass(st, k) - 1 generate
        m(ix(st + 1, k, q)) <= m(ix(st, k, 3 * FAN(st, k) + 2 * HAN(st, k) + q));
      end generate pass;

    end generate cols;
  end generate stages;

  -- slots above each column's height are never read; tie them off
  tie_st : for st in 0 to S generate
    tie_col : for k in 0 to W generate
      tie_q : for q in 0 to D - 1 generate
        unused : if q >= HT(st, k) generate
          m(ix(st, k, q)) <= '0';
        end generate unused;
      end generate tie_q;
    end generate tie_col;
  end generate tie_st;

  -- final two rows -> carry-propagate adder -------------------------------
  rows : for k in 0 to W - 1 generate
    x_bit : if HT(S, k) >= 1 generate
      x(k) <= m(ix(S, k, 0));
    end generate x_bit;
    x_zero : if HT(S, k) < 1 generate
      x(k) <= '0';
    end generate x_zero;
    y_bit : if HT(S, k) >= 2 generate
      y(k) <= m(ix(S, k, 1));
    end generate y_bit;
    y_zero : if HT(S, k) < 2 generate
      y(k) <= '0';
    end generate y_zero;
  end generate rows;

  final : entity work.cpa generic map (W => W, ARCH => CPA)
    port map (x => x, y => y, ci => '0', s => p, co => open);

end architecture structural;
