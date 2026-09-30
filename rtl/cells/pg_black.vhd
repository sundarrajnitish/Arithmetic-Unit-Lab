--------------------------------------------------------------------------------
-- Arithmetic Unit Lab                                     cells/pg_black.vhd
-- Author : Nitish Sundarraj
--
-- Prefix-adder "black" cell: combines the (generate, propagate) pair of a
-- high group with the pair of the adjacent low group.
--   g = g_hi or (p_hi and g_lo)
--   p = p_hi and p_lo
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

entity pg_black is
  port (
    g_hi, p_hi : in  std_logic;
    g_lo, p_lo : in  std_logic;
    g, p       : out std_logic
  );
end entity pg_black;

architecture dataflow of pg_black is
begin
  g <= g_hi or (p_hi and g_lo);
  p <= p_hi and p_lo;
end architecture dataflow;
