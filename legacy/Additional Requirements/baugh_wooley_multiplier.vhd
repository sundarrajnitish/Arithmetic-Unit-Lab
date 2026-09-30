library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity baugh_wooler_multiplier is
    port(
    A : in std_logic_vector(7 downto 0);
    B : in std_logic_vector(7 downto 0);

    P : out std_logic_vector(15 downto 0)
    );
end baugh_wooler_multiplier;

architecture behavior of baugh_wooler_multiplier is
    
    signal O1, O2, O3, O4, O5, O6, O7, O8, O9, O10, O11, O12, O13, O14, O15, O16 : std_logic; -- Output Signals
    
    signal I1, I2, I3, I4, I5, I6, I7, I8, I9, I10, I11, I12, I13, I14, I15, I16, I17, I18, I19, I20, I21, I22, 
    I23, I24, I25, I26, I27, I28, I29, I30, I31, I32, I33, I34, I35, I36, I37, I38, I39, I40, I41, I42, I43, I44, 
    I45, I46, I47, I48, I49, I50, I51, I52, I53, I54, I55, I56, I57, I58, I59, I60, I61, I62, I63 : std_logic; -- Intermediate Signals
    
    signal S1, S2, S3, S4, S5, S6, S7, S8, S9, S10, S11, S12, S13, S14, S15, S16, S17, S18, S19, S20, S21, S22, 
    S23, S24, S25, S26, S27, S28, S29, S30, S31, S32, S33, S34, S35, S36, S37, S38, S39, S40, S41, S42, S43, S44 : std_logic;
    
    signal C1, C2, C3, C4, C5, C6, C7, C8, C9, C10, C11, C12, C13, C14, C15, C16, C17, C18, C19, C20, C21, C22, 
    C23, C24, C25, C26, C27, C28, C29, C30, C31, C32, C33, C34, C35, C36, C37, C38, C39, C40, C41, C42, C43, C44, C45, C46, C47, C48, C49, C50, C51, C52, C53, C54, C55, C56, C57, C58, C59 : std_logic;

    signal N1, N2, N3, N4, N5, N6, N7, N8, N9, N10, N11, N12, N13, N14, N15, N16 : std_logic; -- NOT Signals

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

    component not_gate
        port (
            A: in std_logic;
            B: out std_logic
        );
    end component;

    begin
    
    --First Stage
    M1: multiplier port map(A => A(0), B => B(0), C => O1); -- A0 * B0

    M2: multiplier port map(A => A(0), B => B(0), C => I1); -- A0 * B0
    M3: multiplier port map(A => A(1), B => B(0), C => I2); -- A1 * B0
    HA1: half_adder port map(A => I1, B => I2, S => O2, Cout => C1); -- A1 * B0 + A0 * B1 (First Half Adder)

    M4: multiplier port map(A => A(1), B => B(1), C => I3); -- A1 * B1
    M5: multiplier port map(A => A(2), B => B(0), C => I4); -- A2 * B0
    HA2: half_adder port map(A => I3, B => I4, S => S1, Cout => C2); -- A1 * B1 + A2 * B0 (Second Half Adder)

    M6: multiplier port map(A => A(2), B => B(1), C => I5); -- A2 * B1
    M7: multiplier port map(A => A(3), B => B(0), C => I6); -- A3 * B0
    HA3: half_adder port map(A => I5, B => I6, S => S2, Cout => C3); -- A2 * B1 + A3 * B0 (Third Half Adder)

    M8: multiplier port map(A => A(3), B => B(1), C => I7); -- A3 * B1
    M9: multiplier port map(A => A(4), B => B(0), C => I8); -- A4 * B0
    HA4: half_adder port map(A => I7, B => I8, S => S3, Cout => C4); -- A3 * B1 + A4 * B0 (Fourth Half Adder)

    M10: multiplier port map(A => A(4), B => B(1), C => I9); -- A4 * B1
    M11: multiplier port map(A => A(5), B => B(0), C => I10); -- A5 * B0
    HA5: half_adder port map(A => I9, B => I10, S => S4, Cout => C5); -- A4 * B1 + A5 * B0 (Fifth Half Adder)

    M12: multiplier port map(A => A(5), B => B(1), C => I11); -- A5 * B1
    M13: multiplier port map(A => A(6), B => B(0), C => I12); -- A6 * B0
    HA6: half_adder port map(A => I11, B => I12, S => S5, Cout => C6); -- A5 * B1 + A6 * B0 (Sixth Half Adder)

    M14: multiplier port map(A => A(6), B => B(1), C => I13); -- A6 * B1
    NOT1: not_gate port map(A => B(0), B => N1); -- NOT B0
    M15: multiplier port map(A => A(7), B => N1, C => I14); -- A7 * NOT B0
    HA7: half_adder port map(A => I13, B => I14, S => S6, Cout => C7); -- A6 * B1 + A7 * NOT B0 (Seventh Half Adder)

    --Correct

    --Second Stage 

    M16: multiplier port map(A => A(0), B => B(2), C => I15); -- A0 * B2
    FA1: full_adder port map(A => I15, B => S1, Cin => C1, S => O3, Cout => C8); -- A0 * B0 + A1 * B0 + A0 * B1 (First Full Adder)
    
    M17: multiplier port map(A => A(1), B => B(2), C => I16); -- A1 * B2
    FA2: full_adder port map(A => I16, B => S2, Cin => C2, S => S7, Cout => C9); -- A1 * B1 + A2 * B0 + A1 * B2 (Second Full Adder)

    M18: multiplier port map(A => A(2), B => B(2), C => I17); -- A2 * B2
    FA3: full_adder port map(A => I17, B => S3, Cin => C3, S => S8, Cout => C10); -- A2 * B1 + A3 * B0 + A2 * B2 (Third Full Adder)

    M19: multiplier port map(A => A(3), B => B(2), C => I18); -- A3 * B2
    FA4: full_adder port map(A => I18, B => S4, Cin => C4, S => S9, Cout => C11); -- A3 * B1 + A4 * B0 + A3 * B2 (Fourth Full Adder)

    M20: multiplier port map(A => A(4), B => B(2), C => I19); -- A4 * B2
    FA5: full_adder port map(A => I19, B => S5, Cin => C5, S => S10, Cout => C12); -- A4 * B1 + A5 * B0 + A4 * B2 (Fifth Full Adder)

    M21: multiplier port map(A => A(5), B => B(2), C => I20); -- A5 * B2
    FA6: full_adder port map(A => I20, B => S6, Cin => C6, S => S11, Cout => C13); -- A5 * B1 + A6 * B0 + A5 * B2 (Sixth Full Adder)

    M22: multiplier port map(A => A(6), B => B(2), C => I21); -- A6 * B2
    NOT2: not_gate port map(A => B(1), B => N2); -- NOT B1
    M23: multiplier port map(A => A(7), B => N2, C => I22); -- A7 * NOT B1
    FA7: full_adder port map(A => I21, B => I22, Cin => C7, S => S12, Cout => C14); 

    --Third Stage
    M24: multiplier port map(A => A(0), B => B(3), C => I23); -- A0 * B3
    FA8: full_adder port map(A => I23, B => S7, Cin => C8, S => O4, Cout => C15); -- A0 * B2 + A1 * B1 + A0 * B3 (First Full Adder)

    M25: multiplier port map(A => A(1), B => B(3), C => I24); -- A1 * B3
    FA9: full_adder port map(A => I24, B => S8, Cin => C9, S => S13, Cout => C16); -- A1 * B2 + A2 * B1 + A1 * B3 (Second Full Adder)

    M26: multiplier port map(A => A(2), B => B(3), C => I25); -- A2 * B3
    FA10: full_adder port map(A => I25, B => S9, Cin => C10, S => S14, Cout => C17); -- A2 * B2 + A3 * B1 + A2 * B3 (Third Full Adder)

    M27: multiplier port map(A => A(3), B => B(3), C => I26); -- A3 * B3
    FA11: full_adder port map(A => I26, B => S10, Cin => C11, S => S15, Cout => C18); -- A3 * B2 + A4 * B1 + A3 * B3 (Fourth Full Adder)

    M28: multiplier port map(A => A(4), B => B(3), C => I27); -- A4 * B3
    FA12: full_adder port map(A => I27, B => S11, Cin => C12, S => S16, Cout => C19); -- A4 * B2 + A5 * B1 + A4 * B3 (Fifth Full Adder)

    M29: multiplier port map(A => A(5), B => B(3), C => I28); -- A5 * B3
    FA13: full_adder port map(A => I28, B => S12, Cin => C13, S => S17, Cout => C20); -- A5 * B2 + A6 * B1 + A5 * B3 (Sixth Full Adder)

    M30: multiplier port map(A => A(6), B => B(3), C => I29); -- A6 * B3
    NOT3: not_gate port map(A => B(2), B => N3); -- NOT B2
    M31: multiplier port map(A => A(7), B => N3, C => I30); -- A7 * NOT B2
    FA14: full_adder port map(A => I29, B => I30, Cin => C14, S => S18, Cout => C21); -- A6 * B2 + A7 * NOT B2 + A6 * B3 (Seventh Full Adder)

    --Fourth Stage
    M32: multiplier port map(A => A(0), B => B(4), C => I31); -- A0 * B4
    FA15: full_adder port map(A => I31, B => S13, Cin => C15, S => O5, Cout => C22); -- A0 * B3 + A1 * B2 + A0 * B4 (First Full Adder)

    M33: multiplier port map(A => A(1), B => B(4), C => I32); -- A1 * B4
    FA16: full_adder port map(A => I32, B => S14, Cin => C16, S => S19, Cout => C23); -- A1 * B3 + A2 * B2 + A1 * B4 (Second Full Adder)

    M34: multiplier port map(A => A(2), B => B(4), C => I33); -- A2 * B4
    FA17: full_adder port map(A => I33, B => S15, Cin => C17, S => S20, Cout => C24); -- A2 * B3 + A3 * B2 + A2 * B4 (Third Full Adder)

    M35: multiplier port map(A => A(3), B => B(4), C => I34); -- A3 * B4
    FA18: full_adder port map(A => I34, B => S16, Cin => C18, S => S21, Cout => C25); -- A3 * B3 + A4 * B2 + A3 * B4 (Fourth Full Adder)

    M36: multiplier port map(A => A(4), B => B(4), C => I35); -- A4 * B4
    FA19: full_adder port map(A => I35, B => S17, Cin => C19, S => S22, Cout => C26); -- A4 * B3 + A5 * B2 + A4 * B4 (Fifth Full Adder)

    M37: multiplier port map(A => A(5), B => B(4), C => I36); -- A5 * B4
    FA20: full_adder port map(A => I36, B => S18, Cin => C20, S => S23, Cout => C27); -- A5 * B3 + A6 * B2 + A5 * B4 (Sixth Full Adder)

    M38: multiplier port map(A => A(6), B => B(4), C => I37); -- A6 * B4
    NOT4: not_gate port map(A => B(3), B => N4); -- NOT B3
    M39: multiplier port map(A => A(7), B => N4, C => I38); -- A7 * NOT B3
    FA21: full_adder port map(A => I37, B => I38, Cin => C21, S => S24, Cout => C28); -- A6 * B3 + A7 * NOT B3 + A6 * B4 (Seventh Full Adder)

    --Fifth Stage
    M40: multiplier port map(A => A(0), B => B(5), C => I39); -- A0 * B5
    FA22: full_adder port map(A => I39, B => S19, Cin => C22, S => O6, Cout => C29); -- A0 * B4 + A1 * B3 + A0 * B5 (First Full Adder)

    M41: multiplier port map(A => A(1), B => B(5), C => I40); -- A1 * B5
    FA23: full_adder port map(A => I40, B => S20, Cin => C23, S => S25, Cout => C30); -- A1 * B4 + A2 * B3 + A1 * B5 (Second Full Adder)

    M42: multiplier port map(A => A(2), B => B(5), C => I41); -- A2 * B5
    FA24: full_adder port map(A => I41, B => S21, Cin => C24, S => S26, Cout => C31); -- A2 * B4 + A3 * B3 + A2 * B5 (Third Full Adder)

    M43: multiplier port map(A => A(3), B => B(5), C => I42); -- A3 * B5
    FA25: full_adder port map(A => I42, B => S22, Cin => C25, S => S27, Cout => C32); -- A3 * B4 + A4 * B3 + A3 * B5 (Fourth Full Adder)

    M44: multiplier port map(A => A(4), B => B(5), C => I43); -- A4 * B5
    FA26: full_adder port map(A => I43, B => S23, Cin => C26, S => S28, Cout => C33); -- A4 * B4 + A5 * B3 + A4 * B5 (Fifth Full Adder)

    M45: multiplier port map(A => A(5), B => B(5), C => I44); -- A5 * B5
    FA27: full_adder port map(A => I44, B => S24, Cin => C27, S => S29, Cout => C34); -- A5 * B4 + A6 * B3 + A5 * B5 (Sixth Full Adder)

    M46: multiplier port map(A => A(6), B => B(5), C => I45); -- A6 * B5
    NOT5: not_gate port map(A => B(4), B => N5); -- NOT B4
    M47: multiplier port map(A => A(7), B => N5, C => I46); -- A7 * NOT B4
    FA28: full_adder port map(A => I45, B => I46, Cin => C28, S => S30, Cout => C35); -- A6 * B4 + A7 * NOT B4 + A6 * B5 (Seventh Full Adder)

    --Sixth Stage
    M48: multiplier port map(A => A(0), B => B(6), C => I47); -- A0 * B6
    FA29: full_adder port map(A => I47, B => S25, Cin => C29, S => O7, Cout => C36); -- A0 * B5 + A1 * B4 + A0 * B6 (First Full Adder)

    M49: multiplier port map(A => A(1), B => B(6), C => I48); -- A1 * B6
    FA30: full_adder port map(A => I48, B => S26, Cin => C30, S => S31, Cout => C37); -- A1 * B5 + A2 * B4 + A1 * B6 (Second Full Adder)

    M50: multiplier port map(A => A(2), B => B(6), C => I49); -- A2 * B6
    FA31: full_adder port map(A => I49, B => S27, Cin => C31, S => S32, Cout => C38); -- A2 * B5 + A3 * B4 + A2 * B6 (Third Full Adder)

    M51: multiplier port map(A => A(3), B => B(6), C => I50); -- A3 * B6
    FA32: full_adder port map(A => I50, B => S28, Cin => C32, S => S33, Cout => C39); -- A3 * B5 + A4 * B4 + A3 * B6 (Fourth Full Adder)

    M52: multiplier port map(A => A(4), B => B(6), C => I51); -- A4 * B6
    FA33: full_adder port map(A => I51, B => S29, Cin => C33, S => S34, Cout => C40); -- A4 * B5 + A5 * B4 + A4 * B6 (Fifth Full Adder)

    M53: multiplier port map(A => A(5), B => B(6), C => I52); -- A5 * B6
    FA34: full_adder port map(A => I52, B => S30, Cin => C34, S => S35, Cout => C41); -- A5 * B5 + A6 * B4 + A5 * B6 (Sixth Full Adder)

    M54: multiplier port map(A => A(6), B => B(6), C => I53); -- A6 * B6
    NOT6: not_gate port map(A => B(5), B => N6); -- NOT B5
    M55: multiplier port map(A => A(7), B => N6, C => I54); -- A7 * NOT B5
    FA35: full_adder port map(A => I53, B => I54, Cin => C35, S => S36, Cout => C42); -- A6 * B5 + A7 * NOT B5 + A6 * B6 (Seventh Full Adder)

    --Seventh Stage
    NOT7: not_gate port map(A => A(0), B => N7); -- NOT A0
    M56: multiplier port map(A => N7, B => B(7), C => I55); -- NOT A0 * B7
    FA36: full_adder port map(A => I55, B => S31, Cin => C36, S => S37, Cout => C43); -- A0 * B6 + A1 * B5 + A0 * B7 (First Full Adder)
    
    NOT8: not_gate port map(A => A(1), B => N8); -- NOT A1
    M57: multiplier port map(A => N8, B => B(7), C => I56); -- NOT A1 * B7
    FA37: full_adder port map(A => I56, B => S32, Cin => C37, S => S38, Cout => C44); -- A1 * B6 + A2 * B5 + A1 * B7 (Second Full Adder)

    NOT9: not_gate port map(A => A(2), B => N9); -- NOT A2
    M58: multiplier port map(A => N9, B => B(7), C => I57); -- NOT A2 * B7
    FA38: full_adder port map(A => I57, B => S33, Cin => C38, S => S39, Cout => C45); -- A2 * B6 + A3 * B5 + A2 * B7 (Third Full Adder)

    NOT10: not_gate port map(A => A(3), B => N10); -- NOT A3
    M59: multiplier port map(A => N10, B => B(7), C => I58); -- NOT A3 * B7
    FA39: full_adder port map(A => I58, B => S34, Cin => C39, S => S40, Cout => C46); -- A3 * B6 + A4 * B5 + A3 * B7 (Fourth Full Adder)

    NOT11: not_gate port map(A => A(4), B => N11); -- NOT A4
    M60: multiplier port map(A => N11, B => B(7), C => I59); -- NOT A4 * B7
    FA40: full_adder port map(A => I59, B => S35, Cin => C40, S => S41, Cout => C47); -- A4 * B6 + A5 * B5 + A4 * B7 (Fifth Full Adder)

    NOT12: not_gate port map(A => A(5), B => N12); -- NOT A5
    M61: multiplier port map(A => N12, B => B(7), C => I60); -- NOT A5 * B7
    FA41: full_adder port map(A => I60, B => S36, Cin => C41, S => S42, Cout => C48); -- A5 * B6 + A6 * B5 + A5 * B7 (Sixth Full Adder)

    NOT13: not_gate port map(A => A(6), B => N13); -- NOT A6
    M62: multiplier port map(A => N13, B => B(7), C => I61); -- NOT A6 * B7
    NOT14: not_gate port map(A => B(6), B => N14); -- NOT B6
    M63: multiplier port map(A => A(7), B => N14, C => I62); -- A7 * NOT B6
    FA42: full_adder port map(A => I61, B => I62, Cin => C42, S => S43, Cout => C49); -- A6 * B6 + A7 * NOT B6 + A6 * B7 (Seventh Full Adder)

    NOT15: not_gate port map(A => B(7), B => N15); -- NOT B7
    NOT16: not_gate port map(A => A(7), B => N16); -- NOT A7
    M64: multiplier port map(A => A(7), B => B(7), C => I63); -- A7 * B7
    FA43: full_adder port map(A => N15, B => N16, Cin => I63, S => S44, Cout => C50); -- NOT A7 * NOT B7 + A7 * B7 (First Full Adder)

    --Eighth Stage
    FA44: full_adder port map(A => A(7), B => A(7), Cin => B(7), S => O8, Cout => C51); -- A0 * B7 + A1 * B6 + A0 * B8 (First Full Adder)
    
    FA45: full_adder port map(A => C43, B => S38, Cin => C51, S => O9, Cout => C52); -- A1 * B7 + A2 * B6 + A1 * B8 (Second Full Adder)

    FA46: full_adder port map(A => C44, B => S39, Cin => C52, S => O10, Cout => C53); -- A2 * B7 + A3 * B6 + A2 * B8 (Third Full Adder)
    
    FA47: full_adder port map(A => C45, B => S40, Cin => C53, S => O11, Cout => C54); -- A3 * B7 + A4 * B6 + A3 * B8 (Fourth Full Adder)

    FA48: full_adder port map(A => C46, B => S41, Cin => C54, S => O12, Cout => C55); -- A4 * B7 + A5 * B6 + A4 * B8 (Fifth Full Adder)

    FA49: full_adder port map(A => C47, B => S42, Cin => C55, S => O13, Cout => C56); -- A5 * B7 + A6 * B6 + A5 * B8 (Sixth Full Adder)

    FA50: full_adder port map(A => C48, B => S43, Cin => C56, S => O14, Cout => C57); -- A6 * B7 + A7 * B6 + A6 * B8 (Seventh Full Adder)

    FA51: full_adder port map(A => C49, B => S44, Cin => C57, S => O15, Cout => C58); -- A7 * B7 + A7 * B7 + A7 * B8 (Eighth Full Adder)

    FA52: full_adder port map(A => S44, B => '0', Cin => C58, S => O16, Cout => C59); -- A7 * B7 + A7 * B7 + A7 * B8 (Ninth Full Adder)

    --Output Assignment
    P <= O16 & O15 & O14 & O13 & O12 & O11 & O10 & O9 & O8 & O7 & O6 & O5 & O4 & O3 & O2 & O1;

    end behavior;