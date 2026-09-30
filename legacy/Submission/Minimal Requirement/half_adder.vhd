--------------------------------------------------------------------------------
--
-- Authors: Nitish Sundarraj Balaji, Balaji Ravindaran, Shu Gho
-- 
-- File: half_adder.vhd
--------------------------------------------------------------------------------
-- Design Units:
--   Entity: half_adder
--     Function: Implements a 1-bit half adder with two inputs (A, B) and two outputs (S, Cout)
--     Inputs: A, B (1 bit each)
--     Outputs: S, Cout (1 bit each)
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity half_adder is
    port(
        A : in std_logic;
        B : in std_logic;

        S : out std_logic;
        Cout : out std_logic
    );
end half_adder;

architecture behavioral of half_adder is
begin
    
    S <= A xor B;
    Cout <= (A and B);

end behavioral;

--------------------------------------------------------------------------------
-- Synthesis and Verification:
--   Synthesis Software:
--   Options/Script:
--   Target Technology:
--   Test Bench: test_bench_half_adder
--------------------------------------------------------------------------------
-- Revision History
--   Version 1.0:
--   Date: 10/2023
--   Comments: Original implementation of the half_adder entity and architecture
--------------------------------------------------------------------------------