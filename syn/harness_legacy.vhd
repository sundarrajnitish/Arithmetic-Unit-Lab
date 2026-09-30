--------------------------------------------------------------------------------
-- Arithmetic Unit Lab                                syn/harness_legacy.vhd
-- Author : Nitish Sundarraj
--
-- Same register harness around the 2023 multipliers (legacy/ sources), so
-- they can be measured with exactly the flow used for v2.
--   IMPL = "ARRAY"    legacy array_multiplier (8-bit, unsigned)
--   IMPL = "WALLACE"  legacy wallace_tree_multiplier (8-bit, unsigned)
--   IMPL = "BAUGH"    legacy generic Baugh-Wooley array (entity renamed)
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

entity harness_legacy is
  generic (IMPL : string := "ARRAY");
  port (
    clk  : in  std_logic;
    a, b : in  std_logic_vector(7 downto 0);
    sgn  : in  std_logic;
    p    : out std_logic_vector(15 downto 0)
  );
end entity harness_legacy;

architecture rtl of harness_legacy is
  signal a_r, b_r : std_logic_vector(7 downto 0);
  signal s_r      : std_logic;
  signal prod     : std_logic_vector(15 downto 0);
begin
  process (clk)
  begin
    if rising_edge(clk) then
      a_r <= a; b_r <= b; s_r <= sgn;
      p   <= prod;
    end if;
  end process;

  arr : if IMPL = "ARRAY" generate
    u : entity work.array_multiplier port map (A => a_r, B => b_r, start => '1', P => prod);
  end generate arr;
  wal : if IMPL = "WALLACE" generate
    u : entity work.wallace_tree_multiplier port map (A => a_r, B => b_r, start => '1', P => prod);
  end generate wal;
  bw : if IMPL = "BAUGH" generate
    u : entity work.generic_array_multiplier generic map (N => 8)
      port map (A => a_r, B => b_r, mode => s_r, start => '1', P_out => prod);
  end generate bw;
end architecture rtl;
