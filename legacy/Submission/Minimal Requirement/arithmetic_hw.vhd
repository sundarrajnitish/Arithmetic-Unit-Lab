--------------------------------------------------------------------------------
--
-- Authors: Nitish Sundarraj Balaji, Balaji Ravindaran, Shu Gho
-- 
-- File: arithmetic_hw.vhd
--------------------------------------------------------------------------------
-- Design Units:
--   Entity: arithmetic_hw
--     Function: Implements a 8 to 16 bit arithmetic unit with two inputs (A, B) and one output (P)
--     Inputs: A, B (8 bit each)
--     Outputs: P (16 bit)
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity arithmeitc_hw is
    Port ( A : in  STD_LOGIC_VECTOR (7 downto 0);
           B : in  STD_LOGIC_VECTOR (7 downto 0);
           P : out  STD_LOGIC_VECTOR (15 downto 0));
end arithmetic_hw;

architecture behavior of arithmetic_hw is

    signal am_output: std_logic_vector(15 downto 0);
    signal divider_output: std_logic_vector(15 downto 0);
    signal fa_16_cout: std_logic;

    component array_multiplier is
        port (
            A, B: in std_logic_vector(7 downto 0);
            P: out std_logic_vector(15 downto 0)
        );
    end component;

    component divider_unit is
        port (
            A: in std_logic_vector(15 downto 0);
            D: out std_logic_vector(15 downto 0)
        );
    end component;

    component full_adder_16 is
        port(
            A : in std_logic_vector(15 downto 0);
            S : out std_logic_vector(15 downto 0);
            Cout : out std_logic
        );
    end component;


    begin 
        AM: array_multiplier port map (A => A, B => B, P => am_output);
        DU: divider_unit port map (A => am_output, D => divider_output);
        FD: full_adder_16 port map (A => divider_output, S => P, Cout => fa_16_cout);

end behavior;

--------------------------------------------------------------------------------
-- Synthesis and Verification:
--   Synthesis Software:
--   Options/Script:
--   Target Technology:
--   Test Bench: ahw_test_bench
--------------------------------------------------------------------------------
-- Revision History
--   Version 1.0:
--   Date: 10/2023
--   Comments: Original implementation of the arithmeitc_hw entity and architecture
--------------------------------------------------------------------------------