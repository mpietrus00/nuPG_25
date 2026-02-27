// =====================================================================
// Example 1: Formant Independence as Temporal Lens
//            and Archaeological Object
//
// This example uses the PulsarGenerator's fundamental-formant
// independence in two complementary ways:
//
//   Configuration A — the independence as a temporal LENS:
//     Formant fixed at 800 Hz while emission rate sweeps 1–500 Hz.
//     A burst/rest mask of 5:3 creates an 8-step pattern locked to
//     the emission clock. Because the formant does not track the
//     fundamental, the pulsaret timbre remains constant throughout.
//     Only the temporal pattern transforms — from rhythm through
//     tremolo into spectral sidebands. The independence isolates
//     the emission clock as the sole agent of perceptual change.
//
//   Configuration B — the independence as an archaeological OBJECT:
//     Eight passes through fundamental (or formant) sweeps and
//     stochastic trajectories, each revealing a different dimension
//     of the formant-fundamental relationship:
//       Pass 1: Absolute (original PG) — formants fixed, sound fragments
//       Pass 2: Harmonic ratios (×8, ×12, ×16) — coherent scaling
//       Pass 3: Subharmonic ratios (×0.5, ×0.75, ×1) — inverted hierarchy
//       Pass 4: Just intonation (×1, ×5/4, ×3/2) — pulsaret as chord
//       Pass 5: Formant sweep — fund fixed, ratios glide sub→overtone
//       Pass 6: Brownian fundamental, absolute formants — fragility exposed
//       Pass 7: Same Brownian trajectory, ratio formants — coherence maintained
//       Pass 8: Dual Brownian (fund + ratios) — compositional realism
//     Passes 1–5 use monotonic sweeps to isolate variables analytically.
//     Passes 6–8 use stochastic movement to show what the difference
//     means in compositional practice.
//
// What the first configuration uses as a transparent analytical
// tool — the independence that lets us isolate the emission clock —
// the second configuration renders visible as a historical design
// decision. The lens becomes the object of study. Eight passes
// map the space of alternatives the original design excluded,
// moving from analytical sweeps to compositionally realistic
// stochastic trajectories.
//
// Prerequisites:
//   ~app = NuPG_Application(1, 1).boot;
// =====================================================================


// =====================================================================
// RATIO MODE SETUP
// (extracted from nuPG_FormantRatioMode.scd for self-contained use)
// =====================================================================

(
~formantRatioDeps = ~formantRatioDeps ?? { Dictionary.new };

~formantRatioEnable = { |instance=0, formantNum=1, ratio=2|
	var key = (instance.asString ++ "_" ++ formantNum).asSymbol;
	var fundCV = ~app.data.data_main[instance][0];
	var synth = ~app.synthesis.trainInstances[instance];
	var synthOscOS = ~app.synthesisOscOS.trainInstances[instance];
	var paramName = [\formant_frequency_One, \formant_frequency_Two,
		\formant_frequency_Three][formantNum - 1];
	var dep;

	if (~formantRatioDeps[key].notNil) {
		fundCV.removeDependant(~formantRatioDeps[key]);
	};

	dep = { |cv, what, val|
		if (what == \value) {
			synth.set(paramName, val * ratio);
			synthOscOS.set(paramName, val * ratio);
		};
	};

	~formantRatioDeps[key] = dep;
	dep.(fundCV, \value, fundCV.value);
	fundCV.addDependant(dep);
};

~formantRatioDisable = { |instance=0, formantNum=1|
	var key = (instance.asString ++ "_" ++ formantNum).asSymbol;
	var fundCV = ~app.data.data_main[instance][0];
	var formantCV = ~app.data.data_main[instance][formantNum];
	var synth = ~app.synthesis.trainInstances[instance];
	var synthOscOS = ~app.synthesisOscOS.trainInstances[instance];
	var paramName = [\formant_frequency_One, \formant_frequency_Two,
		\formant_frequency_Three][formantNum - 1];

	if (~formantRatioDeps[key].notNil) {
		fundCV.removeDependant(~formantRatioDeps[key]);
		~formantRatioDeps[key] = nil;
		synth.set(paramName, formantCV.value);
		synthOscOS.set(paramName, formantCV.value);
	};
};

~formantRatioDisableAll = { |instance=0|
	3.do { |i| ~formantRatioDisable.(instance, i + 1) };
};

~formantRatioSet = { |instance=0, ratios=#[1, 2, 3]|
	ratios.do { |r, i| ~formantRatioEnable.(instance, i + 1, r) };
};

"Ratio mode functions loaded.".postln;
)


