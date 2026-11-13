"use strict";
// Hammer minigame for the construction job: a ring closes on the nail, strike it (left click on the nail)
// as the ring meets the dashed circle. Good strikes drive the nail in, perfect ones count double.
// Loaded by jo_libs' NUI (next to its menu and prompts), which gives this frame GetParentResourceName
const RESOURCE = typeof GetParentResourceName === "function" ? GetParentResourceName() : "ez_actionjobs";
const $ = (id) => document.getElementById(id);

const DEFAULTS = {
    nails: 4,
    strikes: 2,
    ringTime: 1150,
    goodWindow: 150,
    perfectWindow: 45,
    mistakes: 4,
    timeLimit: 0,
    wood: "dark",
    volume: 0.6,
};

const HAMMER_HOTSPOT = { x: 35 / 160, y: 92 / 110 }; // bottom of the striking face, in the svg

const el = {
    app: $("app"),
    window: $("window"),
    title: $("title"),
    hint: $("hint"),
    stage: $("stage"),
    plank: $("plank"),
    nails: $("nails"),
    target: $("ringTarget"),
    approach: $("ringApproach"),
    fx: $("fx"),
    banner: $("banner"),
    bannerText: $("bannerText"),
    nailPips: $("nailPips"),
    bentPips: $("bentPips"),
    labelNails: $("labelNails"),
    labelBent: $("labelBent"),
    timer: $("timer"),
    timerFill: $("timerFill"),
    keyStrike: $("keyStrike"),
    keyGiveUp: $("keyGiveUp"),
    hammer: $("hammer"),
};

const S = {
    open: false,
    finished: false,
    opts: { ...DEFAULTS },
    L: {},
    nails: [],      // { el, body, head, depth, done }
    active: 0,
    mistakes: 0,
    phase: "idle",  // "intro" | "aim" | "cooldown" | "done"
    ringStart: 0,
    ringDur: 0,
    tTarget: 0,
    T: 0,           // dashed circle radius (px)
    R0: 0,          // ring radius when it appears (px)
    hitRadius: 0,
    timeTotal: 0,
    deadline: 0,
    loop: 0,
    timers: [],
    mouse: { x: innerWidth / 2, y: innerHeight / 2 },
};

// ---------------------------------------------------------------- Helpers

function post(name, data = {}) {
    return fetch(`https://${RESOURCE}/${name}`, {
        method: "POST",
        headers: { "Content-Type": "application/json; charset=UTF-8" },
        body: JSON.stringify(data),
    }).catch(() => {});
}

const vh = () => innerHeight / 100;
const rand = (min, max) => min + Math.random() * (max - min);

function later(ms, fn) {
    const id = setTimeout(fn, ms);
    S.timers.push(id);
}

function clearTimers() {
    S.timers.forEach(clearTimeout);
    S.timers = [];
}

/** Centre of a nail's head, in viewport coordinates */
function headPoint(nail) {
    const r = nail.head.getBoundingClientRect();
    return { x: r.left + r.width / 2, y: r.top + r.height / 2 };
}

function toStage(point) {
    const r = el.stage.getBoundingClientRect();
    return { x: point.x - r.left, y: point.y - r.top };
}

function restart(node, className) {
    node.classList.remove(className);
    void node.offsetWidth;
    node.classList.add(className);
}

// ---------------------------------------------------------------- Sound (made on the fly, no files needed)

