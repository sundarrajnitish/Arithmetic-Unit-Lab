library ieee;
use ieee.std_logic_1164.all;

entity carry_save_adder is
    port(
        A : in std_logic;
        B : in std_logic;
        C : in std_logic;

        S : out std_logic;
        Cout : out std_logic_vector(1 downto 0)
    );
end carry_save_adder;

architecture behavioral of carry_save_adder is
begin
    
    S <= A xor B xor C;
    Cout <= (A and B) or (A and C) or (B and C) & '0';

end behavioral;