// =====================================================================
// CONFIGURATION A: Formant Independence as Temporal Lens
// =====================================================================

(
// --- Load pulsaret and envelope ---
// Set data CV (updates GUI table editor) then send to server buffer.
// CV expects Array, not Signal — use .asArray to convert.

var pulsaretData = Signal.sineFill(2048, [1, 0.5, 0.25]).as(Array);
var envelopeData = Signal.hanningWindow(2048).as(Array);

~app.data.data_pulsaret[0].value = pulsaretData;
~app.pulsaretBuffers[0].sendCollection(pulsaretData);

~app.data.data_envelope[0].value = envelopeData;
~app.envelopeBuffers[0].sendCollection(envelopeData);
)

(
// --- Configure parameters for Configuration A ---

var d = ~app.data;

// Burst/rest mask: 5 on, 3 off = 8-step repeating pattern
d.data_burstMask[0][0].value_(5);
d.data_burstMask[0][1].value_(3);

// Starting fundamental: 1 Hz
d.data_main[0][0].value_(1);

// Formant frequency: 800 Hz absolute — FIXED throughout the sweep.
// Independent of fundamental, as in the original PG.
// Pulsaret timbre remains constant regardless of emission rate.
d.data_main[0][1].value_(800);

// Envelope dilation: 1 = one complete cycle per grain
d.data_main[0][4].value_(1);

// Only group 1 active, full amplitude, centre pan
d.data_main[0][10].value_(0.7);  // amp 1
d.data_main[0][11].value_(0);    // amp 2
d.data_main[0][12].value_(0);    // amp 3
d.data_main[0][7].value_(0);     // pan 1

// No probability masking — burst/rest is the only structure
d.data_probabilityMaskSingular[0].value_(1.0);

// No modulation
d.data_modulators[0][0].value_(0);    // FM amount off
d.data_modulators[0][2].value_(0.0);  // flux off
)

(
// --- Sweep fundamental from 1 Hz to 500 Hz over 40 seconds ---
//
// The formant stays fixed at 800 Hz. As the fundamental rises:
//   - emission period compresses (1000 ms → 2 ms)
//   - burst/rest cycle compresses (8 s → 16 ms)
//   - pulsaret timbre does NOT change
//
// Rhythm becomes tremolo becomes spectral structure,
// unified by a single temporal mechanism.

var d = ~app.data;
var sweepDuration = 40;
var startFreq = 1;
var endFreq = 500;
var updateRate = 20;
var numSteps = (sweepDuration * updateRate).asInteger;

~app.synthSwitcher.play;

~sweepA = Routine({
	numSteps.do { |step|
		var normalised = step / numSteps;
		var freq = startFreq * (endFreq / startFreq).pow(normalised);
		d.data_main[0][0].value_(freq);

		if (step % (numSteps / 8).asInteger == 0) {
			var burstCycle = 8 / freq;
			("A | emission: " ++ freq.round(0.1) ++ " Hz"
				++ " | formant: 800 Hz (constant)"
				++ " | 8-step cycle: " ++ (burstCycle * 1000).round(0.1) ++ " ms"
			).postln;
		};
		(1 / updateRate).wait;
	};
	"--- Configuration A complete ---".postln;
}).play(AppClock);
)

// --- Stop Configuration A ---
(
~sweepA.stop;
~app.synthSwitcher.stop;
)


