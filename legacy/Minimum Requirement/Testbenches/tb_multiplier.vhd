library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity m_test_bench is
end m_test_bench;

architecture behavior of m_test_bench is
    signal A, B, C: std_logic;

    component multiplier
        port (
            A, B: in std_logic;
            C: out std_logic
        );
    end component;
    
begin
    Multiplier_test: multiplier port map (A, B, C);

    process
    begin
        -- Test case 1: A=0, B=0
        A <= '0';
        B <= '0';
        wait for 10 ns;
        assert (C = '0')
            report "Test case 1 failed" severity error;

        -- Test case 2: A=0, B=1
        A <= '0';
        B <= '1';
        wait for 10 ns;
        assert (C = '0')
            report "Test case 2 failed" severity error;

        -- Test case 3: A=1, B=0
        A <= '1';
        B <= '0';
        wait for 10 ns;
        assert (C = '0')
            report "Test case 3 failed" severity error;

        -- Test case 4: A=1, B=1
        A <= '1';
        B <= '1';
        wait for 10 ns;
        assert (C = '1')
            report "Test case 4 failed" severity error;

        -- Stop simulation
        wait;
    end process;

end behavior;
