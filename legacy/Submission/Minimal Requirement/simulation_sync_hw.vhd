library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.NUMERIC_STD.ALL;

entity simulation_sync_hw is
end simulation_sync_hw;

architecture behavior of simulation_sync_hw is
    signal A, B: std_logic_vector(7 downto 0) := "10101010";
    signal P: std_logic_vector(15 downto 0);

    signal clk, status : std_logic;
    signal reset, load : std_logic := '1';

    component sync_arithmetic_hw is
        Port ( 
           clk, reset, load : in  STD_LOGIC;
           A : in  STD_LOGIC_VECTOR (7 downto 0);
           B : in  STD_LOGIC_VECTOR (7 downto 0);

           status : out std_logic;
           P : out  STD_LOGIC_VECTOR (15 downto 0));
    end component;

begin
    sync_test: sync_arithmetic_hw port map (A => A, B => B, P => P, clk => clk, reset => reset, load => load, status => status);
    
    process
        begin   
        for i in 0 to 20 loop
            clk <= '0';
            wait for 10 ns;
            clk <= '1';
            wait for 10 ns;
        end loop;
        wait; -- wait indefinitely
        end process;

end behavior;
