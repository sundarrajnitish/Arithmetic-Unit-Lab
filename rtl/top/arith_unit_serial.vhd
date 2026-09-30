--------------------------------------------------------------------------------
-- Arithmetic Unit Lab                               top/arith_unit_serial.vhd
-- Author : Nitish Sundarraj
--
-- Additional requirement 4: serial I/O around arith_unit.
-- Eight pins instead of 3 + (2N + CW + DW + 2) + (2N + 3): 56 for N = CW = DW = 8.
--
--   Input frame, LSB first, one bit per clock while sin_en = '1':
--     A (N) | B (N) | C (CW) | D (DW) | sgn | fsel        (2N+CW+DW+2 bits)
--   start = '1' for one clock hands the frame to the unit (busy goes high).
--   Output frame, LSB first, one bit per clock while sout_valid = '1':
--     P (2N) | err | ovf                                  (2N+2 bits)
--   busy falls after the last output bit.
--
-- Shifting in the next frame while busy is allowed (double buffering: the
-- unit has its own operand registers).
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

entity arith_unit_serial is
  generic (
    N         : positive := 8;
    CW        : positive := 8;
    DW        : positive := 8;
    MULT_ARCH : string   := "DADDA";
    CPA_ARCH  : string   := "KOGGE_STONE"
  );
  port (
    clk        : in  std_logic;
    reset_n    : in  std_logic;
    sin        : in  std_logic;
    sin_en     : in  std_logic;
    start      : in  std_logic;
    sout       : out std_logic;
    sout_valid : out std_logic;
    busy       : out std_logic
  );
end entity arith_unit_serial;

architecture rtl of arith_unit_serial is
  constant FI : natural := 2 * N + CW + DW + 2;
  constant FO : natural := 2 * N + 2;

  signal sr_in   : std_logic_vector(FI - 1 downto 0);
  signal sr_out  : std_logic_vector(FO - 1 downto 0);
  signal out_cnt : natural range 0 to FO;
  signal waiting : std_logic;

  signal u_status, u_err, u_ovf : std_logic;
  signal u_p     : std_logic_vector(2 * N - 1 downto 0);
begin

  core : entity work.arith_unit
    generic map (N => N, CW => CW, DW => DW, MULT_ARCH => MULT_ARCH, CPA_ARCH => CPA_ARCH)
    port map (
      clk => clk, reset_n => reset_n, load => start,
      A    => sr_in(N - 1 downto 0),
      B    => sr_in(2 * N - 1 downto N),
      C    => sr_in(2 * N + CW - 1 downto 2 * N),
      D    => sr_in(2 * N + CW + DW - 1 downto 2 * N + CW),
      sgn  => sr_in(FI - 2),
      fsel => sr_in(FI - 1),
      status => u_status, err => u_err, ovf => u_ovf, P => u_p);

  process (clk, reset_n)
  begin
    if reset_n = '0' then
      sr_in   <= (others => '0');
      sr_out  <= (others => '0');
      out_cnt <= 0;
      waiting <= '0';
    elsif rising_edge(clk) then
      if sin_en = '1' then
        sr_in <= sin & sr_in(FI - 1 downto 1);
      end if;

      if start = '1' then
        waiting <= '1';
        out_cnt <= 0;
      elsif waiting = '1' and u_status = '1' then
        waiting <= '0';
        sr_out  <= u_ovf & u_err & u_p;
        out_cnt <= FO;
      elsif out_cnt /= 0 then
        sr_out  <= '0' & sr_out(FO - 1 downto 1);
        out_cnt <= out_cnt - 1;
      end if;
    end if;
  end process;

  sout       <= sr_out(0);
  sout_valid <= '1' when out_cnt /= 0 else '0';
  busy       <= '1' when waiting = '1' or out_cnt /= 0 else '0';

end architecture rtl;
