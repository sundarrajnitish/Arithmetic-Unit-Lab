--------------------------------------------------------------------------------
-- Arithmetic Unit Lab                                       cells/dff_en.vhd
-- Author : Nitish Sundarraj
--
-- 1-bit flip-flop, rising edge, clock enable, asynchronous active-low reset.
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

entity dff_en is
  port (
    clk     : in  std_logic;
    reset_n : in  std_logic;
    en      : in  std_logic;
    d       : in  std_logic;
    q       : out std_logic
  );
end entity dff_en;

architecture rtl of dff_en is
begin
  process (clk, reset_n)
  begin
    if reset_n = '0' then
      q <= '0';
    elsif rising_edge(clk) then
      if en = '1' then
        q <= d;
      end if;
    end if;
  end process;
end architecture rtl;
