library IEEE;
use IEEE.STD_LOGIC_1164.ALL; 

entity synthesis is
	generic (N: INTEGER:= 8); -- N is the number of bits in the input numbers
 	port (A,B: in std_logic_vector (N-1 downto 0); -- Input numbers
	 	mode: in std_logic;	-- '0' for unsigned and '1' for signed
		start : in std_logic;

 		P_out: out std_logic_vector (2*N-1 downto 0)); -- Output product
end synthesis;   

architecture structural_generic of synthesis is
 	component full_adder is
        port(
            A : in std_logic;
            B : in std_logic;
            Cin : in std_logic;
    
            S : out std_logic;
            Cout : out std_logic
        );
 	end component;
 
	type signal_array is array (natural range <>, natural range <>) of std_logic;

 	signal ab: signal_array(N-1 downto 0, N-1 downto 0);
 	signal sum: signal_array(N downto 0, N downto 0);
 	signal carry: signal_array(N downto 0, N-1 downto 0);
	signal cpa_in: std_logic_vector (N downto 0);

	signal P : std_logic_vector (2*N-1 downto 0);

begin
	-- Array of N*N full adders: CSA --
 	horizontal_stack: for i in 0 to N-1 generate -- to generate rows
 		vertical_stack: for j in 0 to N-1 generate -- to generate columns
 			-- Mode Independent Cells --
			signed_independent: if (i < N-1 and j < N-1) or (i = N-1 and j = N-1) generate
				ab(i,j) <= A(i) and B(j);
				fij: Full_Adder port map 
					(Cin => carry(i,j), A => sum(i,j+1) , B => ab(i,j),
                    S => sum(i+1,j), Cout => carry(i+1,j));
			end generate;
			-- Mode Dependent Cells --
			signed_dependent: if (i < N-1 and j = N-1) or (i = N-1 and j < N-1) generate
				ab(i,j) <= mode xor (A(i) and B(j));
				fij: Full_Adder port map 
					(Cin => carry(i,j), A => sum(i,j+1) , B => ab(i,j),
                    S => sum(i+1,j), Cout => carry(i+1,j));
 			end generate;
 		end generate;
 	end generate;
	
	-- Last row : CPA --
 	horizontal_stack_last: for j in 0 to N-1 generate
		P(j) <= sum(j+1,0);
 		carry(0,j) <= '0';
		sum(0,j+1) <= '0';
		-- CPA cell --
	 	flj: full_adder port map 
			(Cin => carry(N,j), A => sum(N,j+1) , B => cpa_in(j),
            S => P(N+j), Cout => cpa_in(j+1)); 
		ini: if j>1 generate
			sum(j,N) <= '0';
		end generate;
	end generate;
	
	sum(N,N) <= mode;
	sum(1,N) <= mode;
	cpa_in(0) <= '0';

	P_out <= P when (start = '1') else
		 	(others => 'Z');
	
end structural_generic;