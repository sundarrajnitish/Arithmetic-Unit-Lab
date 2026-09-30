// Arithmetic Unit Lab - checks the website's JavaScript model against the
// golden-model vectors (same files the VHDL testbenches use).
// Author: Nitish Sundarraj          Run: node tests/test_js_model.mjs
import { readFileSync } from "node:fs";
import { createRequire } from "node:module";
const require = createRequire(import.meta.url);
const AU = require("../docs/js/model.js");

let checks = 0, fails = 0;
const expect = (cond, msg) => { checks++; if (!cond) { fails++; if (fails < 15) console.error("FAIL", msg); } };

function vectors(file) {
  return readFileSync(new URL(`../tb/vectors/${file}`, import.meta.url), "utf8").split("\n")
    .filter((l) => l && !l.startsWith("#")).map((l) => {
      const f = l.trim().split(/\s+/);
      const h = f.slice(0, 9).map((x) => parseInt(x, 16));
      return { a: h[0], b: h[1], c: h[2], d: h[3], sgn: h[4], fsel: h[5], p: h[6], err: h[7], ovf: h[8], lat: +f[9] };
    });
}

for (const [file, n, cw, dw] of [["arith_unit_n8.txt", 8, 8, 8], ["arith_unit_n4.txt", 4, 4, 4],
                                 ["arith_unit_n16.txt", 16, 8, 16], ["arith_unit_n8_dw16.txt", 8, 8, 16]]) {
  const vs = vectors(file);
  for (const v of vs) {
    const r = AU.arithUnit(v.a, v.b, v.c, v.d, v.sgn, v.fsel, n, cw, dw);
    expect(r.p === v.p && r.err === v.err && r.ovf === v.ovf && r.latency === v.lat, `${file} formula ${JSON.stringify(v)} got ${JSON.stringify(r)}`);
  }
  // cycle-accurate simulator through the handshake
  const sim = new AU.AUSim(n, cw, dw);
  for (const v of vs) {
    sim.step({ load: 1, A: v.a, B: v.b, C: v.c, D: v.d, sgn: v.sgn, fsel: v.fsel });
    let cyc = 0;
    while (!sim.status && cyc < 4 * n + 20) { sim.step({ load: 0 }); cyc++; }
    expect(cyc === v.lat && sim.p === v.p && sim.err === v.err && sim.ovf === v.ovf,
      `${file} AUSim ${JSON.stringify(v)} got lat ${cyc} p ${sim.p} err ${sim.err} ovf ${sim.ovf}`);
    sim.step({ load: 0 });
    expect(sim.status === 1 && sim.p === v.p, `${file} result hold`);
  }
  console.log(`  ${file}: ${vs.length} vectors (formula + cycle simulator)`);
}

// multipliers: trace functions and cell netlists
const rnd = (() => { let s = 12345; return () => (s = (s * 1103515245 + 12345) % 2147483648) / 2147483648; })();
const nets = {};
for (const n of [2, 3, 4, 5, 8, 12, 16]) {
  for (const arch of ["ARRAY", "DADDA"]) for (const cpa of ["RIPPLE", "KOGGE_STONE"]) nets[`${n}${arch}${cpa}`] = AU.buildNetlist(n, arch, cpa);
  const pairs = [];
  if (n <= 4) { for (let a = 0; a < 2 ** n; a++) for (let b = 0; b < 2 ** n; b++) pairs.push([a, b]); }
  else for (let k = 0; k < 300; k++) pairs.push([Math.floor(rnd() * 2 ** n), Math.floor(rnd() * 2 ** n)]);
  for (const [a, b] of pairs) for (const sgn of [0, 1]) {
    const w = 2 * n;
    const want = sgn ? AU.toPattern(AU.toSigned(a, n) * AU.toSigned(b, n), w) : a * b;
    expect(AU.daddaTrace(a, b, n, sgn).p === want, `daddaTrace n=${n} ${a}*${b} sgn=${sgn}`);
    expect(AU.arrayTrace(a, b, n, sgn).p === want, `arrayTrace n=${n} ${a}*${b} sgn=${sgn}`);
    for (const arch of ["ARRAY", "DADDA"]) for (const cpa of ["RIPPLE", "KOGGE_STONE"]) {
      expect(AU.settle(nets[`${n}${arch}${cpa}`], a, b, sgn).p === want, `netlist ${n} ${arch}/${cpa} ${a}*${b} sgn=${sgn}`);
    }
  }
}
// unit-delay simulation must end on the right product
for (const arch of ["ARRAY", "DADDA"]) for (const cpa of ["RIPPLE", "KOGGE_STONE"]) {
  const nl = nets[`8${arch}${cpa}`];
  const r = AU.unitDelaySim(nl, { a: 0, b: 0, sgn: 0 }, { a: 255, b: 255, sgn: 0 });
  expect(r.final === 65025, `unitDelaySim ${arch}/${cpa}`);
  console.log(`  N=8 ${arch}/${cpa}: depth ${AU.depth(nl)} cells, 0x0 -> 255x255 settles after ${r.settleAt}`);
}
// Dadda plan identical to the Python model for N=8
const plan = AU.daddaPlan(8);
expect(JSON.stringify(plan.targets) === "[6,4,3,2]", "dadda targets");
expect(plan.fa.flat().reduce((x, y) => x + y) === 36 && plan.ha.flat().reduce((x, y) => x + y) === 6, "dadda adder counts");

console.log(fails ? `FAIL ${fails} of ${checks}` : `PASS test_js_model checks=${checks}`);
process.exit(fails ? 1 : 0);
