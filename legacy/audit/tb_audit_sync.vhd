-- Cycle trace of the 2023 synchronous unit (entity renamed from "synthesis" so it can bind)
library ieee; use ieee.std_logic_1164.all; use ieee.numeric_std.all;
entity tb_audit_sync is generic (LOAD_CYCLES : natural := 1; A_VAL : natural := 200; B_VAL : natural := 100); end;
architecture a of tb_audit_sync is
  signal clk : std_logic := '0';
  signal reset, load, status : std_logic := '0';
  signal A, B : std_logic_vector(7 downto 0);
  signal P : std_logic_vector(15 downto 0);
  function img(v : std_logic_vector) return string is
    variable s : string(1 to v'length); variable k : natural := 1;
  begin
    for i in v'range loop s(k) := std_logic'image(v(i))(2); k := k + 1; end loop; return s;
  end;
begin
  dut : entity work.sync_arithmetic_hw port map (clk, reset, load, A, B, status, P);
  clk <= not clk after 10 ns;
  process begin
    A <= std_logic_vector(to_unsigned(A_VAL, 8)); B <= std_logic_vector(to_unsigned(B_VAL, 8));
    reset <= '0'; wait until falling_edge(clk); reset <= '1';
    wait until falling_edge(clk);
    load <= '1';
    for k in 1 to LOAD_CYCLES loop wait until falling_edge(clk); end loop;
    load <= '0';
    for k in 1 to 8 loop
      wait until falling_edge(clk);
      if is_x(P) or P(0) = 'Z' then
        report "TRACE cycle=" & integer'image(k) & " status=" & std_logic'image(status) & " P=" & img(P);
      else
        report "TRACE cycle=" & integer'image(k) & " status=" & std_logic'image(status) & " P=" & integer'image(to_integer(unsigned(P)));
      end if;
    end loop;
    report "EXPECTED " & integer'image(A_VAL*B_VAL/4+1);
    std.env.stop;
  end process;
end;
