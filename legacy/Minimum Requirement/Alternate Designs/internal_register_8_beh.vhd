library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity internal_register_8_beh is
    Port ( clk : in  STD_LOGIC;
           reset : in  STD_LOGIC;
           load : in  STD_LOGIC;
           A : in  STD_LOGIC_VECTOR (7 downto 0);
           B : out  STD_LOGIC_VECTOR (7 downto 0));
end internal_register_8;

architecture Behavioral of internal_register_8_beh is
    begin 
        process (clk, reset)
        begin 
            if (reset = '1') then
                B <= (others => '0');
            elsif (clk'event and clk = '1') and load = '1' then
                B <= A;
            end if;
            end process;
        end architecture;
    