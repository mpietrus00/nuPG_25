// =====================================================================
// Example 2: The 2048-Point Table as Recursive Structure
//
// Demonstrates the recursive temporal ontology of pulsar synthesis:
// the same 2048-point data structure simultaneously defines
// micro-temporal waveform shape (at audio rate) and macro-temporal
// parametric trajectory (at the rate of the loop task).
//
// The example uses a single table shape loaded into BOTH:
//   - the pulsaret waveform buffer (read at the formant frequency,
//     defining the spectral content of each grain)
//   - the formant frequency loop table (read over the train duration,
//     defining how formant frequency evolves across time)
//
// When we transform this shared shape — quantize it, smooth it,
// reverse it, add noise — both temporal scales are affected
// simultaneously by the same operation. The resulting sonic
// phenomena are categorically different at the two scales (timbre
// vs. parametric trajectory) yet structurally identical.
//
// This is the displacement that generates archaeological insight:
// the recognition that digital reduction at the micro level and
// stepped sequencing at the macro level are the SAME thing viewed
// at different temporal scales.
//
// Structure:
//   Part A — Smooth sine shape at both scales (baseline)
//   Part B — Quantized shape: the core demonstration
//   Part C — Catalog of table operations (R, I, SM, +N, PW)
//   Part D — Progressive transformation as formal process
//
// Prerequisites:
//   ~app = NuPG_Application(1, 1).boot;
// =====================================================================


// =====================================================================
// HELPER FUNCTIONS
// =====================================================================

(
// --- Load a shape into BOTH the pulsaret buffer AND the formant
//     frequency loop table simultaneously ---
// shape: Array of 2048 floats in -1..1 range
// This is the core operation: one shape, two temporal scales.

~loadShapeBothScales = { |shape|
	// Audio rate: pulsaret waveform
	// Updates GUI table editor AND server buffer
	~app.data.data_pulsaret[0].value = shape;
	~app.pulsaretBuffers[0].sendCollection(shape);

	// Parametric rate: formant frequency loop table
	// The CV holds a 2048-element Array; the loop task reads it
	// at (trainDuration / 2048) seconds per step, mapping -1..1
	// to the maxMin range. Setting .value replaces the whole array.
	~app.data.data_formantFrequencyOne[0].value = shape;
};

// --- Table operations ---
// These replicate the GUI table editor buttons (QT, SM, R, I, +N, PW).
// Each takes an Array and returns a transformed Array.
// The operation is identical regardless of what temporal scale
// the table will be read at — that is the point.

~tableQuantize = { |array, levels = 8|
	array.collect { |val|
		((val + 1) / 2 * levels).round / levels * 2 - 1
	};
};

~tableSmooth = { |array, windowSize = 8|
	var size = array.size;
	Array.fill(size, { |j|
		var sum = 0, count = 0;
		windowSize.do { |k|
			var idx = (j - (windowSize / 2).asInteger + k).wrap(0, size - 1);
			sum = sum + array[idx];
			count = count + 1;
		};
		sum / count;
	});
};

~tableReverse = { |array|
	array.reverse;
};

~tableInvert = { |array|
	array.neg;
};

~tableAddNoise = { |array, amount = 0.1|
	array.collect { |val| (val + amount.rand2).clip(-1, 1) };
};

~tablePower = { |array, exponent = 2|
	array.collect { |val| val.sign * (val.abs.pow(exponent)) };
};

"Helper functions loaded.".postln;
)


// =====================================================================
// SETUP: Configure train parameters
// =====================================================================

