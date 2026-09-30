--------------------------------------------------------------------------------
-- Arithmetic Unit Lab                                           arith/cpa.vhd
-- Author : Nitish Sundarraj
--
-- Carry-propagate adder with a selectable architecture:
--   ARCH = "RIPPLE"       ripple_adder       (area)
--   ARCH = "KOGGE_STONE"  kogge_stone_adder  (speed, any technology)
--   ARCH = "INFERRED"     numeric_std "+"    (lets the FPGA tool use its
--                                            dedicated carry chain)
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity cpa is
  generic (
    W    : positive := 16;
    ARCH : string   := "KOGGE_STONE"
  );
  port (
    x, y : in  std_logic_vector(W - 1 downto 0);
    ci   : in  std_logic;
    s    : out std_logic_vector(W - 1 downto 0);
    co   : out std_logic
  );
end entity cpa;

architecture structural of cpa is
begin
  assert ARCH = "RIPPLE" or ARCH = "KOGGE_STONE" or ARCH = "INFERRED"
    report "cpa: ARCH must be RIPPLE, KOGGE_STONE or INFERRED" severity failure;

  rca : if ARCH = "RIPPLE" generate
    u : entity work.ripple_adder generic map (W => W)
      port map (x => x, y => y, ci => ci, s => s, co => co);
  end generate rca;

  ks : if ARCH = "KOGGE_STONE" generate
    u : entity work.kogge_stone_adder generic map (W => W)
      port map (x => x, y => y, ci => ci, s => s, co => co);
  end generate ks;

  inf : if ARCH = "INFERRED" generate
    signal sum : unsigned(W downto 0);
    signal cin : unsigned(0 downto 0);
  begin
    cin(0) <= ci;
    sum    <= resize(unsigned(x), W + 1) + resize(unsigned(y), W + 1) + cin;
    s      <= std_logic_vector(sum(W - 1 downto 0));
    co     <= sum(W);
  end generate inf;
end architecture structural;