// =====================================================================
// CONFIGURATION B: Formant Independence as Archaeological Object
// =====================================================================
//
// A series of passes through fundamental sweeps and stochastic
// trajectories, each revealing a different dimension of the
// formant-fundamental relationship.
// The absolute mode (Pass 1) establishes the original PG's behaviour;
// subsequent passes use the ratio mode extension to show what that
// design decision excluded.
//
//   Pass 1 — Absolute (original PG): formants fixed at 800, 1200, 1600 Hz
//   Pass 2 — Harmonic ratios: formants track as ×8, ×12, ×16
//   Pass 3 — Subharmonic ratios: formants below fundamental (×0.5, ×0.75, ×1)
//   Pass 4 — Just intonation triad: formants as ×1, ×1.25, ×1.5 (JI major)
//   Pass 5 — Formant sweep: fundamental fixed, formants glide through ratios
//   Pass 6 — Brownian fundamental, absolute formants
//   Pass 7 — Same Brownian trajectory, ratio formants
//   Pass 8 — Dual Brownian: fundamental and ratios both wander
//
// Evaluate the shared setup block first, then run passes individually.
// =====================================================================


// --- Shared setup for all Configuration B passes ---
(
var d = ~app.data;

// Disable burst/rest — clean train, no masking
d.data_burstMask[0][0].value_(1);
d.data_burstMask[0][1].value_(0);

// All three groups active
d.data_main[0][10].value_(0.5);  // amp 1
d.data_main[0][11].value_(0.5);  // amp 2
d.data_main[0][12].value_(0.5);  // amp 3

// Envelope dilation for all three
d.data_main[0][4].value_(1);
d.data_main[0][5].value_(1);
d.data_main[0][6].value_(1);

// Panning: spread across stereo field
d.data_main[0][7].value_(-0.5);  // pan 1 left
d.data_main[0][8].value_(0);     // pan 2 centre
d.data_main[0][9].value_(0.5);   // pan 3 right

// Starting fundamental
d.data_main[0][0].value_(50);

// Three formants: 800, 1200, 1600 Hz absolute
d.data_main[0][1].value_(800);
d.data_main[0][2].value_(1200);
d.data_main[0][3].value_(1600);

// No modulation
d.data_modulators[0][0].value_(0);
d.data_modulators[0][2].value_(0.0);
d.data_probabilityMaskSingular[0].value_(1.0);

// Ensure ratio mode is off
~formantRatioDisableAll.(0);

"Configuration B setup complete.".postln;
)


// --- Pass 1: Absolute mode (original PG behaviour) ---
// Formants remain at 800, 1200, 1600 Hz regardless of fundamental.
// Sound fragments as fundamental moves away from formant region.
// This is the PG's design: the pulsaret is a fixed spectral object.

(
var d = ~app.data;
var sweepDuration = 20;
var startFreq = 50;
var endFreq = 500;
var updateRate = 20;
var numSteps = (sweepDuration * updateRate).asInteger;

~formantRatioDisableAll.(0);

"--- Pass 1: ABSOLUTE mode ---".postln;
("Formants fixed at 800, 1200, 1600 Hz").postln;

~app.synthSwitcher.play;

~sweepB1 = Routine({
	numSteps.do { |step|
		var normalised = step / numSteps;
		var freq = startFreq * (endFreq / startFreq).pow(normalised);
		d.data_main[0][0].value_(freq);

		if (step % (numSteps / 5).asInteger == 0) {
			("  absolute | fund: " ++ freq.round(0.1) ++ " Hz"
				++ " | formants: 800, 1200, 1600 Hz"
			).postln;
		};
		(1 / updateRate).wait;
	};
	"--- Pass 1 complete ---".postln;
	~app.synthSwitcher.stop;
}).play(AppClock);
)

// --- Stop Pass 1 if needed ---
(
~sweepB1.stop;
~app.synthSwitcher.stop;
)


// --- Pass 2: Harmonic ratios (×8, ×12, ×16) ---
// Formants track the fundamental as integer multiples.
// At fund=100: formants = 800, 1200, 1600 (matching Pass 1's start).
// As fundamental moves, spectral proportions are preserved.
// The sound remains coherent — a resonant body that scales with pitch.

