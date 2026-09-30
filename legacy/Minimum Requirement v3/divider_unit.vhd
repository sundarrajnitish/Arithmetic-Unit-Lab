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
        'Z' & 'Z' & 'Z' & 'Z' & 'Z' & 'Z' & 'Z' & 'Z' & 'Z' & 'Z' & 'Z' & 'Z' & 'Z' & 'Z' & 'Z' & 'Z';

end behavioral;