(
var d = ~app.data;

// Hanning envelope
var envData = Signal.hanningWindow(2048).as(Array);
d.data_envelope[0].value = envData;
~app.envelopeBuffers[0].sendCollection(envData);

// No burst/rest masking — continuous emission
d.data_burstMask[0][0].value_(1);
d.data_burstMask[0][1].value_(0);

// Fundamental: 150 Hz — stable pitch in the audio range
d.data_main[0][0].value_(150);

// Formant frequency base: 800 Hz
// (the loop table will modulate this via the _loop parameter)
d.data_main[0][1].value_(800);

// Envelope dilation
d.data_main[0][4].value_(1);

// Group 1 only
d.data_main[0][10].value_(0.6);  // amp 1
d.data_main[0][11].value_(0);    // amp 2
d.data_main[0][12].value_(0);    // amp 3
d.data_main[0][7].value_(0);     // pan centre

// No modulation
d.data_modulators[0][0].value_(0);
d.data_modulators[0][2].value_(0.0);
d.data_probabilityMaskSingular[0].value_(1.0);

// --- Loop task configuration ---
// The formant frequency loop table maps -1..1 to this range:
d.data_formantFrequencyOne_maxMin[0][0].value_(2000);  // max Hz
d.data_formantFrequencyOne_maxMin[0][1].value_(200);   // min Hz

// Train duration: 8 seconds per full traversal of 2048 points
// This means each table point is held for ~3.9 ms
d.data_trainDuration[0].value_(8);

// Store the base shape for later transformations
~baseShape = Signal.sineFill(2048, [1, 0.3, 0.1]).as(Array);

"Setup complete.".postln;
)


// =====================================================================
// PART A: Smooth sine shape at both scales
// =====================================================================
// The shape — a sine with mild harmonics — is loaded into both the
// pulsaret waveform buffer and the formant frequency loop table.
//
// At audio rate: the shape defines each pulsaret's spectral content.
//   A smooth sine produces a clean, harmonically simple tone.
//
// At parametric rate: the same shape sweeps the formant frequency
//   between 200 and 2000 Hz over 8 seconds. The trajectory is
//   smooth and continuous because the underlying data is smooth.

(
~loadShapeBothScales.(~baseShape);
"Part A: Smooth sine loaded at both scales.".postln;
"  Pulsaret: clean, harmonically simple tone".postln;
"  Formant trajectory: smooth 200-2000 Hz sweep over 8 seconds".postln;
)

// --- Play Part A ---
(
~app.synthSwitcher.play;
~app.loopTask.tasks[0].set(\playbackDirection, 0);
~app.loopTask.tasks[0].play;
"--- Playing Part A: smooth sine ---".postln;
)

// --- Stop Part A ---
(
~app.loopTask.tasks[0].stop;
~app.synthSwitcher.stop;
)


// =====================================================================
// PART B: Quantized shape — the core demonstration
// =====================================================================
// The SAME sine shape is quantized to 8 discrete levels, then
// loaded into both scales simultaneously. The operation is
// identical — same algorithm, same number of levels, same data
// structure. But the sonic results are categorically different:
//
// At audio rate: the stepped waveform introduces strong harmonics,
//   producing a harsh, bitcrushed spectral character. The 8 levels
//   create a staircase waveform similar to low-bit-depth audio.
//
// At parametric rate: the formant frequency now snaps between 8
//   discrete values instead of gliding smoothly. The trajectory
//   has a mechanical, sequencer-like character — stepped plateaus
//   with abrupt jumps.
//
// ONE operation. TWO incommensurable sonic phenomena.
// Both are the same thing at different temporal scales.

(
var quantized = ~tableQuantize.(~baseShape, 8);
~loadShapeBothScales.(quantized);
"Part B: Quantized (8 levels) loaded at both scales.".postln;
"  Pulsaret: harsh, bitcrushed spectral character".postln;
"  Formant trajectory: 8-step staircase between 200-2000 Hz".postln;
"  SAME data structure, SAME operation — different temporal scales".postln;
)

// --- Play Part B ---
(
~app.synthSwitcher.play;
~app.loopTask.tasks[0].set(\playbackDirection, 0);
~app.loopTask.tasks[0].play;
"--- Playing Part B: quantized (8 levels) ---".postln;
)

// --- Stop Part B ---
(
~app.loopTask.tasks[0].stop;
~app.synthSwitcher.stop;
)


// =====================================================================
// PART C: Catalog of table operations
// =====================================================================
// Each operation from the table editor applied to the same base
// shape, loaded at both scales. Evaluate one at a time while
// the synth and loop task are running to hear the transformation
// at both temporal scales simultaneously.

// --- Start playback for Part C ---
(
~loadShapeBothScales.(~baseShape);  // start from smooth sine
~app.synthSwitcher.play;
~app.loopTask.tasks[0].set(\playbackDirection, 0);
~app.loopTask.tasks[0].play;
"--- Part C: evaluate operations below while listening ---".postln;
)

