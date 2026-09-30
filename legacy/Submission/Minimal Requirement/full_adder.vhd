--------------------------------------------------------------------------------
--
-- Authors: Nitish Sundarraj Balaji, Balaji Ravindaran, Shu Gho
-- 
-- File: full_adder.vhd
--------------------------------------------------------------------------------
-- Design Units:
--   Entity: full_adder
--     Function: Implements a 1-bit full adder with three inputs (A, B, Cin) and two outputs (S, Cout)
--     Inputs: A, B, Cin (1 bit each)
--     Outputs: S, Cout (1 bit each)
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity full_adder is
    port(
        A : in std_logic;
        B : in std_logic;
        Cin : in std_logic;

        S : out std_logic;
        Cout : out std_logic
    );
end full_adder;

architecture behavioral of full_adder is
begin
    
    S <= A xor B xor Cin;
    Cout <= (A and B) or (Cin and A) or (Cin and B);

end behavioral;

--------------------------------------------------------------------------------
-- Synthesis and Verification:
--   Synthesis Software:
--   Options/Script:
--   Target Technology:
--   Test Bench: test_bench_full_adder
--------------------------------------------------------------------------------
-- Revision History
--   Version 1.0:
--   Date: 10/2023
--   Comments: Original implementation of the full_adder entity and architecture
--------------------------------------------------------------------------------