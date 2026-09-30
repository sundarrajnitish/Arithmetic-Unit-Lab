--------------------------------------------------------------------------------
-- Arithmetic Unit Lab                                  arith/ripple_adder.vhd
-- Author : Nitish Sundarraj
--
-- W-bit ripple-carry adder: a chain of W full adders.
-- Smallest possible adder; delay grows linearly with W.
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

entity ripple_adder is
  generic (W : positive := 16);
  port (
    x, y : in  std_logic_vector(W - 1 downto 0);
    ci   : in  std_logic;
    s    : out std_logic_vector(W - 1 downto 0);
    co   : out std_logic
  );
end entity ripple_adder;

architecture structural of ripple_adder is
  signal c : std_logic_vector(W downto 0);
begin
  c(0) <= ci;
  bits : for i in 0 to W - 1 generate
    fa : entity work.full_adder
      port map (a => x(i), b => y(i), ci => c(i), s => s(i), co => c(i + 1));
  end generate bits;
  co <= c(W);
end architecture structural;
