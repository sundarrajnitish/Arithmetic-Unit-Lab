library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity test_bench is
end test_bench;

architecture behavior of test_bench is
    signal A, B, Cin, S, Cout: std_logic;

    component full_adder
        port (
            A, B, Cin: in std_logic;
            S, Cout: out std_logic
        );
    end component;

begin
    FA_test: full_adder port map (A, B, Cin, S, Cout);

    process
    begin
        -- Test case 1: A=0, B=0, Cin=0
        A <= '0';
        B <= '0';
        Cin <= '0';
        wait for 10 ns;
        assert (S = '0' and Cout = '0')
            report "Test case 1 failed" severity error;

        -- Test case 2: A=0, B=1, Cin=0
        A <= '0';
        B <= '1';
        Cin <= '0';
        wait for 10 ns;
        assert (S = '1' and Cout = '0')
            report "Test case 2 failed" severity error;

        -- Test case 3: A=1, B=0, Cin=0
        A <= '1';
        B <= '0';
        Cin <= '0';
        wait for 10 ns;
        assert (S = '1' and Cout = '0')
            report "Test case 3 failed" severity error;

        -- Test case 4: A=1, B=1, Cin=0
        A <= '1';
        B <= '1';
        Cin <= '0';
        wait for 10 ns;
        assert (S = '0' and Cout = '1')
            report "Test case 4 failed" severity error;

        -- Test case 5: A=0, B=0, Cin=1
        A <= '0';
        B <= '0';
        Cin <= '1';
        wait for 10 ns;
        assert (S = '1' and Cout = '0')
            report "Test case 5 failed" severity error;

        -- Test case 6: A=0, B=1, Cin=1
        A <= '0';
        B <= '1';
        Cin <= '1';
        wait for 10 ns;
        assert (S = '0' and Cout = '1')
            report "Test case 6 failed" severity error;

        -- Test case 7: A=1, B=0, Cin=1
        A <= '1';
        B <= '0';
        Cin <= '1';
        wait for 10 ns;
        assert (S = '0' and Cout = '1')
            report "Test case 7 failed" severity error;

        -- Test case 8: A=1, B=1, Cin=1
        A <= '1';
        B <= '1';
        Cin <= '1';
        wait for 10 ns;
        assert (S = '1' and Cout = '1')
            report "Test case 8 failed" severity error;

        -- Stop simulation
        wait;
    end process;

end behavior;