(
var d = ~app.data;
var sweepDuration = 20;
var startFreq = 50;
var endFreq = 500;
var updateRate = 20;
var numSteps = (sweepDuration * updateRate).asInteger;

~formantRatioSet.(0, [8, 12, 16]);
d.data_main[0][0].value_(startFreq);

"--- Pass 2: HARMONIC RATIOS (×8, ×12, ×16) ---".postln;

~app.synthSwitcher.play;

~sweepB2 = Routine({
	numSteps.do { |step|
		var normalised = step / numSteps;
		var freq = startFreq * (endFreq / startFreq).pow(normalised);
		d.data_main[0][0].value_(freq);

		if (step % (numSteps / 5).asInteger == 0) {
			("  ratio | fund: " ++ freq.round(0.1) ++ " Hz"
				++ " | formants: "
				++ (freq * 8).round(0.1) ++ ", "
				++ (freq * 12).round(0.1) ++ ", "
				++ (freq * 16).round(0.1) ++ " Hz"
			).postln;
		};
		(1 / updateRate).wait;
	};
	"--- Pass 2 complete ---".postln;
	~app.synthSwitcher.stop;
	~formantRatioDisableAll.(0);
}).play(AppClock);
)

// --- Stop Pass 2 if needed ---
(
~sweepB2.stop;
~app.synthSwitcher.stop;
~formantRatioDisableAll.(0);
)


// --- Pass 3: Subharmonic ratios (×0.5, ×0.75, ×1) ---
// Formants sit BELOW or at the fundamental frequency.
// This inverts the normal spectral hierarchy: the pulsaret's
// spectral content is lower than its emission rate.
// At fund=200: formants = 100, 150, 200 Hz.
// The result is a dark, weighted texture where the grain envelope
// modulates a sub-fundamental drone — the opposite of the bright,
// separated pulsarets in absolute mode.
// This regime was inaccessible in the original PG's fixed-formant
// paradigm (formants below fundamental produced no useful result
// because they couldn't track).

(
var d = ~app.data;
var sweepDuration = 20;
var startFreq = 80;
var endFreq = 400;
var updateRate = 20;
var numSteps = (sweepDuration * updateRate).asInteger;

~formantRatioSet.(0, [0.5, 0.75, 1]);
d.data_main[0][0].value_(startFreq);

"--- Pass 3: SUBHARMONIC RATIOS (×0.5, ×0.75, ×1) ---".postln;

~app.synthSwitcher.play;

~sweepB3 = Routine({
	numSteps.do { |step|
		var normalised = step / numSteps;
		var freq = startFreq * (endFreq / startFreq).pow(normalised);
		d.data_main[0][0].value_(freq);

		if (step % (numSteps / 5).asInteger == 0) {
			("  subharm | fund: " ++ freq.round(0.1) ++ " Hz"
				++ " | formants: "
				++ (freq * 0.5).round(0.1) ++ ", "
				++ (freq * 0.75).round(0.1) ++ ", "
				++ (freq * 1).round(0.1) ++ " Hz"
			).postln;
		};
		(1 / updateRate).wait;
	};
	"--- Pass 3 complete ---".postln;
	~app.synthSwitcher.stop;
	~formantRatioDisableAll.(0);
}).play(AppClock);
)

// --- Stop Pass 3 if needed ---
(
~sweepB3.stop;
~app.synthSwitcher.stop;
~formantRatioDisableAll.(0);
)


// --- Pass 4: Just intonation triad (×1, ×1.25, ×1.5) ---
// Formants form a just-intoned major triad relative to the fundamental:
//   root (×1), major third (×5/4), perfect fifth (×3/2).
// At fund=200: formants = 200, 250, 300 Hz — a close-voiced chord
// embedded within each pulsaret. The fundamental sweep from 80–400 Hz
// transposes the entire chord, preserving the just intervals.
// This demonstrates the ratio mode as a means of embedding harmonic
// structure within the grain itself — the pulsaret becomes a chord.