const Sound = {
    ctx: null,
    volume: 0.6,
    noiseCache: null,

    init() {
        if (!this.ctx) {
            try {
                this.ctx = new (window.AudioContext || window.webkitAudioContext)();
            } catch (e) {
                this.ctx = null;
            }
        }
        if (this.ctx && this.ctx.state === "suspended") this.ctx.resume();
    },

    noise() {
        if (this.noiseCache) return this.noiseCache;
        const c = this.ctx;
        const buffer = c.createBuffer(1, c.sampleRate * 0.5, c.sampleRate);
        const data = buffer.getChannelData(0);
        for (let i = 0; i < data.length; i++) data[i] = Math.random() * 2 - 1;
        this.noiseCache = buffer;
        return buffer;
    },

    env(gain, t, peak, decay) {
        gain.gain.setValueAtTime(0.0001, t);
        gain.gain.exponentialRampToValueAtTime(Math.max(peak, 0.0002), t + 0.004);
        gain.gain.exponentialRampToValueAtTime(0.0001, t + decay);
    },

    tone(type, from, to, peak, decay, delay = 0) {
        const c = this.ctx;
        const t = c.currentTime + delay;
        const osc = c.createOscillator();
        const gain = c.createGain();
        osc.type = type;
        osc.frequency.setValueAtTime(from, t);
        if (to !== from) osc.frequency.exponentialRampToValueAtTime(to, t + decay * 0.6);
        this.env(gain, t, peak * this.volume, decay);
        osc.connect(gain).connect(c.destination);
        osc.start(t);
        osc.stop(t + decay + 0.02);
    },

    burst(filterType, freq, q, peak, decay) {
        const c = this.ctx;
        const t = c.currentTime;
        const src = c.createBufferSource();
        src.buffer = this.noise();
        const filter = c.createBiquadFilter();
        filter.type = filterType;
        filter.frequency.value = freq;
        filter.Q.value = q;
        const gain = c.createGain();
        this.env(gain, t, peak * this.volume, decay);
        src.connect(filter).connect(gain).connect(c.destination);
        src.start(t);
        src.stop(t + decay + 0.02);
    },

    thud(power = 1) {
        if (!this.ctx) return;
        this.tone("sine", 180, 52, 0.9 * power, 0.22);
        this.burst("bandpass", 950, 0.9, 0.75 * power, 0.07);
        this.burst("lowpass", 300, 0.7, 0.5 * power, 0.12);
    },

    ting() {
        if (!this.ctx) return;
        this.tone("sine", 2480, 2480, 0.12, 0.45, 0.01);
        this.tone("sine", 3720, 3720, 0.07, 0.3, 0.01);
    },

    clank() {
        if (!this.ctx) return;
        this.tone("square", 310, 190, 0.12, 0.16);
        this.tone("triangle", 1250, 900, 0.1, 0.22);
        this.burst("highpass", 2600, 0.8, 0.3, 0.1);
    },

    whoosh() {
        if (!this.ctx) return;
        this.burst("bandpass", 700, 0.6, 0.18, 0.12);
    },

    file(name, volume = 0.5) {
        const audio = new Audio(`assets/sounds/${name}.mp3`);
        audio.volume = Math.min(1, volume * this.volume);
        audio.play().catch(() => {});
    },
};

// ---------------------------------------------------------------- Effects

function particles(point, count, colors, spread, rise, sizeVh) {
    const p = toStage(point);
    for (let i = 0; i < count; i++) {
        const node = document.createElement("div");
        node.className = "particle";
        node.style.left = `${p.x}px`;
        node.style.top = `${p.y}px`;
        node.style.setProperty("--dx", `${rand(-spread, spread) * vh()}px`);
        node.style.setProperty("--dy", `${-rand(rise * 0.3, rise) * vh()}px`);
        node.style.setProperty("--size", `${rand(sizeVh * 0.5, sizeVh)}vh`);
        node.style.setProperty("--color", colors[i % colors.length]);
        node.style.setProperty("--life", `${rand(0.4, 0.75)}s`);
        el.fx.appendChild(node);
        setTimeout(() => node.remove(), 800);
    }
}

function popup(point, text, kind) {
    const p = toStage(point);
    const node = document.createElement("div");
    node.className = `popup popup--${kind}`;
    node.textContent = text;
    node.style.left = `${p.x}px`;
    node.style.top = `${p.y - 2 * vh()}px`;
    el.fx.appendChild(node);
    setTimeout(() => node.remove(), 800);
}

function banner(text, kind) {
    el.bannerText.textContent = text;
    el.banner.className = `banner ${kind || ""}`;
}

function hideBanner() {
    el.banner.classList.add("hidden");
}

function swing() {
    restart(el.hammer, "strike");
    later(90, () => el.hammer.classList.remove("strike"));
}

function moveHammer() {
    const w = el.hammer.offsetWidth;
    const h = el.hammer.offsetHeight;
    el.hammer.style.left = `${S.mouse.x - w * HAMMER_HOTSPOT.x}px`;
    el.hammer.style.top = `${S.mouse.y - h * HAMMER_HOTSPOT.y}px`;
}

// ---------------------------------------------------------------- Board

function setExposed(nail) {
    const length = 9; // vh, matches --nail-length
    const flush = 1.0;
    const left = 1 - nail.depth / S.opts.strikes;
    nail.body.style.setProperty("--exposed", `${flush + (length - flush) * left}vh`);
}

function buildNails() {
    el.nails.innerHTML = "";
    S.nails = [];
    const n = S.opts.nails;
    for (let i = 0; i < n; i++) {
        const node = document.createElement("div");
        node.className = "nail waiting";
        node.style.left = `${12 + (76 * (i + 0.5)) / n + rand(-2, 2)}%`;
        node.innerHTML = '<div class="nail__hole"></div><div class="nail__body"><div class="nail__shank"></div><div class="nail__head"></div></div>';
        el.nails.appendChild(node);
        const nail = {
            el: node,
            body: node.querySelector(".nail__body"),
            head: node.querySelector(".nail__head"),
            depth: 0,
            done: false,
        };
        setExposed(nail);
        S.nails.push(nail);
    }
}

