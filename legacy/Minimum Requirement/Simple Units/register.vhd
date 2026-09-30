library ieee;
use ieee.std_logic_1164.all;

entity register_dq is
    port(
        clk, reset : in std_logic;
        d : in std_logic_vector(7 downto 0);
        q : out std_logic_vector(7 downto 0)
    );
end register_dq;

architecture rtl of register_dq is
    signal q_int : std_logic_vector(7 downto 0);
    begin
        process(clk, reset)
        begin
            if reset = '1' then
                q_int <= (others => '0');
            elsif (clk = '1' and clk'event) then
                q_int <= d;
            end if;
        end process;
        q <= q_int;
end rtl;
