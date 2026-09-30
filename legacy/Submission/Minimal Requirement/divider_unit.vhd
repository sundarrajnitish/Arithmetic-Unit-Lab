--------------------------------------------------------------------------------
--
-- Authors: Nitish Sundarraj Balaji, Balaji Ravindaran, Shu Gho
-- 
-- File: divider_unit.vhd
--------------------------------------------------------------------------------
-- Design Units:
--   Entity: divider_unit
--     Function: Implements a 16-bit double right shifter with two inputs (A, start) and one output (D)
--     Inputs: A (16 bit), start (1 bit)
--     Outputs: D (16 bit)
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity divider_unit is
    port(
    A : in std_logic_vector(15 downto 0);
    start : in std_logic;

    D : out std_logic_vector(15 downto 0)
    );
end divider_unit;

architecture behavioral of divider_unit is
    signal temp : std_logic_vector(13 downto 0);

    begin
        temp <= A(15 downto 2);
        D <= "00" & temp when (start = '1') else
        (others=> '0');

end behavioral;

--------------------------------------------------------------------------------
-- Synthesis and Verification:
--   Synthesis Software:
--   Options/Script:
--   Target Technology:
--   Test Bench: divider_unit_test_bench
--------------------------------------------------------------------------------
-- Revision History
--   Version 1.0:
--   Date: 10/2023
--   Comments: Original implementation of the divider_unit entity and architecture
--------------------------------------------------------------------------------