// C1: Reset to smooth sine
(
~loadShapeBothScales.(~baseShape);
"C1: Reset to smooth sine".postln;
)

// C2: Quantize — 8 levels
// Audio: bitcrushed. Parametric: staircase.
(
~loadShapeBothScales.(~tableQuantize.(~baseShape, 8));
"C2: Quantized (8 levels)".postln;
)

// C3: Quantize — 4 levels (more extreme)
// Audio: harsher square-like waveform. Parametric: 4 broad steps.
(
~loadShapeBothScales.(~tableQuantize.(~baseShape, 4));
"C3: Quantized (4 levels)".postln;
)

// C4: Quantize — 2 levels (maximum)
// Audio: pure square wave. Parametric: binary flip between min and max.
(
~loadShapeBothScales.(~tableQuantize.(~baseShape, 2));
"C4: Quantized (2 levels) — square wave / binary flip".postln;
)

// C5: Reverse
// Audio: reversed waveform (changes phase relationships, subtle
//   timbral shift). Parametric: trajectory runs backwards
//   (descending where it ascended).
(
~loadShapeBothScales.(~tableReverse.(~baseShape));
"C5: Reversed".postln;
)

// C6: Invert (vertical flip)
// Audio: negated waveform (inaudible change for symmetric waveforms
//   but significant for asymmetric ones). Parametric: trajectory
//   inverted (high becomes low, low becomes high).
(
~loadShapeBothScales.(~tableInvert.(~baseShape));
"C6: Inverted".postln;
)

// C7: Smooth (moving average, window = 32)
// Audio: gentler waveform, reduced high harmonics (low-pass effect).
// Parametric: smoother trajectory, reduced detail.
(
~loadShapeBothScales.(~tableSmooth.(~baseShape, 32));
"C7: Smoothed (window 32)".postln;
)

// C8: Add noise
// Audio: noisy waveform, spectral broadening.
// Parametric: jittery trajectory, random perturbation of the sweep.
(
~loadShapeBothScales.(~tableAddNoise.(~baseShape, 0.3));
"C8: Noise added (0.3)".postln;
)

// C9: Power curve (squared)
// Audio: waveform concentrated near zero, sharp peaks — adds
//   harmonics, changes spectral balance.
// Parametric: trajectory spends more time near the minimum,
//   with sharper excursions to the maximum.
(
~loadShapeBothScales.(~tablePower.(~baseShape, 2));
"C9: Power curve (squared)".postln;
)

// C10: Power curve (cubed)
// Audio: more extreme concentration, richer harmonics.
// Parametric: trajectory strongly biased toward minimum,
//   brief spikes to maximum.
(
~loadShapeBothScales.(~tablePower.(~baseShape, 3));
"C10: Power curve (cubed)".postln;
)

// C11: Compound — noise + quantize + power
// The three-stage transformation described in the article,
// applied as a single compound operation.
(
var shaped = ~baseShape.deepCopy;
shaped = ~tableAddNoise.(shaped, 0.15);
shaped = ~tableQuantize.(shaped, 6);
shaped = ~tablePower.(shaped, 2);
~loadShapeBothScales.(shaped);
"C11: Compound (noise + quantize + power)".postln;
)

// --- Stop Part C ---
(
~app.loopTask.tasks[0].stop;
~app.synthSwitcher.stop;
)


// =====================================================================
// PART D: Progressive transformation as formal process
// =====================================================================
// A single formal process operates simultaneously at all temporal
// scales. The piece begins with a smooth sine-based table, then
// progressively applies:
//   Phase 1 (0–20 s):  Noise addition — increasing roughness
//   Phase 2 (20–40 s): Quantization — decreasing resolution
//   Phase 3 (40–60 s): Power curve — increasing concentration
//
// Each transformation simultaneously roughens the timbral character
// of individual pulsarets (audio rate) and introduces increasing
// structural complexity into the parametric trajectories (loop rate).
// The formal arc of the composition is generated by a single process
// operating at all temporal scales, producing a coherence that
// derives directly from the system's recursive architecture.

