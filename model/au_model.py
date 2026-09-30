"""Golden model of the Arithmetic Unit Lab designs.

This file is the specification in executable form.  The VHDL testbenches
read vectors generated from it, and the website's JavaScript model is tested
against the same vectors, so all three agree bit for bit.

    python -m model.au_model vectors --n 8 --count 4000 > tb/vectors/arith_unit_n8.txt
    python -m model.au_model plan --n 8          # Dadda reduction plan
    python -m model.au_model eval 200 100 2 1    # one evaluation
"""
from __future__ import annotations

import argparse
import random
import sys
from dataclasses import dataclass
from functools import lru_cache


# --------------------------------------------------------------------------- helpers

def to_signed(v: int, bits: int) -> int:
    """Interpret the low `bits` bits of v as two's complement."""
    v &= (1 << bits) - 1
    return v - (1 << bits) if v >> (bits - 1) else v


def div_trunc(a: int, b: int) -> int:
    """Integer division rounded toward zero (VHDL "/", C "/", Python int(a/b))."""
    q = abs(a) // abs(b)
    return q if (a >= 0) == (b > 0) else -q


# --------------------------------------------------------------------------- units

def arith_min(a: int, b: int, n: int = 8) -> int:
    """Minimum requirement: P = A*B/4 + 1, A and B unsigned n-bit."""
    mask = (1 << n) - 1
    return ((a & mask) * (b & mask)) // 4 + 1


@dataclass(frozen=True)
class Result:
    p: int        # 2n-bit pattern on the P output
    err: int      # divide by zero (fsel = 1 and C = 0)
    ovf: int      # result does not fit in 2n bits
    latency: int  # rising edges from the load edge until status = 1


def arith_unit(a: int, b: int, c: int, d: int, sgn: int, fsel: int,
               n: int = 8, cw: int = 8, dw: int = 8) -> Result:
    """General unit.

    fsel = 0 : P = A*B / 2^C + D
    fsel = 1 : P = A*B / C^2 + D   (err, P = 0 when C = 0)
    sgn  = 1 : A, B, D are two's complement; C is always unsigned.
    """
    w = 2 * n
    c &= (1 << cw) - 1
    if sgn:
        av, bv, dv = to_signed(a, n), to_signed(b, n), to_signed(d, dw)
    else:
        av, bv, dv = a & ((1 << n) - 1), b & ((1 << n) - 1), d & ((1 << dw) - 1)
    prod = av * bv

    if fsel:
        if c == 0:
            return Result(0, 1, 0, 3)
        q = div_trunc(prod, c * c)
        latency = w + 5
    else:
        q = div_trunc(prod, 1 << c)
        latency = 3

    r = q + dv
    if sgn:
        ovf = int(not (-(1 << (w - 1)) <= r < (1 << (w - 1))))
    else:
        ovf = int(r >= (1 << w))
    return Result(r & ((1 << w) - 1), 0, ovf, latency)


# --------------------------------------------------------------------------- structure

def pp_height(n: int, k: int) -> int:
    h = min(k, 2 * n - 2 - k) + 1 if k <= 2 * n - 2 else 0
    if k in (n, 2 * n - 1):
        h += 1                      # Baugh-Wooley constant
    return h


