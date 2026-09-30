library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity synthesis is
    Port ( 
           clk, reset, load : in  STD_LOGIC;
           A : in  STD_LOGIC_VECTOR (7 downto 0);
           B : in  STD_LOGIC_VECTOR (7 downto 0);

           status : out std_logic;
           P : out  STD_LOGIC_VECTOR (15 downto 0));
end synthesis;

architecture Behavioral of synthesis is

    type arith_state is (idle, load_state, multiply, divide, add, output_state);
    signal state_next, state_reg : arith_state;

    signal array_strobe, divider_strobe, adder_strobe, load_strobe, output_strobe : std_logic;

    signal A_reg, B_reg, A_in, B_in : std_logic_vector(7 downto 0);

    signal mul_output, divider_output, adder_output, multi_output, divid_output, P_end : std_logic_vector(15 downto 0);

    signal P_reg : std_logic_vector(15 downto 0);

    component wallace_tree_multiplier is
        port(
            A : in std_logic_vector(7 downto 0);
            B : in std_logic_vector(7 downto 0);

            start : in std_logic;

            P : out std_logic_vector(15 downto 0)
    );
    end component;

    component divider_unit is
        port(
            A : in std_logic_vector(15 downto 0);
            start : in std_logic;

            D : out std_logic_vector(15 downto 0)
    );
    end component;


    component full_adder_16 is
        port(
            A : in std_logic_vector(15 downto 0);
            start : in std_logic;

            S : out std_logic_vector(15 downto 0);
            Cout : out std_logic
    );
    end component;
    
    begin 

    -- Multiplier
    multiplier : wallace_tree_multiplier port map(
        A => A_reg,
        B => B_reg,
        start => array_strobe,
        P => mul_output
    );

    -- Divider
    divider : divider_unit port map(
        A => multi_output,
        start => divider_strobe,
        D => divider_output
    );

    -- Adder
    adder : full_adder_16 port map(
        A => divid_output,
        start => adder_strobe,
        S => adder_output,
        Cout => open
    );
    
    -- State Register
    process(clk, reset)
    begin
        if reset = '0' then
            state_reg <= idle;
        elsif (clk' event and clk ='1')  then
            state_reg <= state_next;
        end if;
    end process;

    -- Register A
    process(clk, reset, load)
    begin
        if reset = '0' then
            A_reg <= (others => '0');
        elsif (clk' event and clk ='1') then
            if load = '1' then
                A_reg <= A_in;
            end if;
        end if;
    end process;

    -- Register B
    process(clk, reset, load)
    begin
        if reset = '0' then
            B_reg <= (others => '0');
        elsif (clk' event and clk ='1') then
            if load = '1' then
                B_reg <= B_in;
            end if;
        end if;
    end process;

    -- Load State Tristate
    A_in <= A when load_strobe = '1' else (others => 'Z');
    B_in <= B when load_strobe = '1' else (others => 'Z');

    -- Multiplier Output Register
    process(clk, reset)
    begin
        if reset = '0' then
            multi_output <= (others => '0');
        elsif (clk' event and clk ='1') then
            multi_output <= mul_output;
        end if;
    end process;

    -- Divider Output Register
    process(clk, reset)
    begin
        if reset = '0' then
            divid_output <= (others => '0');
        elsif (clk' event and clk ='1') then
            divid_output <= divider_output;
        end if;
    end process;


    -- Register P
    process(clk, reset)
    begin
        if reset = '0' then
            P_reg <= (others => '0');
        elsif (clk' event and clk ='1') then
                P_reg <= adder_output;
        end if;
    end process;

    -- State Next Logic
    process(state_reg, load)
    begin
        load_strobe <= '0';
        array_strobe <= '0';
        divider_strobe <= '0';
        adder_strobe <= '0';
        output_strobe <= '0';
        case state_reg is 
            when idle =>
                if load = '1' then
                    state_next <= load_state;
                else
                    state_next <= idle;
                end if;
            when load_state =>
                load_strobe <= '1';
                array_strobe <= '0';
                divider_strobe <= '0';
                adder_strobe <= '0';
                output_strobe <= '0';

                state_next <= multiply;
            when multiply =>
                load_strobe <= '0';
                array_strobe <= '1';
                divider_strobe <= '0';
                adder_strobe <= '0';
                output_strobe <= '0';

                state_next <= divide;
            when divide =>
                load_strobe <= '0';
                array_strobe <= '0';
                divider_strobe <= '1';
                adder_strobe <= '0';
                output_strobe <= '0';

                state_next <= add;
            when add =>
                load_strobe <= '0';
                array_strobe <= '0';
                divider_strobe <= '0';
                adder_strobe <= '1';
                output_strobe <= '0';
            
                state_next <= output_state;
            when output_state =>
                output_strobe <= '1';   
                state_next <= idle;
        end case;
    end process;

    -- Output Logic
    process(state_reg)
    begin
        status <= '1';
        case state_reg is
            when idle =>
                status <= '0'; 
            when load_state =>
                status <= '0';
            when multiply =>
                status <= '0';
            when divide =>
                status <= '0';
            when add =>
                status <= '0';
            when output_state =>
                status <= '1';
        end case;
    end process;

    -- Output Logic
    P_end <= (others => '0') when output_strobe = '0' and reset = '1' else
         P_reg when output_strobe = '1';

    P <= P_end when output_strobe = '1' else (others => 'Z');

    --P <= P_end when output_strobe = '1';

    end Behavioral;

