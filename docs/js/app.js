/* Arithmetic Unit Lab - page behaviour.  Author: Nitish Sundarraj
 * Every number shown comes from docs/js/model.js (the tested port of the RTL)
 * or from docs/data/site-data.js (written by scripts/build_site_data.py from
 * the regression and synthesis runs).
 */
(function () {
  "use strict";
  const AU = window.AU;
  const DATA = window.AU_DATA || { synth: { rows: [] }, tests: [] };
  const $ = (s, r = document) => r.querySelector(s);
  const $$ = (s, r = document) => Array.from(r.querySelectorAll(s));
  const css = (n) => getComputedStyle(document.documentElement).getPropertyValue(n).trim();
  const hex = (v, w) => v.toString(16).toUpperCase().padStart(Math.ceil(w / 4), "0");
  const bin = (v, w) => v.toString(2).padStart(w, "0");
  const fmt = (v) => v.toLocaleString("en-US");
  const esc = (s) => String(s).replace(/[&<>"]/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;" }[c]));
  const reduce = window.matchMedia("(prefers-reduced-motion: reduce)").matches;
  const svgNS = "http://www.w3.org/2000/svg";

  /* ------------------------------------------------------------- theme */
  const redraws = [];
  const onTheme = (f) => redraws.push(f);
  const fire = () => redraws.forEach((f) => { try { f(); } catch (e) { console.error(e); } });
  try { const t = localStorage.getItem("au-theme"); if (t) document.documentElement.dataset.theme = t; } catch (e) { /* storage unavailable */ }
  const isDark = () => {
    const t = document.documentElement.dataset.theme;
    return t ? t === "dark" : window.matchMedia("(prefers-color-scheme: dark)").matches;
  };
  $("#themeBtn").addEventListener("click", () => {
    const t = isDark() ? "light" : "dark";
    document.documentElement.dataset.theme = t;
    try { localStorage.setItem("au-theme", t); } catch (e) { /* ignore */ }
    fire();
  });
  window.matchMedia("(prefers-color-scheme: dark)").addEventListener("change", fire);
  let resizeT;
  window.addEventListener("resize", () => { clearTimeout(resizeT); resizeT = setTimeout(fire, 150); });

  function fitCanvas(cv, w, h) {
    const dpr = Math.min(window.devicePixelRatio || 1, 2);
    cv.width = Math.round(w * dpr); cv.height = Math.round(h * dpr);
    cv.style.width = w + "px"; cv.style.height = h + "px";
    const g = cv.getContext("2d");
    g.setTransform(dpr, 0, 0, dpr, 0, 0);
    return g;
  }

  /* nav highlight */
  const links = $$(".nav li a");
  const secs = links.map((a) => $(a.getAttribute("href")));
  if ("IntersectionObserver" in window) {
    const io = new IntersectionObserver((ents) => {
      ents.forEach((e) => { if (e.isIntersecting) links.forEach((a) => a.classList.toggle("on", a.getAttribute("href") === "#" + e.target.id)); });
    }, { rootMargin: "-45% 0px -50% 0px" });
    secs.forEach((s) => s && io.observe(s));
  }

  /* ------------------------------------------------ hero: circuit traces */
  function drawTraces() {
    const cv = $("#traceBg"), host = cv.parentElement;
    const w = host.clientWidth, h = host.clientHeight;
    const g = fitCanvas(cv, w, h);
    g.clearRect(0, 0, w, h);
    let s = 7;
    const r = () => (s = (s * 16807) % 2147483647) / 2147483647;
    g.strokeStyle = "rgba(200,170,255,.16)"; g.lineWidth = 1;
    g.fillStyle = "rgba(200,170,255,.28)";
    for (let k = 0; k < 26; k++) {
      let x = r() * w, y = r() * h;
      g.beginPath(); g.moveTo(x, y);
      for (let seg = 0; seg < 4; seg++) {
        if (seg % 2 === 0) x += (r() - .5) * 360; else y += (r() - .5) * 180;
        if (r() < .3) { const d = (r() - .5) * 60; x += d; y += d; }
        g.lineTo(x, y);
      }
      g.stroke();
      g.beginPath(); g.arc(x, y, 2.2, 0, Math.PI * 2); g.fill();
    }
  }
  onTheme(drawTraces);

  /* ------------------------------------------------ hero: Dadda dots */
  const hero = { n: 8, stage: 0, t0: 0, trace: AU.daddaTrace(181, 109, 8, 0) };
  function kindColor(kind) {
    return { pp: css("--dot-pp"), ppi: css("--dot-inv"), const: css("--dot-const"), fas: css("--dot-sum"), has: css("--dot-sum"),
             fac: css("--dot-carry"), hac: css("--dot-carry"), pass: css("--dot-pass") }[kind] || css("--dot-pass");
  }
  function drawHero(progress) {
    const cv = $("#heroDots");
    const w = Math.max(240, cv.parentElement.clientWidth - 34), h = w * 10 / 16;
    const g = fitCanvas(cv, w, h);
    const tr = hero.trace, cols = tr.stages[hero.stage], W = 16;
    const pad = w * 0.05, cw = (w - 2 * pad) / W, rh = Math.min(cw, (h - 60) / 8.5), r = Math.min(cw, rh) * 0.34;
    g.clearRect(0, 0, w, h);
    g.strokeStyle = "rgba(255,255,255,.08)";
    for (let k = 0; k < W; k++) { const x = pad + (W - 1 - k) * cw + cw / 2; g.beginPath(); g.moveTo(x, 12); g.lineTo(x, h - 36); g.stroke(); }
    const target = hero.stage === 0 ? 8 : tr.plan.targets[hero.stage - 1];
    const ty = h - 40 - target * rh;
    g.strokeStyle = "rgba(242,193,78,.7)"; g.setLineDash([5, 5]);
    g.beginPath(); g.moveTo(pad - 4, ty + rh * 0.5); g.lineTo(w - pad + 4, ty + rh * 0.5); g.stroke(); g.setLineDash([]);
    const brand = { pp: "#c9a6f5", ppi: "#ff7ab6", const: "#ffb347", fas: "#6cc8ff", has: "#6cc8ff", fac: "#43d19c", hac: "#43d19c", pass: "#b8aecb" };
    cols.forEach((col, k) => {
      col.forEach((b, q) => {
        const x = pad + (W - 1 - k) * cw + cw / 2;
        const y = h - 40 - q * rh - rh / 2;
        const a = Math.min(1, progress * 1.4 + 0.15);
        g.globalAlpha = b.kind === "pass" || b.kind === "pp" ? 1 : a;
        g.beginPath(); g.arc(x, y, r, 0, Math.PI * 2);
        if (b.v) { g.fillStyle = brand[b.kind]; g.fill(); }
        else { g.strokeStyle = brand[b.kind]; g.lineWidth = 1.6; g.stroke(); }
      });
    });
    g.globalAlpha = 1;
    g.fillStyle = "rgba(255,255,255,.45)"; g.font = "11px IBM Plex Mono, monospace"; g.textAlign = "center";
    for (let k = 0; k < W; k += 1) { if (k % 3 === 0 || k === W - 1) g.fillText(String(k), pad + (W - 1 - k) * cw + cw / 2, h - 16); }
    const adders = tr.plan.fa.slice(0, hero.stage).flat().reduce((a, b) => a + b, 0);
    const has = tr.plan.ha.slice(0, hero.stage).flat().reduce((a, b) => a + b, 0);
    $("#heroStage").textContent = hero.stage === 0 ? "start" : `${hero.stage} of ${tr.plan.fa.length}`;
    $("#heroTarget").textContent = String(target);
    $("#heroAdders").textContent = `${adders} FA · ${has} HA`;
  }
  function heroLoop(ts) {
    if (!hero.t0) hero.t0 = ts;
    const dt = ts - hero.t0;
    const hold = hero.stage === hero.trace.plan.fa.length ? 2600 : 1500;
    if (dt > hold) {
      hero.t0 = ts;
      hero.stage = (hero.stage + 1) % (hero.trace.plan.fa.length + 1);
      if (hero.stage === 0) {
        const a = 1 + Math.floor(Math.random() * 255), b = 1 + Math.floor(Math.random() * 255);
        hero.trace = AU.daddaTrace(a, b, 8, 0);
      }
    }
    drawHero(Math.min(1, (ts - hero.t0) / 400));
    requestAnimationFrame(heroLoop);
  }
  onTheme(() => drawHero(1));
  if (reduce) { hero.stage = 0; drawHero(1); } else requestAnimationFrame(heroLoop);

  /* ============================================================ SIMULATOR */
  const N = 8, CW = 8, DW = 8, W = 16;
  const sim = new AU.AUSim(N, CW, DW);
  let hist = [];                 // {load, snap}
  let latched = null;            // inputs at the last load, for the reference check
  const ui = { sgn: 0, fsel: 0 };

  function segInit(id, key, cb) {
    $$("#" + id + " button").forEach((b) => b.addEventListener("click", () => {
      $$("#" + id + " button").forEach((x) => x.classList.toggle("on", x === b));
      ui[key] = +b.dataset.v; cb && cb();
    }));
  }
  function setSeg(id, v) { $$("#" + id + " button").forEach((x) => x.classList.toggle("on", +x.dataset.v === v)); }

  function readInputs() {
    const lim = ui.sgn ? [-128, 127] : [0, 255];
    const clamp = (el, lo, hi) => { let v = Math.round(+el.value || 0); v = Math.max(lo, Math.min(hi, v)); el.value = v; return v; };
    const a = clamp($("#inA"), ...lim), b = clamp($("#inB"), ...lim), d = clamp($("#inD"), ...lim), c = clamp($("#inC"), 0, 255);
    return { A: AU.toPattern(a, N), B: AU.toPattern(b, N), C: c, D: AU.toPattern(d, DW), sgn: ui.sgn, fsel: ui.fsel, av: a, bv: b, dv: d };
  }
  function refreshBits() {
    const i = readInputs();
    $("#inAb").textContent = bin(i.A, N); $("#inBb").textContent = bin(i.B, N); $("#inDb").textContent = bin(i.D, DW);
    $("#rangeNote").textContent = ui.sgn ? "A, B, D: −128 … 127 (two's complement), C: 0 … 255" : "A, B, D: 0 … 255, C: 0 … 255";
    ["#inA", "#inB", "#inD"].forEach((s) => { const el = $(s); el.min = ui.sgn ? -128 : 0; el.max = ui.sgn ? 127 : 255; });
  }
  segInit("sgnSeg", "sgn", () => { refreshBits(); });
  segInit("fselSeg", "fsel", () => { refreshBits(); });
  ["#inA", "#inB", "#inC", "#inD"].forEach((s) => $(s).addEventListener("input", refreshBits));

  function clockEdge(load) {
    const inp = load ? readInputs() : { load: 0 };
    if (load) { inp.load = 1; latched = inp; }
    sim.step(inp);
    hist.push({ load: load ? 1 : 0, snap: sim.snapshot() });
    renderSim();
  }
  function resetSim() { sim.reset(); hist = [{ load: 0, snap: sim.snapshot(), reset: true }]; latched = null; renderSim(); }
  $("#bLoad").addEventListener("click", () => clockEdge(true));
  $("#bStep").addEventListener("click", () => clockEdge(false));
  $("#bRun").addEventListener("click", () => {
    let k = 0;
    if (!latched) clockEdge(true);
    while (!sim.status && k < 60) { clockEdge(false); k++; }
    if (sim.status) clockEdge(false);
  });
  $("#bReset").addEventListener("click", resetSim);

  const PRESETS = {
    spec: { sgn: 0, fsel: 0, A: 200, B: 100, C: 2, D: 1 },
    neg: { sgn: 1, fsel: 0, A: -5, B: 3, C: 1, D: 0 },
    sq: { sgn: 0, fsel: 1, A: 200, B: 100, C: 5, D: 7 },
    sqneg: { sgn: 1, fsel: 1, A: -128, B: 127, C: 3, D: -1 },
    dz: { sgn: 0, fsel: 1, A: 17, B: 3, C: 0, D: 9 },
  };
  function runPreset(p) {
    ui.sgn = p.sgn; ui.fsel = p.fsel; setSeg("sgnSeg", p.sgn); setSeg("fselSeg", p.fsel);
    $("#inA").value = p.A; $("#inB").value = p.B; $("#inC").value = p.C; $("#inD").value = p.D;
    refreshBits(); resetSim(); clockEdge(false); clockEdge(true);
    let k = 0; while (!sim.status && k < 60) { clockEdge(false); k++; }
    clockEdge(false);
  }
  $$("#presets .chip").forEach((b) => b.addEventListener("click", () => runPreset(PRESETS[b.dataset.p])));

  /* datapath diagram ---------------------------------------------------- */
  const BLOCKS = [
    { id: "rA", x: 10, y: 20, w: 104, h: 40, t: "A reg" },
    { id: "rB", x: 10, y: 70, w: 104, h: 40, t: "B reg" },
    { id: "rC", x: 10, y: 120, w: 104, h: 40, t: "C reg" },
    { id: "rD", x: 10, y: 170, w: 104, h: 40, t: "D reg" },
    { id: "mux", x: 146, y: 44, w: 34, h: 92, t: "", sub: "" },
    { id: "mult", x: 206, y: 34, w: 124, h: 112, t: "multiplier", sub: "Dadda + KS" },
    { id: "rX", x: 360, y: 40, w: 96, h: 40, t: "x reg" },
    { id: "rDV", x: 360, y: 104, w: 96, h: 40, t: "dv = C²" },
    { id: "shift", x: 488, y: 20, w: 120, h: 44, t: "÷ 2^C shifter" },
    { id: "abs", x: 488, y: 80, w: 56, h: 36, t: "|x|" },
    { id: "div", x: 488, y: 126, w: 120, h: 44, t: "÷ C² restoring" },
    { id: "rQ", x: 636, y: 64, w: 104, h: 40, t: "q reg + rnd" },
    { id: "add", x: 636, y: 150, w: 104, h: 44, t: "q + D + rnd" },
    { id: "rP", x: 636, y: 228, w: 104, h: 40, t: "P reg" },
  ];
  const WIRES = [
    ["rA", "M114,40 H146"], ["rB", "M114,90 H146"], ["rC", "M114,140 H130 V120 H146"],
    ["mux", "M180,90 H206"], ["mult", "M330,60 H360"], ["mult", "M330,124 H360"],
    ["rX", "M456,60 H472 V42 H488"], ["rX", "M456,60 H472 V98 H488"], ["abs", "M544,98 H560 V126"], ["rDV", "M456,124 H472 V148 H488"],
    ["shift", "M608,42 H622 V84 H636"], ["div", "M608,148 H622 V92 H636"],
    ["rQ", "M688,104 V150"], ["rD", "M114,190 H300 V210 H600 V172 H636"], ["add", "M688,194 V228"],
  ];
  const ACTIVE = {
    IDLE: [], SQR: ["rC", "mux", "mult", "rDV"], MUL: ["rA", "rB", "mux", "mult", "rX"],
    SHIFT: ["rX", "rC", "shift", "rQ"], DIV_GO: ["rX", "abs", "rDV", "div"], DIV_WAIT: ["div", "rQ"], ADD: ["rQ", "rD", "add", "rP"],
  };
  const STATES = ["IDLE", "SQR", "MUL", "SHIFT", "DIV_GO", "DIV_WAIT", "ADD"];
  function buildDatapath() {
    const s = [`<svg viewBox="0 0 760 350" role="img" aria-label="Datapath of arith_unit">`];
    s.push(`<defs><marker id="ah" markerWidth="7" markerHeight="7" refX="6" refY="3.5" orient="auto"><path d="M0,0 L7,3.5 L0,7 z" fill="var(--ink-3)"/></marker></defs>`);
    WIRES.forEach(([from, d], i) => s.push(`<path id="w${i}" data-from="${from}" d="${d}" fill="none" stroke="var(--line)" stroke-width="1.6" marker-end="url(#ah)"/>`));
    BLOCKS.forEach((b) => {
      const isMux = b.id === "mux";
      const shape = isMux
        ? `<path d="M${b.x},${b.y} L${b.x + b.w},${b.y + 14} L${b.x + b.w},${b.y + b.h - 14} L${b.x},${b.y + b.h} Z"`
        : `<rect x="${b.x}" y="${b.y}" width="${b.w}" height="${b.h}" rx="3"`;
      s.push(`<g class="blk" id="b_${b.id}">${shape} fill="var(--panel)" stroke="var(--line)" stroke-width="1.4"/>`);
      if (!isMux) {
        s.push(`<text x="${b.x + 8}" y="${b.y + 15}" font-family="var(--f-display)" font-size="12.5" font-weight="700" fill="var(--ink-2)">${esc(b.t)}</text>`);
        s.push(`<text id="v_${b.id}" x="${b.x + 8}" y="${b.y + b.h - 9}" font-family="var(--f-mono)" font-size="13" fill="var(--ink)">${esc(b.sub || "")}</text>`);
      } else {
        s.push(`<text x="${b.x + 17}" y="${b.y + 50}" text-anchor="middle" font-family="var(--f-mono)" font-size="10" fill="var(--ink-3)">sel</text>`);
      }
      s.push(`</g>`);
    });
    s.push(`<text x="742" y="290" text-anchor="end" font-family="var(--f-mono)" font-size="12" fill="var(--ink-2)" id="v_out">P, status</text>`);
    // FSM strip
    const sx = 10, sy = 312, sw = 100;
    STATES.forEach((st, i) => {
      const x = sx + i * (sw + 6);
      s.push(`<g id="s_${st}"><rect x="${x}" y="${sy}" width="${sw}" height="28" rx="14" fill="var(--panel)" stroke="var(--line)" stroke-width="1.4"/>`);
      s.push(`<text x="${x + sw / 2}" y="${sy + 18}" text-anchor="middle" font-family="var(--f-mono)" font-size="11.5" font-weight="600" fill="var(--ink-2)">${st}</text></g>`);
    });
    s.push(`<text x="10" y="302" font-family="var(--f-display)" font-size="10.5" font-weight="700" letter-spacing="1.2" fill="var(--ink-3)">STATE MACHINE</text>`);
    s.push(`</svg>`);
    $("#datapath").innerHTML = s.join("");
  }
  buildDatapath();

  const NOTES = {
    IDLE: "Idle. The result registers hold their value; press Load to start.",
    SQR: "SQR: the shared multiplier computes C × C (unsigned) and the edge stores it in dv.",
    MUL: "MUL: the same multiplier now forms A × B; the edge stores the 16-bit product in x.",
    SHIFT: "SHIFT: the barrel shifter divides x by 2^C. It also flags a negative x that lost 1-bits, so the adder can round toward zero.",
    DIV_GO: "DIV_GO: |x| and dv = C² are handed to the restoring divider (start pulse).",
    DIV_WAIT: "DIV_WAIT: the divider produces one quotient bit per clock for 16 clocks.",
    ADD: "ADD: q + D + rnd goes into P; status rises on this edge.",
  };
  function sval(v, bits, sgn) { return sgn ? AU.toSigned(v, bits) : v; }

  function renderSim() {
    const s = sim.snapshot();
    const shown = s.state;
    $("#simState").textContent = shown;
    const act = new Set(ACTIVE[shown] || []);
    if (shown === "IDLE" && s.status) act.add("rP");
    BLOCKS.forEach((b) => {
      const g = $("#b_" + b.id), sh = g.firstElementChild, on = act.has(b.id);
      sh.setAttribute("fill", on ? "var(--accent-soft)" : "var(--panel)");
      sh.setAttribute("stroke", on ? "var(--accent)" : "var(--line)");
    });
    $$("#datapath path[data-from]").forEach((p) => {
      const on = act.has(p.dataset.from);
      p.setAttribute("stroke", on ? "var(--accent)" : "var(--line)");
      p.setAttribute("stroke-width", on ? "2.2" : "1.6");
    });
    STATES.forEach((st) => {
      const g = $("#s_" + st), on = st === shown;
      g.firstElementChild.setAttribute("fill", on ? "var(--accent)" : "var(--panel)");
      g.firstElementChild.setAttribute("stroke", on ? "var(--accent)" : "var(--line)");
      g.lastElementChild.setAttribute("fill", on ? "#ffffff" : "var(--ink-2)");
    });
    const set = (id, t) => { const el = $("#v_" + id); if (el) el.textContent = t; };
    set("rA", `${sval(s.a, N, s.sgn)}`); set("rB", `${sval(s.b, N, s.sgn)}`); set("rC", `${s.c}`); set("rD", `${sval(s.d, DW, s.sgn)}`);
    set("mult", s.state === "SQR" ? `C·C = ${s.c * s.c}` : `${sval(sim.multOut(), W, s.sgn)}`);
    set("rX", `${sval(s.x, W, s.sgn)}`); set("rDV", `${s.dv}`);
    set("shift", `>> ${s.c}`); set("div", s.div.run ? `bit ${W - s.div.cnt + 1}/${W}` : (s.div.done ? "done" : "idle"));
    set("abs", ""); set("rQ", `${sval(s.q, W, s.sgn)} + ${s.rnd}`);
    set("add", ""); set("rP", `${sval(s.p, W, s.sgn)}`);
    $("#v_out").textContent = `P = ${sval(s.p, W, s.sgn)}, status ${s.status}`;
    $("#stateNote").textContent = NOTES[shown] + (shown === "IDLE" && s.status ? " status = 1: P is valid." : "");

    $("#outP").innerHTML = `${fmt(sval(s.p, W, s.sgn))}<small>0x${hex(s.p, W)}</small><small>status ${s.status} · err ${s.err} · ovf ${s.ovf}</small>`;
    // reference check
    let box = "";
    if (latched) {
      const ref = AU.arithUnit(latched.A, latched.B, latched.C, latched.D, latched.sgn, latched.fsel, N, CW, DW);
      const f = latched.fsel ? `${latched.av}·${latched.bv}/${latched.C}² + ${latched.dv}` : `${latched.av}·${latched.bv}/2^${latched.C} + ${latched.dv}`;
      const refV = latched.sgn ? AU.toSigned(ref.p, W) : ref.p;
      const li = hist.map((h) => h.load).lastIndexOf(1);
      let si = hist.findIndex((h, i) => i > li && h.snap.status === 1);
      const cyc = (si < 0 ? hist.length - 1 : si) - li;
      if (s.status) {
        const ok = s.p === ref.p && s.err === ref.err && s.ovf === ref.ovf;
        box = `<span class="pill ${ok ? "good" : "bad"}">${ok ? "matches reference model" : "differs from reference"}</span>
          <p class="small muted mt8">${esc(f)} = ${fmt(refV)}${ref.err ? " (divide by zero: err = 1)" : ""}, ready after ${cyc} clock${cyc === 1 ? "" : "s"}; the model says ${ref.latency}.</p>`;
      } else {
        box = `<span class="pill warn">computing</span><p class="small muted mt8">${esc(f)} will be ${fmt(refV)} after ${ref.latency} clocks (now ${cyc}).</p>`;
      }
    } else box = `<span class="pill info">no load yet</span>`;
    $("#checkBox").innerHTML = box;
    const rows = [["a", `${sval(s.a, N, s.sgn)}`, "rA"], ["b", `${sval(s.b, N, s.sgn)}`, "rB"], ["c", `${s.c}`, "rC"], ["d", `${sval(s.d, DW, s.sgn)}`, "rD"],
      ["sgn / fsel", `${s.sgn} / ${s.fsel}`], ["x", `0x${hex(s.x, W)}`, "rX"], ["dv", `${s.dv}`, "rDV"], ["q, rnd", `0x${hex(s.q, W)}, ${s.rnd}`, "rQ"],
      ["div r / cnt", `${s.div.r} / ${s.div.cnt}`, "div"], ["P", `0x${hex(s.p, W)}`, "rP"]];
    $("#regTable").innerHTML = rows.map(([k, v, b]) => `<tr class="${b && act.has(b) ? "hot" : ""}"><td>${k}</td><td>${v}</td></tr>`).join("");
    drawWave();
    renderSerial();
  }

  /* waveform -------------------------------------------------------------- */
  function drawBus(g, x0, x1, y, h, text, color, xcolor) {
    const m = Math.min(5, (x1 - x0) / 3);
    g.strokeStyle = color; g.lineWidth = 1.2;
    g.beginPath(); g.moveTo(x0, y + h / 2); g.lineTo(x0 + m, y); g.lineTo(x1 - m, y); g.lineTo(x1, y + h / 2); g.lineTo(x1 - m, y + h); g.lineTo(x0 + m, y + h); g.closePath(); g.stroke();
    if (xcolor) { g.fillStyle = xcolor; g.globalAlpha = 0.18; g.fill(); g.globalAlpha = 1; }
    g.save(); g.beginPath(); g.rect(x0 + m, y, x1 - x0 - 2 * m, h); g.clip();
    g.fillStyle = css("--wave-text"); g.font = "11px IBM Plex Mono, monospace"; g.textBaseline = "middle";
    g.fillText(text, x0 + m + 3, y + h / 2 + 0.5); g.restore();
  }
  function waveGeneric(cv, rows, steps, opts = {}) {
    // rows: [{name, kind: 'clk'|'bit'|'bus', vals: [...]}]; vals per step
    const LW = 86, CWd = opts.cw || 46, RH = 24, host = cv.parentElement;
    const w = Math.max(host.clientWidth, LW + steps * CWd + 16), h = rows.length * RH + 12;
    const g = fitCanvas(cv, w, h);
    g.fillStyle = css("--wave-bg"); g.fillRect(0, 0, w, h);
    g.strokeStyle = css("--wave-grid"); g.lineWidth = 1;
    for (let i = 0; i <= steps; i++) { const x = LW + i * CWd + 0.5; g.beginPath(); g.moveTo(x, 4); g.lineTo(x, h - 4); g.stroke(); }
    rows.forEach((r, ri) => {
      const y = 8 + ri * RH, hh = RH - 10;
      g.fillStyle = css("--wave-text"); g.font = "600 11px IBM Plex Mono, monospace"; g.textBaseline = "middle";
      g.fillText(r.name, 8, y + hh / 2);
      if (r.kind === "clk") {
        g.strokeStyle = css("--sig-clk"); g.lineWidth = 1.2; g.beginPath();
        for (let i = 0; i < steps; i++) { const x = LW + i * CWd; g.moveTo(x, y + hh); g.lineTo(x, y); g.lineTo(x + CWd / 2, y); g.lineTo(x + CWd / 2, y + hh); g.lineTo(x + CWd, y + hh); }
        g.stroke();
      } else if (r.kind === "bit") {
        g.lineWidth = 1.5; g.beginPath();
        let prev = null;
        for (let i = 0; i < steps; i++) {
          const v = r.vals[i], x = LW + i * CWd;
          if (v === "X" || v === "Z") { g.stroke(); g.strokeStyle = css(v === "X" ? "--sig-x" : "--sig-z"); g.beginPath(); g.moveTo(x, y + hh / 2); g.lineTo(x + CWd, y + hh / 2); g.stroke(); g.beginPath(); prev = null; continue; }
          const yy = v ? y : y + hh;
          g.strokeStyle = css("--sig-hi");
          if (prev === null) g.moveTo(x, yy); else g.lineTo(x, yy);
          g.lineTo(x + CWd, yy); prev = v;
        }
        g.stroke();
      } else {
        let i = 0;
        while (i < steps) {
          let j = i + 1; while (j < steps && r.vals[j] === r.vals[i]) j++;
          const v = r.vals[i];
          const col = v === "X" || /X/.test(String(v)) ? css("--sig-x") : v === "Z" || /^Z+$/.test(String(v)) ? css("--sig-z") : css("--sig-bus");
          drawBus(g, LW + i * CWd, LW + j * CWd, y, hh, String(v), col, v === "X" ? col : null);
          i = j;
        }
      }
    });
    // frozen label column: a small canvas pinned over the left edge of the scroller
    let lab = cv._lab;
    if (!lab) {
      lab = cv._lab = document.createElement("canvas");
      lab.setAttribute("aria-hidden", "true");
      lab.style.position = "absolute"; lab.style.left = "0"; lab.style.pointerEvents = "none";
      host.parentElement.appendChild(lab);
    }
    lab.style.top = host.offsetTop + "px";
    const lg = fitCanvas(lab, LW - 4, h);
    lg.fillStyle = css("--wave-bg"); lg.fillRect(0, 0, LW - 4, h);
    lg.fillStyle = css("--wave-text"); lg.font = "600 11px IBM Plex Mono, monospace"; lg.textBaseline = "middle";
    rows.forEach((r, ri) => lg.fillText(r.name, 8, 8 + ri * RH + (RH - 10) / 2));
    if (opts.cursor != null) {
      const x = LW + opts.cursor * CWd;
      g.strokeStyle = css("--sig-bus"); g.setLineDash([4, 3]); g.beginPath(); g.moveTo(x + 0.5, 2); g.lineTo(x + 0.5, h - 2); g.stroke(); g.setLineDash([]);
    }
    return w;
  }
  function drawWave() {
    const steps = hist.length;
    const sgnOf = (sn) => sn.sgn;
    const rows = [
      { name: "clk", kind: "clk" },
      { name: "load", kind: "bit", vals: hist.map((h, i) => (hist[i + 1] ? hist[i + 1].load : 0)) },
      { name: "state", kind: "bus", vals: hist.map((h) => h.snap.state) },
      { name: "x", kind: "bus", vals: hist.map((h) => hex(h.snap.x, W)) },
      { name: "q", kind: "bus", vals: hist.map((h) => hex(h.snap.q, W)) },
      { name: "P", kind: "bus", vals: hist.map((h) => String(sval(h.snap.p, W, sgnOf(h.snap)))) },
      { name: "status", kind: "bit", vals: hist.map((h) => h.snap.status) },
      { name: "err", kind: "bit", vals: hist.map((h) => h.snap.err) },
    ];
    $("#waveCycles").textContent = String(steps - 1);
    const cv = $("#wave");
    const w = waveGeneric(cv, rows, steps, { cursor: steps - 1, cw: 46 });
    const sc = $("#waveScroll"); sc.scrollLeft = w;
  }
  onTheme(() => { buildDatapath(); renderSim(); });

  /* ========================================================= MULTIPLIERS */
  const mul = { arch: "DADDA", sgn: 0, stage: 0, playing: null };
  $$("#multipliers .tab").forEach((t) => t.addEventListener("click", () => {
    $$("#multipliers .tab").forEach((x) => { x.classList.toggle("on", x === t); x.setAttribute("aria-selected", x === t ? "true" : "false"); });
    mul.arch = t.dataset.arch; renderMul();
  }));
  $$("#mSgn button").forEach((b) => b.addEventListener("click", () => {
    $$("#mSgn button").forEach((x) => x.classList.toggle("on", x === b)); mul.sgn = +b.dataset.v; clampMul(); renderMul();
  }));
  function clampMul() {
    const n = +$("#mN").value;
    const lo = mul.sgn ? -(2 ** (n - 1)) : 0, hi = mul.sgn ? 2 ** (n - 1) - 1 : 2 ** n - 1;
    ["#mA", "#mB"].forEach((s) => { const el = $(s); el.min = lo; el.max = hi; let v = Math.round(+el.value || 0); el.value = Math.max(lo, Math.min(hi, v)); });
  }
  $("#mN").addEventListener("input", () => { $("#mNv").textContent = $("#mN").value; clampMul(); mul.stage = 0; renderMul(); });
  ["#mA", "#mB"].forEach((s) => $(s).addEventListener("change", () => { clampMul(); renderMul(); }));
  $("#mStage").addEventListener("input", () => { mul.stage = +$("#mStage").value; renderMul(); });
  $("#mRand").addEventListener("click", () => {
    const n = +$("#mN").value;
    const r = () => mul.sgn ? Math.floor(Math.random() * 2 ** n) - 2 ** (n - 1) : Math.floor(Math.random() * 2 ** n);
    $("#mA").value = r(); $("#mB").value = r(); renderMul();
  });
  $("#mPlay").addEventListener("click", () => {
    if (mul.playing) { clearInterval(mul.playing); mul.playing = null; $("#mPlay").textContent = "Play stages"; return; }
    mul.stage = 0; renderMul();
    $("#mPlay").textContent = "Stop";
    mul.playing = setInterval(() => {
      const S = AU.daddaPlan(+$("#mN").value).fa.length;
      if (mul.stage >= S) { clearInterval(mul.playing); mul.playing = null; $("#mPlay").textContent = "Play stages"; return; }
      mul.stage++; renderMul();
    }, 900);
  });

  const KIND_LABEL = [["pp", "partial product aᵢbⱼ"], ["ppi", "complemented (signed)"], ["const", "Baugh-Wooley 1"], ["fas", "adder sum"], ["fac", "adder carry"], ["pass", "passed through"]];
  function renderMul() {
    const n = +$("#mN").value, w = 2 * n, sgn = mul.sgn;
    const av = +$("#mA").value, bv = +$("#mB").value;
    const a = AU.toPattern(av, n), b = AU.toPattern(bv, n);
    const plan = AU.daddaPlan(n), S = plan.fa.length;
    mul.stage = Math.min(mul.stage, S);
    $("#mStage").max = S; $("#mStage").value = mul.stage;
    $("#mStageV").textContent = mul.stage === 0 ? `0 of ${S} (all partial products)` : `${mul.stage} of ${S} (height ≤ ${plan.targets[mul.stage - 1]})`;
    $("#stageCtl").hidden = mul.arch !== "DADDA";
    $("#mCfg").textContent = `N=${n} · ${sgn ? "signed" : "unsigned"} · ${mul.arch === "DADDA" ? "Dadda" : "carry-save array"}`;
    const nlR = AU.buildNetlist(n, mul.arch, "RIPPLE"), nlK = AU.buildNetlist(n, mul.arch, "KOGGE_STONE");
    const fa = mul.arch === "DADDA" ? plan.fa.flat().reduce((x, y) => x + y, 0) : (n - 1) * (n - 2);
    const ha = mul.arch === "DADDA" ? plan.ha.flat().reduce((x, y) => x + y, 0) : (n - 1) + (n - 2);
    $("#mStats").innerHTML = [
      [fa, "full adders in the reduction"], [ha, "half adders"], [mul.arch === "DADDA" ? S : n - 1, mul.arch === "DADDA" ? "reduction stages" : "adder rows"],
      [`${AU.depth(nlR)} / ${AU.depth(nlK)}`, "cells on the longest path, ripple / Kogge-Stone final adder"],
    ].map(([v, l]) => `<div><div class="v">${v}</div><div class="l">${l}</div></div>`).join("");
    const want = sgn ? AU.toPattern(AU.toSigned(a, n) * AU.toSigned(b, n), w) : a * b;
    let p;
    const colW = n > 12 ? 22 : 26, rowH = n > 12 ? 20 : 24;
    const svg = [];
    if (mul.arch === "DADDA") {
      const tr = AU.daddaTrace(a, b, n, sgn); p = tr.p;
      const cols = tr.stages[mul.stage];
      const maxh = Math.max(...plan.heights[0]);
      const W2 = w * colW + 60, H2 = maxh * rowH + 70;
      svg.push(`<svg width="${W2}" viewBox="0 0 ${W2} ${H2}" role="img" aria-label="Dadda stage ${mul.stage}">`);
      const X = (k) => 40 + (w - 1 - k) * colW + colW / 2, Y = (q) => H2 - 46 - q * rowH - rowH / 2;
      if (mul.stage > 0 || true) {
        const tgt = mul.stage === 0 ? null : plan.targets[mul.stage - 1];
        if (tgt) svg.push(`<line x1="30" x2="${W2 - 10}" y1="${Y(tgt - 1) - rowH / 2}" y2="${Y(tgt - 1) - rowH / 2}" stroke="var(--dot-const)" stroke-dasharray="5 4"/><text x="${W2 - 12}" y="${Y(tgt - 1) - rowH / 2 - 5}" text-anchor="end" font-size="11" font-family="var(--f-mono)" fill="var(--dot-const)">target ${tgt}</text>`);
      }
      // brackets for the next stage's adders
      if (mul.stage < S) {
        for (let k = 0; k < w; k++) {
          const f = plan.fa[mul.stage][k], h = plan.ha[mul.stage][k];
          for (let t = 0; t < f; t++) svg.push(`<rect x="${X(k) - colW / 2 + 2}" y="${Y(3 * t + 2) - rowH / 2 + 2}" width="${colW - 4}" height="${3 * rowH - 4}" rx="${colW / 2 - 2}" fill="none" stroke="var(--dot-sum)" stroke-width="1.3"/>`);
          for (let u = 0; u < h; u++) svg.push(`<rect x="${X(k) - colW / 2 + 2}" y="${Y(3 * f + 2 * u + 1) - rowH / 2 + 2}" width="${colW - 4}" height="${2 * rowH - 4}" rx="${colW / 2 - 2}" fill="none" stroke="var(--dot-sum)" stroke-width="1.3" stroke-dasharray="3 2"/>`);
        }
      }
      const colorOf = { pp: "--dot-pp", ppi: "--dot-inv", const: "--dot-const", fas: "--dot-sum", has: "--dot-sum", fac: "--dot-carry", hac: "--dot-carry", pass: "--dot-pass" };
      cols.forEach((col, k) => col.forEach((bt, q) => {
        const c = `var(${colorOf[bt.kind]})`;
        svg.push(`<circle cx="${X(k)}" cy="${Y(q)}" r="${colW * 0.3}" fill="${bt.v ? c : "var(--panel)"}" stroke="${c}" stroke-width="1.8"><title>column ${k}${bt.i != null ? `: a${bt.i}·b${bt.j}` : ""} = ${bt.v}</title></circle>`);
      }));
      for (let k = 0; k < w; k++) svg.push(`<text x="${X(k)}" y="${H2 - 26}" text-anchor="middle" font-size="10" font-family="var(--f-mono)" fill="var(--ink-3)">${k}</text>`);
      if (mul.stage === S) {
        for (let k = 0; k < w; k++) svg.push(`<text x="${X(k)}" y="${H2 - 8}" text-anchor="middle" font-size="12" font-weight="600" font-family="var(--f-mono)" fill="var(--brand-ink)">${AU.bit(p, k)}</text>`);
        svg.push(`<text x="4" y="${H2 - 8}" font-size="11" font-family="var(--f-mono)" fill="var(--ink-3)">P</text>`);
      } else svg.push(`<text x="4" y="${H2 - 26}" font-size="10" font-family="var(--f-mono)" fill="var(--ink-3)">bit</text>`);
      svg.push(`</svg>`);
      $("#mNote").textContent = mul.stage < S
        ? `Outlined groups are the adders of stage ${mul.stage + 1}: a solid ring is a full adder (three bits in, sum stays, carry moves one column left), a dashed ring a half adder. Hollow dots are 0s.`
        : `Two rows left. The final ${w}-bit carry-propagate adder turns them into P. Hollow dots are 0s.`;
      $("#mLegend").innerHTML = KIND_LABEL.map(([k, l]) => `<span><i style="background:var(--dot-${{ pp: "pp", ppi: "inv", const: "const", fas: "sum", fac: "carry", pass: "pass" }[k]})"></i>${l}</span>`).join("");
    } else {
      const tr = AU.arrayTrace(a, b, n, sgn); p = tr.p;
      const cw = n > 12 ? 30 : 38, rh = n > 12 ? 30 : 36;
      const W2 = (2 * n) * cw + 70, H2 = (n + 1) * rh + 60;
      svg.push(`<svg width="${W2}" viewBox="0 0 ${W2} ${H2}" role="img" aria-label="Carry-save array">`);
      const X = (weight) => 50 + (2 * n - 1 - weight) * cw;
      for (let j = 0; j < n; j++) {
        svg.push(`<text x="6" y="${20 + j * rh + rh / 2}" font-size="10" font-family="var(--f-mono)" fill="var(--ink-3)">b${j}</text>`);
        for (let i = 0; i < n; i++) {
          const k = tr.kind[j][i], x = X(i + j), y = 12 + j * rh;
          const fill = k === "FA" ? "var(--accent-soft)" : k === "HA" ? "var(--band)" : "var(--panel)";
          svg.push(`<rect x="${x + 2}" y="${y}" width="${cw - 4}" height="${rh - 6}" rx="3" fill="${fill}" stroke="${k === "FA" ? "var(--accent)" : "var(--line)"}"/>`);
          svg.push(`<text x="${x + cw / 2}" y="${y + 12}" text-anchor="middle" font-size="9" font-family="var(--f-display)" font-weight="700" fill="var(--ink-3)">${k === "wire" ? (j === 0 ? "pp" : "—") : k}</text>`);
          svg.push(`<text x="${x + cw / 2}" y="${y + rh - 11}" text-anchor="middle" font-size="11" font-family="var(--f-mono)" fill="var(--ink)">${tr.s[j][i]}${j > 0 ? `<tspan fill="var(--dot-carry)" font-size="9">${tr.c[j][i]}</tspan>` : ""}</text>`);
        }
      }
      // final CPA
      const yc = 12 + n * rh;
      svg.push(`<rect x="${X(2 * n - 1) + 2}" y="${yc}" width="${n * cw - 4}" height="${rh - 6}" rx="3" fill="none" stroke="var(--dot-sum)" stroke-dasharray="4 3"/>`);
      svg.push(`<text x="${X(2 * n - 1) + 8}" y="${yc + rh / 2}" font-size="11" font-family="var(--f-display)" font-weight="700" fill="var(--dot-sum)">${n}-bit carry-propagate adder → P[${2 * n - 1}:${n}]</text>`);
      for (let k = 0; k < 2 * n; k++) svg.push(`<text x="${X(k) + cw / 2}" y="${H2 - 12}" text-anchor="middle" font-size="12" font-weight="600" font-family="var(--f-mono)" fill="var(--brand-ink)">${AU.bit(p, k)}</text>`);
      svg.push(`<text x="6" y="${H2 - 12}" font-size="11" font-family="var(--f-mono)" fill="var(--ink-3)">P</text></svg>`);
      $("#mNote").textContent = "Each cell shows its sum bit and, in green, its carry. A row's carries go straight down into the next row, so a row costs one adder delay; only the last adder has to propagate carries sideways.";
      $("#mLegend").innerHTML = `<span><i style="background:var(--accent)"></i>full adder</span><span><i style="background:var(--line)"></i>half adder or wire</span><span><i style="background:var(--dot-carry)"></i>carry out</span>`;
    }
    $("#mView").innerHTML = svg.join("");
    const pv = sgn ? AU.toSigned(p, w) : p;
    $("#mResult").innerHTML = `<dt>A</dt><dd>${av} = ${bin(a, n)}</dd><dt>B</dt><dd>${bv} = ${bin(b, n)}</dd><dt>P</dt><dd>${fmt(pv)}</dd><dt>check</dt><dd>${p === want ? `<span class="pill good">A × B</span>` : `<span class="pill bad">mismatch</span>`}</dd>`;
  }
  onTheme(renderMul);

  /* ============================================================== TIMING */
  const tnets = {};
  const ARCHS = [["ARRAY", "RIPPLE", "carry-save array + ripple"], ["ARRAY", "KOGGE_STONE", "carry-save array + Kogge-Stone"],
                 ["DADDA", "RIPPLE", "Dadda tree + ripple"], ["DADDA", "KOGGE_STONE", "Dadda tree + Kogge-Stone"]];
  function netsFor(n) {
    if (!tnets[n]) tnets[n] = ARCHS.map(([a, c]) => AU.buildNetlist(n, a, c));
    return tnets[n];
  }
  function parsePair(s, n) {
    const m = String(s).split(/[,\s]+/).filter(Boolean).map((x) => Math.round(+x) || 0);
    const hi = 2 ** n - 1;
    return { a: Math.max(0, Math.min(hi, m[0] || 0)), b: Math.max(0, Math.min(hi, m[1] || 0)), sgn: 0 };
  }
  function renderTiming() {
    const n = +$("#tN").value, nets = netsFor(n);
    const from = parsePair($("#tA0").value, n), to = parsePair($("#tA1").value, n);
    $("#tA0").value = `${from.a}, ${from.b}`; $("#tA1").value = `${to.a}, ${to.b}`;
    $("#tCfg").textContent = `N=${n} · ${from.a}×${from.b} → ${to.a}×${to.b} = ${fmt(to.a * to.b)}`;
    const res = nets.map((nl) => AU.unitDelaySim(nl, from, to));
    const T = Math.max(...res.map((r) => r.trace.length), ...nets.map((nl) => AU.depth(nl) + 1));
    $("#tGrid").innerHTML = ARCHS.map(([a, c, label], i) => {
      const r = res[i], d = AU.depth(nets[i]);
      const pop = (x) => { let c = 0; x = x >>> 0; while (x) { c += x & 1; x >>>= 1; } return c; };
      let flips = 0; for (let t = 1; t < r.trace.length; t++) flips += pop(r.trace[t] ^ r.trace[t - 1]);
      const needN = pop(r.trace[0] ^ r.final);
      return `<div class="timing-card"><h4>${label}<span>settled at t = ${r.settleAt} · longest path ${d} · ${flips - needN} extra toggles</span></h4><canvas id="tc${i}"></canvas></div>`;
    }).join("");
    res.forEach((r, i) => {
      const cv = $("#tc" + i), w = cv.parentElement.clientWidth - 26, bits = 2 * n;
      const cw = Math.max(4, Math.floor(w / bits)), rh = Math.max(4, Math.min(9, Math.floor(200 / T)));
      const g = fitCanvas(cv, cw * bits, rh * T + 1);
      g.fillStyle = css("--band"); g.fillRect(0, 0, cw * bits, rh * T);
      const d = AU.depth(nets[i]);
      g.fillStyle = css("--line"); g.fillRect(0, d * rh, cw * bits, (T - d) * rh);
      for (let t = 0; t < T; t++) {
        const v = r.trace[Math.min(t, r.trace.length - 1)], pv = t > 0 ? r.trace[Math.min(t - 1, r.trace.length - 1)] : v;
        for (let k = 0; k < bits; k++) {
          const bv = AU.bit(v, k), ch = t > 0 && bv !== AU.bit(pv, k);
          if (!bv && !ch) continue;
          g.globalAlpha = ch ? 1 : 0.38;
          g.fillStyle = ch ? css("--dot-const") : css("--dot-pp");
          g.fillRect((bits - 1 - k) * cw + 1, t * rh + 1, cw - 2, rh - 1);
        }
      }
      g.globalAlpha = 1;
      g.strokeStyle = css("--good"); g.lineWidth = 2;
      g.beginPath(); g.moveTo(0, r.settleAt * rh + 0.5); g.lineTo(cw * bits, r.settleAt * rh + 0.5); g.stroke();
    });
  }
  $("#tN").addEventListener("change", () => {
    const n = +$("#tN").value, m = 2 ** n - 1;
    $("#tA0").value = "0, 0"; $("#tA1").value = `${m}, ${m}`; renderTiming();
  });
  ["#tA0", "#tA1"].forEach((s) => $(s).addEventListener("change", renderTiming));
  $("#tRand").addEventListener("click", () => {
    const n = +$("#tN").value, r = () => Math.floor(Math.random() * 2 ** n);
    $("#tA0").value = `${r()}, ${r()}`; $("#tA1").value = `${r()}, ${r()}`; renderTiming();
  });
  $("#tWorst").addEventListener("click", () => {
    const n = +$("#tN").value, nets = netsFor(n), r = () => Math.floor(Math.random() * 2 ** n);
    let best = null, bestT = -1;
    for (let k = 0; k < 150; k++) {
      const f = { a: r(), b: r(), sgn: 0 }, t = { a: r(), b: r(), sgn: 0 };
      const s = AU.unitDelaySim(nets[0], f, t).settleAt;
      if (s > bestT) { bestT = s; best = [f, t]; }
    }
    $("#tA0").value = `${best[0].a}, ${best[0].b}`; $("#tA1").value = `${best[1].a}, ${best[1].b}`; renderTiming();
  });
  onTheme(renderTiming);

  /* ============================================================ DIVIDERS */
  function renderShift() {
    const w = 16;
    let x = Math.round(+$("#sX").value || 0); x = Math.max(-32768, Math.min(32767, x)); $("#sX").value = x;
    const c = +$("#sC").value; $("#sCv").textContent = String(c);
    const xp = AU.toPattern(x, w), d = AU.shiftDetail(xp, c, w, 1);
    const cells = [];
    for (let i = w - 1; i >= 0; i--) {
      const src = i + c;
      if (src >= w) cells.push(`<span class="fill" title="sign fill">${AU.bit(xp, w - 1)}</span>`);
      else cells.push(`<span class="keep" title="x bit ${src}">${AU.bit(xp, src)}</span>`);
    }
    if (c > 0) {
      cells.push(`<span class="gap"></span>`);
      for (let i = Math.min(c, w) - 1; i >= 0; i--) { const v = AU.bit(xp, i); cells.push(`<span class="${v ? "lost1" : "lost"}" title="shifted out, bit ${i}">${v}</span>`); }
    }
    $("#sBits").innerHTML = cells.join("");
    $("#sTbl").innerHTML = [
      ["x", `${fmt(d.xv)}`], ["arithmetic shift (floor)", `${fmt(d.floorQ)}`], ["bits shifted out", c === 0 ? "none" : (d.lost ? "some 1s" : "all 0")],
      ["round_up = negative and a 1 lost", `${d.rnd}`], ["q + round_up (what the unit returns)", `<b>${fmt(d.trunc)}</b>`],
      [`x / 2<sup>${c}</sup> rounded toward zero`, `${fmt(AU.divTrunc(d.xv, 2 ** c))} <span class="pill good">match</span>`],
    ].map(([k, v]) => `<tr><td>${k}</td><td class="num">${v}</td></tr>`).join("");
  }
  ["#sX", "#sC"].forEach((s) => $(s).addEventListener("input", renderShift));
  $$("#dividers .chip").forEach((b) => b.addEventListener("click", () => { $("#sX").value = b.dataset.x; $("#sC").value = b.dataset.c; renderShift(); }));
  function renderDiv() {
    let x = Math.round(+$("#dX").value || 0); x = Math.max(0, Math.min(65535, x)); $("#dX").value = x;
    const c = +$("#dC").value, dv = c * c;
    $("#dCv").textContent = `${c} → C² = ${dv}`;
    const steps = AU.restoringSteps(x, dv, 16);
    $("#dTbl").innerHTML = steps.map((s) => `<tr><td class="num">${s.k + 1}</td><td class="num">${s.inBit}</td><td class="num">${s.trial}</td><td class="${s.ok ? "ok" : "no"}">${s.ok ? "yes · q=1" : "no · q=0"}</td><td class="num">${s.r}</td><td class="num mono">${bin(s.qd & ((1 << (s.k + 1)) - 1), s.k + 1)}</td></tr>`).join("");
    const last = steps[steps.length - 1];
    $("#dNote").textContent = `After 16 clocks: quotient ${last.qd} and remainder ${last.r}, so ${x} = ${dv} × ${last.qd} + ${last.r}. A negative product is divided as |x| and the quotient is negated through the final adder (invert, carry-in 1).`;
  }
  ["#dX", "#dC"].forEach((s) => $(s).addEventListener("input", renderDiv));

  /* ============================================================== SERIAL */
  let serAnim = null, serCursor = null;
  function serialModel() {
    const i = latched || readInputs();
    const ref = AU.arithUnit(i.A, i.B, i.C, i.D, i.sgn, i.fsel, N, CW, DW);
    const fields = [["A", i.A, N, "--dot-pp"], ["B", i.B, N, "--dot-inv"], ["C", i.C, CW, "--dot-const"], ["D", i.D, DW, "--dot-sum"], ["sgn", i.sgn, 1, "--dot-carry"], ["fsel", i.fsel, 1, "--dot-pass"]];
    const outs = [["P", ref.p, W, "--dot-pp"], ["err", ref.err, 1, "--dot-const"], ["ovf", ref.ovf, 1, "--dot-inv"]];
    const inBits = [], outBits = [];
    fields.forEach(([, v, b]) => { for (let k = 0; k < b; k++) inBits.push(AU.bit(v, k)); });
    outs.forEach(([, v, b]) => { for (let k = 0; k < b; k++) outBits.push(AU.bit(v, k)); });
    return { fields, outs, inBits, outBits, lat: ref.latency };
  }
  function frameHtml(list) {
    return list.map(([name, v, b, col]) => `<div style="border-top:3px solid var(${col})"><b style="color:var(${col})">${name}</b>${bin(v, b)}<br><span class="muted">${b} bit${b > 1 ? "s" : ""}</span></div>`).join("");
  }
  function renderSerial() {
    const m = serialModel();
    $("#serIn").innerHTML = frameHtml(m.fields); $("#serOut").innerHTML = frameHtml(m.outs);
    $("#serInLen").textContent = m.inBits.length; $("#serOutLen").textContent = m.outBits.length;
    const FI = m.inBits.length, FO = m.outBits.length, L = m.lat;
    const total = FI + 1 + L + 1 + FO + 2;
    const sin_en = [], sin = [], start = [], busy = [], sval_ = [], sout = [];
    for (let t = 0; t < total; t++) {
      const inPh = t < FI, st = t === FI, outPh = t >= FI + 1 + L + 1 && t < FI + 1 + L + 1 + FO;
      sin_en.push(inPh ? 1 : 0); sin.push(inPh ? m.inBits[t] : "Z"); start.push(st ? 1 : 0);
      busy.push(t > FI && t < FI + 1 + L + 1 + FO ? 1 : 0); sval_.push(outPh ? 1 : 0);
      sout.push(outPh ? m.outBits[t - (FI + L + 2)] : 0);
    }
    const lim = serCursor == null ? total : serCursor;
    const cut = (arr) => arr.map((v, t) => (t < lim ? v : (t === 0 ? 0 : "Z")));
    const rows = [{ name: "clk", kind: "clk" }, { name: "sin_en", kind: "bit", vals: cut(sin_en) }, { name: "sin", kind: "bit", vals: cut(sin) },
      { name: "start", kind: "bit", vals: cut(start) }, { name: "busy", kind: "bit", vals: cut(busy) }, { name: "sout_valid", kind: "bit", vals: cut(sval_) }, { name: "sout", kind: "bit", vals: cut(sout) }];
    waveGeneric($("#serWave"), rows, total, { cw: 14, cursor: serCursor });
    $("#serCycles").textContent = String(total);
    $("#serPhase").textContent = `${FI} in · start · ${L} compute · ${FO} out`;
  }
  $("#serPlay").addEventListener("click", () => {
    if (serAnim) { clearInterval(serAnim); serAnim = null; serCursor = null; renderSerial(); $("#serPlay").textContent = "Play transfer"; return; }
    serCursor = 0; $("#serPlay").textContent = "Stop";
    serAnim = setInterval(() => {
      serCursor++;
      renderSerial();
      const sc = $("#serWave").parentElement; sc.scrollLeft = Math.max(0, 86 + serCursor * 14 - sc.clientWidth + 60);
      if (serCursor > 90) { clearInterval(serAnim); serAnim = null; serCursor = null; renderSerial(); $("#serPlay").textContent = "Play transfer"; }
    }, reduce ? 5 : 45);
  });
  onTheme(renderSerial);

  /* ======================================================== VERIFICATION */
  const TB_INFO = {
    tb_cells: "Truth tables of half adder, full adder, partial-product and prefix cells",
    tb_cpa: "Ripple, Kogge-Stone and inferred adders: every input up to 8 bits, carry-chain corners and random words to 64 bits",
    tb_multiplier: "Array and Dadda multipliers with both final adders, signed and unsigned: every operand pair up to N = 8, corners and random pairs to N = 32",
    tb_shift_divider: "x / 2^C rounded toward zero for every x (W ≤ 10) and every C, including shifts wider than the word",
    tb_restoring_divider: "Quotient, busy and done timing for every dividend/divisor pair at 8/6 bits, random at 16/16",
    tb_arith_unit_min: "P = A·B/4 + 1 through load/status for all 65,536 pairs; held load, back-to-back loads, reset in flight",
    tb_arith_unit_vectors: "Both formulas, signed and unsigned, err and ovf, exact latency, result hold, interrupted loads, reset in flight",
    tb_arith_unit_serial: "Serial frames in and out against the same vectors",
    pytest: "Golden model: bit-level multipliers exhaustive to N = 6, rounding, overflow, Dadda plan",
    js: "This site's JavaScript model against all vectors, cycle by cycle",
  };
  function renderTests() {
    const groups = {};
    (DATA.tests || []).forEach((t) => {
      const g = groups[t.tb] || (groups[t.tb] = { runs: 0, checks: 0, pass: 0 });
      g.runs++; g.checks += t.checks || 0; if (t.pass) g.pass++;
    });
    const order = ["tb_cells", "tb_cpa", "tb_multiplier", "tb_shift_divider", "tb_restoring_divider", "tb_arith_unit_min", "tb_arith_unit_vectors", "tb_arith_unit_serial", "pytest", "js"];
    const rows = order.filter((k) => groups[k]).map((k) => {
      const g = groups[k], ok = g.pass === g.runs;
      return `<tr><td><code>${k}</code></td><td>${TB_INFO[k] || ""}</td><td class="num">${g.runs}</td><td class="num">${g.checks ? fmt(g.checks) : "–"}</td><td><span class="pill ${ok ? "good" : "bad"}">${ok ? "pass" : "fail"}</span></td></tr>`;
    });
    $("#tbTable tbody").innerHTML = rows.join("") || `<tr><td colspan="5">No regression data bundled.</td></tr>`;
    const runs = (DATA.tests || []).length, fails = (DATA.tests || []).filter((t) => !t.pass).length;
    const checks = (DATA.tests || []).reduce((a, t) => a + (t.checks || 0), 0);
    $("#kpiRuns").textContent = runs ? String(runs) : "–";
    $("#tbNote").textContent = runs ? `${runs} runs, ${fmt(checks)} individual checks, ${fails} failures. Generated ${DATA.generated || ""} by scripts/run_tests.sh, node tests/test_js_model.mjs and pytest.` : "";
  }
  renderTests();

  /* ============================================================= RESULTS */
  const SERIES = [
    ["ARRAY", "RIPPLE", "array + ripple", "--s1"], ["ARRAY", "KOGGE_STONE", "array + Kogge-Stone", "--s2"],
    ["DADDA", "RIPPLE", "Dadda + ripple", "--s3"], ["DADDA", "KOGGE_STONE", "Dadda + Kogge-Stone", "--s4"],
    ["DADDA", "INFERRED", "Dadda + carry chain", "--s6"], ["BEHAVIORAL", "-", "numeric_std \"*\"", "--s5"],
  ];
  function lineChart(el, key, yLabel) {
    const rows = (DATA.synth && DATA.synth.rows || []).filter((r) => r.group === "mult");
    if (!rows.length) { el.innerHTML = `<p class="small muted">No synthesis data bundled.</p>`; return; }
    const ns = [...new Set(rows.map((r) => r.n))].sort((a, b) => a - b);
    const vals = rows.map((r) => r[key]).filter((v) => v != null);
    const W = 520, H = 300, L = 48, R = 12, T = 12, B = 34;
    const ymax = Math.max(...vals) * 1.08, xmin = ns[0], xmax = ns[ns.length - 1];
    const X = (n) => L + (n - xmin) / (xmax - xmin || 1) * (W - L - R), Y = (v) => T + (1 - v / ymax) * (H - T - B);
    const step = key === "lut4" ? (ymax > 3000 ? 1000 : ymax > 1500 ? 500 : 200) : (ymax > 150 ? 50 : 25);
    const s = [`<svg viewBox="0 0 ${W} ${H}" role="img" aria-label="${esc(yLabel)} versus operand width">`];
    for (let v = 0; v <= ymax; v += step) s.push(`<line x1="${L}" x2="${W - R}" y1="${Y(v)}" y2="${Y(v)}" stroke="var(--line-2)"/><text x="${L - 6}" y="${Y(v) + 4}" text-anchor="end">${v}</text>`);
    ns.forEach((n) => s.push(`<text x="${X(n)}" y="${H - 12}" text-anchor="middle">N=${n}</text>`));
    SERIES.forEach(([a, c, , col]) => {
      const pts = ns.map((n) => rows.find((r) => r.n === n && r.arch === a && (a === "BEHAVIORAL" || r.cpa === c))).filter((r) => r && r[key] != null);
      if (!pts.length) return;
      s.push(`<polyline points="${pts.map((r) => `${X(r.n)},${Y(r[key])}`).join(" ")}" fill="none" stroke="var(${col})" stroke-width="2.2" stroke-linejoin="round"/>`);
      pts.forEach((r) => s.push(`<circle cx="${X(r.n)}" cy="${Y(r[key])}" r="3.2" fill="var(${col})"><title>${esc(r.name)}: ${r[key]}</title></circle>`));
    });
    s.push(`</svg>`);
    el.innerHTML = s.join("");
  }
  function renderResults() {
    lineChart($("#chFmax"), "fmax_mhz", "fmax");
    lineChart($("#chLut"), "lut4", "LUT4");
    $("#chLegend").innerHTML = SERIES.map(([, , l, c]) => `<span><i style="background:var(${c})"></i>${esc(l)}</span>`).join("");
    const units = (DATA.synth && DATA.synth.rows || []).filter((r) => r.group === "unit" && !/^20\d\d/.test(r.name));
    const notes = {
      "arith_unit_min": "base formula, P = A·B/4 + 1",
      "arith_unit ": "both formulas, signed, err/ovf",
      "arith_unit_serial": "8 pins",
    };
    $("#unitTable tbody").innerHTML = units.map((r) => {
      const note = Object.keys(notes).find((k) => r.name.startsWith(k.trim()) && (k !== "arith_unit " || !r.name.startsWith("arith_unit_")));
      return `<tr><td>${esc(r.name)}</td><td class="num">${r.lut4}</td><td class="num">${r.ff}</td><td class="num">${r.fmax_mhz ?? "–"}</td><td class="small">${note ? notes[note] : ""}${r.note ? ` (${esc(r.note)})` : ""}</td></tr>`;
    }).join("");
    const m8 = (DATA.synth.rows || []).filter((r) => r.group === "mult" && r.n === 8);
    const label = (r) => r.arch === "BEHAVIORAL" ? 'numeric_std "*" (tool-built)' : `${r.arch === "ARRAY" ? "Carry-save array" : "Dadda tree"} + ${{ RIPPLE: "ripple", KOGGE_STONE: "Kogge-Stone", INFERRED: "carry chain" }[r.cpa]}`;
    const fastest = Math.max(...m8.map((r) => r.fmax_mhz || 0));
    $("#multTable tbody").innerHTML = m8.map((r) => [label(r), r])
      .map(([n, r]) => `<tr class="${r.fmax_mhz === fastest ? "me" : ""}"><td>${esc(n)}</td><td class="num">${r.lut4}</td><td class="num">${r.fmax_mhz ?? "–"}</td><td class="num">${r.gate_depth ?? "–"}</td><td class="num">${r.gates ?? "–"}</td></tr>`).join("");
    const best = m8.filter((r) => r.arch === "DADDA" && r.cpa === "INFERRED")[0];
    if (best) $("#kpiFmax").innerHTML = `${Math.round(best.fmax_mhz)} <small>MHz</small>`;
    $("#synthNote").textContent = DATA.synth.flow ? `Flow: ${DATA.synth.flow}. ${Object.values(DATA.synth.tools || {}).join(" · ")}. fmax is for iCE40; syn/quartus has the MAX 10 project with its clock constraint.` : "";
  }
  renderResults();
  onTheme(renderResults);

  /* ======================================================== DESIGN NOTES */
  const NOTES_D = [
    ["handshake", "Operands are latched on the load edge", "load = 1 on one rising edge is enough: A, B, C, D and the mode bits go straight into their registers and status drops. P, status, err and ovf are registers too, so the result holds until the next load, and a load while busy simply restarts with the new operands.",
      "reg_en with en = load for every operand; status, err and ovf are dff_en flip-flops set by the ADD state and cleared by load."],
    ["fpga", "No tri-states, no latches", "Every signal has exactly one driver and every storage element is an edge-triggered flip-flop with an asynchronous active-low reset. That keeps the design portable across FPGA families and simulators and lets timing analysis see every path.",
      "Plain VHDL-93, analysed as both VHDL-93 and VHDL-2008 in every regression run."],
    ["speed", "A Dadda tree for depth, a carry-save array for regularity", "The array adds one row per full-adder delay. The Dadda tree compresses every column at once through the heights 6, 4, 3, 2 for N = 8, using the fewest adders that reach each target. At N = 8 with a Kogge-Stone final adder the longest path is 21 gates, half the 42 of the array with a ripple adder.",
      "au_pkg.dadda_plan computes heights and adder counts at elaboration; dadda_multiplier only instantiates what the plan says, for any N."],
    ["signed", "Signed numbers at no extra cost", "Modified Baugh-Wooley: complement the partial products that touch exactly one sign bit and add 2^N + 2^(2N−1). The first constant enters through the final adder's carry-in and the second through an input that is otherwise always 0, so signed mode adds no extra adder row.",
      "pp_cell with inv = sgn on the mixed-sign products; sgn wired to the CPA carry-in and to its top x bit."],
    ["rounding", "Round toward zero through the adder's carry-in", "An arithmetic shift rounds negative numbers down: −15 >> 1 is −8, while −15 / 2 is −7. The shifter reports when a negative value lost any 1-bits, and the adder that already adds D adds that bit through its carry-in. The divider path negates its quotient the same way: invert, carry-in 1.",
      "shift_divider.round_up and the rnd flip-flop feed cpa.ci in the ADD state."],
    ["area", "One multiplier, two jobs", "A·B/C² + D needs C² as well as A·B. Instead of a second multiplier the state machine runs the shared one twice: C·C in the SQR state, A·B in MUL. A restoring divider then produces one quotient bit per clock from |A·B| and C².",
      "Input multiplexers in front of multiplier, selected by state = S_SQR; restoring_divider with W = 2N steps."],
    ["speed", "The right final adder for each target", "Ripple is the smallest, Kogge-Stone has log₂ depth on any technology, and INFERRED hands the addition to the FPGA's dedicated carry chain. With the Dadda tree and the carry chain the 8×8 multiplier runs at 122 MHz in 134 LUTs, ahead of numeric_std \"*\" at 98 MHz in 211 LUTs.",
      "cpa with ARCH = RIPPLE | KOGGE_STONE | INFERRED, selected by the CPA_ARCH generic of every top level."],
    ["pins", "Serial I/O with its own buffer", "arith_unit_serial shifts the 34-bit operand frame in on sin, pulses start, and shifts P, err and ovf back out on sout: 8 pins instead of 56. Because the core latches its operands on start, the next frame can be shifted in while the current one is computing.",
      "A FI-bit input shift register and an FO-bit output shift register around an unchanged arith_unit."],
  ];
  $("#findings").innerHTML = NOTES_D.map(([tag, h, p, rtl]) => `<div class="finding"><span class="pill info">${esc(tag)}</span><div><h4>${esc(h)}</h4><p>${esc(p)}</p></div><div class="fix"><b>In the RTL</b>${esc(rtl)}</div></div>`).join("");

  /* ---------------------------------------------------------------- boot */
  refreshBits();
  resetSim();
  runPreset(PRESETS.spec);
  renderMul();
  renderTiming();
  renderShift();
  renderDiv();
  drawTraces();
})();
