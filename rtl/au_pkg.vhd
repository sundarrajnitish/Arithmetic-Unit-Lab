--------------------------------------------------------------------------------
-- Arithmetic Unit Lab                                        au_pkg.vhd
-- Author : Nitish Sundarraj
--
-- Shared constants and elaboration-time helpers.
--
--   clog2        ceil(log2(x)), used to size prefix-adder levels
--   pow2_ge      true when 2**k >= w without overflowing integer
--   dadda_*      the Dadda reduction plan for an N x N multiplier whose
--                partial-product matrix also carries the two Baugh-Wooley
--                sign constants (column N and column 2N-1).
--
-- The Dadda plan is computed here once, at elaboration, and the multiplier
-- architecture only instantiates what the plan says.  The same algorithm is
-- mirrored in model/au_model.py and docs/js/model.js so the website draws the
-- exact tree that is synthesised.
--
-- VHDL-93 compatible.
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

package au_pkg is

  type int_mat is array (natural range <>, natural range <>) of integer;

  function clog2 (x : positive) return natural;
  function pow2_ge (k : natural; w : positive) return boolean;
  function max_int (a, b : integer) return integer;
  function min_int (a, b : integer) return integer;

  -- number of reduction stages Dadda needs for an n x n matrix (n >= 2)
  function dadda_stage_count (n : positive) return natural;

  -- which = 0 : column heights  H(s, k), s = 0 .. S
  -- which = 1 : full adders     F(s, k), s = 0 .. S-1 (row S is zero)
  -- which = 2 : half adders     A(s, k), s = 0 .. S-1 (row S is zero)
  -- k runs over 0 .. 2n (one spare column that is always empty)
  function dadda_plan (n : positive; which : natural) return int_mat;

  -- initial height of column k (partial products plus sign constants)
  function pp_height (n : positive; k : natural) return natural;

end package au_pkg;

package body au_pkg is

  function clog2 (x : positive) return natural is
    variable r : natural := 0;
    variable v : natural := 1;
  begin
    while v < x loop
      v := v * 2;
      r := r + 1;
    end loop;
    return r;
  end function;

  function pow2_ge (k : natural; w : positive) return boolean is
    variable v : natural := 1;
  begin
    for i in 1 to k loop
      v := v * 2;
      if v >= w then
        return true;
      end if;
    end loop;
    return v >= w;
  end function;

  function max_int (a, b : integer) return integer is
  begin
    if a > b then return a; else return b; end if;
  end function;

  function min_int (a, b : integer) return integer is
  begin
    if a < b then return a; else return b; end if;
  end function;

  function pp_height (n : positive; k : natural) return natural is
    variable h : natural := 0;
  begin
    if k <= 2 * n - 2 then
      h := min_int(k, 2 * n - 2 - k) + 1;
    end if;
    if k = n or k = 2 * n - 1 then
      h := h + 1;                       -- Baugh-Wooley constant bit
    end if;
    return h;
  end function;

  -- Dadda targets 2, 3, 4, 6, 9, 13, 19, 28, 42, 63, ...
  function dadda_target (j : natural) return natural is
    variable d : natural := 2;
  begin
    for i in 1 to j loop
      d := (d * 3) / 2;
    end loop;
    return d;
  end function;

  function dadda_stage_count (n : positive) return natural is
    variable maxh : natural := 0;
    variable s    : natural := 0;
  begin
    for k in 0 to 2 * n - 1 loop
      maxh := max_int(maxh, pp_height(n, k));
    end loop;
    while dadda_target(s) < maxh loop
      s := s + 1;
    end loop;
    return s;
  end function;

  function dadda_plan (n : positive; which : natural) return int_mat is
    constant S   : natural := dadda_stage_count(n);
    constant W   : natural := 2 * n;
    variable h   : int_mat(0 to S, 0 to W) := (others => (others => 0));
    variable fa  : int_mat(0 to S, 0 to W) := (others => (others => 0));
    variable ha  : int_mat(0 to S, 0 to W) := (others => (others => 0));
    variable d, cin, ex, f, a, r : integer;
  begin
    for k in 0 to W - 1 loop
      h(0, k) := pp_height(n, k);
    end loop;
    for st in 0 to S - 1 loop
      d   := dadda_target(S - 1 - st);
      cin := 0;
      for k in 0 to W loop
        ex := h(st, k) + cin - d;
        f  := 0;
        a  := 0;
        if ex > 0 then
          f := min_int(ex / 2, h(st, k) / 3);
          r := ex - 2 * f;
          a := min_int(r, (h(st, k) - 3 * f) / 2);
        end if;
        fa(st, k)    := f;
        ha(st, k)    := a;
        h(st + 1, k) := h(st, k) - 2 * f - a + cin;
        cin          := f + a;
      end loop;
    end loop;
    if which = 0 then
      return h;
    elsif which = 1 then
      return fa;
    else
      return ha;
    end if;
  end function;

end package body au_pkg;