function buildPips() {
    el.nailPips.innerHTML = "";
    for (let i = 0; i < S.opts.nails; i++) {
        const pip = document.createElement("div");
        pip.className = "pip pip--nail";
        el.nailPips.appendChild(pip);
    }
    el.bentPips.innerHTML = "";
    for (let i = 0; i < S.opts.mistakes; i++) {
        const pip = document.createElement("div");
        pip.className = "pip pip--bent";
        el.bentPips.appendChild(pip);
    }
}

function updatePips() {
    [...el.nailPips.children].forEach((pip, i) => pip.classList.toggle("on", i < S.active));
    [...el.bentPips.children].forEach((pip, i) => pip.classList.toggle("on", i < S.mistakes));
}

function setActive() {
    S.nails.forEach((nail, i) => {
        nail.el.classList.toggle("active", i === S.active);
        nail.el.classList.toggle("waiting", i > S.active);
    });
}

function placeRing(node, center, scale) {
    const size = S.T * 2;
    node.style.transform = `translate(${center.x - size / 2}px, ${center.y - size / 2}px) scale(${scale})`;
}

// ---------------------------------------------------------------- Game

function startRing() {
    if (S.phase === "done") return;
    S.ringDur = S.opts.ringTime * rand(0.85, 1.15);
    S.tTarget = S.ringDur * (1 - S.T / S.R0);
    S.ringStart = performance.now();
    el.approach.classList.remove("hidden", "fade");
    el.target.classList.remove("hidden");
    S.phase = "aim";
}

function hit(nail, amount, grade) {
    S.phase = "cooldown";
    const head = headPoint(nail);
    nail.depth = Math.min(S.opts.strikes, nail.depth + amount);
    nail.el.classList.remove("bent");
    nail.body.style.setProperty("--bend", "0deg");
    setExposed(nail);

    const base = nail.el.getBoundingClientRect();
    const plankPoint = { x: base.left + base.width / 2, y: base.bottom };
    particles(plankPoint, grade === "perfect" ? 14 : 9, ["#8a6744", "#b48c63", "#5d4129", "#cfae86"], 6, 5, 0.7);
    if (grade === "perfect") {
        particles(head, 10, ["#ffe3a0", "#ffc861", "#fff4d6"], 5, 7, 0.45);
        Sound.ting();
    }
    popup(head, S.L[grade] || grade, grade);
    Sound.thud(grade === "perfect" ? 1.1 : 0.9);
    restart(el.stage, "shake");
    restart(el.plank, "hit");
    el.approach.classList.add("fade");

    if (nail.depth >= S.opts.strikes) {
        nail.done = true;
        nail.el.classList.remove("active");
        nail.el.classList.add("sunk");
        S.active++;
        updatePips();
        if (S.active >= S.nails.length) {
            el.target.classList.add("hidden");
            return later(300, success);
        }
        setActive();
    }
    later(grade === "perfect" ? 260 : 320, startRing);
}

/** kind: "early" (struck at the wrong time: the nail bends) | "late" (the ring closed without a strike) */
function miss(kind) {
    S.phase = "cooldown";
    const nail = S.nails[S.active];
    const head = headPoint(nail);
    S.mistakes++;
    updatePips();
    popup(head, S.L[kind] || kind, "miss");
    el.approach.classList.add("fade");

    const failing = S.mistakes > S.opts.mistakes;
    if (kind === "early") {
        const side = Math.random() < 0.5 ? -1 : 1;
        nail.el.classList.add("bent");
        nail.body.style.setProperty("--bend", `${side * (failing ? 38 : rand(10, 16))}deg`);
        Sound.thud(0.6);
        Sound.clank();
        restart(el.stage, "shake--big");
        if (!failing) later(420, () => nail.body.style.setProperty("--bend", "0deg"));
    } else {
        Sound.whoosh();
    }

    if (failing) return fail(S.L.failed);
    later(520, startRing);
}

function success() {
    S.phase = "done";
    banner(S.L.success, "ok");
    Sound.file("selected", 0.6);
    later(1100, () => close("success"));
}

function fail(text) {
    if (S.phase === "done") return;
    S.phase = "done";
    el.approach.classList.add("hidden");
    el.target.classList.add("hidden");
    banner(text, "bad");
    Sound.file("menu_close", 0.6);
    later(1300, () => close("failed"));
}

function close(status) {
    if (S.finished) return;
    S.finished = true;
    S.phase = "done";
    el.window.classList.add("closing");
    setTimeout(() => {
        S.open = false;
        clearTimers();
        el.app.classList.add("hidden");
        el.fx.innerHTML = "";
        post("hammerFinished", { status });
    }, 250);
}

