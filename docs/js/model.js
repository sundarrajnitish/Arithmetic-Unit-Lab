/* Arithmetic Unit Lab - bit-accurate JavaScript model of the v2 RTL.
 * Author: Nitish Sundarraj
 *
 * Mirrors rtl/ and model/au_model.py:
 *   arithUnit()        formula result, err, ovf, latency (golden model)
 *   AUSim              cycle-accurate model of top/arith_unit.vhd (FSM + registers)
 *   daddaPlan()        au_pkg.dadda_plan
 *   daddaTrace()       every bit of every Dadda stage, with where it came from
 *   arrayTrace()       every cell of the carry-save array
 *   buildNetlist()     cell-level netlist of multiplier.vhd (ARRAY|DADDA x RIPPLE|KOGGE_STONE)
 *   unitDelaySim()     settle-time simulation of that netlist, one delay unit per cell
 * Tested against the golden-model vectors by tests/test_js_model.mjs.
 * Works in the browser (window.AU) and in Node (module.exports).
 */
(function (root) {
  "use strict";

  const mask = (bits) => (bits >= 31 ? 2 ** bits - 1 : (1 << bits) - 1);
  const bit = (v, i) => Math.floor(v / 2 ** i) % 2;           // safe past 32 bits
  const toSigned = (v, bits) => { v = v % 2 ** bits; return v >= 2 ** (bits - 1) ? v - 2 ** bits : v; };
  const toPattern = (v, bits) => ((v % 2 ** bits) + 2 ** bits) % 2 ** bits;
  const divTrunc = (a, b) => { const q = Math.floor(Math.abs(a) / Math.abs(b)); return (a >= 0) === (b > 0) ? q : -q; };

  /* ------------------------------------------------------------ formula */
  function arithMin(a, b, n = 8) { return Math.floor((a & mask(n)) * (b & mask(n)) / 4) + 1; }

  function arithUnit(a, b, c, d, sgn, fsel, n = 8, cw = 8, dw = 8) {
    const w = 2 * n;
    c = c % 2 ** cw;
    let av, bv, dv;
    if (sgn) { av = toSigned(a, n); bv = toSigned(b, n); dv = toSigned(d, dw); }
    else { av = a % 2 ** n; bv = b % 2 ** n; dv = d % 2 ** dw; }
    const prod = av * bv;
    let q, latency;
    if (fsel) {
      if (c === 0) return { p: 0, err: 1, ovf: 0, latency: 3 };
      q = divTrunc(prod, c * c); latency = w + 5;
    } else {
      q = divTrunc(prod, 2 ** c); latency = 3;
    }
    const r = q + dv;
    const ovf = sgn ? (r < -(2 ** (w - 1)) || r >= 2 ** (w - 1) ? 1 : 0) : (r >= 2 ** w ? 1 : 0);
    return { p: toPattern(r, w), err: 0, ovf, latency, prod, q, value: r };
  }

  /* ------------------------------------------------ cycle-accurate unit */
  // State names follow top/arith_unit.vhd.
  class AUSim {
    constructor(n = 8, cw = 8, dw = 8) { this.n = n; this.cw = cw; this.dw = dw; this.reset(); }
    reset() {
      const z = { a: 0, b: 0, c: 0, d: 0, sgn: 0, fsel: 0, x: 0, dv: 0, q: 0, rnd: 0, p: 0,
                  status: 0, err: 0, ovf: 0, state: "IDLE",
                  div: { r: 0, qd: 0, dv: 0, cnt: 0, run: 0, done: 0 } };
      Object.assign(this, z);
      this.cycle = 0;
    }
    // multiplier output as seen by the current state (shared multiplier)
    multOut() {
      const n = this.n, w = 2 * n;
      if (this.state === "SQR") return this.c * this.c;
      const av = this.sgn ? toSigned(this.a, n) : this.a;
      const bv = this.sgn ? toSigned(this.b, n) : this.b;
      return toPattern(av * bv, w);
    }
    shiftOut() {
      const w = 2 * this.n;
      const xv = this.sgn ? toSigned(this.x, w) : this.x;
      const q = Math.floor(xv / 2 ** Math.min(this.c, 64));
      const lost = xv - q * 2 ** Math.min(this.c, 64) !== 0;
      return { q: toPattern(this.c >= 64 ? (xv < 0 ? -1 : 0) : q, w), rnd: (xv < 0 && lost) ? 1 : 0 };
    }
    neg() { return this.sgn && bit(this.x, 2 * this.n - 1) ? 1 : 0; }
    xMag() { const w = 2 * this.n; return this.neg() ? toPattern(-toSigned(this.x, w), w) : this.x; }
    finalAdd() {
      const w = 2 * this.n;
      if (this.fsel && this.c === 0) return { p: 0, ovf: 0, err: 1 };
      const qv = this.sgn ? toSigned(this.q, w) : this.q;
      const dv = this.sgn ? toSigned(this.d, this.dw) : this.d;
      const r = qv + dv + this.rnd;
      const ovf = this.sgn ? (r < -(2 ** (w - 1)) || r >= 2 ** (w - 1) ? 1 : 0) : (r >= 2 ** w ? 1 : 0);
      return { p: toPattern(r, w), ovf, err: 0 };
    }
    /* One rising clock edge.  inp = {load, A, B, C, D, sgn, fsel}.  Returns what changed. */
    step(inp) {
      const n = this.n, w = 2 * n, load = inp.load ? 1 : 0;
      const nx = {};                                  // next register values
      const ev = [];
      const div = this.div;
      const ndiv = Object.assign({}, div, { done: 0 });
      const mo = this.multOut();
      const divStart = this.state === "DIV_GO" && !load;
      // restoring divider (runs regardless of the FSM, like the RTL)
      if (divStart) {
        Object.assign(ndiv, { r: 0, qd: this.xMag(), dv: this.dv, cnt: w, run: 1 });
      } else if (div.run) {
        const trial = div.r * 2 + bit(div.qd, w - 1);
        const ok = trial >= div.dv;
        ndiv.r = ok ? trial - div.dv : trial;
        ndiv.qd = toPattern(div.qd * 2 + (ok ? 1 : 0), w);
        if (div.cnt === 1) { ndiv.run = 0; ndiv.done = 1; }
        ndiv.cnt = div.cnt - 1;
      }
      if (load) {
        Object.assign(nx, { a: inp.A % 2 ** n, b: inp.B % 2 ** n, c: inp.C % 2 ** this.cw, d: inp.D % 2 ** this.dw,
                            sgn: inp.sgn ? 1 : 0, fsel: inp.fsel ? 1 : 0, status: 0, err: 0, ovf: 0,
                            state: inp.fsel ? "SQR" : "MUL" });
        ev.push("load");
      } else {
        switch (this.state) {
          case "SQR": nx.dv = mo; nx.state = "MUL"; ev.push("dv"); break;
          case "MUL":
            nx.x = mo; ev.push("x");
            nx.state = !this.fsel ? "SHIFT" : (this.c === 0 ? "ADD" : "DIV_GO");
            break;
          case "SHIFT": { const s = this.shiftOut(); nx.q = s.q; nx.rnd = s.rnd; nx.state = "ADD"; ev.push("q"); break; }
          case "DIV_GO": nx.state = "DIV_WAIT"; ev.push("divstart"); break;
          case "DIV_WAIT":
            if (div.done) {
              const ng = this.neg();
              nx.q = ng ? toPattern(-div.qd - 1, w) : div.qd; nx.rnd = ng; nx.state = "ADD"; ev.push("q");
            }
            break;
          case "ADD": { const f = this.finalAdd(); Object.assign(nx, { p: f.p, ovf: f.ovf, err: f.err, status: 1, state: "IDLE" }); ev.push("p"); break; }
          default: break;
        }
      }
      Object.assign(this, nx);
      this.div = ndiv;
      this.cycle++;
      return ev;
    }
    snapshot() {
      return { cycle: this.cycle, state: this.state, a: this.a, b: this.b, c: this.c, d: this.d, sgn: this.sgn, fsel: this.fsel,
               x: this.x, dv: this.dv, q: this.q, rnd: this.rnd, p: this.p, status: this.status, err: this.err, ovf: this.ovf,
               div: Object.assign({}, this.div) };
    }
  }

  /* ------------------------------------------------------ Dadda plan */
  function ppHeight(n, k) {
    let h = k <= 2 * n - 2 ? Math.min(k, 2 * n - 2 - k) + 1 : 0;
    if (k === n || k === 2 * n - 1) h += 1;
    return h;
  }
  function daddaTargets(maxh) {
    const d = [2];
    while (Math.floor(d[d.length - 1] * 3 / 2) < maxh) d.push(Math.floor(d[d.length - 1] * 3 / 2));
    return d.filter((x) => x < maxh).reverse();
  }
  const planCache = {};
  function daddaPlan(n) {
    if (planCache[n]) return planCache[n];
    const w = 2 * n;
    let h = []; for (let k = 0; k < w; k++) h.push(ppHeight(n, k));
    const heights = [h.slice()], fa = [], ha = [];
    const targets = daddaTargets(Math.max(...h));
    for (const d of targets) {
      const f = new Array(w).fill(0), a = new Array(w).fill(0), nh = new Array(w).fill(0);
      let cin = 0;
      for (let k = 0; k < w; k++) {
        const ex = h[k] + cin - d;
        let ff = 0, aa = 0;
        if (ex > 0) { ff = Math.min(Math.floor(ex / 2), Math.floor(h[k] / 3)); aa = Math.min(ex - 2 * ff, Math.floor((h[k] - 3 * ff) / 2)); }
        f[k] = ff; a[k] = aa; nh[k] = h[k] - 2 * ff - aa + cin; cin = ff + aa;
      }
      heights.push(nh); fa.push(f); ha.push(a); h = nh;
    }
    return (planCache[n] = { n, targets, heights, fa, ha });
  }

  // bit objects: {v, kind, i, j}  kind: pp | ppi (inverted pp) | const | pass | fas | fac | has | hac
  function daddaTrace(a, b, n, sgn) {
    const w = 2 * n, plan = daddaPlan(n);
    let cols = [];
    for (let k = 0; k < w; k++) {
      const col = [];
      for (let i = 0; i < n; i++) {
        const j = k - i;
        if (j < 0 || j >= n) continue;
        const inv = sgn && ((i === n - 1) !== (j === n - 1)) ? 1 : 0;
        col.push({ v: (bit(a, i) & bit(b, j)) ^ inv, kind: inv ? "ppi" : "pp", i, j });
      }
      if (k === n || k === w - 1) col.push({ v: sgn ? 1 : 0, kind: "const" });
      cols.push(col);
    }
    const stages = [cols];
    for (let st = 0; st < plan.fa.length; st++) {
      const keep = [], sums = [], carries = [];
      for (let k = 0; k <= w; k++) { keep.push([]); sums.push([]); carries.push([]); }
      for (let k = 0; k < w; k++) {
        const col = cols[k], f = plan.fa[st][k], h = plan.ha[st][k];
        const fs = [], fc = [], hs = [], hc = [];
        for (let t = 0; t < f; t++) {
          const [x, y, z] = col.slice(3 * t, 3 * t + 3).map((o) => o.v);
          fs.push({ v: x ^ y ^ z, kind: "fas", t }); fc.push({ v: (x & y) | (x & z) | (y & z), kind: "fac", t });
        }
        for (let u = 0; u < h; u++) {
          const [x, y] = col.slice(3 * f + 2 * u, 3 * f + 2 * u + 2).map((o) => o.v);
          hs.push({ v: x ^ y, kind: "has", t: u }); hc.push({ v: x & y, kind: "hac", t: u });
        }
        keep[k] = col.slice(3 * f + 2 * h).map((o) => Object.assign({}, o, { kind: o.kind === "pp" || o.kind === "ppi" || o.kind === "const" ? o.kind : "pass" }));
        sums[k] = fs.concat(hs);
        carries[k + 1] = fc.concat(hc);
      }
      cols = []; for (let k = 0; k < w; k++) cols.push(keep[k].concat(sums[k], carries[k]));
      stages.push(cols);
    }
    let x = 0, y = 0;
    cols.forEach((col, k) => { if (col[0]) x += col[0].v * 2 ** k; if (col[1]) y += col[1].v * 2 ** k; });
    return { plan, stages, x, y, p: (x + y) % 2 ** w };
  }

  function arrayTrace(a, b, n, sgn) {
    const pp = (i, j) => (bit(a, i) & bit(b, j)) ^ (sgn && ((i === n - 1) !== (j === n - 1)) ? 1 : 0);
    const s = [], c = [], kind = [];
    for (let j = 0; j < n; j++) { s.push(new Array(n).fill(0)); c.push(new Array(n).fill(0)); kind.push(new Array(n).fill("wire")); }
    for (let i = 0; i < n; i++) { s[0][i] = pp(i, 0); kind[0][i] = "pp"; }
    let p = s[0][0];
    for (let j = 1; j < n; j++) {
      for (let i = 0; i < n; i++) {
        const up = i < n - 1 ? s[j - 1][i + 1] : 0;
        const t = pp(i, j) + up + c[j - 1][i];
        s[j][i] = t & 1; c[j][i] = t >> 1;
        kind[j][i] = j === 1 ? (i < n - 1 ? "HA" : "wire") : (i < n - 1 ? "FA" : "HA");
      }
      p += s[j][0] * 2 ** j;
    }
    let x = 0, y = 0;
    for (let m = 0; m < n - 1; m++) x += s[n - 1][m + 1] * 2 ** m;
    x += (sgn ? 1 : 0) * 2 ** (n - 1);
    for (let m = 0; m < n; m++) y += c[n - 1][m] * 2 ** m;
    const hi = (x + y + (sgn ? 1 : 0)) % 2 ** n;
    return { s, c, kind, x, y, hi, p: p + hi * 2 ** n };
  }

  /* ------------------------------------------------ gate/cell netlist */
  // A netlist is a list of cells {type, ins:[net], outs:[net]} over numbered nets.
  // Nets 0..n-1 = a, n..2n-1 = b, 2n = sgn, 2n+1 = const 0, 2n+2 = const 1.
  function buildNetlist(n, arch, cpa) {
    let next = 2 * n + 3;
    const ZERO = 2 * n + 1, ONE = 2 * n + 2, SGN = 2 * n;
    const cells = [];
    const net = () => next++;
    const A = (i) => i, B = (j) => n + j;
    const cell = (type, ins, nouts, tag) => { const outs = []; for (let k = 0; k < nouts; k++) outs.push(net()); cells.push({ type, ins, outs, tag }); return outs; };
    const ppNet = (i, j) => cell("PP", [A(i), B(j), (i === n - 1) !== (j === n - 1) ? SGN : ZERO], 1, { i, j })[0];

    function adder(xs, ys, ci, w, kind) {           // returns {s:[nets], co}
      if (kind === "RIPPLE") {
        const s = []; let c = ci;
        for (let i = 0; i < w; i++) { const [so, co] = cell("FA", [xs[i], ys[i], c], 2, { cpa: i }); s.push(so); c = co; }
        return { s, co: c };
      }
      // Kogge-Stone (INFERRED is modelled as Kogge-Stone depth here)
      const M = w + 1; let L = 0; while (2 ** L < M) L++;
      let g = [ci], p = [ZERO]; const hp = [];
      for (let i = 0; i < w; i++) { const [ps, gs] = cell("HA", [xs[i], ys[i]], 2, { pg: i }); hp.push(ps); g.push(gs); p.push(ps); }
      for (let l = 1; l <= L; l++) {
        const d = 2 ** (l - 1), ng = g.slice(), np = p.slice();
        for (let i = d; i < M; i++) { const [go, po] = cell("BK", [g[i], p[i], g[i - d], p[i - d]], 2, { l, i }); ng[i] = go; np[i] = po; }
        g = ng; p = np;
      }
      const s = []; for (let i = 0; i < w; i++) s.push(cell("XOR", [hp[i], g[i]], 1, { sum: i })[0]);
      return { s, co: g[w] };
    }

    const P = new Array(2 * n);
    if (arch === "ARRAY") {
      const sv = [], cv = [];
      for (let j = 0; j < n; j++) { sv.push([]); cv.push([]); }
      for (let i = 0; i < n; i++) { sv[0][i] = ppNet(i, 0); cv[0][i] = ZERO; }
      for (let j = 1; j < n; j++) {
        for (let i = 0; i < n; i++) {
          const pp = ppNet(i, j);
          if (j === 1 && i < n - 1) { const [s, c] = cell("HA", [pp, sv[0][i + 1]], 2, { row: j, col: i }); sv[j][i] = s; cv[j][i] = c; }
          else if (j === 1) { sv[j][i] = pp; cv[j][i] = ZERO; }
          else if (i < n - 1) { const [s, c] = cell("FA", [pp, sv[j - 1][i + 1], cv[j - 1][i]], 2, { row: j, col: i }); sv[j][i] = s; cv[j][i] = c; }
          else { const [s, c] = cell("HA", [pp, cv[j - 1][i]], 2, { row: j, col: i }); sv[j][i] = s; cv[j][i] = c; }
        }
      }
      for (let j = 0; j < n; j++) P[j] = sv[j][0];
      const xs = [], ys = [];
      for (let m = 0; m < n - 1; m++) xs.push(sv[n - 1][m + 1]);
      xs.push(SGN);
      for (let m = 0; m < n; m++) ys.push(cv[n - 1][m]);
      const r = adder(xs, ys, SGN, n, cpa);
      for (let m = 0; m < n; m++) P[n + m] = r.s[m];
    } else {
      const w = 2 * n, plan = daddaPlan(n);
      let cols = [];
      for (let k = 0; k < w; k++) {
        const col = [];
        for (let i = 0; i < n; i++) { const j = k - i; if (j >= 0 && j < n) col.push(ppNet(i, j)); }
        if (k === n || k === w - 1) col.push(SGN);
        cols.push(col);
      }
      for (let st = 0; st < plan.fa.length; st++) {
        const keep = [], sums = [], carries = [];
        for (let k = 0; k <= w; k++) { keep.push([]); sums.push([]); carries.push([]); }
        for (let k = 0; k < w; k++) {
          const col = cols[k], f = plan.fa[st][k], h = plan.ha[st][k];
          const fs = [], fc = [], hs = [], hc = [];
          for (let t = 0; t < f; t++) { const [s, c] = cell("FA", col.slice(3 * t, 3 * t + 3), 2, { st, k }); fs.push(s); fc.push(c); }
          for (let u = 0; u < h; u++) { const [s, c] = cell("HA", col.slice(3 * f + 2 * u, 3 * f + 2 * u + 2), 2, { st, k }); hs.push(s); hc.push(c); }
          keep[k] = col.slice(3 * f + 2 * h); sums[k] = fs.concat(hs); carries[k + 1] = fc.concat(hc);
        }
        cols = []; for (let k = 0; k < w; k++) cols.push(keep[k].concat(sums[k], carries[k]));
      }
      const xs = cols.map((c) => (c.length > 0 ? c[0] : ZERO));
      const ys = cols.map((c) => (c.length > 1 ? c[1] : ZERO));
      const r = adder(xs, ys, ZERO, w, cpa);
      for (let k = 0; k < w; k++) P[k] = r.s[k];
    }
    return { n, arch, cpa, nets: next, cells, P, counts: cells.reduce((o, c) => { o[c.type] = (o[c.type] || 0) + 1; return o; }, {}) };
  }

  function evalCell(type, v) {
    switch (type) {
      case "PP": return [(v[0] & v[1]) ^ v[2]];
      case "HA": return [v[0] ^ v[1], v[0] & v[1]];
      case "FA": return [v[0] ^ v[1] ^ v[2], (v[0] & v[1]) | (v[0] & v[2]) | (v[1] & v[2])];
      case "BK": return [v[0] | (v[1] & v[2]), v[1] & v[3]];
      case "XOR": return [v[0] ^ v[1]];
      default: throw new Error(type);
    }
  }

  function setInputs(vals, nl, a, b, sgn) {
    const n = nl.n;
    for (let i = 0; i < n; i++) { vals[i] = bit(a, i); vals[n + i] = bit(b, i); }
    vals[2 * n] = sgn ? 1 : 0; vals[2 * n + 1] = 0; vals[2 * n + 2] = 1;
  }

  // settle the netlist completely (zero delay)
  function settle(nl, a, b, sgn) {
    const vals = new Uint8Array(nl.nets);
    setInputs(vals, nl, a, b, sgn);
    for (const c of nl.cells) {               // cells are in topological order by construction
      const o = evalCell(c.type, c.ins.map((i) => vals[i]));
      c.outs.forEach((net, k) => { vals[net] = o[k]; });
    }
    return { vals, p: nl.P.reduce((acc, net, k) => acc + vals[net] * 2 ** k, 0) };
  }

  /* Unit-delay simulation: every cell output at step t is its function of the
   * inputs at step t-1.  Starts settled on (a0,b0), switches to (a1,b1) at t=0.
   * Returns the product seen at each step and how many cells toggled. */
  function unitDelaySim(nl, from, to, maxSteps = 400) {
    let cur = settle(nl, from.a, from.b, from.sgn).vals;
    const trace = [], toggles = [];
    let stable = 0;
    setInputs(cur, nl, to.a, to.b, to.sgn);
    const readP = (v) => nl.P.reduce((acc, net, k) => acc + v[net] * 2 ** k, 0);
    trace.push(readP(cur)); toggles.push(0);
    for (let t = 1; t <= maxSteps; t++) {
      const nxt = cur.slice();
      let tog = 0;
      for (const c of nl.cells) {
        const o = evalCell(c.type, c.ins.map((i) => cur[i]));
        c.outs.forEach((net, k) => { if (nxt[net] !== o[k]) tog++; nxt[net] = o[k]; });
      }
      cur = nxt;
      trace.push(readP(cur)); toggles.push(tog);
      if (tog === 0) { stable++; if (stable >= 1) break; } else stable = 0;
    }
    let settleAt = trace.length - 1;
    while (settleAt > 0 && trace[settleAt - 1] === trace[trace.length - 1]) settleAt--;
    return { trace, toggles, settleAt, final: trace[trace.length - 1] };
  }

  // longest path in cells (static depth)
  function depth(nl) {
    const d = new Int32Array(nl.nets);
    let worst = 0;
    for (const c of nl.cells) {
      const din = Math.max(...c.ins.map((i) => d[i])) + 1;
      c.outs.forEach((o) => { d[o] = din; });
    }
    for (const p of nl.P) worst = Math.max(worst, d[p]);
    return worst;
  }

  /* --------------------------------------------- shift divider detail */
  function shiftDetail(x, c, w, sgn) {
    const xv = sgn ? toSigned(x, w) : x % 2 ** w;
    const sh = Math.min(c, 64);
    const floorQ = Math.floor(xv / 2 ** sh);
    const lost = xv - floorQ * 2 ** sh;
    const rnd = xv < 0 && lost !== 0 ? 1 : 0;
    return { xv, floorQ, lost, rnd, trunc: floorQ + rnd, pattern: toPattern(floorQ, w) };
  }

  function restoringSteps(dividend, divisor, w) {
    const steps = []; let r = 0, qd = dividend;
    for (let k = 0; k < w; k++) {
      const inBit = bit(qd, w - 1), trial = r * 2 + inBit, ok = trial >= divisor ? 1 : 0;
      r = ok ? trial - divisor : trial;
      qd = toPattern(qd * 2 + ok, w);
      steps.push({ k, inBit, trial, ok, r, qd });
    }
    return steps;
  }

  const AU = { mask, bit, toSigned, toPattern, divTrunc, arithMin, arithUnit, AUSim, ppHeight, daddaPlan, daddaTrace,
               arrayTrace, buildNetlist, settle, unitDelaySim, depth, shiftDetail, restoringSteps };
  if (typeof module !== "undefined" && module.exports) module.exports = AU;
  else root.AU = AU;
})(typeof window !== "undefined" ? window : globalThis);
