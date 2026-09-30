--------------------------------------------------------------------------------------
--
-- Authors: Nitish Sundarraj Balaji, Balaji Ravindaran
-- 
-- File: header.vhd

-- Design Units:
--      entity full_adder
--          function: To show a header
--          input: A, B, Cin
--          output: S, Cout
--      architecture behavioral_full_adder:
--          full adder circuit implementation
--          implementation
--
-- Library/ Package:
--      ieee.std_logic_1164: to use std_logic
--
-- Synthesis and Verification:
--      Synthesis Software: 
--      Options/Script :
--      Target Technology:
--      Test Bench: full_adder_tb
--
-- Revision History
--      Version 1.0:
--      Date: 10/2023
--      Comments: Original
--
--------------------------------------------------------------------------------------

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