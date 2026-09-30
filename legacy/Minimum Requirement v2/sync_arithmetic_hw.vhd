library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity sync_arithmetic_hw is
    Port ( 
           clk, reset, load : in  STD_LOGIC;
           A : in  STD_LOGIC_VECTOR (7 downto 0);
           B : in  STD_LOGIC_VECTOR (7 downto 0);

           status : out std_logic;
           P : out  STD_LOGIC_VECTOR (15 downto 0));
end sync_arithmetic_hw;

architecture Behavioral of sync_arithmetic_hw is

    type mc_state is (idle, done);
    signal state_next, state : mc_state;

    signal A_reg, B_reg : std_logic_vector(7 downto 0);
    signal P_reg : std_logic_vector(15 downto 0);

    signal state_reg : std_logic;

    component arithmetic_hw is 
        Port ( 
               A : in  STD_LOGIC_VECTOR (7 downto 0);
               B : in  STD_LOGIC_VECTOR (7 downto 0);

               P : out  STD_LOGIC_VECTOR (15 downto 0));
    end component;

    component register_dq_8 is
        port(
        clk, reset : in std_logic;
        d : in std_logic_vector(7 downto 0);
        q : out std_logic_vector(7 downto 0)
    );
    end component;

    component register_dq_16 is
        port(
        clk, reset : in std_logic;
        d : in std_logic_vector(15 downto 0);
        q : out std_logic_vector(15 downto 0)
    );
    end component;

    component register_dq_1 is
        port(
        clk, reset : in std_logic;
        d : in std_logic;
        q : out std_logic
    );
    end component;

begin

    arithmetic : arithmetic_hw port map(A => A_reg, B => B_reg, P => P_reg);

    A_reg_d : register_dq_8 port map(clk => clk, reset => reset, d => A, q => A_reg);
    B_reg_d : register_dq_8 port map(clk => clk, reset => reset, d => B, q => B_reg);

    P_reg_d : register_dq_16 port map(clk => clk, reset => reset, d => P_reg, q => P);

    status_reg_d : register_dq_1 port map(clk => clk, reset => reset, d => state_reg, q => status);

    -- state register
    process(clk, reset)
    begin
        if reset = '1' then
            state <= idle;
        elsif rising_edge(clk) then
            state <= state_next;
        end if;
    end process;

    -- next state logic
    
    process(state, load)
    begin
        case state is
            when idle =>
                if load = '1' then
                    state_next <= load_A;
                else
                    state_next <= idle;
                end if;
            when done =>
                if load = '0' then
                    state_next <= idle;
                else
                    state_next <= done;
                end if;
            when others =>
                state_next <= done;
                end case;
    end process;

    -- Moore output logic

    process(state)
    begin
        case state is
            when idle =>
                state_reg <= '0';
            when done =>
                state_reg <= '1';
        end case;
    end process;

    status <= state_reg;
    

end Behavioral;
