library IEEE;
use IEEE.STD_LOGIC_1164.ALL; 
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.NUMERIC_STD.ALL;

entity divider_2c is
	generic (N: INTEGER:= 8 ; K: INTEGER:= 32); -- N is the number of bits in the input numbers
    --generic (); -- K is the max number of bits
 	port (A : in std_logic_vector (2*N-1 downto 0); -- Input numbers
          C : in std_logic_vector (N-1 downto 0); -- Input shift amount
          mode: in std_logic;	-- '0' for unsigned and '1' for signed

 		  P: out std_logic_vector (2*N-1 downto 0)); -- Output product
end divider_2c;   

-- architecture of a divider that divides an input by 2^C for both signed and unsigned numbers upto a maxiumum of 32 bit input

architecture Behavioral of divider_2c is

    --signal C_in : std_logic_vector (4 downto 0) := C(4 downto 0); -- Input shift amount
    --signal concat_out : std_logic_vector (31 downto 0); -- Output product
    --signal concat_zeroes : std_logic_vector () := (others => '0'); -- Output product

    signal just_A : std_logic_vector(2*N-1 downto 0);

    signal remaining_bits_zeroes : std_logic_vector ((K-(2*N-1))-2 downto 0); -- Output product

    signal remaining_bits_ones : std_logic_vector ((K-(2*N-1))-2 downto 0);

    --signal modified_c : std_logic_vector (31 downto 0); -- Input shift amount

    signal modified_a_unsigned : std_logic_vector (31 downto 0); -- Input shift amount

    signal modified_a_signed : std_logic_vector (31 downto 0); -- Input shift amount

    signal concat_out_unsigned, concat_out_signed : std_logic_vector (31 downto 0) := (others => '0'); -- Output product

    signal c_check : std_logic_vector (4 downto 0); -- Input shift amount

    
    
