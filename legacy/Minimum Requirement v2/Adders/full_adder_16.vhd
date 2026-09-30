library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity full_adder_16 is
    port(
    A : in std_logic_vector(15 downto 0);

    S : out std_logic_vector(15 downto 0);
    Cout : out std_logic
    
    );
end full_adder_16;

architecture behavioral of full_adder_16 is

    component full_adder is
        port(
        A : in std_logic;
        B : in std_logic;
        Cin : in std_logic;

        S : out std_logic;
        Cout : out std_logic
        );
    end component;

    signal S1, S2, S3, S4, S5, S6, S7, S8, S9, S10, S11, S12, S13, S14, S15, S16 : std_logic;
    signal C1, C2, C3, C4, C5, C6, C7, C8, C9, C10, C11, C12, C13, C14, C15 : std_logic;

    begin 
    FA1: full_adder port map(A => A(0), B => '1', Cin => '0', S => S1, Cout => C1); --Cin => '0' because it is the first bit
    FA2: full_adder port map(A => A(1), B => '0', Cin => C1, S => S2, Cout => C2); 
    FA3: full_adder port map(A => A(2), B => '0', Cin => C2, S => S3, Cout => C3);
    FA4: full_adder port map(A => A(3), B => '0', Cin => C3, S => S4, Cout => C4);
    FA5: full_adder port map(A => A(4), B => '0', Cin => C4, S => S5, Cout => C5);
    FA6: full_adder port map(A => A(5), B => '0', Cin => C5, S => S6, Cout => C6);
    FA7: full_adder port map(A => A(6), B => '0', Cin => C6, S => S7, Cout => C7);
    FA8: full_adder port map(A => A(7), B => '0', Cin => C7, S => S8, Cout => C8);
    FA9: full_adder port map(A => A(8), B => '0', Cin => C8, S => S9, Cout => C9);
    FA10: full_adder port map(A => A(9), B => '0', Cin => C9, S => S10, Cout => C10);
    FA11: full_adder port map(A => A(10), B => '0', Cin => C10, S => S11, Cout => C11);
    FA12: full_adder port map(A => A(11), B => '0', Cin => C11, S => S12, Cout => C12);
    FA13: full_adder port map(A => A(12), B => '0', Cin => C12, S => S13, Cout => C13);
    FA14: full_adder port map(A => A(13), B => '0', Cin => C13, S => S14, Cout => C14);
    FA15: full_adder port map(A => A(14), B => '0', Cin => C14, S => S15, Cout => C15);
    FA16: full_adder port map(A => A(15), B => '0', Cin => C15, S => S16, Cout => Cout); --Cout => Cout because it is the last bit
    
    S <= S16 & S15 & S14 & S13 & S12 & S11 & S10 & S9 & S8 & S7 & S6 & S5 & S4 & S3 & S2 & S1;

end behavioral;
