-- Exhaustive audit of the 2023 generic Baugh-Wooley array (N=8) and the 2^C divider sign handling
library ieee; use ieee.std_logic_1164.all; use ieee.numeric_std.all;
entity tb_audit_bw is end;
architecture a of tb_audit_bw is
  signal A, B : std_logic_vector(7 downto 0);
  signal P_s, P_u, Q : std_logic_vector(15 downto 0);
  signal DA : std_logic_vector(15 downto 0);
  signal C : std_logic_vector(7 downto 0);
begin
  u_s : entity work.generic_array_multiplier generic map (N => 8) port map (A => A, B => B, mode => '1', start => '1', P_out => P_s);
  u_u : entity work.generic_array_multiplier generic map (N => 8) port map (A => A, B => B, mode => '0', start => '1', P_out => P_u);
  u_d : entity work.divider_2c generic map (N => 8, K => 32) port map (A => DA, C => C, mode => '1', start => '1', P_out => Q);
  process
    variable es, eu, ed_pos, ed_neg, npos, nneg : natural := 0;
  begin
    for i in 0 to 255 loop
      for j in 0 to 255 loop
        A <= std_logic_vector(to_unsigned(i, 8)); B <= std_logic_vector(to_unsigned(j, 8));
        wait for 1 ns;
        if P_u /= std_logic_vector(to_unsigned(i*j, 16)) then eu := eu + 1; end if;
        if signed(P_s) /= to_signed(to_integer(signed(A)) * to_integer(signed(B)), 16) then es := es + 1; end if;
      end loop;
    end loop;
    for v in -32768 to 32767 loop
      for s in 1 to 3 loop
        DA <= std_logic_vector(to_signed(v, 16)); C <= std_logic_vector(to_unsigned(s, 8)); wait for 1 ns;
        if v >= 0 then npos := npos + 1; if to_integer(signed(Q)) /= v / 2**s then ed_pos := ed_pos + 1; end if;
        else nneg := nneg + 1; if to_integer(signed(Q)) /= v / 2**s and to_integer(signed(Q)) /= (v - 2**s + 1) / 2**s then ed_neg := ed_neg + 1; end if; end if;
      end loop;
    end loop;
    report "RESULT baugh unsigned mismatches=" & integer'image(eu) & "/65536";
    report "RESULT baugh signed mismatches=" & integer'image(es) & "/65536";
    report "RESULT divider_2c signed: non-negative inputs wrong=" & integer'image(ed_pos) & "/" & integer'image(npos)
         & ", negative inputs wrong=" & integer'image(ed_neg) & "/" & integer'image(nneg);
    wait;
  end process;
end;
