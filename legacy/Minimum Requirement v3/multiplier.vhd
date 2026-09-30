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