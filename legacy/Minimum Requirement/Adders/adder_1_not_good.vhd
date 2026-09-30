library ieee;
use ieee.std_logic_1164.all;

entity half_adder is
    port(
        A : in std_logic_vector(15 downto 0);

        S : out std_logic_vector(15 downto 0);
        Cout : out std_logic_vector(15 downto 0)
    );
end half_adder;

architecture behavioral of half_adder is
    signal B : std_logic_vector(15 downto 0) := "0000000000000001";
begin
    
    S <= A xor B;
    Cout <= (A and B);

end behavioral;