function frame(now, loopId) {
    if (!S.open || loopId !== S.loop) return;
    requestAnimationFrame((t) => frame(t, loopId));

    if (S.timeTotal > 0 && S.phase !== "done") {
        const left = Math.max(0, S.deadline - now);
        el.timerFill.style.transform = `scaleX(${Math.min(1, left / S.timeTotal)})`;
        if (left <= 0 && S.phase !== "intro") return fail(S.L.timeUp);
    }

    const nail = S.nails[S.active];
    if (!nail) return;
    const center = toStage(headPoint(nail));
    placeRing(el.target, center, 1);

    if (S.phase === "aim") {
        const t = now - S.ringStart;
        const r = Math.max(0, S.R0 * (1 - t / S.ringDur));
        placeRing(el.approach, center, r / S.T);
        if (t > S.tTarget + S.opts.goodWindow) miss("late");
    }
}

function start(options, lang) {
    clearTimers();
    S.opts = { ...DEFAULTS, ...(options || {}) };
    S.opts.nails = Math.max(1, Math.min(8, Math.floor(S.opts.nails)));
    S.opts.strikes = Math.max(1, Math.floor(S.opts.strikes));
    S.opts.mistakes = Math.max(0, Math.floor(S.opts.mistakes));
    S.L = lang || {};
    S.active = 0;
    S.mistakes = 0;
    S.finished = false;
    S.phase = "intro";

    el.title.textContent = S.L.title || "";
    el.hint.textContent = S.L.hint || "";
    el.labelNails.textContent = S.L.nails || "";
    el.labelBent.textContent = S.L.bent || "";
    el.keyStrike.textContent = S.L.strike || "";
    el.keyGiveUp.textContent = S.L.giveUp || "";
    el.plank.className = `plank wood-${S.opts.wood}`;
    el.fx.innerHTML = "";
    el.approach.classList.add("hidden");
    el.target.classList.add("hidden");

    el.window.classList.remove("closing");
    el.app.classList.remove("hidden");

    S.T = 3.4 * vh();
    S.R0 = S.T * 3;
    S.hitRadius = 4.8 * vh();
    el.target.style.setProperty("--ring-size", `${S.T * 2}px`);
    el.approach.style.setProperty("--ring-size", `${S.T * 2}px`);

    buildNails();
    buildPips();
    updatePips();
    setActive();
    moveHammer();

    Sound.volume = Math.max(0, Math.min(1, Number(S.opts.volume) || 0));
    Sound.init();
    Sound.file("menu_open", 0.5);

    const intro = 800;
    S.timeTotal = S.opts.timeLimit > 0 ? S.opts.timeLimit * 1000 : 0;
    el.timer.classList.toggle("off", S.timeTotal === 0);
    el.timerFill.style.transform = "scaleX(1)";
    S.deadline = performance.now() + intro + S.timeTotal;

    banner(S.L.ready, "");
    later(intro, () => {
        hideBanner();
        startRing();
    });

    S.open = true;
    S.loop++;
    const loopId = S.loop;
    requestAnimationFrame((t) => frame(t, loopId));
}

// ---------------------------------------------------------------- Input

document.addEventListener("mousemove", (e) => {
    S.mouse.x = e.clientX;
    S.mouse.y = e.clientY;
    if (S.open) moveHammer();
});

document.addEventListener("mousedown", (e) => {
    if (!S.open || S.phase === "done" || e.button !== 0) return;
    Sound.init();
    swing();
    if (S.phase !== "aim") return Sound.whoosh();

    const nail = S.nails[S.active];
    const head = headPoint(nail);
    if (Math.hypot(S.mouse.x - head.x, S.mouse.y - head.y) > S.hitRadius) return Sound.whoosh();

    const t = performance.now() - S.ringStart;
    const off = Math.abs(t - S.tTarget);
    if (off <= S.opts.perfectWindow) hit(nail, 2, "perfect");
    else if (off <= S.opts.goodWindow) hit(nail, 1, "good");
    else miss(t < S.tTarget ? "early" : "late");
});

document.addEventListener("keydown", (e) => {
    if (!S.open || S.finished) return;
    if (e.key === "Escape" || e.key === "Backspace") {
        clearTimers();
        Sound.file("menu_close", 0.5);
        close("canceled");
    }
});

window.addEventListener("message", (e) => {
    const data = e.data;
    if (!data) return;
    if (data.action === "hammer:start") {
        start(data.options, data.lang);
    } else if (data.action === "hammer:stop" && S.open) {
        S.finished = true;
        S.open = false;
        clearTimers();
        el.app.classList.add("hidden");
    }
});

post("ready");
