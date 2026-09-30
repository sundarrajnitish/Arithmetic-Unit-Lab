library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.NUMERIC_STD.ALL;

entity simulation_sync_hw is
end simulation_sync_hw;

architecture behavior of simulation_sync_hw is
    signal A, B, D: std_logic_vector(7 downto 0) := "10101010";
    signal C: std_logic_vector(7 downto 0) := "00000001";
    signal P: std_logic_vector(15 downto 0);

    signal clk, status : std_logic;
    signal load : std_logic := '1';
    signal reset : std_logic := '1';

    component sync_arithmetic_hw_ar is
        generic (N: INTEGER:= 8 ; K: INTEGER:= 32);
        Port ( 
           clk, reset, load : in  STD_LOGIC;
           A : in  STD_LOGIC_VECTOR (N-1 downto 0);
           B : in  STD_LOGIC_VECTOR (N-1 downto 0);
           C : in  STD_LOGIC_VECTOR (N-1 downto 0);
           D : in  STD_LOGIC_VECTOR (N-1 downto 0);
           mode : in  STD_LOGIC;
           mode_d : in  STD_LOGIC;

           status : out std_logic;
           P : out  STD_LOGIC_VECTOR (2*N-1 downto 0));
    end component;

begin
    UUT: sync_arithmetic_hw_ar port map (A=> A, B=> B, C=> C, D=> D, P=> P, clk=> clk, reset=> reset, load=> load, status=> status, mode=> '0', mode_d=> '0');
    
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