(
var d = ~app.data;
var sweepDuration = 20;
var startFreq = 80;
var endFreq = 400;
var updateRate = 20;
var numSteps = (sweepDuration * updateRate).asInteger;

~formantRatioSet.(0, [1, 1.25, 1.5]);
d.data_main[0][0].value_(startFreq);

"--- Pass 4: JUST INTONATION TRIAD (×1, ×5/4, ×3/2) ---".postln;

~app.synthSwitcher.play;

~sweepB4 = Routine({
	numSteps.do { |step|
		var normalised = step / numSteps;
		var freq = startFreq * (endFreq / startFreq).pow(normalised);
		d.data_main[0][0].value_(freq);

		if (step % (numSteps / 5).asInteger == 0) {
			("  JI triad | fund: " ++ freq.round(0.1) ++ " Hz"
				++ " | formants: "
				++ (freq * 1).round(0.1) ++ ", "
				++ (freq * 1.25).round(0.1) ++ ", "
				++ (freq * 1.5).round(0.1) ++ " Hz"
			).postln;
		};
		(1 / updateRate).wait;
	};
	"--- Pass 4 complete ---".postln;
	~app.synthSwitcher.stop;
	~formantRatioDisableAll.(0);
}).play(AppClock);
)

// --- Stop Pass 4 if needed ---
(
~sweepB4.stop;
~app.synthSwitcher.stop;
~formantRatioDisableAll.(0);
)


// --- Pass 5: Formant sweep (fundamental fixed, ratios glide) ---
// The inverse of Passes 1–4: fundamental stays at 150 Hz while
// the formant ratios sweep continuously from subharmonic through
// harmonic to high-overtone territory.
//
// All three formants move in parallel:
//   formant 1: ratio sweeps 0.5 → 12
//   formant 2: ratio sweeps 0.75 → 16
//   formant 3: ratio sweeps 1.0 → 20
//
// The listener hears the spectral content of the pulsaret rise
// from below the fundamental (dark, beating drone) through unison
// (reinforcement) into increasingly bright, separated partials.
// The fundamental is the constant; the formant relationship is
// the variable — reversing the analytical strategy of Pass 1.

(
var d = ~app.data;
var sweepDuration = 25;
var updateRate = 20;
var numSteps = (sweepDuration * updateRate).asInteger;
var fund = 150;

var startRatios = [0.5, 0.75, 1.0];
var endRatios = [12, 16, 20];

// Fix fundamental
d.data_main[0][0].value_(fund);

"--- Pass 5: FORMANT SWEEP (fund fixed at 150 Hz) ---".postln;
("Ratios glide from " ++ startRatios ++ " to " ++ endRatios).postln;

~app.synthSwitcher.play;

~sweepB5 = Routine({
	numSteps.do { |step|
		var normalised = step / numSteps;
		var currentRatios = 3.collect { |j|
			startRatios[j] * (endRatios[j] / startRatios[j]).pow(normalised);
		};

		// Update ratios — re-enable with new values each step
		3.do { |j|
			~formantRatioEnable.(0, j + 1, currentRatios[j]);
		};

		if (step % (numSteps / 8).asInteger == 0) {
			("  sweep | fund: " ++ fund ++ " Hz"
				++ " | ratios: ×" ++ currentRatios[0].round(0.01)
				++ ", ×" ++ currentRatios[1].round(0.01)
				++ ", ×" ++ currentRatios[2].round(0.01)
				++ " | formants: "
				++ (fund * currentRatios[0]).round(0.1)
				++ ", " ++ (fund * currentRatios[1]).round(0.1)
				++ ", " ++ (fund * currentRatios[2]).round(0.1) ++ " Hz"
			).postln;
		};
		(1 / updateRate).wait;
	};
	"--- Pass 5 complete ---".postln;
	~app.synthSwitcher.stop;
	~formantRatioDisableAll.(0);
}).play(AppClock);
)

// --- Stop Pass 5 if needed ---
(
~sweepB5.stop;
~app.synthSwitcher.stop;
~formantRatioDisableAll.(0);
)


// --- Pass 6: Brownian fundamental, absolute formants ---
// All previous passes used monotonic sweeps — useful for isolating
// variables but not representative of compositional use. This pass
// applies a bounded Brownian walk to the fundamental frequency,
// producing the kind of irregular, exploratory trajectory that
// characterizes actual musical work with the system.
//
// Formants remain fixed at 800, 1200, 1600 Hz (absolute mode).
// As the fundamental wanders, the spectral relationship between
// fundamental and formants shifts unpredictably — sometimes the
// formants sit far above the emission rate (bright, separated
// pulsarets), sometimes they converge (dense, fused texture),
// sometimes they cross below (spectral inversion). The timbral
// character lurches between regimes rather than transitioning
// smoothly. The Brownian trajectory exposes the absolute mode's
// fragility: small changes in fundamental produce disproportionate
// timbral shifts when the formants don't track.