begin
    remaining_bits_zeroes <= (others => '0');
    remaining_bits_ones <= (others => '1');

    just_A <= A;
    modified_a_unsigned <= remaining_bits_zeroes & just_A; -- Zeroes are concatenated to the input number to make the output product 2N bits long
    modified_a_signed <= remaining_bits_ones & just_A; -- Zeroes are concatenated to the input number to make the output product 2N bits long

    --modified_c <= remaining_bits & C; -- Zeroes are concatenated to the input number to make the output product 2N bits long
    c_check <= C(4 downto 0);
    -- Zeroes are concatenated to the input number to make the output product 2N bits long
    --concat_out <= concat_zeroes & A(2*N-1 downto 0);

        concat_out_unsigned <= modified_a_unsigned(31 downto 0) when (c_check = "00000") else -- shift by 0
                    '0' & modified_a_unsigned(31 downto 1) when (c_check ="00001") else -- shift by 1
                    "00" & modified_a_unsigned(31 downto 2) when (c_check ="00010") else -- shift by 2
                    "000" & modified_a_unsigned(31 downto 3) when (c_check ="00011") else -- shift by 3
                    "0000" & modified_a_unsigned(31 downto 4) when (c_check ="00100") else -- shift by 4
                    "00000" & modified_a_unsigned(31 downto 5) when (c_check ="00101") else -- shift by 5
                    "000000" & modified_a_unsigned(31 downto 6) when (c_check ="00110") else -- shift by 6
                    "0000000" & modified_a_unsigned(31 downto 7) when (c_check ="00111") else -- shift by 7
                    "00000000" & modified_a_unsigned(31 downto 8) when (c_check ="01000") else -- shift by 8
                    "000000000" & modified_a_unsigned(31 downto 9) when (c_check ="01001") else -- shift by 9
                    "0000000000" & modified_a_unsigned(31 downto 10) when (c_check ="01010") else -- shift by 10
                    "00000000000" & modified_a_unsigned(31 downto 11) when (c_check ="01011") else -- shift by 11
                    "000000000000" & modified_a_unsigned(31 downto 12) when (c_check ="01100") else -- shift by 12
                    "0000000000000" & modified_a_unsigned(31 downto 13) when (c_check ="01101") else -- shift by 13
                    "00000000000000" & modified_a_unsigned(31 downto 14) when (c_check ="01110") else -- shift by 14
                    "000000000000000" & modified_a_unsigned(31 downto 15) when (c_check ="01111") else -- shift by 15
                    "0000000000000000" & modified_a_unsigned(31 downto 16) when (c_check ="10000") else -- shift by 16
                    "00000000000000000" & modified_a_unsigned(31 downto 17) when (c_check ="10001") else -- shift by 17
                    "000000000000000000" & modified_a_unsigned(31 downto 18) when (c_check ="10010") else -- shift by 18
                    "0000000000000000000" & modified_a_unsigned(31 downto 19) when (c_check ="10011") else -- shift by 19
                    "00000000000000000000" & modified_a_unsigned(31 downto 20) when (c_check ="10100") else -- shift by 20
                    "000000000000000000000" & modified_a_unsigned(31 downto 21) when (c_check ="10101") else -- shift by 21
                    "0000000000000000000000" & modified_a_unsigned(31 downto 22) when (c_check ="10110") else -- shift by 22
                    "00000000000000000000000" & modified_a_unsigned(31 downto 23) when (c_check ="10111") else -- shift by 23
                    "000000000000000000000000" & modified_a_unsigned(31 downto 24) when (c_check ="11000") else -- shift by 24
                    "0000000000000000000000000" & modified_a_unsigned(31 downto 25) when (c_check ="11001") else -- shift by 25
                    "00000000000000000000000000" & modified_a_unsigned(31 downto 26) when (c_check ="11010") else -- shift by 26
                    "000000000000000000000000000" & modified_a_unsigned(31 downto 27) when (c_check ="11011") else -- shift by 27
                    "0000000000000000000000000000" & modified_a_unsigned(31 downto 28) when (c_check ="11100") else -- shift by 28
                    "00000000000000000000000000000" & modified_a_unsigned(31 downto 29) when (c_check ="11101") else -- shift by 29
                    "000000000000000000000000000000" & modified_a_unsigned(31 downto 30) when (c_check ="11110") else -- shift by 30
                    "00000000000000000000000000000000"; -- shift by 31

        concat_out_signed <= modified_a_signed(31 downto 0) when (c_check = "00000") else -- shift by 0
                    '1' & modified_a_signed(31 downto 1) when (c_check ="00001") else -- shift by 1
                    "11" & modified_a_signed(31 downto 2) when (c_check ="00010") else -- shift by 2
                    "111" & modified_a_signed(31 downto 3) when (c_check ="00011") else -- shift by 3
                    "1111" & modified_a_signed(31 downto 4) when (c_check ="00100") else -- shift by 4
                    "11111" & modified_a_signed(31 downto 5) when (c_check ="00101") else -- shift by 5
                    "111111" & modified_a_signed(31 downto 6) when (c_check ="00110") else -- shift by 6
                    "1111111" & modified_a_signed(31 downto 7) when (c_check ="00111") else -- shift by 7
                    "11111111" & modified_a_signed(31 downto 8) when (c_check ="01000") else -- shift by 8
                    "111111111" & modified_a_signed(31 downto 9) when (c_check ="01001") else -- shift by 9
                    "1111111111" & modified_a_signed(31 downto 10) when (c_check ="01010") else -- shift by 10
                    "11111111111" & modified_a_signed(31 downto 11) when (c_check ="01011") else -- shift by 11
                    "111111111111" & modified_a_signed(31 downto 12) when (c_check ="01100") else -- shift by 12
                    "1111111111111" & modified_a_signed(31 downto 13) when (c_check ="01101") else -- shift by 13
                    "11111111111111" & modified_a_signed(31 downto 14) when (c_check ="01110") else -- shift by 14
                    "111111111111111" & modified_a_signed(31 downto 15) when (c_check ="01111") else -- shift by 15
                    "1111111111111111" & modified_a_signed(31 downto 16) when (c_check ="10000") else -- shift by 16
                    "11111111111111111" & modified_a_signed(31 downto 17) when (c_check ="10001") else -- shift by 17
                    "111111111111111111" & modified_a_signed(31 downto 18) when (c_check ="10010") else -- shift by 18
                    "1111111111111111111" & modified_a_signed(31 downto 19) when (c_check ="10011") else -- shift by 19
                    "11111111111111111111" & modified_a_signed(31 downto 20) when (c_check ="10100") else -- shift by 20
                    "111111111111111111111" & modified_a_signed(31 downto 21) when (c_check ="10101") else -- shift by 21
                    "1111111111111111111111" & modified_a_signed(31 downto 22) when (c_check ="10110") else -- shift by 22
                    "11111111111111111111111" & modified_a_signed(31 downto 23) when (c_check ="10111") else -- shift by 23
                    "111111111111111111111111" & modified_a_signed(31 downto 24) when (c_check ="11000") else -- shift by 24
                    "1111111111111111111111111" & modified_a_signed(31 downto 25) when (c_check ="11001") else -- shift by 25
                    "11111111111111111111111111" & modified_a_signed(31 downto 26) when (c_check ="11010") else -- shift by 26
                    "111111111111111111111111111" & modified_a_signed(31 downto 27) when (c_check ="11011") else -- shift by 27
                    "1111111111111111111111111111" & modified_a_signed(31 downto 28) when (c_check ="11100") else -- shift by 28
                    "11111111111111111111111111111" & modified_a_signed(31 downto 29) when (c_check ="11101") else -- shift by 29
                    "111111111111111111111111111111" & modified_a_signed(31 downto 30) when (c_check ="11110") else -- shift by 30
                    "11111111111111111111111111111111"; -- shift by 31
                            
                    

    --P <= concat_out; -- Output product
    p <= concat_out_unsigned(2*N-1 downto 0) when (mode = '0') else
         concat_out_signed(2*N-1 downto 0); -- Output product

   

end Behavioral;