(
var d = ~app.data;
var duration = 60;
var updateRate = 2;  // table updates per second (2048 CVs per update)
var numSteps = (duration * updateRate).asInteger;

// Start playback
~app.synthSwitcher.play;
~app.loopTask.tasks[0].set(\playbackDirection, 0);
~app.loopTask.tasks[0].play;

"--- Part D: Progressive transformation (60 seconds) ---".postln;

~progressRoutine = Routine({
	numSteps.do { |step|
		var progress = step / numSteps;  // 0.0 → 1.0
		var shaped = ~baseShape.deepCopy;
		var phase;

		// Phase 1 (0–0.33): Progressive noise addition
		// Noise amount increases from 0 to 0.3
		if (progress < 0.33) {
			var noiseAmt = progress.linlin(0, 0.33, 0, 0.3);
			shaped = ~tableAddNoise.(shaped, noiseAmt);
			phase = "noise (amt: " ++ noiseAmt.round(0.01) ++ ")";
		};

		// Phase 2 (0.33–0.66): Progressive quantization
		// Levels decrease from 64 to 3
		// Noise from end of Phase 1 is retained (0.3)
		if (progress >= 0.33 and: { progress < 0.66 }) {
			var levels = progress.linlin(0.33, 0.66, 64, 3).round.asInteger.max(2);
			shaped = ~tableAddNoise.(shaped, 0.3);
			shaped = ~tableQuantize.(shaped, levels);
			phase = "quantize (levels: " ++ levels ++ ")";
		};

		// Phase 3 (0.66–1.0): Progressive power curve
		// Exponent increases from 1 to 4
		// Noise and moderate quantization retained
		if (progress >= 0.66) {
			var power = progress.linlin(0.66, 1.0, 1, 4);
			shaped = ~tableAddNoise.(shaped, 0.3);
			shaped = ~tableQuantize.(shaped, 5);
			shaped = ~tablePower.(shaped, power);
			phase = "power (exp: " ++ power.round(0.01) ++ ")";
		};

		// Load transformed shape at both scales
		~loadShapeBothScales.(shaped);

		// Progress reporting
		if (step % (numSteps / 6).asInteger == 0) {
			("  " ++ (progress * 100).round(1) ++ "% | " ++ phase).postln;
		};

		(1 / updateRate).wait;
	};

	"--- Progressive transformation complete ---".postln;
	~app.loopTask.tasks[0].stop;
	~app.synthSwitcher.stop;
}).play(AppClock);
)

// --- Stop Part D ---
(
~progressRoutine.stop;
~app.loopTask.tasks[0].stop;
~app.synthSwitcher.stop;
)


// =====================================================================
// PART E: Variations — different base shapes
// =====================================================================
// The recursive architecture is not limited to sine shapes.
// Any 2048-point table operates at both scales simultaneously.
// These variations show how different starting shapes produce
// different cross-scale identities.

// --- Start playback for Part E ---
(
~app.synthSwitcher.play;
~app.loopTask.tasks[0].set(\playbackDirection, 0);
~app.loopTask.tasks[0].play;
)

// E1: Sawtooth
// Audio: bright, harmonically rich. Parametric: linear ramp.
(
var saw = Array.fill(2048, { |i| i.linlin(0, 2047, -1, 1) });
~loadShapeBothScales.(saw);
"E1: Sawtooth — bright waveform / linear ramp trajectory".postln;
)

// E2: Triangle
// Audio: mellow, odd harmonics only. Parametric: V-shaped sweep.
(
var tri = Array.fill(2048, { |i|
	var phase = i / 2048;
	if (phase < 0.5) { phase.linlin(0, 0.5, -1, 1) }
	{ phase.linlin(0.5, 1, 1, -1) };
});
~loadShapeBothScales.(tri);
"E2: Triangle — mellow waveform / V-shaped trajectory".postln;
)

// E3: Random (noise table)
// Audio: noise burst per pulsaret. Parametric: chaotic trajectory.
(
var noise = Array.fill(2048, { 1.0.rand2 });
~loadShapeBothScales.(noise);
"E3: Random noise — noise burst / chaotic trajectory".postln;
)

