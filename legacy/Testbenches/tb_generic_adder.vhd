library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_generic_adder is
end tb_generic_adder;

architecture behavior of tb_generic_adder is
    signal A, B: std_logic_vector(15 downto 0);
    signal P: std_logic_vector(15 downto 0);
    signal start: std_logic;

    component generic_adder is
        port (
            A, B: in std_logic_vector(15 downto 0);
            start: in std_logic;
            P_out: out std_logic_vector(15 downto 0)
        );
    end component;

    constant MAX : natural := 65535;
begin
    AM_test: generic_adder port map (A => A, B => B, start => start, P_out => P);

    start <= '1';

    process
    begin
        for i in 0 to 65535 loop
            A <= std_logic_vector(to_unsigned(i, A'length));
            B <= std_logic_vector(to_unsigned(65535-i, B'length));
            wait for 1 ns;

            assert P = std_logic_vector(to_unsigned(65535, P'length))
                report "Test case " & integer'image(i) & " * " & integer'image(65535-i) & " Failed" severity error;
        end loop;

        report "All Test Cases Passed";
        wait;
    end process;

end behavior;
