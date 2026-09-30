--------------------------------------------------------------------------------
-- Arithmetic Unit Lab                                   cells/full_adder.vhd
-- Author : Nitish Sundarraj
--
-- 1-bit full adder (3:2 counter).  s = a xor b xor ci, co = majority(a,b,ci).
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

entity full_adder is
  port (
    a, b, ci : in  std_logic;
    s        : out std_logic;
    co       : out std_logic
  );
end entity full_adder;

architecture dataflow of full_adder is
begin
  s  <= a xor b xor ci;
  co <= (a and b) or (a and ci) or (b and ci);
end architecture dataflow;