(
var d = ~app.data;
var duration = 30;
var updateRate = 20;
var numSteps = (duration * updateRate).asInteger;

// Brownian walk parameters
var freq = 150;           // starting frequency
var stepSize = 3;         // max Hz change per step
var minFreq = 40;
var maxFreq = 600;

// Store trajectory for reuse in Pass 7
~brownianTrajectory = Array.newClear(numSteps);

~formantRatioDisableAll.(0);

// Fixed formants
d.data_main[0][1].value_(800);
d.data_main[0][2].value_(1200);
d.data_main[0][3].value_(1600);
d.data_main[0][0].value_(freq);

"--- Pass 6: BROWNIAN FUNDAMENTAL, ABSOLUTE FORMANTS ---".postln;
("Formants fixed at 800, 1200, 1600 Hz").postln;

~app.synthSwitcher.play;

~sweepB6 = Routine({
	numSteps.do { |step|
		// Brownian step with reflective boundaries
		freq = (freq + (stepSize.rand2)).clip(minFreq, maxFreq);
		~brownianTrajectory[step] = freq;
		d.data_main[0][0].value_(freq);

		if (step % (numSteps / 6).asInteger == 0) {
			("  brownian/abs | fund: " ++ freq.round(0.1) ++ " Hz"
				++ " | formants: 800, 1200, 1600 Hz (fixed)"
			).postln;
		};
		(1 / updateRate).wait;
	};
	"--- Pass 6 complete ---".postln;
	~app.synthSwitcher.stop;
}).play(AppClock);
)

// --- Stop Pass 6 if needed ---
(
~sweepB6.stop;
~app.synthSwitcher.stop;
)


// --- Pass 7: Same Brownian trajectory, ratio formants ---
// Replays the EXACT trajectory recorded in Pass 6, but with
// formants tracking as proportional multipliers (×5, ×8, ×11).
//
// The comparison is direct: identical fundamental movement,
// different formant behavior. Where Pass 6 lurched between
// timbral regimes unpredictably, Pass 7 maintains a consistent
// spectral character throughout — the same wandering pitch
// contour heard through a stable timbral lens.
//
// The contrast makes vivid what the sweeps demonstrated
// analytically: absolute mode produces a sound whose timbral
// identity is hostage to the fundamental's position relative
// to fixed formant frequencies; ratio mode produces a sound
// whose identity travels with the fundamental. In compositional
// practice, this is the difference between a material that
// fractures under melodic movement and one that remains
// coherent.

(
var d = ~app.data;
var updateRate = 20;
var trajectory = ~brownianTrajectory;

if (trajectory.isNil or: { trajectory[0].isNil }) {
	"ERROR: Run Pass 6 first to generate trajectory.".postln;
} {
	var numSteps = trajectory.size;

	// Ratio mode: formants = fund × [5, 8, 11]
	~formantRatioSet.(0, [5, 8, 11]);
	d.data_main[0][0].value_(trajectory[0]);

	"--- Pass 7: SAME BROWNIAN TRAJECTORY, RATIO FORMANTS (×5, ×8, ×11) ---".postln;

	~app.synthSwitcher.play;

	~sweepB7 = Routine({
		numSteps.do { |step|
			var freq = trajectory[step];
			d.data_main[0][0].value_(freq);

			if (step % (numSteps / 6).asInteger == 0) {
				("  brownian/ratio | fund: " ++ freq.round(0.1) ++ " Hz"
					++ " | formants: "
					++ (freq * 5).round(0.1) ++ ", "
					++ (freq * 8).round(0.1) ++ ", "
					++ (freq * 11).round(0.1) ++ " Hz"
				).postln;
			};
			(1 / updateRate).wait;
		};
		"--- Pass 7 complete ---".postln;
		~app.synthSwitcher.stop;
		~formantRatioDisableAll.(0);
	}).play(AppClock);
};
)

