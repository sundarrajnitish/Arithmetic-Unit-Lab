library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity arithmetic_unit_beh is
    Port ( 
           clk : in  STD_LOGIC;
           load : in  STD_LOGIC;
           reset : in  STD_LOGIC;
           status : out  STD_LOGIC;

           A : in  STD_LOGIC_VECTOR (7 downto 0);
           B : in  STD_LOGIC_VECTOR (7 downto 0);
           P : out  STD_LOGIC_VECTOR (15 downto 0)
           );
end arithmetic_unit_beh;

architecture Behavioral of arithmetic_unit_beh is

    signal input_1 : STD_LOGIC_VECTOR (7 downto 0);
    signal input_2 : STD_LOGIC_VECTOR (7 downto 0);

    signal output_1 : STD_LOGIC_VECTOR (15 downto 0);
    --signal status_out : STD_LOGIC;

    component arithmetic_hw is
        Port (
               A : in  STD_LOGIC_VECTOR (7 downto 0);
               B : in  STD_LOGIC_VECTOR (7 downto 0);
               P : out  STD_LOGIC_VECTOR (15 downto 0));
    end component;

    component internal_register_8 is
        port (
        clk : in  STD_LOGIC;
        reset : in  STD_LOGIC;
        load : in  STD_LOGIC;
        A : in  STD_LOGIC_VECTOR (7 downto 0);
        B : out  STD_LOGIC_VECTOR (7 downto 0));
    end component;

    component internal_register_16 is
        port (
        clk : in  STD_LOGIC;
        reset : in  STD_LOGIC;
        status_out : out  STD_LOGIC;

        A : in  STD_LOGIC_VECTOR (15 downto 0);
        B : out  STD_LOGIC_VECTOR (15 downto 0));
    end component;

    begin
        R1: internal_register_8 port map (clk => clk, reset => reset, load => load, A => A, B => input_1);
        R2: internal_register_8 port map (clk => clk, reset => reset, load => load, A => B, B => input_2);

        AHW: arithmetic_hw port map (A => input_1, B => input_2, P => output_1);

        R3: internal_register_16 port map (clk => clk, reset => reset, A => output_1, B => P, status_out => status);

end Behavioral;
        