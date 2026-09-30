library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.NUMERIC_STD.ALL;

entity ahw_test_bench is
end ahw_test_bench;

architecture behavior of ahw_test_bench is
    signal A, B: std_logic_vector(7 downto 0);
    signal P: std_logic_vector(15 downto 0);

    component arithmetic_hw is
        port (
            A, B: in std_logic_vector(7 downto 0);
            P: out std_logic_vector(15 downto 0)
        );
    end component;

    constant MAX : natural := 255;
begin
    AM_test: arithmetic_hw port map (A => A, B => B, P => P);

    process
    begin
        for i in 0 to 255 loop
            A <= std_logic_vector(to_unsigned(i, A'length));
            B <= std_logic_vector(to_unsigned(255-i, B'length));
            wait for 10 ns;

            assert P = std_logic_vector(to_unsigned((((i*(255-i))/4)+1), P'length))
                report "Test case " & integer'image(i) & " * " & integer'image(255-i) & " Failed" severity error;
        end loop;

        report "All Test Cases Passed";
        wait;
    end process;

end behavior;
