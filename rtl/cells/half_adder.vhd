--------------------------------------------------------------------------------
-- Arithmetic Unit Lab                                   cells/half_adder.vhd
-- Author : Nitish Sundarraj
--
-- 1-bit half adder.  s = a xor b, co = a and b.
-- Also used as the generate/propagate cell of the prefix adder
-- (co = g, s = p).
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

entity half_adder is
  port (
    a, b : in  std_logic;
    s    : out std_logic;
    co   : out std_logic
  );
end entity half_adder;

architecture dataflow of half_adder is
begin
  s  <= a xor b;
  co <= a and b;
end architecture dataflow;
