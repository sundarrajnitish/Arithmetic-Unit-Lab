--------------------------------------------------------------------------------
--
-- Authors: Nitish Sundarraj Balaji, Balaji Ravindaran, Shu Gho
-- 
-- File: multiplier.vhd
--------------------------------------------------------------------------------
-- Design Units:
--   Entity: multiplier
--     Function: Implements a 1-bit multiplier with two inputs (A, B) and one output (C)
--     Inputs: A, B (1 bit each)
--     Outputs: C (1 bit)
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity multiplier is
    port(
        A : in std_logic;
        B : in std_logic;

		C: out std_logic
    );
end multiplier;

architecture behavioral of multiplier is
begin
    
    C <= A and B; 

end behavioral;

--------------------------------------------------------------------------------
-- Synthesis and Verification:
--   Synthesis Software:
--   Options/Script:
--   Target Technology:
--   Test Bench: m_test_bench
--------------------------------------------------------------------------------
-- Revision History
--   Version 1.0:
--   Date: 10/2023
--   Comments: Original implementation of the multiplier entity and architecture
--------------------------------------------------------------------------------