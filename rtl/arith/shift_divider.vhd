--------------------------------------------------------------------------------
-- Arithmetic Unit Lab                                 arith/shift_divider.vhd
-- Author : Nitish Sundarraj
--
-- Division by 2^C with a logarithmic barrel shifter.
--
--   q        = floor(x / 2^C)   (arithmetic shift when sgn = '1')
--   round_up = '1' when x is negative and a 1 was shifted out
--
-- q + round_up is x / 2^C rounded toward zero, which is what integer
-- division means in VHDL, C and Python's int(a / b).  The +round_up is not
-- done here: the arithmetic unit feeds it into the carry-in of the adder that
-- already adds D, so rounding costs no extra adder.
--
-- Stage k shifts by 2^k when c(k) = '1'.  A stage whose shift is at least W
-- replaces the whole word by the fill bit, so any C (even C >= W) is exact.
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use work.au_pkg.all;

entity shift_divider is
  generic (
    W  : positive := 16;                -- dividend width
    CW : positive := 8                  -- shift-amount width
  );
  port (
    x        : in  std_logic_vector(W - 1 downto 0);
    c        : in  std_logic_vector(CW - 1 downto 0);
    sgn      : in  std_logic;
    q        : out std_logic_vector(W - 1 downto 0);
    round_up : out std_logic
  );
end entity shift_divider;

architecture dataflow of shift_divider is
  -- value after stage k -> bits k*W .. k*W+W-1
  signal v      : std_logic_vector((CW + 1) * W - 1 downto 0);
  signal sticky : std_logic_vector(CW downto 0);
  signal fill   : std_logic;

  function or_reduce (s : std_logic_vector) return std_logic is
    variable r : std_logic := '0';
  begin
    for i in s'range loop
      r := r or s(i);
    end loop;
    return r;
  end function;
begin
  fill      <= sgn and x(W - 1);
  v(W - 1 downto 0) <= x;
  sticky(0) <= '0';

  stages : for k in 0 to CW - 1 generate

    short : if not pow2_ge(k, W) generate      -- shift by 2^k < W
      bits : for i in 0 to W - 1 generate
        from_word : if i + 2 ** k <= W - 1 generate
          v((k + 1) * W + i) <= v(k * W + i + 2 ** k) when c(k) = '1' else v(k * W + i);
        end generate from_word;
        from_fill : if i + 2 ** k > W - 1 generate
          v((k + 1) * W + i) <= fill when c(k) = '1' else v(k * W + i);
        end generate from_fill;
      end generate bits;
      sticky(k + 1) <= sticky(k) or (c(k) and or_reduce(v(k * W + 2 ** k - 1 downto k * W)));
    end generate short;

    long : if pow2_ge(k, W) generate           -- shift by 2^k >= W
      bits : for i in 0 to W - 1 generate
        v((k + 1) * W + i) <= fill when c(k) = '1' else v(k * W + i);
      end generate bits;
      sticky(k + 1) <= sticky(k) or (c(k) and or_reduce(v(k * W + W - 1 downto k * W)));
    end generate long;

  end generate stages;

  q        <= v((CW + 1) * W - 1 downto CW * W);
  round_up <= fill and sticky(CW);
end architecture dataflow;
