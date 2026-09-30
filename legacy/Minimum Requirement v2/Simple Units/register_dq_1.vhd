library ieee;
use ieee.std_logic_1164.all;

entity register_dq_1 is
    port(
        clk, reset : in std_logic;
        d : in std_logic;
        q : out std_logic
    );
end register_dq_1;

architecture rtl of register_dq_1 is
    begin
        process(clk, reset)
        begin
            if reset = '1' then
                q <= '0';
            elsif (clk = '1' and clk'event) then
                q <= d;
            end if;
        end process;
end rtl;
