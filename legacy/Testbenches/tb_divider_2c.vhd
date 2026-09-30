library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_divider_2c is
end tb_divider_2c;

architecture behavior of tb_divider_2c is
    signal A: std_logic_vector(15 downto 0);
    signal C: std_logic_vector(7 downto 0);
    signal P_out: std_logic_vector(15 downto 0);
    signal mode, start: std_logic;

    component divider_2c is
        port (
            mode : in std_logic;
            start : in std_logic;
            A: in std_logic_vector(15 downto 0);
            C: in std_logic_vector(7 downto 0);
            P_out: out std_logic_vector(15 downto 0)
        );
    end component;

    constant MAX : natural := 65535;
begin
    AM_test: divider_2c port map (A => A, C => C, mode => mode, start => start, P_out => P_out);

    mode <= '1';
    start <= '1';

    process
    begin
        for i in 2 to 65535 loop
            A <= std_logic_vector(to_signed(i, A'length));
            C <= std_logic_vector(to_signed(((i)/2), C'length));
            wait for 1 ns;

            assert P_out = std_logic_vector(to_signed((i/(i/2)), P_out'length))
                report "Test case " & integer'image(i) & " * " & integer'image(65535-i) & " Failed" severity error;
        end loop;

        report "All Test Cases Passed";
        wait;
    end process;

end behavior;