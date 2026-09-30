library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_data_analyzer is
end tb_data_analyzer;

architecture behavior of tb_data_analyzer is
    signal A: std_logic_vector(15 downto 0);
    signal D: std_logic_vector(7 downto 0);
    signal A_out, D_out: std_logic_vector(15 downto 0);
    signal mode, d_mode: std_logic;

    component data_analyzer is
        port (
            mode : in std_logic;
            d_mode : in std_logic;
            A: in std_logic_vector(15 downto 0);
            D: in std_logic_vector(7 downto 0);
            A_out: out std_logic_vector(15 downto 0);
            D_out: out std_logic_vector(15 downto 0)
        );
    end component;

    constant MAX : natural := 65535;
begin
    AM_test: data_analyzer port map (A => A, D => D, mode => mode, d_mode => d_mode, A_out => A_out, D_out => D_out);

    mode <= '1';
    d_mode <= '0';

    process
    begin
        for i in 0 to 65535 loop
            A <= std_logic_vector(to_unsigned(i, A'length));
            D <= std_logic_vector(to_unsigned((65535-i)/2, D'length));
            wait for 1 ns;

            assert A_out = not std_logic_vector(to_unsigned(i, A_out'length))
                report "Test case " & integer'image(i) & " * " & integer'image(65535-i) & " Failed" severity error;

            assert D_out = std_logic_vector(to_unsigned(((65535-i)/2), D_out'length))
                report "Test case " & integer'image(i) & " * " & integer'image((65535-i)/2) & " Failed" severity error;
        end loop;

        report "All Test Cases Passed";
        wait;
    end process;

    mode <= '0';
    d_mode <= '1';

    process
    begin
        for i in 0 to 65535 loop
            A <= std_logic_vector(to_unsigned(i, A'length));
            D <= std_logic_vector(to_unsigned((65535-i)/2, D'length));
            wait for 1 ns;

            assert A_out = std_logic_vector(to_unsigned(i, A_out'length))
                report "Test case " & integer'image(i) & " * " & integer'image(65535-i) & " Failed" severity error;

            assert D_out = not std_logic_vector(to_unsigned(((65535-i)/2), D_out'length))
                report "Test case " & integer'image(i) & " * " & integer'image((65535-i)/2) & " Failed" severity error;
        end loop;

        report "All Test Cases Passed";
        wait;
    end process;

end behavior;
