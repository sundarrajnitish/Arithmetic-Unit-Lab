--------------------------------------------------------------------------------
-- Arithmetic Unit Lab                                      cells/pp_cell.vhd
-- Author : Nitish Sundarraj
--
-- Partial-product cell:  p = (a and b) xor inv.
-- inv = 0 gives the ordinary AND of an unsigned multiplier.  The Baugh-Wooley
-- signed form complements the partial products that involve exactly one sign
-- bit, so those cells get inv = sgn and every other cell gets inv = '0'.
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

entity pp_cell is
  port (
    a, b : in  std_logic;
    inv  : in  std_logic;
    p    : out std_logic
  );
end entity pp_cell;

architecture dataflow of pp_cell is
begin
  p <= (a and b) xor inv;
end architecture dataflow;
