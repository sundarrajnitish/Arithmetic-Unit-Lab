library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity wallace_tree_multiplier is
  generic (N: INTEGER := 8);
  port (A, B: in std_logic_vector(N-1 downto 0);
        mode: in std_logic; -- '0' for unsigned and '1' for signed
        P: out std_logic_vector(2*N-1 downto 0));
end wallace_tree_multiplier;

architecture wallace_tree_architecture of wallace_tree_multiplier is
  signal partial_products: std_logic_vector(N-1 downto 0);
  signal sum_array: array(0 to N-1) of std_logic_vector(N-1 downto 0);
  signal carry: std_logic_vector(N-1 downto 0);

  component full_adder is
    port (
      A, B, Cin: in std_logic;
      S, Cout: out std_logic
    );
  end component;

begin
  -- Generate partial products
  partial_products_generation: for i in 0 to N-1 generate
    if mode = '0' then
      partial_products(i) <= (others => '0');
      partial_products(i)(i downto 0) <= (others => '0') & A;
      partial_products(i) <= partial_products(i) and B(i);
    else -- Mode is '1' for signed numbers
      partial_products(i) <= (others => '0');
      partial_products(i)(i downto 0) <= (others => A(N-1)) & A;
      partial_products(i) <= partial_products(i) and B(i);
    end if;
  end generate;

  -- Generate sum_array
  sum_array_generation: for i in 0 to N-1 generate
    sum_array(i) <= (others => '0');
    sum_array(i)(i downto 0) <= partial_products(i);
  end generate;

  -- Generate Wallace Tree
  tree_generation: for level in 1 to N-1 generate
    level_reduction: for i in 0 to N-2-level generate
      process (sum_array(i), sum_array(i+1), carry(i))
      begin
        sum_array(i) <= (others => '0');
        carry(i) <= '0';
        full_adder_inst: for j in 0 to N-1 generate
          full_adder_port: full_adder port map (
            A => sum_array(i)(j),
            B => sum_array(i+1)(j),
            Cin => carry(i),
            S => sum_array(i)(j),
            Cout => carry(i)
          );
        end generate;
      end process;
    end generate;
  end generate;

  -- Output the final product
  P <= (others => '0');
  for i in 0 to N-1 loop
    P(i+N-1 downto i) <= P(i+N-1 downto i) + sum_array(0)(N-1 downto 0);
  end loop;

end wallace_tree_architecture;
