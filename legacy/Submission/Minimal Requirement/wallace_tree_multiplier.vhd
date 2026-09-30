library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity wallace_tree_multiplier is
    port(
    A : in std_logic_vector(7 downto 0);
    B : in std_logic_vector(7 downto 0);

    start: in std_logic;

    P : out std_logic_vector(15 downto 0)
    );
end wallace_tree_multiplier;

architecture behavior of wallace_tree_multiplier is
    
    signal O1, O2, O3, O4, O5, O6, O7, O8, O9, O10, O11, O12, O13, O14, O15, O16 : std_logic; -- Output Signals
    
    signal I1, I2, I3, I4, I5, I6, I7, I8, I9, I10, I11, I12, I13, I14, I15, I16, I17, I18, I19, I20, I21, I22, 
    I23, I24, I25, I26, I27, I28, I29, I30, I31, I32, I33, I34, I35, I36, I37, I38, I39, I40, I41, I42, I43, I44, 
    I45, I46, I47, I48, I49, I50, I51, I52, I53, I54, I55, I56, I57, I58, I59, I60, I61, I62, I63 : std_logic; -- Intermediate Signals
    
    signal S1, S2, S3, S4, S5, S6, S7, S8, S9, S10, S11, S12, S13, S14, S15, S16, S17, S18, S19, S20, S21, S22, 
    S23, S24, S25, S26, S27, S28, S29, S30, S31, S32, S33, S34, S35, S36, S37, S38, S39, S40, S41, S42: std_logic;
    
    signal C1, C2, C3, C4, C5, C6, C7, C8, C9, C10, C11, C12, C13, C14, C15, C16, C17, C18, C19, C20, C21, C22, 
    C23, C24, C25, C26, C27, C28, C29, C30, C31, C32, C33, C34, C35, C36, C37, C38, C39, C40, C41, C42, C43, C44, C45, C46, C47, C48, C49, C50, C51, C52, C53, C54, C55 : std_logic; -- Carry Signals

    --signal P_out : std_logic_vector(15 downto 0); -- Output Signal


    component full_adder
        port (
            A, B, Cin: in std_logic;
            S, Cout: out std_logic
        );
    end component;

    component half_adder
        port (
            A, B: in std_logic;
            S, Cout: out std_logic
        );
    end component;

    component multiplier
        port (
            A, B: in std_logic;
            C: out std_logic
        );
    end component;

    begin

    --First Stage

    M1: multiplier port map(A => A(0), B => B(0), C => O1);

    M2: multiplier port map(A => A(1), B => B(0), C => I1); -- A1*B0
    M3: multiplier port map(A => A(0), B => B(1), C => I2); -- A0*B1
    HA1: half_adder port map(A => I1, B => I2, S => O2, Cout => C1); -- A1*B0 + A0*B1

    M4: multiplier port map(A => A(2), B => B(0), C => I3); -- A2*B0
    M5: multiplier port map(A => A(1), B => B(1), C => I4); -- A1*B1
    FA1: full_adder port map(A => I3, B => I4, Cin => C1, S => S1, Cout => C2); -- A2*B0 + A1*B1 + A1*B0 + A0*B1

    M6: multiplier port map(A => A(3), B => B(0), C => I5); -- A3*B0
    M7: multiplier port map(A => A(2), B => B(1), C => I6); -- A2*B1
    FA2: full_adder port map(A => I5, B => I6, Cin => C2, S => S2, Cout => C3); -- A3*B0 + A2*B1 + A2*B0 + A1*B1 + A1*B0 + A0*B1

    M8: multiplier port map(A => A(4), B => B(0), C => I7); -- A4*B0
    M9: multiplier port map(A => A(3), B => B(1), C => I8); -- A3*B1
    FA3: full_adder port map(A => I7, B => I8, Cin => C3, S => S3, Cout => C4); -- A4*B0 + A3*B1 + A3*B0 + A2*B1 + A2*B0 + A1*B1 + A1*B0 + A0*B1

    M10: multiplier port map(A => A(5), B => B(0), C => I9); -- A5*B0
    M11: multiplier port map(A => A(4), B => B(1), C => I10); -- A4*B1
    FA4: full_adder port map(A => I9, B => I10, Cin => C4, S => S4, Cout => C5); -- A5*B0 + A4*B1 + A4*B0 + A3*B1 + A3*B0 + A2*B1 + A2*B0 + A1*B1 + A1*B0 + A0*B1

    M12: multiplier port map(A => A(6), B => B(0), C => I11); -- A6*B0
    M13: multiplier port map(A => A(5), B => B(1), C => I12); -- A5*B1
    FA5: full_adder port map(A => I11, B => I12, Cin => C5, S => S5, Cout => C6); -- A6*B0 + A5*B1 + A5*B0 + A4*B1 + A4*B0 + A3*B1 + A3*B0 + A2*B1 + A2*B0 + A1*B1 + A1*B0 + A0*B1

    M14: multiplier port map(A => A(6), B => B(1), C => I13); -- A6*B1
    M15: multiplier port map(A => A(7), B => B(0), C => I14); -- A7*B0
    FA6: full_adder port map(A => I13, B => I14, Cin => C6, S => S6, Cout => C7); -- A6*B1 + A7*B0 + A6*B0 + A5*B1 + A5*B0 + A4*B1 + A4*B0 + A3*B1 + A3*B0 + A2*B1 + A2*B0 + A1*B1 + A1*B0 + A0*B1

    M16: multiplier port map(A => A(6), B => B(2), C => I15); -- A6*B2
    M17: multiplier port map(A => A(7), B => B(1), C => I16); -- A7*B1
    FA7: full_adder port map(A => I15, B => I16, Cin => C7, S => S7, Cout => C8); -- A6*B2 + A7*B1 + A7*B0 + A6*B1 + A6*B0 + A5*B1 + A5*B0 + A4*B1 + A4*B0 + A3*B1 + A3*B0 + A2*B1 + A2*B0 + A1*B1 + A1*B0 + A0*B1

    M18: multiplier port map(A => A(6), B => B(3), C => I17); -- A6*B3  
    M19: multiplier port map(A => A(7), B => B(2), C => I18); -- A7*B2
    FA8: full_adder port map(A => I17, B => I18, Cin => C8, S => S8, Cout => C9); -- A6*B3 + A7*B2 + A7*B1 + A7*B0 + A6*B2 + A6*B1 + A6*B0 + A5*B1 + A5*B0 + A4*B1 + A4*B0 + A3*B1 + A3*B0 + A2*B1 + A2*B0 + A1*B1 + A1*B0 + A0*B1

    M20: multiplier port map(A => A(6), B => B(4), C => I19); -- A6*B4
    M21: multiplier port map(A => A(7), B => B(3), C => I20); -- A7*B3
    FA9: full_adder port map(A => I19, B => I20, Cin => C9, S => S9, Cout => C10); -- A6*B4 + A7*B3 + A7*B2 + A7*B1 + A7*B0 + A6*B3 + A6*B2 + A6*B1 + A6*B0 + A5*B1 + A5*B0 + A4*B1 + A4*B0 + A3*B1 + A3*B0 + A2*B1 + A2*B0 + A1*B1 + A1*B0 + A0*B1

    M22: multiplier port map(A => A(6), B => B(5), C => I21); -- A6*B5
    M23: multiplier port map(A => A(7), B => B(4), C => I22); -- A7*B4
    FA10: full_adder port map(A => I21, B => I22, Cin => C10, S => S10, Cout => C11); -- A6*B5 + A7*B4 + A7*B3 + A7*B2 + A7*B1 + A7*B0 + A6*B4 + A6*B3 + A6*B2 + A6*B1 + A6*B0 + A5*B1 + A5*B0 + A4*B1 + A4*B0 + A3*B1 + A3*B0 + A2*B1 + A2*B0 + A1*B1 + A1*B0 + A0*B1

    M24: multiplier port map(A => A(6), B => B(6), C => I23); -- A6*B6
    M25: multiplier port map(A => A(7), B => B(5), C => I24); -- A7*B5
    FA11: full_adder port map(A => I23, B => I24, Cin => C11, S => S11, Cout => C12); -- A6*B6 + A7*B5 + A7*B4 + A7*B3 + A7*B2 + A7*B1 + A7*B0 + A6*B5 + A6*B4 + A6*B3 + A6*B2 + A6*B1 + A6*B0 + A5*B1 + A5*B0 + A4*B1 + A4*B0 + A3*B1 + A3*B0 + A2*B1 + A2*B0 + A1*B1 + A1*B0 + A0*B1

    M26: multiplier port map(A => A(6), B => B(7), C => I25); -- A6*B7
    M27: multiplier port map(A => A(7), B => B(6), C => I26); -- A7*B6
    FA12: full_adder port map(A => I25, B => I26, Cin => C12, S => S12, Cout => C13); -- A6*B7 + A7*B6 + A7*B5 + A7*B4 + A7*B3 + A7*B2 + A7*B1 + A7*B0 + A6*B6 + A6*B5 + A6*B4 + A6*B3 + A6*B2 + A6*B1 + A6*B0 + A5*B1 + A5*B0 + A4*B1 + A4*B0 + A3*B1 + A3*B0 + A2*B1 + A2*B0 + A1*B1 + A1*B0 + A0*B1

    M28: multiplier port map(A => A(7), B => B(7), C => I27); -- A7*B7
    AFA1: full_adder port map(A => I27, B => C13, Cin => C25, S => O15, Cout => O16); -- A7*B7 + A6*B7 + A7*B6 + A7*B5 + A7*B4 + A7*B3 + A7*B2 + A7*B1 + A7*B0 + A6*B6 + A6*B5 + A6*B4 + A6*B3 + A6*B2 + A6*B1 + A6*B0 + A5*B1 + A5*B0 + A4*B1 + A4*B0 + A3*B1 + A3*B0 + A2*B1 + A2*B0 + A1*B1 + A1*B0 + A0*B1

    --Second Stage

    M29: multiplier port map(A => A(0), B => B(2), C => I28); -- A0*B2
    HA2: half_adder port map(A => I28, B => S1, S => O3, Cout => C14); -- A0*B2 + A1*B0 + A0*B1

    M30: multiplier port map(A => A(1), B => B(2), C => I29); -- A1*B2
    FA13: full_adder port map(A => I29, B => S2, Cin => C14, S => S13, Cout => C15); -- A1*B2 + A2*B0 + A1*B1 + A1*B0 + A0*B1

    M31: multiplier port map(A => A(2), B => B(2), C => I30); -- A2*B2
    FA14: full_adder port map(A => I30, B => S3, Cin => C15, S => S14, Cout => C16); -- A2*B2 + A3*B0 + A2*B1 + A2*B0 + A1*B1 + A1*B0 + A0*B1

    M32: multiplier port map(A => A(3), B => B(2), C => I31); -- A3*B2
    FA15: full_adder port map(A => I31, B => S4, Cin => C16, S => S15, Cout => C17); -- A3*B2 + A4*B0 + A3*B1 + A3*B0 + A2*B1 + A2*B0 + A1*B1 + A1*B0 + A0*B1

    M33: multiplier port map(A => A(4), B => B(2), C => I32); -- A4*B2
    FA16: full_adder port map(A => I32, B => S5, Cin => C17, S => S16, Cout => C18); -- A4*B2 + A5*B0 + A4*B1 + A4*B0 + A3*B1 + A3*B0 + A2*B1 + A2*B0 + A1*B1 + A1*B0 + A0*B1

    M34: multiplier port map(A => A(5), B => B(2), C => I33); -- A5*B2
    FA17: full_adder port map(A => I33, B => S6, Cin => C18, S => S17, Cout => C19); -- A5*B2 + A6*B0 + A5*B1 + A5*B0 + A4*B1 + A4*B0 + A3*B1 + A3*B0 + A2*B1 + A2*B0 + A1*B1 + A1*B0 + A0*B1

    M35: multiplier port map(A => A(5), B => B(3), C => I34); -- A5*B3
    FA18: full_adder port map(A => I34, B => S7, Cin => C19, S => S18, Cout => C20); -- A5*B3 + A6*B1 + A5*B2 + A5*B1 + A5*B0 + A4*B2 + A4*B1 + A4*B0 + A3*B1 + A3*B0 + A2*B1 + A2*B0 + A1*B1 + A1*B0 + A0*B1

    M36: multiplier port map(A => A(5), B => B(4), C => I35); -- A5*B4
    FA19: full_adder port map(A => I35, B => S8, Cin => C20, S => S19, Cout => C21); -- A5*B4 + A6*B2 + A5*B3 + A5*B2 + A5*B1 + A5*B0 + A4*B3 + A4*B2 + A4*B1 + A4*B0 + A3*B1 + A3*B0 + A2*B1 + A2*B0 + A1*B1 + A1*B0 + A0*B1

    M37: multiplier port map(A => A(5), B => B(5), C => I36); -- A5*B5
    FA20: full_adder port map(A => I36, B => S9, Cin => C21, S => S20, Cout => C22); -- A5*B5 + A6*B3 + A5*B4 + A5*B3 + A5*B2 + A5*B1 + A5*B0 + A4*B4 + A4*B3 + A4*B2 + A4*B1 + A4*B0 + A3*B1 + A3*B0 + A2*B1 + A2*B0 + A1*B1 + A1*B0 + A0*B1

    M38: multiplier port map(A => A(5), B => B(6), C => I37); -- A5*B6
    FA21: full_adder port map(A => I37, B => S10, Cin => C22, S => S21, Cout => C23); -- A5*B6 + A6*B4 + A5*B5 + A5*B4 + A5*B3 + A5*B2 + A5*B1 + A5*B0 + A4*B5 + A4*B4 + A4*B3 + A4*B2 + A4*B1 + A4*B0 + A3*B1 + A3*B0 + A2*B1 + A2*B0 + A1*B1 + A1*B0 + A0*B1

    M39: multiplier port map(A => A(5), B => B(7), C => I38); -- A5*B7
    FA22: full_adder port map(A => I38, B => S11, Cin => C23, S => S22, Cout => C24); -- A5*B7 + A6*B5 + A5*B6 + A5*B5 + A5*B4 + A5*B3 + A5*B2 + A5*B1 + A5*B0 + A4*B6 + A4*B5 + A4*B4 + A4*B3 + A4*B2 + A4*B1 + A4*B0 + A3*B1 + A3*B0 + A2*B1 + A2*B0 + A1*B1 + A1*B0 + A0*B1

    AFA2: full_adder port map(A => S12, B => C24, Cin => C35, S => O14, Cout => C25); -- A7*B7 + A6*B7 + A7*B6 + A7*B5 + A7*B4 + A7*B3 + A7*B2 + A7*B1 + A7*B0 + A6*B6 + A6*B5 + A6*B4 + A6*B3 + A6*B2 + A6*B1 + A6*B0 + A5*B1 + A5*B0 + A4*B1 + A4*B0 + A3*B1 + A3*B0 + A2*B1 + A2*B0 + A1*B1 + A1*B0 + A0*B1

    --Third Stage

    M40: multiplier port map(A => A(0), B => B(3), C => I39); -- A0*B3
    HA3: half_adder port map(A => I39, B => S13, S => O4, Cout => C26); -- A0*B3 + A1*B2 + A0*B2 + A1*B1 + A0*B1

    M41: multiplier port map(A => A(1), B => B(3), C => I40); -- A1*B3
    FA23: full_adder port map(A => I40, B => S14, Cin => C26, S => S23, Cout => C27); -- A1*B3 + A2*B2 + A1*B2 + A2*B1 + A1*B1 + A1*B0 + A0*B1

    M42: multiplier port map(A => A(2), B => B(3), C => I41); -- A2*B3
    FA24: full_adder port map(A => I41, B => S15, Cin => C27, S => S24, Cout => C28); -- A2*B3 + A3*B2 + A2*B2 + A3*B1 + A2*B1 + A2*B0 + A1*B1 + A1*B0 + A0*B1

    M43: multiplier port map(A => A(3), B => B(3), C => I42); -- A3*B3
    FA25: full_adder port map(A => I42, B => S16, Cin => C28, S => S25, Cout => C29); -- A3*B3 + A4*B2 + A3*B2 + A4*B1 + A3*B1 + A3*B0 + A2*B1 + A2*B0 + A1*B1 + A1*B0 + A0*B1

    M44: multiplier port map(A => A(4), B => B(3), C => I43); -- A4*B3
    FA26: full_adder port map(A => I43, B => S17, Cin => C29, S => S26, Cout => C30); -- A4*B3 + A5*B2 + A4*B2 + A5*B1 + A4*B1 + A4*B0 + A3*B1 + A3*B0 + A2*B1 + A2*B0 + A1*B1 + A1*B0 + A0*B1

    M45: multiplier port map(A => A(4), B => B(4), C => I44); -- A4*B4
    FA27: full_adder port map(A => I44, B => S18, Cin => C30, S => S27, Cout => C31); -- A4*B4 + A5*B3 + A4*B3 + A5*B2 + A4*B2 + A5*B1 + A4*B1 + A4*B0 + A3*B1 + A3*B0 + A2*B1 + A2*B0 + A1*B1 + A1*B0 + A0*B1

    M46: multiplier port map(A => A(4), B => B(5), C => I45); -- A4*B5
    FA28: full_adder port map(A => I45, B => S19, Cin => C31, S => S28, Cout => C32); -- A4*B5 + A5*B4 + A4*B4 + A5*B3 + A4*B3 + A5*B2 + A4*B2 + A5*B1 + A4*B1 + A4*B0 + A3*B1 + A3*B0 + A2*B1 + A2*B0 + A1*B1 + A1*B0 + A0*B1

    M47: multiplier port map(A => A(4), B => B(6), C => I46); -- A4*B6
    FA29: full_adder port map(A => I46, B => S20, Cin => C32, S => S29, Cout => C33); -- A4*B6 + A5*B5 + A4*B5 + A5*B4 + A4*B4 + A5*B3 + A4*B3 + A5*B2 + A4*B2 + A5*B1 + A4*B1 + A4*B0 + A3*B1 + A3*B0 + A2*B1 + A2*B0 + A1*B1 + A1*B0 + A0*B1

    M48: multiplier port map(A => A(4), B => B(7), C => I47); -- A4*B7
    FA30: full_adder port map(A => I47, B => S21, Cin => C33, S => S30, Cout => C34); -- A4*B7 + A5*B6 + A4*B6 + A5*B5 + A4*B5 + A5*B4 + A4*B4 + A5*B3 + A4*B3 + A5*B2 + A4*B2 + A5*B1 + A4*B1 + A4*B0 + A3*B1 + A3*B0 + A2*B1 + A2*B0 + A1*B1 + A1*B0 + A0*B1

    AFA3: full_adder port map(A => S22, B => C34, Cin => C43, S => O13, Cout => C35); -- A7*B7 + A6*B7 + A7*B6 + A7*B5 + A7*B4 + A7*B3 + A7*B2 + A7*B1 + A7*B0 + A6*B6 + A6*B5 + A6*B4 + A6*B3 + A6*B2 + A6*B1 + A6*B0 + A5*B1 + A5*B0 + A4*B1 + A4*B0 + A3*B1 + A3*B0 + A2*B1 + A2*B0 + A1*B1 + A1*B0 + A0*B1


    --Fourth Stage

    M49: multiplier port map(A => A(0), B => B(4), C => I48); -- A0*B4
    HA4: half_adder port map(A => I48, B => S23, S => O5, Cout => C36); -- A0*B4 + A1*B3 + A0*B3 + A1*B2 + A0*B2 + A1*B1 + A0*B1

    M50: multiplier port map(A => A(1), B => B(4), C => I49); -- A1*B4
    FA31: full_adder port map(A => I49, B => S24, Cin => C36, S => S31, Cout => C37); -- A1*B4 + A2*B3 + A1*B3 + A2*B2 + A1*B2 + A2*B1 + A1*B1 + A1*B0 + A0*B1

    M51: multiplier port map(A => A(2), B => B(4), C => I50); -- A2*B4
    FA32: full_adder port map(A => I50, B => S25, Cin => C37, S => S32, Cout => C38); -- A2*B4 + A3*B3 + A2*B3 + A3*B2 + A2*B2 + A3*B1 + A2*B1 + A2*B0 + A1*B1 + A1*B0 + A0*B1

    M52: multiplier port map(A => A(3), B => B(4), C => I51); -- A3*B4
    FA33: full_adder port map(A => I51, B => S26, Cin => C38, S => S33, Cout => C39); -- A3*B4 + A4*B3 + A3*B3 + A4*B2 + A3*B2 + A4*B1 + A3*B1 + A3*B0 + A2*B1 + A2*B0 + A1*B1 + A1*B0 + A0*B1

    M53: multiplier port map(A => A(3), B => B(5), C => I52); -- A3*B5
    FA34: full_adder port map(A => I52, B => S27, Cin => C39, S => S34, Cout => C40); -- A3*B5 + A4*B4 + A3*B4 + A4*B3 + A3*B3 + A4*B2 + A3*B2 + A4*B1 + A3*B1 + A3*B0 + A2*B1 + A2*B0 + A1*B1 + A1*B0 + A0*B1

    M54: multiplier port map(A => A(3), B => B(6), C => I53); -- A3*B6
    FA35: full_adder port map(A => I53, B => S28, Cin => C40, S => S35, Cout => C41); -- A3*B6 + A4*B5 + A3*B5 + A4*B4 + A3*B4 + A4*B3 + A3*B3 + A4*B2 + A3*B2 + A4*B1 + A3*B1 + A3*B0 + A2*B1 + A2*B0 + A1*B1 + A1*B0 + A0*B1

    M55: multiplier port map(A => A(3), B => B(7), C => I54); -- A3*B7
    FA36: full_adder port map(A => I54, B => S29, Cin => C41, S => S36, Cout => C42); -- A3*B7 + A4*B6 + A3*B6 + A4*B5 + A3*B5 + A4*B4 + A3*B4 + A4*B3 + A3*B3 + A4*B2 + A3*B2 + A4*B1 + A3*B1 + A3*B0 + A2*B1 + A2*B0 + A1*B1 + A1*B0 + A0*B1

    AFA4: full_adder port map(A => S30, B => C42, Cin => C49, S => O12, Cout => C43); -- A7*B7 + A6*B7 + A7*B6 + A7*B5 + A7*B4 + A7*B3 + A7*B2 + A7*B1 + A7*B0 + A6*B6 + A6*B5 + A6*B4 + A6*B3 + A6*B2 + A6*B1 + A6*B0 + A5*B1 + A5*B0 + A4*B1 + A4*B0 + A3*B1 + A3*B0 + A2*B1 + A2*B0 + A1*B1 + A1*B0 + A0*B1

    --Fifth Stage

    M56: multiplier port map(A => A(0), B => B(5), C => I55); -- A0*B5
    HA5: half_adder port map(A => I55, B => S31, S => O6, Cout => C44); -- A0*B5 + A1*B4 + A0*B4 + A1*B3 + A0*B3 + A1*B2 + A0*B2 + A1*B1 + A0*B1

    M57: multiplier port map(A => A(1), B => B(5), C => I56); -- A1*B5
    FA37: full_adder port map(A => I56, B => S32, Cin => C44, S => S37, Cout => C45); -- A1*B5 + A2*B4 + A1*B4 + A2*B3 + A1*B3 + A2*B2 + A1*B2 + A2*B1 + A1*B1 + A1*B0 + A0*B1

    M58: multiplier port map(A => A(2), B => B(5), C => I57); -- A2*B5
    FA38: full_adder port map(A => I57, B => S33, Cin => C45, S => S38, Cout => C46); -- A2*B5 + A3*B4 + A2*B4 + A3*B3 + A2*B3 + A3*B2 + A2*B2 + A3*B1 + A2*B1 + A2*B0 + A1*B1 + A1*B0 + A0*B1

    M59: multiplier port map(A => A(2), B => B(6), C => I58); -- A2*B6
    FA39: full_adder port map(A => I58, B => S34, Cin => C46, S => S39, Cout => C47); -- A2*B6 + A3*B5 + A2*B5 + A3*B4 + A2*B4 + A3*B3 + A2*B3 + A3*B2 + A2*B2 + A3*B1 + A2*B1 + A2*B0 + A1*B1 + A1*B0 + A0*B1

    M60: multiplier port map(A => A(2), B => B(7), C => I59); -- A2*B7
    FA40: full_adder port map(A => I59, B => S35, Cin => C47, S => S40, Cout => C48); -- A2*B7 + A3*B6 + A2*B6 + A3*B5 + A2*B5 + A3*B4 + A2*B4 + A3*B3 + A2*B3 + A3*B2 + A2*B2 + A3*B1 + A2*B1 + A2*B0 + A1*B1 + A1*B0 + A0*B1

    AFA5: full_adder port map(A => S36, B => C48, Cin => C53, S => O11, Cout => C49); -- A7*B7 + A6*B7 + A7*B6 + A7*B5 + A7*B4 + A7*B3 + A7*B2 + A7*B1 + A7*B0 + A6*B6 + A6*B5 + A6*B4 + A6*B3 + A6*B2 + A6*B1 + A6*B0 + A5*B1 + A5*B0 + A4*B1 + A4*B0 + A3*B1 + A3*B0 + A2*B1 + A2*B0 + A1*B1 + A1*B0 + A0*B1

    --Sixth Stage

    M61: multiplier port map(A => A(0), B => B(6), C => I60); -- A0*B6
    HA6: half_adder port map(A => I60, B => S37, S => O7, Cout => C50); -- A0*B6 + A1*B5 + A0*B5 + A1*B4 + A0*B4 + A1*B3 + A0*B3 + A1*B2 + A0*B2 + A1*B1 + A0*B1

    M62: multiplier port map(A => A(1), B => B(6), C => I61); -- A1*B6
    FA41: full_adder port map(A => I61, B => S38, Cin => C50, S => S41, Cout => C51); -- A1*B6 + A2*B5 + A1*B5 + A2*B4 + A1*B4 + A2*B3 + A1*B3 + A2*B2 + A1*B2 + A2*B1 + A1*B1 + A1*B0 + A0*B1

    M63: multiplier port map(A => A(1), B => B(7), C => I62); -- A1*B7
    FA42: full_adder port map(A => I62, B => S39, Cin => C51, S => S42, Cout => C52); -- A1*B7 + A2*B6 + A1*B6 + A2*B5 + A1*B5 + A2*B4 + A1*B4 + A2*B3 + A1*B3 + A2*B2 + A1*B2 + A2*B1 + A1*B1 + A1*B0 + A0*B1 

    AFA6: full_adder port map(A => S40, B => C52, Cin => C55, S => O10, Cout => C53); -- A7*B7 + A6*B7 + A7*B6 + A7*B5 + A7*B4 + A7*B3 + A7*B2 + A7*B1 + A7*B0 + A6*B6 + A6*B5 + A6*B4 + A6*B3 + A6*B2 + A6*B1 + A6*B0 + A5*B1 + A5*B0 + A4*B1 + A4*B0 + A3*B1 + A3*B0 + A2*B1 + A2*B0 + A1*B1 + A1*B0 + A0*B1
    
    --Seventh Stage

    M64: multiplier port map(A => A(0), B => B(7), C => I63); -- A0*B7
    HA7: half_adder port map(A => I63, B => S41, S => O8, Cout => C54); -- A0*B7 + A1*B6 + A0*B6 + A1*B5 + A0*B5 + A1*B4 + A0*B4 + A1*B3 + A0*B3 + A1*B2 + A0*B2 + A1*B1 + A0*B1

    HA8: half_adder port map(A => S42, B => C54, S => O9, Cout => C55); -- A1*B7 + A2*B6 + A1*B6 + A2*B5 + A1*B5 + A2*B4 + A1*B4 + A2*B3 + A1*B3 + A2*B2 + A1*B2 + A2*B1 + A1*B1 + A1*B0 + A0*B1

    --Output

    --P_out <= O16 & O15 & O14 & O13 & O12 & O11 & O10 & O9 & O8 & O7 & O6 & O5 & O4 & O3 & O2 & O1;

    P <= O16 & O15 & O14 & O13 & O12 & O11 & O10 & O9 & O8 & O7 & O6 & O5 & O4 & O3 & O2 & O1 when (start = '1') else
    'Z' & 'Z' & 'Z' & 'Z' & 'Z' & 'Z' & 'Z' & 'Z' & 'Z' & 'Z' & 'Z' & 'Z' & 'Z' & 'Z' & 'Z' & 'Z';


    end behavior;