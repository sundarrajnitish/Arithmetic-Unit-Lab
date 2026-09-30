library ieee;
use ieee.std_logic_1164.all;

entity not_gate is
    port(
        A : in std_logic;
        
		B: out std_logic
    );
end not_gate;

architecture behavioral of not_gate is
    signal temp_A : std_logic;
begin
    temp_A <= not A;
    B <= temp_A;

end behavioral;