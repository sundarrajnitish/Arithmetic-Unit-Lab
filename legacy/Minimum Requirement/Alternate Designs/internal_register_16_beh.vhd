library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity internal_register_16_beh is
    Port ( clk : in  STD_LOGIC;
           reset : in  STD_LOGIC;
           A : in  STD_LOGIC_VECTOR (15 downto 0);
           B : out  STD_LOGIC_VECTOR (15 downto 0);
           status_out : out STD_LOGIC);
end internal_register_16;

architecture Behavioral of internal_register_16_beh is

    signal temp_output : STD_LOGIC_VECTOR (15 downto 0);
    signal temp_A : STD_LOGIC_VECTOR (15 downto 0);

    begin 
        temp_A <= A;
        process (clk, reset)
        begin
            if (reset = '1') then
                B <= (others => '0');
            elsif (clk'event and clk = '1') then
                B <= A;
            end if;
            if temp_output = temp_A then
                status_out <= '0';
            else
                status_out <= '1';
            end if;
            temp_output <= A;
            end process;
        end architecture;
    