// E4: Quantized random — stochastic staircase
// Audio: quantized noise. Parametric: random step sequence.
(
var noise = Array.fill(2048, { 1.0.rand2 });
var quantNoise = ~tableQuantize.(noise, 8);
~loadShapeBothScales.(quantNoise);
"E4: Quantized random — quantized noise / random 8-step sequence".postln;
)

// E5: Cauchy distribution (sharp peak)
// Audio: impulse-like waveform with sharp transient.
// Parametric: trajectory hovers near minimum with sharp spikes.
(
var cauchy = Array.fill(2048, { |i|
	var x = i.linlin(0, 2047, -4, 4);
	(1 / (1 + (x * x))) * 2 - 1;
});
~loadShapeBothScales.(cauchy);
"E5: Cauchy peak — impulse-like waveform / spike trajectory".postln;
)

// E6: Compound sine (complex shape)
// Audio: rich, evolving harmonic content.
// Parametric: complex multi-peaked trajectory.
(
var complex = Signal.sineFill(2048, [1, 0, 0.5, 0, 0.3, 0, 0.2, 0, 0.1]).as(Array);
~loadShapeBothScales.(complex);
"E6: Compound sine — rich harmonics / multi-peaked trajectory".postln;
)

// --- Stop Part E ---
(
~app.loopTask.tasks[0].stop;
~app.synthSwitcher.stop;
)


// =====================================================================
// Listening guide:
//
// PART A (smooth sine):
//   Clean, harmonically simple tone with a gentle formant frequency
//   sweep between 200 and 2000 Hz over 8 seconds. Both dimensions
//   are smooth because the underlying data is smooth. This is the
//   baseline — the "well-behaved" condition before transformation.
//
// PART B (quantized to 8 levels):
//   The same fundamental, envelope, and emission rate. ONLY the
//   table shape has changed, and it has undergone a single operation.
//   Yet the result splits into two categorically different phenomena:
//
//   Audio rate: harsh, digitally reduced spectral character. The 8
//   discrete levels create a staircase waveform with strong harmonics
//   resembling bitcrushed or sample-reduced audio.
//
//   Parametric rate: the formant frequency snaps between 8 discrete
//   values. The sweep becomes a staircase — mechanical, sequencer-
//   like plateaus with abrupt transitions. The same mathematical
//   operation (round to nearest level) that produces harmonic
//   distortion at audio rate produces rhythmic stepping at
//   parametric rate.
//
//   The archaeological insight: these are structurally identical.
//   One operation, one data structure, two incommensurable sonic
//   manifestations. The recognition of this identity is an insight
//   about the system's recursive temporal ontology — digital
//   reduction and step-sequencing are the same thing at different
//   temporal scales.
//
// PART C (operation catalog):
//   Each operation shows a different cross-scale transformation:
//     Quantize: bitcrushing / step-sequencing
//     Reverse: phase shift / trajectory reversal
//     Invert: phase inversion / range inversion
//     Smooth: low-pass filtering / trajectory softening
//     Noise: spectral broadening / trajectory jitter
//     Power: harmonic redistribution / trajectory compression
//   Every operation is the SAME algorithm applied to the SAME data
//   structure — only the reading rate differs.
//
// PART D (progressive transformation):
//   A formal process that operates at all temporal scales
//   simultaneously. As noise roughens the waveform, it also
//   roughens the parametric trajectory. As quantization reduces
//   spectral complexity, it simultaneously creates rhythmic
//   stepping. As the power curve concentrates the waveform,
//   it also compresses the trajectory toward its extremes.
//   The coherence of the formal arc derives directly from the
//   system's recursive architecture — one process, all scales.
//
// PART E (alternative shapes):
//   Different base shapes produce different cross-scale
//   identities. A sawtooth is both a bright waveform and a
//   linear ramp. A noise table is both a noise burst and a
//   chaotic trajectory. The Cauchy peak is both an impulse-like
//   transient and a hovering-with-spikes contour. Each shape
//   proposes a different relationship between its micro-temporal
//   and macro-temporal manifestations.
//
// The 2048-point table is not merely a convenient data container
// but an epistemological framework that proposes musical time is
// self-similar across scales.
// =====================================================================
