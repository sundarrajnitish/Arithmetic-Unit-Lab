library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.NUMERIC_STD.ALL;

entity am_test_bench is
end am_test_bench;

architecture behavior of am_test_bench is
    signal A, B: std_logic_vector(7 downto 0);
    signal P, expected_result: std_logic_vector(15 downto 0);

    component array_multiplier is
        port (
            A, B: in std_logic_vector(7 downto 0);
            P: out std_logic_vector(15 downto 0)
        );
    end component;

    constant MAX : natural := 255;
begin
    AM_test: array_multiplier port map (A => A, B => B, P => P);

    process
    begin
        for i in 0 to 255 loop
            A <= std_logic_vector(to_unsigned(i, A'length));
            B <= std_logic_vector(to_unsigned(255-i, B'length));
            wait for 10 ns;

            assert P = std_logic_vector(to_unsigned(i*(255-i), P'length))
                report "Test case " & integer'image(i) & " * " & integer'image(255-i) & " Failed" severity error;

        end loop;

        report "All Test Cases Passed";
        wait;
    end process;

end behavior;
