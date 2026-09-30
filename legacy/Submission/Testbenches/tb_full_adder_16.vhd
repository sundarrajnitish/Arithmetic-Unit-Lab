library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.NUMERIC_STD.ALL;

entity full_adder_16_unit_test_bench is
end full_adder_16_unit_test_bench;

architecture behavior of full_adder_16_unit_test_bench is
    signal A : std_logic_vector(15 downto 0);
    signal S : std_logic_vector(15 downto 0);
    signal Cout: std_logic;

    component full_adder_16 is
        port (
            A : in std_logic_vector(15 downto 0);
            S : out std_logic_vector(15 downto 0);
            Cout: out std_logic
        );
    end component;

    constant MAX : natural := 65534;
begin
    FA16_test : full_adder_16 port map (A => A, S => S, Cout => Cout);

    process
    begin
        A <= std_logic_vector(to_unsigned(65535, A'length));
        wait for 1 ns;
        assert (S = "0000000000000000" and Cout = '1')
            report "Test case 65535 Failed" severity error;
        wait for 1 ns;
        for i in MAX downto 0 loop
            A <= std_logic_vector(to_unsigned(i, A'length));
            wait for 1 ns;
            assert (S = std_logic_vector(to_unsigned(i+1, S'length)) and Cout = '0')
                report "Test case " & integer'image(i) & " Failed" severity error;
        end loop;
        wait;
        
    end process;

end behavior;
