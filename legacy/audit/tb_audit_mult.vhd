-- Exhaustive audit of the 2023 8x8 unsigned multipliers (array + "wallace")
library ieee; use ieee.std_logic_1164.all; use ieee.numeric_std.all;
entity tb_audit_mult is end;
architecture a of tb_audit_mult is
  signal A, B : std_logic_vector(7 downto 0);
  signal P_arr, P_wal : std_logic_vector(15 downto 0);
  signal start : std_logic := '1';
begin
  u_arr : entity work.array_multiplier port map (A => A, B => B, start => start, P => P_arr);
  u_wal : entity work.wallace_tree_multiplier port map (A => A, B => B, start => start, P => P_wal);
  process
    variable e_arr, e_wal : natural := 0;
  begin
    for i in 0 to 255 loop
      for j in 0 to 255 loop
        A <= std_logic_vector(to_unsigned(i, 8)); B <= std_logic_vector(to_unsigned(j, 8));
        wait for 1 ns;
        if P_arr /= std_logic_vector(to_unsigned(i*j, 16)) then e_arr := e_arr + 1; end if;
        if P_wal /= std_logic_vector(to_unsigned(i*j, 16)) then e_wal := e_wal + 1; end if;
      end loop;
    end loop;
    report "RESULT array_multiplier mismatches=" & integer'image(e_arr) & "/65536";
    report "RESULT wallace_tree_multiplier mismatches=" & integer'image(e_wal) & "/65536";
    wait;
  end process;
end;
