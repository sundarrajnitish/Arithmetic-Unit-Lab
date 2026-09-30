library IEEE;
use IEEE.std_logic_1164.all;

entity array_multiplier_32 is
    port (
        A, B: in std_logic_vector(15 downto 0);
        P: out std_logic_vector(31 downto 0)
    );
end array_multiplier_32;

architecture behaviour of array_multiplier_32 is
    signal O1, O2: std_logic_vector(15 downto 0);

    component array_multiplier
    port (
        A, B: in std_logic_vector(7 downto 0);
        P: out std_logic_vector(15 downto 0)
    );
    end component;

begin
    M1: array_multiplier port map(A=> A(15 downto 8), B=> B(15 downto 8), P=> O1);
    M2: array_multiplier port map(A=> A(7 downto 0), B=> B(7 downto 0), P=> O2);

    P <= O1 & O2;

end behaviour;