// --- Stop Pass 7 if needed ---
(
~sweepB7.stop;
~app.synthSwitcher.stop;
~formantRatioDisableAll.(0);
)


// --- Pass 8: Brownian fundamental AND drifting ratios ---
// Both fundamental and formant ratios move simultaneously via
// independent Brownian walks. The fundamental wanders 60–400 Hz
// while each ratio drifts within its own bounded range:
//   ratio 1: 0.5–6   (subharmonic through mid-harmonic)
//   ratio 2: 2–12    (low harmonic through high)
//   ratio 3: 4–20    (mid through very high overtone)
//
// This is the most compositionally realistic pass: nothing is
// fixed, everything moves, and the formant-fundamental relationship
// is itself in flux. The result is a continuously morphing texture
// where timbral identity, pitch, and spectral balance all shift
// independently but remain coupled through the ratio system.
// Moments of consonance (ratios near simple integers) emerge and
// dissolve into inharmonic, bell-like territories as the ratios
// drift through non-integer values.

(
var d = ~app.data;
var duration = 40;
var updateRate = 20;
var numSteps = (duration * updateRate).asInteger;

// Fundamental Brownian walk
var freq = 150;
var freqStep = 4;
var minFreq = 60;
var maxFreq = 400;

// Ratio Brownian walks — three independent streams
var ratios = [2.0, 7.0, 12.0];        // starting ratios
var ratioSteps = [0.15, 0.2, 0.25];   // step sizes (smaller = smoother)
var ratioMins = [0.5, 2.0, 4.0];
var ratioMaxs = [6.0, 12.0, 20.0];

"--- Pass 8: DUAL BROWNIAN (fundamental + ratios) ---".postln;

~app.synthSwitcher.play;

~sweepB8 = Routine({
	numSteps.do { |step|
		// Walk the fundamental
		freq = (freq + (freqStep.rand2)).clip(minFreq, maxFreq);
		d.data_main[0][0].value_(freq);

		// Walk each ratio independently
		3.do { |j|
			ratios[j] = (ratios[j] + (ratioSteps[j].rand2))
				.clip(ratioMins[j], ratioMaxs[j]);
			~formantRatioEnable.(0, j + 1, ratios[j]);
		};

		if (step % (numSteps / 8).asInteger == 0) {
			("  dual brownian | fund: " ++ freq.round(0.1) ++ " Hz"
				++ " | ratios: ×" ++ ratios[0].round(0.01)
				++ ", ×" ++ ratios[1].round(0.01)
				++ ", ×" ++ ratios[2].round(0.01)
				++ " | formants: "
				++ (freq * ratios[0]).round(0.1) ++ ", "
				++ (freq * ratios[1]).round(0.1) ++ ", "
				++ (freq * ratios[2]).round(0.1) ++ " Hz"
			).postln;
		};
		(1 / updateRate).wait;
	};
	"--- Pass 8 complete ---".postln;
	~app.synthSwitcher.stop;
	~formantRatioDisableAll.(0);
}).play(AppClock);
)

// --- Stop Pass 8 if needed ---
(
~sweepB8.stop;
~app.synthSwitcher.stop;
~formantRatioDisableAll.(0);
)


