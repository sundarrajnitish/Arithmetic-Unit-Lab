library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.NUMERIC_STD.ALL;

entity divider_unit_test_bench is
end divider_unit_test_bench;

architecture behavior of divider_unit_test_bench is
    signal A : std_logic_vector(15 downto 0);
    signal D : std_logic_vector(15 downto 0);

    component divider_unit is
        port (
            A : in std_logic_vector(15 downto 0);
            D : out std_logic_vector(15 downto 0)
        );
    end component;

    constant MAX : natural := 65535;
begin
    DU_test : divider_unit port map (A => A, D => D);

    process
    begin
        for i in MAX downto 0 loop
            A <= std_logic_vector(to_unsigned(i, A'length));
            wait for 1 ns;
            assert D = std_logic_vector(to_unsigned(i/4, D'length))
                report "Test case " & integer'image(i) & " Failed" severity error;
        end loop;
        wait;

        
    end process;

end behavior;
