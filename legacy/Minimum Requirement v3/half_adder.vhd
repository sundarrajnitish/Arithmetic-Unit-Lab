--------------------------------------------------------------------------------------
--
-- Authors: Nitish Sundarraj Balaji, Balaji Ravindaran
-- 
-- File: half_adder.vhd

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