"""Tests for the golden model (python -m pytest tests)."""
import itertools

import pytest

from model import au_model as m


@pytest.mark.parametrize("n", [2, 3, 4, 5, 6])
@pytest.mark.parametrize("sgn", [0, 1])
def test_bit_level_multipliers_exhaustive(n, sgn):
    for a, b in itertools.product(range(1 << n), repeat=2):
        exp = (m.to_signed(a, n) * m.to_signed(b, n) if sgn else a * b) & ((1 << 2 * n) - 1)
        assert m.dadda_multiply(a, b, n, sgn) == exp
        assert m.array_multiply(a, b, n, sgn) == exp


@pytest.mark.parametrize("n", [8, 12, 16, 24, 32])
def test_bit_level_multipliers_random(n):
    import random
    r = random.Random(n)
    for _ in range(400):
        a, b, sgn = r.getrandbits(n), r.getrandbits(n), r.getrandbits(1)
        exp = (m.to_signed(a, n) * m.to_signed(b, n) if sgn else a * b) & ((1 << 2 * n) - 1)
        assert m.dadda_multiply(a, b, n, sgn) == exp
        assert m.array_multiply(a, b, n, sgn) == exp


def test_dadda_plan_shape():
    plan = m.dadda_plan(8)
    assert plan["targets"] == [6, 4, 3, 2]
    assert max(plan["heights"][0]) == 8
    assert max(plan["heights"][-1]) <= 2
    assert sum(map(sum, plan["fa"])) == 36 and sum(map(sum, plan["ha"])) == 6
    assert [len(m.dadda_plan(n)["fa"]) for n in (4, 8, 16, 32)] == [2, 4, 6, 8]


def test_min_formula():
    assert m.arith_min(200, 100) == 5001
    assert m.arith_min(255, 255) == 16257
    assert m.arith_min(0, 0) == 1
    assert m.arith_min(3, 1) == 1          # 3/4 truncates to 0


def test_rounding_toward_zero():
    assert m.div_trunc(-7, 2) == -3 and m.div_trunc(7, 2) == 3
    assert m.div_trunc(-8, 4) == -2 and m.div_trunc(-1, 256) == 0
    # signed shift mode: (-5 * 3) / 2^1 + 0 = -7 (floor would give -8)
    r = m.arith_unit(0xFB, 3, 1, 0, 1, 0)
    assert m.to_signed(r.p, 16) == -7 and r.err == 0 and r.ovf == 0


def test_square_mode_and_div_by_zero():
    r = m.arith_unit(200, 100, 5, 7, 0, 1)
    assert r.p == 20000 // 25 + 7 and r.latency == 21
    r = m.arith_unit(200, 100, 0, 7, 0, 1)
    assert (r.p, r.err, r.latency) == (0, 1, 3)


def test_no_overflow_when_dw_le_n():
    n = 4
    for a, b, d in itertools.product(range(16), repeat=3):
        for sgn in (0, 1):
            for c in range(0, 9):
                for fsel in (0, 1):
                    assert m.arith_unit(a, b, c, d, sgn, fsel, n=4, cw=4, dw=4).ovf == 0


def test_overflow_flag_when_dw_wide():
    # unsigned: 255*255 + 65535 does not fit 16 bits
    assert m.arith_unit(255, 255, 0, 0xFFFF, 0, 0, dw=16).ovf == 1
    # signed: 127*127 + 32767 > 32767
    assert m.arith_unit(127, 127, 0, 0x7FFF, 1, 0, dw=16).ovf == 1


def test_vectors_are_deterministic():
    a = list(m.gen_vectors(8, 8, 8, 50, 1))
    b = list(m.gen_vectors(8, 8, 8, 50, 1))
    assert a == b and len(a) > 50
