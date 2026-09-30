library ieee;
use ieee.std_logic_1164.all;

entity register_dq_8 is
    port(
        clk, reset : in std_logic;
        d : in std_logic_vector(7 downto 0);
        q : out std_logic_vector(7 downto 0)
    );
end register_dq_8;

architecture rtl of register_dq_8 is
    begin
        process(clk, reset)
        begin
            if reset = '1' then
                q <= (others => '0');
            elsif (clk = '1' and clk'event) then
                q <= d;
            end if;
        end process;
end rtl;