// =====================================================================
// Listening guide:
//
// CONFIGURATION A — Temporal Lens
//
//  0–10 s  (~1–5 Hz):
//    Individual pulsarets as discrete clicks, each with 800 Hz
//    timbral character. The 5:3 burst/rest pattern is heard as
//    slow rhythmic grouping — five clicks, silence, five clicks.
//
//  10–20 s (~5–25 Hz):
//    Pulsarets fuse into a buzzing texture. Burst/rest becomes
//    tremolo. The timbre of each pulsaret is unchanged — what
//    transforms is the temporal pattern.
//
//  20–30 s (~25–150 Hz):
//    Clear pitch emerges. The burst/rest pattern manifests as
//    spectral sidebands — Roads's observation that masking sounds
//    like ring modulation. The pulsaret still carries 800 Hz
//    spectral content, but the masking pattern now shapes the
//    spectrum rather than the rhythm.
//
//  30–40 s (~150–500 Hz):
//    Stable pitched tone with sideband structure. The 5:3 pattern
//    is absorbed into spectral identity. Rhythm has become timbre.
//
//
// CONFIGURATION B — Archaeological Object
//
//  Pass 1 (Absolute):
//    At 50 Hz the three formants (800, 1200, 1600) sit well above
//    the sparse emission rate — bright, separated pulsarets. As the
//    fundamental rises, the formants do not follow. The pulsarets
//    thicken into a pitched tone, but the fixed formant frequencies
//    increasingly merge with the densifying pulse train. The sound
//    fragments — spectral identity and temporal pattern pull apart.
//
//  Pass 2 (Harmonic ratios ×8, ×12, ×16):
//    Same sweep, formants track proportionally. At 50 Hz the formants
//    are 400, 600, 800 Hz. At 500 Hz they are 4000, 6000, 8000 Hz.
//    Spectral relationship preserved — the pulsaret scales coherently
//    with pitch. Compare directly with Pass 1: the difference is
//    the design decision made audible.
//
//  Pass 3 (Subharmonic ratios ×0.5, ×0.75, ×1):
//    Formants sit below or at the fundamental. The normal spectral
//    hierarchy is inverted: pulsaret content is darker than the
//    emission rate suggests. Heavy, weighted texture — the grain
//    envelope modulates a sub-fundamental drone. This territory
//    was essentially inaccessible in the original PG because fixed
//    sub-fundamental formants only made sense at one emission rate.
//    Ratio mode opens it as a stable regime across the pitch range.
//
//  Pass 4 (Just intonation ×1, ×5/4, ×3/2):
//    Formants form a major triad locked to the fundamental. Each
//    pulsaret is itself a chord. The sweep transposes the chord
//    from 80 Hz to 400 Hz with just intervals preserved throughout.
//    At low rates individual triadic grains are audible; as rate
//    rises they fuse into a harmonically rich pitched tone.
//
//  Pass 5 (Formant sweep, fund fixed at 150 Hz):
//    The inverse: fundamental constant, ratios glide from
//    subharmonic (×0.5) to high-overtone (×20). The pulsaret's
//    spectral content rises continuously from below the fundamental
//    through unison reinforcement into bright, separated partials.
//    Reverses the analytical strategy — the emission clock is the
//    constant, formant relationship is the variable.
//
//  Pass 6 (Brownian fundamental, absolute formants):
//    A bounded random walk drives the fundamental (40–600 Hz)
//    while formants stay fixed at 800, 1200, 1600 Hz. The
//    trajectory is stored for reuse. Unlike the smooth sweeps,
//    the Brownian path produces unpredictable lurches between
//    timbral regimes — sometimes bright and separated, sometimes
//    dense and fused, sometimes spectrally inverted. The absolute
//    mode's fragility is exposed: small changes in fundamental
//    produce disproportionate timbral shifts.
//
//  Pass 7 (Same trajectory, ratio formants):
//    The EXACT Brownian trajectory from Pass 6, replayed with
//    formants tracking as ×5, ×8, ×11. The comparison is direct:
//    identical pitch movement, different timbral behavior. Where
//    Pass 6 lurched between regimes, Pass 7 maintains consistent
//    spectral character throughout. This is the compositional
//    difference: a material that fractures under melodic movement
//    versus one that remains coherent.
//
//  Pass 8 (Dual Brownian — fundamental and ratios):
//    Both fundamental and formant ratios move via independent
//    Brownian walks. The most compositionally realistic pass:
//    nothing is fixed, everything drifts. Moments of consonance
//    (ratios near simple integers) emerge and dissolve into
//    inharmonic, bell-like territories. The texture morphs
//    continuously — timbral identity, pitch, and spectral balance
//    all shift but remain coupled through the ratio system.
//
//  Collectively, the eight passes demonstrate that the original PG's
//  absolute formant model is one point in a space of possible
//  formant-fundamental relationships. The ratio mode does not
//  replace the original but makes it visible as a specific position.
//  The Brownian passes (6–8) show what this means in practice:
//  the difference between a synthesis architecture that fragments
//  under complex movement and one that remains compositionally
//  tractable.
// =====================================================================
