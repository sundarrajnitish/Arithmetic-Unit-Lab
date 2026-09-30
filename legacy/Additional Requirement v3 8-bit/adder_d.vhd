library IEEE;
use IEEE.STD_LOGIC_1164.ALL; 

entity generic_adder is
    generic (N: INTEGER:= 8;  K: INTEGER:= 32);
    port (
    A, B: in std_logic_vector(2*N-1 downto 0);
    start : in std_logic;

    P_out: out std_logic_vector(2*N-1 downto 0)
    );
end generic_adder;

architecture beh_arch of generic_adder is
    component full_adder is
        port(
            A : in std_logic;
            B : in std_logic;
            Cin : in std_logic;
    
            S : out std_logic;
            Cout : out std_logic
        );
 	end component;

    signal carry1, carry2, carry3, carry4, carry5, carry6, carry7, carry8, carry9, carry10: std_logic;
    signal carry11, carry12, carry13, carry14, carry15, carry16, carry17, carry18, carry19, carry20: std_logic;
    signal carry21, carry22, carry23, carry24, carry25, carry26, carry27, carry28, carry29, carry30: std_logic;
    signal carry31, carry32: std_logic;
    signal sum: std_logic_vector(31 downto 0);

    signal just_A : std_logic_vector(2*N-1 downto 0);
    signal just_B : std_logic_vector(2*N-1 downto 0);

    signal remaining_bits : std_logic_vector ((K-(2*N-1))-2 downto 0); -- Output product

    --signal modified_c : std_logic_vector (31 downto 0); -- Input shift amount

    signal modified_a : std_logic_vector (31 downto 0); -- Input shift amount
    signal modified_b : std_logic_vector (31 downto 0); -- Input shift amount

    signal P : std_logic_vector (2*N-1 downto 0); -- Output product

    begin
        remaining_bits <= (others => '0');
        just_A <= A;
        just_B <= B;
        modified_a <= remaining_bits & just_A; -- Zeroes are concatenated to the input number to make the output product 2N bits long
        modified_b <= remaining_bits & just_B; -- Zeroes are concatenated to the input number to make the output product 2N bits long
        --modified_c <= remaining_bits & C; -- Zeroes are concatenated to the input number to make the output product 2N bits long

        f00: full_adder port map (Cin=>'0', A=>modified_a(0), B=>modified_b(0), S=>sum(0), Cout=>carry1);
        f01: full_adder port map (Cin=>carry1, A=>modified_a(1), B=>modified_b(1), S=>sum(1), Cout=>carry2);
        f02: full_adder port map (Cin=>carry2, A=>modified_a(2), B=>modified_b(2), S=>sum(2), Cout=>carry3);
        f03: full_adder port map (Cin=>carry3, A=>modified_a(3), B=>modified_b(3), S=>sum(3), Cout=>carry4);
        f04: full_adder port map (Cin=>carry4, A=>modified_a(4), B=>modified_b(4), S=>sum(4), Cout=>carry5);
        f05: full_adder port map (Cin=>carry5, A=>modified_a(5), B=>modified_b(5), S=>sum(5), Cout=>carry6);
        f06: full_adder port map (Cin=>carry6, A=>modified_a(6), B=>modified_b(6), S=>sum(6), Cout=>carry7);
        f07: full_adder port map (Cin=>carry7, A=>modified_a(7), B=>modified_b(7), S=>sum(7), Cout=>carry8);
        f08: full_adder port map (Cin=>carry8, A=>modified_a(8), B=>modified_b(8), S=>sum(8), Cout=>carry9);
        f09: full_adder port map (Cin=>carry9, A=>modified_a(9), B=>modified_b(9), S=>sum(9), Cout=>carry10);
        f10: full_adder port map (Cin=>carry10, A=>modified_a(10), B=>modified_b(10), S=>sum(10), Cout=>carry11);
        f11: full_adder port map (Cin=>carry11, A=>modified_a(11), B=>modified_b(11), S=>sum(11), Cout=>carry12);
        f12: full_adder port map (Cin=>carry12, A=>modified_a(12), B=>modified_b(12), S=>sum(12), Cout=>carry13);
        f13: full_adder port map (Cin=>carry13, A=>modified_a(13), B=>modified_b(13), S=>sum(13), Cout=>carry14);
        f14: full_adder port map (Cin=>carry14, A=>modified_a(14), B=>modified_b(14), S=>sum(14), Cout=>carry15);
        f15: full_adder port map (Cin=>carry15, A=>modified_a(15), B=>modified_b(15), S=>sum(15), Cout=>carry16);
        f16: full_adder port map (Cin=>carry16, A=>modified_a(16), B=>modified_b(16), S=>sum(16), Cout=>carry17);
        f17: full_adder port map (Cin=>carry17, A=>modified_a(17), B=>modified_b(17), S=>sum(17), Cout=>carry18);
        f18: full_adder port map (Cin=>carry18, A=>modified_a(18), B=>modified_b(18), S=>sum(18), Cout=>carry19);
        f19: full_adder port map (Cin=>carry19, A=>modified_a(19), B=>modified_b(19), S=>sum(19), Cout=>carry20);
        f20: full_adder port map (Cin=>carry20, A=>modified_a(20), B=>modified_b(20), S=>sum(20), Cout=>carry21);
        f21: full_adder port map (Cin=>carry21, A=>modified_a(21), B=>modified_b(21), S=>sum(21), Cout=>carry22);
        f22: full_adder port map (Cin=>carry22, A=>modified_a(22), B=>modified_b(22), S=>sum(22), Cout=>carry23);
        f23: full_adder port map (Cin=>carry23, A=>modified_a(23), B=>modified_b(23), S=>sum(23), Cout=>carry24);
        f24: full_adder port map (Cin=>carry24, A=>modified_a(24), B=>modified_b(24), S=>sum(24), Cout=>carry25);
        f25: full_adder port map (Cin=>carry25, A=>modified_a(25), B=>modified_b(25), S=>sum(25), Cout=>carry26);
        f26: full_adder port map (Cin=>carry26, A=>modified_a(26), B=>modified_b(26), S=>sum(26), Cout=>carry27);
        f27: full_adder port map (Cin=>carry27, A=>modified_a(27), B=>modified_b(27), S=>sum(27), Cout=>carry28);
        f28: full_adder port map (Cin=>carry28, A=>modified_a(28), B=>modified_b(28), S=>sum(28), Cout=>carry29);
        f29: full_adder port map (Cin=>carry29, A=>modified_a(29), B=>modified_b(29), S=>sum(29), Cout=>carry30);
        f30: full_adder port map (Cin=>carry30, A=>modified_a(30), B=>modified_b(30), S=>sum(30), Cout=>carry31);
        f31: full_adder port map (Cin=>carry31, A=>modified_a(31), B=>modified_b(31), S=>sum(31), Cout=>carry32);


        P <= sum(2*N-1 downto 0);

        P_out <= P when start = '1' else
                (others => 'Z');

end beh_arch;