def dadda_targets(maxh: int) -> list[int]:
    d = [2]
    while (d[-1] * 3) // 2 < maxh:
        d.append((d[-1] * 3) // 2)
    return [x for x in reversed(d) if x < maxh]


@lru_cache(maxsize=None)
def dadda_plan(n: int) -> dict:
    """Same algorithm as au_pkg.dadda_plan: heights, full and half adders per stage."""
    w = 2 * n
    h = [pp_height(n, k) for k in range(w)]
    heights, fas, has = [h[:]], [], []
    for d in dadda_targets(max(h)):
        fa, ha, nh, cin = [0] * w, [0] * w, [0] * w, 0
        for k in range(w):
            ex = h[k] + cin - d
            f = a = 0
            if ex > 0:
                f = min(ex // 2, h[k] // 3)
                a = min(ex - 2 * f, (h[k] - 3 * f) // 2)
            fa[k], ha[k] = f, a
            nh[k] = h[k] - 2 * f - a + cin
            cin = f + a
        assert cin == 0 and max(nh) <= d
        heights.append(nh)
        fas.append(fa)
        has.append(ha)
        h = nh
    return {"n": n, "targets": dadda_targets(max(heights[0])),
            "heights": heights, "fa": fas, "ha": has}


def dadda_multiply(a: int, b: int, n: int, sgn: int) -> int:
    """Bit-level evaluation of the Dadda tree, in the same bit order as the RTL."""
    w = 2 * n
    plan = dadda_plan(n)
    abit = [(a >> i) & 1 for i in range(n)]
    bbit = [(b >> j) & 1 for j in range(n)]
    cols = []
    for k in range(w):
        col = []
        for i in range(n):
            j = k - i
            if 0 <= j < n:
                inv = sgn if ((i == n - 1) != (j == n - 1)) else 0
                col.append((abit[i] & bbit[j]) ^ inv)
        if k in (n, w - 1):
            col.append(sgn)
        cols.append(col)
    for st in range(len(plan["fa"])):
        fa, ha = plan["fa"][st], plan["ha"][st]
        nxt_keep = [[] for _ in range(w + 1)]
        nxt_sum = [[] for _ in range(w + 1)]
        carries = [[] for _ in range(w + 1)]
        for k in range(w):
            col = cols[k]
            f, h = fa[k], ha[k]
            fs, fc, hs, hc = [], [], [], []
            for t in range(f):
                x, y, z = col[3 * t:3 * t + 3]
                fs.append(x ^ y ^ z)
                fc.append((x & y) | (x & z) | (y & z))
            for u in range(h):
                x, y = col[3 * f + 2 * u:3 * f + 2 * u + 2]
                hs.append(x ^ y)
                hc.append(x & y)
            nxt_keep[k] = col[3 * f + 2 * h:]
            nxt_sum[k] = fs + hs
            carries[k + 1] = fc + hc
        cols = [nxt_keep[k] + nxt_sum[k] + carries[k] for k in range(w)]
    x = sum((col[0] if len(col) > 0 else 0) << k for k, col in enumerate(cols))
    y = sum((col[1] if len(col) > 1 else 0) << k for k, col in enumerate(cols))
    return (x + y) & ((1 << w) - 1)


def array_multiply(a: int, b: int, n: int, sgn: int) -> int:
    """Bit-level evaluation of the carry-save array, same cell order as the RTL."""
    pp = lambda i, j: (((a >> i) & 1) & ((b >> j) & 1)) ^ (sgn if (i == n - 1) != (j == n - 1) else 0)
    s = [[0] * n for _ in range(n)]
    c = [[0] * n for _ in range(n)]
    for i in range(n):
        s[0][i] = pp(i, 0)
    p = s[0][0]
    for j in range(1, n):
        for i in range(n):
            up = s[j - 1][i + 1] if i < n - 1 else 0
            t = pp(i, j) + up + c[j - 1][i]
            s[j][i], c[j][i] = t & 1, t >> 1
        p |= s[j][0] << j
    x = sum(s[n - 1][m + 1] << m for m in range(n - 1)) | (sgn << (n - 1))
    y = sum(c[n - 1][m] << m for m in range(n))
    hi = (x + y + sgn) & ((1 << n) - 1)
    return p | (hi << n)


# --------------------------------------------------------------------------- vectors

def corner_values(bits: int, signed: bool) -> list[int]:
    m = (1 << bits) - 1
    vals = {0, 1, 2, 3, m, m - 1, 1 << (bits - 1), (1 << (bits - 1)) - 1, (1 << (bits - 1)) + 1}
    return sorted(v & m for v in vals)


def gen_vectors(n: int, cw: int, dw: int, count: int, seed: int):
    rnd = random.Random(seed)
    rows = []
    cA = corner_values(n, True)
    cC = sorted({0, 1, 2, 3, 4, 7, 8, n, 2 * n - 1, 2 * n, 2 * n + 1, (1 << cw) - 1} & set(range(1 << cw)))
    cD = corner_values(dw, True)
    for sgn in (0, 1):
        for fsel in (0, 1):
            for a in cA:
                for b in cA:
                    rows.append((a, b, rnd.choice(cC), rnd.choice(cD), sgn, fsel))
            for c in cC:
                for d in cD:
                    rows.append((rnd.choice(cA), rnd.choice(cA), c, d, sgn, fsel))
    for _ in range(count):
        rows.append((rnd.getrandbits(n), rnd.getrandbits(n),
                     rnd.getrandbits(cw) if rnd.random() < 0.5 else rnd.randrange(0, 2 * n + 2) & ((1 << cw) - 1),
                     rnd.getrandbits(dw), rnd.getrandbits(1), rnd.getrandbits(1)))
    for a, b, c, d, sgn, fsel in rows:
        r = arith_unit(a, b, c, d, sgn, fsel, n, cw, dw)
        yield (a, b, c, d, sgn, fsel, r.p, r.err, r.ovf, r.latency)


# --------------------------------------------------------------------------- cli

def main(argv=None) -> int:
    ap = argparse.ArgumentParser(prog="au_model")
    sub = ap.add_subparsers(dest="cmd", required=True)
    v = sub.add_parser("vectors", help="test vectors for tb_arith_unit_vectors")
    v.add_argument("--n", type=int, default=8)
    v.add_argument("--cw", type=int, default=8)
    v.add_argument("--dw", type=int, default=8)
    v.add_argument("--count", type=int, default=4000)
    v.add_argument("--seed", type=int, default=2023)
    pl = sub.add_parser("plan", help="print the Dadda plan")
    pl.add_argument("--n", type=int, default=8)
    ev = sub.add_parser("eval", help="evaluate A B C D [sgn] [fsel]")
    ev.add_argument("vals", type=int, nargs="+")
    ev.add_argument("--n", type=int, default=8)
    args = ap.parse_args(argv)

    if args.cmd == "vectors":
        print(f"# arith_unit vectors  N={args.n} CW={args.cw} DW={args.dw}  seed={args.seed}")
        print("# A B C D sgn fsel P err ovf latency   (hex bit patterns, latency decimal)")
        for row in gen_vectors(args.n, args.cw, args.dw, args.count, args.seed):
            print(" ".join(f"{x:X}" for x in row[:-1]), row[-1])
    elif args.cmd == "plan":
        plan = dadda_plan(args.n)
        print("targets", plan["targets"])
        for s, h in enumerate(plan["heights"]):
            print(f"stage {s} heights", h)
            if s < len(plan["fa"]):
                print(f"        FA", plan["fa"][s], "HA", plan["ha"][s])
    else:
        vals = args.vals + [0] * (6 - len(args.vals))
        print(arith_unit(*vals[:6], n=args.n))
    return 0


if __name__ == "__main__":
    sys.exit(main())
