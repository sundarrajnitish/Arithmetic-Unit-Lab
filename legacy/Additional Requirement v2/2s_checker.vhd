library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity data_analyzer is
    generic (N: INTEGER:= 8);
    port (
    mode : in std_logic;
    d_mode : in std_logic;
    A: in std_logic_vector(2*N-1 downto 0);
    D: in std_logic_vector(N-1 downto 0);
    A_out: out std_logic_vector(2*N-1 downto 0);
    D_out: out std_logic_vector(2*N-1 downto 0)
    );

end data_analyzer;

architecture behavioral of data_analyzer is

    --signal remaining_bits_zeroes : std_logic_vector ((K-(2*N-1))-2 downto 0);

    signal a_complement : std_logic_vector (2*N-1 downto 0);
    signal d_complement : std_logic_vector (N-1 downto 0);

    signal remaining_bits_zeroes : std_logic_vector ((N-1) downto 0);

    begin

    remaining_bits_zeroes <= (others => '0');
    
    a_complement <= not A when mode = '1' else A;
    d_complement <= not D when d_mode = '1' else D;

    A_out <= a_complement;
    D_out <= remaining_bits_zeroes & d_complement;

    end behavioral;

