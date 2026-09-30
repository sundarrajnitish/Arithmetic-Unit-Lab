library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity test_bench_half_adder is
end test_bench_half_adder;

architecture behavior of test_bench_half_adder is
    signal A, B, S, Cout: std_logic;

    component half_adder
        port (
            A, B: in std_logic;
            S, Cout: out std_logic
        );
    end component;

begin
    HA_test: half_adder port map (A, B, S, Cout);

    process
    begin
        -- Test case 1: A=0, B=0
        A <= '0';
        B <= '0';
        wait for 10 ns;
        assert (S = '0' and Cout = '0')
            report "Test case 1 failed" severity error;

        -- Test case 2: A=0, B=1
        A <= '0';
        B <= '1';
        wait for 10 ns;
        assert (S = '1' and Cout = '0')
            report "Test case 2 failed" severity error;

        -- Test case 3: A=1, B=0
        A <= '1';
        B <= '0';
        wait for 10 ns;
        assert (S = '1' and Cout = '0')
            report "Test case 3 failed" severity error;

        -- Test case 4: A=1, B=1
        A <= '1';
        B <= '1';
        wait for 10 ns;
        assert (S = '0' and Cout = '1')
            report "Test case 4 failed" severity error;

        -- Stop simulation
        wait;
    end process;

end behavior;
