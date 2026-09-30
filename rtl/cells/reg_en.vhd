--------------------------------------------------------------------------------
-- Arithmetic Unit Lab                                       cells/reg_en.vhd
-- Author : Nitish Sundarraj
--
-- W-bit register, rising edge, clock enable, asynchronous active-low reset
-- (the project specification asks reset to clear every internal register).
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

entity reg_en is
  generic (W : positive := 8);
  port (
    clk     : in  std_logic;
    reset_n : in  std_logic;
    en      : in  std_logic;
    d       : in  std_logic_vector(W - 1 downto 0);
    q       : out std_logic_vector(W - 1 downto 0)
  );
end entity reg_en;

architecture rtl of reg_en is
begin
  process (clk, reset_n)
  begin
    if reset_n = '0' then
      q <= (others => '0');
    elsif rising_edge(clk) then
      if en = '1' then
        q <= d;
      end if;
    end if;
  end process;
end architecture rtl;
