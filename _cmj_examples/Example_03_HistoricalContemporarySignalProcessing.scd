// =====================================================================
// Example 3: The Three-Set Parallel Architecture
//
// Demonstrates the PG's conception of pulsar synthesis as a
// spatial-spectral instrument rather than a monophonic oscillator:
// one emission clock generates three simultaneous pulsaret streams,
// each with independent formant frequency, panning, and amplitude.
//
// The architectural commitment is specific: the three sets share
// a SINGLE fundamental frequency (emission clock), a single burst/
// rest mask, a single probability gate, and a single sieve. Every
// temporal structure is common to all three; every spectral and
// spatial parameter is independent. This produces a distinctive
// kind of complexity — multiple timbral and spatial trajectories
// whose internal coordination derives from the emission-rate
// quantization rather than from explicit synchronization.
//
// The example moves through four stages:
//
//   Part A — Spatial-spectral spread:
//     Three groups with widely divergent formants and panning,
//     sharing one emission clock. Demonstrates the basic
//     architecture: spectral diversity within temporal unity.
//
//   Part B — Temporal substrate transforms all:
//     Changes to the shared temporal parameters (fundamental,
//     masking, probability) simultaneously transform all three
//     streams. The archaeological point: temporal structures
//     don't merely "trigger" the three groups — they shape the
//     sonic result of all three simultaneously, producing
//     coordinated transformations that would require explicit
//     programming under independent voice allocation.
//
//   Part C — Divergent trajectories, shared clock:
//     Uses the loop task to give each group a different formant
//     trajectory (ascending, descending, oscillating) while the
//     shared clock provides temporal coherence. The trajectories
//     diverge maximally in spectral space while remaining locked
//     to the same temporal grid — a spatial-spectral counterpoint
//     that emerges from the architecture itself.
//
//   Part D — Architecture as compositional resource:
//     A formal process that exploits the coupling/independence
//     structure: temporal parameters evolve slowly (shared clock),
//     spectral parameters evolve independently (three formant
//     trajectories), and masking patterns create coordinated
//     rhythmic structures across the three divergent timbres.
//
// Prerequisites:
//   ~app = NuPG_Application(1, 1).boot;
// =====================================================================

// =====================================================================
// PLAYBACK HELPERS
// =====================================================================
(
~playSynth = { |instance=0|
	~app.trainControl.trainPlayStop[instance].valueAction_(1);
};

~stopSynth = { |instance=0|
	~app.trainControl.trainPlayStop[instance].valueAction_(0);
};

~playLoop = { |instance=0|
	~app.trainControl.trainLoopPlayStop[instance].valueAction_(1);
};

~stopLoop = { |instance=0|
	~app.trainControl.trainLoopPlayStop[instance].valueAction_(0);
};

~playAll = { |instance=0|
	~playSynth.(instance);
	~playLoop.(instance);
};

~stopAll = { |instance=0|
	~stopLoop.(instance);
	~stopSynth.(instance);
};

"Playback helpers loaded.".postln;
)

// =====================================================================
// SHARED SETUP
// =====================================================================
(
var d = ~app.data;

// Pulsaret: harmonically rich waveform (8 harmonics)
// Rich enough to make formant frequency differences audible
// as distinct timbral characters
var pulsaretData = Signal.sineFill(2048,
	[1, 0.7, 0.5, 0.35, 0.25, 0.18, 0.12, 0.08]
).as(Array);

// Hanning envelope
var envelopeData = Signal.hanningWindow(2048).as(Array);

d.data_pulsaret[0].value = pulsaretData;
~app.pulsaretBuffers[0].sendCollection(pulsaretData);

d.data_envelope[0].value = envelopeData;
~app.envelopeBuffers[0].sendCollection(envelopeData);

// No modulation
d.data_modulators[0][0].value_(0);
d.data_modulators[0][1].value_(0);
d.data_modulators[0][2].value_(0.0);

d.data_probabilityMaskSingular[0].value_(1.0);

// Continuous emission (no masking yet)
d.data_burstMask[0][0].value_(1);
d.data_burstMask[0][1].value_(0);

// Envelope dilation for all three groups
d.data_main[0][4].value_(1);
d.data_main[0][5].value_(1);
d.data_main[0][6].value_(1);

"Shared setup complete.".postln;
)

// =====================================================================
// PART A: Spatial-Spectral Spread
// =====================================================================
// Three groups with widely divergent formants, panned across
// the stereo field, sharing one emission clock. The fundamental
// frequency is the ONLY temporal parameter — it determines when
// pulsarets are emitted. What each pulsaret sounds like and where
// it appears in space is governed by the three independent sets.
//
// The result is a single temporal stream that contains three
// distinct timbral-spatial identities. Not three oscillators
// playing together — one clock, three spectral-spatial outcomes
// per emission event.

// --- A1: Static spread — three timbres, one clock ---
// Three formant regions: low/warm, mid/bright, high/thin
// Panned left, centre, right
// Listen for the unified temporal grain beneath the spectral diversity.
(
var d = ~app.data;

d.data_main[0][0].value_(120);    // fundamental: 120 Hz

// Group 1: low formant, left
d.data_main[0][1].value_(400);    // formant 1
d.data_main[0][10].value_(0.5);   // amp 1
d.data_main[0][7].value_(-0.8);   // pan 1

// Group 2: mid formant, centre
d.data_main[0][2].value_(1800);   // formant 2
d.data_main[0][11].value_(0.5);   // amp 2
d.data_main[0][8].value_(0);      // pan 2

// Group 3: high formant, right
d.data_main[0][3].value_(5000);   // formant 3
d.data_main[0][12].value_(0.5);   // amp 3
d.data_main[0][9].value_(0.8);    // pan 3

"A1: Three timbres (400/1800/5000 Hz), panned L/C/R, fund 120 Hz".postln;
"--- Evaluate, then play ---".postln;
)

// Play A1
( ~playSynth.(0); )

// Listen, then try different fundamentals to hear how ONE parameter
// transforms ALL THREE timbral streams simultaneously:
( ~app.data.data_main[0][0].value_(40); "fund: 40 Hz".postln; )
( ~app.data.data_main[0][0].value_(80); "fund: 80 Hz".postln; )
( ~app.data.data_main[0][0].value_(200); "fund: 200 Hz".postln; )
( ~app.data.data_main[0][0].value_(400); "fund: 400 Hz".postln; )
( ~app.data.data_main[0][0].value_(120); "fund: 120 Hz (reset)".postln; )

// Stop A1
( ~stopSynth.(0); )

// --- A2: Fundamental sweep reveals the shared clock ---
// As fundamental rises, the emission period compresses. All three
// groups respond identically in time — the same acceleration, the
// same temporal compression — while maintaining their independent
// spectral characters. The low-formant group (left) darkens;
// the high-formant group (right) brightens. The convergence and
// divergence happen simultaneously: temporal unity, spectral independence.
(
var d = ~app.data;

// Wide formant spread
d.data_main[0][1].value_(300);
d.data_main[0][2].value_(2000);
d.data_main[0][3].value_(6000);

~sweepA2 = Routine({
	var steps = 500;
	"--- A2: Fundamental sweep 30→600 Hz (25s) ---".postln;
	~playSynth.(0);

	steps.do { |step|
		var fund = step.linexp(0, steps - 1, 30, 600);
		d.data_main[0][0].value_(fund);
		if (step % 100 == 0) {
			("  fund: " ++ fund.round(1) ++ " Hz").postln;
		};
		(25 / steps).wait;
	};

	~stopSynth.(0);
	"--- A2 complete ---".postln;
}).play(AppClock);
)

// Stop A2
( ~sweepA2.stop; ~stopSynth.(0); )

// --- A3: Isolating groups — hearing the architecture ---
// Toggle individual groups on and off while the fundamental
// runs at a steady rate. Each group in isolation sounds like a
// monophonic pulsaret stream. The combination reveals the
// architecture: not three streams summed but three spectral-
// spatial interpretations of the SAME temporal sequence.
(
var d = ~app.data;
d.data_main[0][0].value_(150);
d.data_main[0][1].value_(500);
d.data_main[0][2].value_(2200);
d.data_main[0][3].value_(5500);
~playSynth.(0);
"--- A3: Toggle groups while listening ---".postln;
)

// All three
( var d = ~app.data; d.data_main[0][10].value_(0.5); d.data_main[0][11].value_(0.5); d.data_main[0][12].value_(0.5); "All three groups".postln; )

// Group 1 only (low, left)
( var d = ~app.data; d.data_main[0][10].value_(0.5); d.data_main[0][11].value_(0); d.data_main[0][12].value_(0); "Group 1 only (low, left)".postln; )

// Group 2 only (mid, centre)
( var d = ~app.data; d.data_main[0][10].value_(0); d.data_main[0][11].value_(0.5); d.data_main[0][12].value_(0); "Group 2 only (mid, centre)".postln; )

// Group 3 only (high, right)
( var d = ~app.data; d.data_main[0][10].value_(0); d.data_main[0][11].value_(0); d.data_main[0][12].value_(0.5); "Group 3 only (high, right)".postln; )

// Groups 1+3 only (low+high, wide stereo)
( var d = ~app.data; d.data_main[0][10].value_(0.5); d.data_main[0][11].value_(0); d.data_main[0][12].value_(0.5); "Groups 1+3 (low left + high right)".postln; )

// Restore all
( var d = ~app.data; d.data_main[0][10].value_(0.5); d.data_main[0][11].value_(0.5); d.data_main[0][12].value_(0.5); "All three restored".postln; )

// Stop A3
( ~stopSynth.(0); )

// =====================================================================
// PART B: Temporal Substrate Transforms All
// =====================================================================
// The shared temporal parameters — fundamental, burst/rest mask,
// probability — affect all three groups simultaneously. This is
// not merely "the same trigger" sent to three independent voices.
// The masking pattern is quantized to the emission clock, so its
// spectral sidebands are identical across groups — but the
// sidebands modulate DIFFERENT formant frequencies, producing
// correlated but spectrally distinct transformations.

// --- B1: Masking transforms three timbres simultaneously ---
// Same formant spread as Part A. Burst/rest patterns applied
// to the shared clock. Each pattern transforms all three groups'
// spectral character at once — but each group responds differently
// because the sidebands interact differently with each formant.
(
var d = ~app.data;
d.data_main[0][0].value_(200);
d.data_main[0][1].value_(500);
d.data_main[0][2].value_(2500);
d.data_main[0][3].value_(6000);
d.data_main[0][10].value_(0.5);
d.data_main[0][11].value_(0.5);
d.data_main[0][12].value_(0.5);
~playSynth.(0);
"--- B1: Try different masks while three groups play ---".postln;
)

// No masking — continuous, three clean timbres
( ~app.data.data_burstMask[0][0].value_(1); ~app.data.data_burstMask[0][1].value_(0); "Mask: 1:0 (continuous)".postln; )

// Gentle masking — slight tremolo across all three
( ~app.data.data_burstMask[0][0].value_(7); ~app.data.data_burstMask[0][1].value_(1); "Mask: 7:1 (gentle)".postln; )

// Equal on/off — strong AM on all three, different sideband interaction per group
( ~app.data.data_burstMask[0][0].value_(4); ~app.data.data_burstMask[0][1].value_(4); "Mask: 4:4 (square wave AM)".postln; )

// Sparse — staccato bursts, three timbres flash simultaneously
( ~app.data.data_burstMask[0][0].value_(1); ~app.data.data_burstMask[0][1].value_(7); "Mask: 1:7 (sparse)".postln; )

// Asymmetric — complex rhythmic pattern shared across three timbres
( ~app.data.data_burstMask[0][0].value_(3); ~app.data.data_burstMask[0][1].value_(5); "Mask: 3:5 (asymmetric)".postln; )

// Very sparse with high rate — masking becomes spectral
( ~app.data.data_main[0][0].value_(500); ~app.data.data_burstMask[0][0].value_(2); ~app.data.data_burstMask[0][1].value_(6); "Mask: 2:6 at 500 Hz (spectral sidebands)".postln; )

// Reset
( ~app.data.data_main[0][0].value_(200); ~app.data.data_burstMask[0][0].value_(1); ~app.data.data_burstMask[0][1].value_(0); "Reset".postln; )

// Stop B1
( ~stopSynth.(0); )

// --- B2: Probability as shared thinning ---
// Probability masking applies to the emission clock, so it
// thins all three groups identically — the same pulsarets are
// omitted from all three streams. This produces a coordinated
// sparseness: the three timbral-spatial identities thin together,
// maintaining their relative balance. Under independent voice
// allocation, each voice would thin independently, destroying
// the internal coordination.
(
var d = ~app.data;
d.data_main[0][0].value_(200);
d.data_main[0][1].value_(600);
d.data_main[0][2].value_(2000);
d.data_main[0][3].value_(5000);
d.data_burstMask[0][0].value_(1);
d.data_burstMask[0][1].value_(0);
~playSynth.(0);
"--- B2: Probability thinning (shared across all groups) ---".postln;
)

// Full density
( ~app.data.data_probabilityMaskSingular[0].value_(1.0); "Probability: 1.0 (full)".postln; )

// Slight thinning
( ~app.data.data_probabilityMaskSingular[0].value_(0.8); "Probability: 0.8".postln; )

// Moderate thinning
( ~app.data.data_probabilityMaskSingular[0].value_(0.5); "Probability: 0.5 (half)".postln; )

// Heavy thinning
( ~app.data.data_probabilityMaskSingular[0].value_(0.25); "Probability: 0.25 (sparse)".postln; )

// Near-silent
( ~app.data.data_probabilityMaskSingular[0].value_(0.05); "Probability: 0.05 (very sparse)".postln; )

// Restore
( ~app.data.data_probabilityMaskSingular[0].value_(1.0); "Probability: 1.0 (restored)".postln; )

// Stop B2
( ~stopSynth.(0); )

// --- B3: Fundamental sweep with masking ---
// Combines B1 and A2: three divergent formants, shared masking
// pattern, swept fundamental. As fundamental rises, the masking
// transitions from rhythmic to spectral — and this transition
// happens identically in time across all three groups while
// producing three different spectral results. The perceptual
// domain crossing (rhythm → AM → spectrum) is a shared temporal
// event with three parallel spectral manifestations.
(
var d = ~app.data;
d.data_main[0][1].value_(400);
d.data_main[0][2].value_(2500);
d.data_main[0][3].value_(7000);
d.data_burstMask[0][0].value_(5);
d.data_burstMask[0][1].value_(3);
d.data_probabilityMaskSingular[0].value_(1.0);

~sweepB3 = Routine({
	var steps = 600;
	"--- B3: Fundamental sweep 20→600 Hz with 5:3 mask (30s) ---".postln;
	"  Three formants: 400 / 2500 / 7000 Hz".postln;
	~playSynth.(0);

	steps.do { |step|
		var fund = step.linexp(0, steps - 1, 20, 600);
		d.data_main[0][0].value_(fund);
		if (step % 120 == 0) {
			var region = case
				{ fund < 30 } { "discrete clicks" }
				{ fund < 80 } { "rhythm" }
				{ fund < 200 } { "tremolo/AM" }
				{ "spectral" };
			("  fund: " ++ fund.round(1) ++ " Hz (" ++ region ++ ")").postln;
		};
		(30 / steps).wait;
	};

	~stopSynth.(0);
	"--- B3 complete ---".postln;
}).play(AppClock);
)

// Stop B3
( ~sweepB3.stop; ~stopSynth.(0); )

// =====================================================================
// PART C: Divergent Trajectories, Shared Clock
// =====================================================================
// Uses the loop task to give each group a different formant
// trajectory while the shared clock provides temporal coherence.
// The three tables are loaded with different shapes — ascending
// ramp, descending ramp, and triangle — so each group traces
// a different spectral path through the same time span.
//
// This produces a spatial-spectral counterpoint that emerges
// from the architecture: the three voices cross, diverge, and
// converge in spectral space while remaining temporally fused.
// The counterpoint is not composed note by note; it is generated
// by the interaction of three independent table shapes with a
// shared temporal substrate.

// --- C1: Setup divergent formant trajectories ---
(
var d = ~app.data;

d.data_main[0][0].value_(150);    // fundamental

// Base formant values (loop table multiplies these)
d.data_main[0][1].value_(200);    // formant 1 base
d.data_main[0][2].value_(200);    // formant 2 base
d.data_main[0][3].value_(200);    // formant 3 base

// All three groups active, spread across stereo field
d.data_main[0][10].value_(0.5);
d.data_main[0][11].value_(0.5);
d.data_main[0][12].value_(0.5);
d.data_main[0][7].value_(-0.7);
d.data_main[0][8].value_(0);
d.data_main[0][9].value_(0.7);

// Loop table ranges: -1..1 maps to multiplier 1..15
// So formants sweep 200 Hz to 3000 Hz
d.data_formantFrequencyOne_maxMin[0][0].value_(15);
d.data_formantFrequencyOne_maxMin[0][1].value_(1);
d.data_formantFrequencyTwo_maxMin[0][0].value_(15);
d.data_formantFrequencyTwo_maxMin[0][1].value_(1);
d.data_formantFrequencyThree_maxMin[0][0].value_(15);
d.data_formantFrequencyThree_maxMin[0][1].value_(1);

// Neutral amplitude/pan/envelope tables
d.data_ampOne_maxMin[0][0].value_(1); d.data_ampOne_maxMin[0][1].value_(1);
d.data_ampTwo_maxMin[0][0].value_(1); d.data_ampTwo_maxMin[0][1].value_(1);
d.data_ampThree_maxMin[0][0].value_(1); d.data_ampThree_maxMin[0][1].value_(1);
d.data_panOne_maxMin[0][0].value_(0); d.data_panOne_maxMin[0][1].value_(0);
d.data_panTwo_maxMin[0][0].value_(0); d.data_panTwo_maxMin[0][1].value_(0);
d.data_panThree_maxMin[0][0].value_(0); d.data_panThree_maxMin[0][1].value_(0);
d.data_envelopeMulOne_maxMin[0][0].value_(1); d.data_envelopeMulOne_maxMin[0][1].value_(1);
d.data_envelopeMulTwo_maxMin[0][0].value_(1); d.data_envelopeMulTwo_maxMin[0][1].value_(1);
d.data_envelopeMulThree_maxMin[0][0].value_(1); d.data_envelopeMulThree_maxMin[0][1].value_(1);

// --- Three different table shapes ---
// Group 1 (left): ascending ramp
d.data_formantFrequencyOne[0].value =
	Array.fill(2048, { |i| i.linlin(0, 2047, -1, 1) });

// Group 2 (centre): descending ramp (contrary motion to Group 1)
d.data_formantFrequencyTwo[0].value =
	Array.fill(2048, { |i| i.linlin(0, 2047, 1, -1) });

// Group 3 (right): triangle (rises then falls)
d.data_formantFrequencyThree[0].value =
	Array.fill(2048, { |i|
		var phase = i / 2048;
		if (phase < 0.5)
			{ phase.linlin(0, 0.5, -1, 1) }
			{ phase.linlin(0.5, 1, 1, -1) };
	});

// Neutral fundamental and other tables
d.data_fundamentalFrequency_maxMin[0][0].value_(1);
d.data_fundamentalFrequency_maxMin[0][1].value_(1);
d.data_fundamentalFrequency[0].value = Array.fill(2048, { 0 });
d.data_ampOne[0].value = Array.fill(2048, { 0 });
d.data_ampTwo[0].value = Array.fill(2048, { 0 });
d.data_ampThree[0].value = Array.fill(2048, { 0 });
d.data_panOne[0].value = Array.fill(2048, { 0 });
d.data_panTwo[0].value = Array.fill(2048, { 0 });
d.data_panThree[0].value = Array.fill(2048, { 0 });
d.data_envelopeMulOne[0].value = Array.fill(2048, { 0 });
d.data_envelopeMulTwo[0].value = Array.fill(2048, { 0 });
d.data_envelopeMulThree[0].value = Array.fill(2048, { 0 });

// Train duration: 10 seconds per traversal
d.data_trainDuration[0].value_(10);

// No masking initially
d.data_burstMask[0][0].value_(1);
d.data_burstMask[0][1].value_(0);

"C1 setup: three divergent formant trajectories loaded".postln;
"  Group 1 (left): ascending ramp (200→3000 Hz)".postln;
"  Group 2 (centre): descending ramp (3000→200 Hz)".postln;
"  Group 3 (right): triangle (200→3000→200 Hz)".postln;
"  Shared clock: 150 Hz, 10s per traversal".postln;
)

// --- Play C1: no masking ---
// Listen for the spectral counterpoint: the three voices cross
// at different points in the cycle, producing moments of
// convergence and divergence.
(
~playAll.(0);
"--- C1 playing: divergent trajectories, no masking ---".postln;
)

// Stop C1
( ~stopAll.(0); )

// --- C2: Same trajectories with masking ---
// Add a burst/rest mask. The mask applies to the shared clock,
// so all three divergent trajectories are rhythmically structured
// by the same pattern. The spectral counterpoint is now
// punctuated by coordinated silence — all three voices are
// present or absent together.
(
~app.data.data_burstMask[0][0].value_(5);
~app.data.data_burstMask[0][1].value_(3);
~playAll.(0);
"--- C2 playing: divergent trajectories, 5:3 mask ---".postln;
)

// Stop C2
( ~stopAll.(0); )

// --- C3: Same trajectories with probability thinning ---
// Instead of deterministic masking, stochastic thinning.
// All three groups share the SAME probability gate — the same
// pulsarets are omitted from all three streams. The spectral
// counterpoint acquires a shared stochastic texture.
(
~app.data.data_burstMask[0][0].value_(1);
~app.data.data_burstMask[0][1].value_(0);
~app.data.data_probabilityMaskSingular[0].value_(0.6);
~playAll.(0);
"--- C3 playing: divergent trajectories, probability 0.6 ---".postln;
)

// Stop C3
( ~app.data.data_probabilityMaskSingular[0].value_(1.0); ~stopAll.(0); )

// =====================================================================
// PART D: Architecture as Compositional Resource
// =====================================================================
// A formal process that exploits the coupling/independence
// structure over 60 seconds:
//
//   Phase 1 (0–20s): Three formant trajectories diverge gradually
//     from unison. Starts with all three groups at similar formant
//     frequencies, then slowly increases the divergence. Masking
//     is minimal — the shared temporal substrate is audible as a
//     unified grain. Fundamental slowly descends.
//
//   Phase 2 (20–40s): Maximum spectral divergence, increasingly
//     active masking. The three groups are now spectrally separate;
//     the masking punctuates all three simultaneously, creating
//     coordinated rhythmic structures across divergent timbres.
//     Fundamental rises into the AM range.
//
//   Phase 3 (40–60s): Spectral reconvergence with stochastic
//     thinning. The formant trajectories begin to converge back
//     toward a shared frequency while probability thinning
//     increases. The texture dissolves from three distinct voices
//     into a sparse, unified stream — the architecture revealing
//     its temporal substrate as the spectral diversity drops away.

(
var d = ~app.data;
var dur = 60;
var updateRate = 20;
var steps = (dur * updateRate).asInteger;

// Base formants: all start at 1200 Hz
d.data_main[0][1].value_(1200);
d.data_main[0][2].value_(1200);
d.data_main[0][3].value_(1200);

// Starting fundamental
d.data_main[0][0].value_(100);

// All groups active
d.data_main[0][10].value_(0.5);
d.data_main[0][11].value_(0.5);
d.data_main[0][12].value_(0.5);
d.data_main[0][7].value_(-0.7);
d.data_main[0][8].value_(0);
d.data_main[0][9].value_(0.7);

// No masking to start
d.data_burstMask[0][0].value_(1);
d.data_burstMask[0][1].value_(0);
d.data_probabilityMaskSingular[0].value_(1.0);

~playSynth.(0);

"--- Part D: Formal process (60 seconds) ---".postln;

~partDRoutine = Routine({
	steps.do { |step|
		var t = step / steps;  // 0.0 → 1.0
		var phase;

		// --- Phase 1 (0–0.33): Divergence from unison ---
		if (t < 0.33) {
			var pt = t / 0.33;  // 0→1 within phase
			var spread = pt.linexp(0, 1, 1, 15);  // formant spread grows

			// Three formants diverge from 1200 Hz
			d.data_main[0][1].value_(1200 / spread);            // descends
			d.data_main[0][2].value_(1200);                     // holds
			d.data_main[0][3].value_(1200 * spread.sqrt);       // ascends (slower)

			// Fundamental slowly descends
			d.data_main[0][0].value_(pt.linexp(0, 1, 120, 60));

			// No masking
			d.data_burstMask[0][0].value_(1);
			d.data_burstMask[0][1].value_(0);
			d.data_probabilityMaskSingular[0].value_(1.0);

			phase = "Phase 1: divergence";
		};

		// --- Phase 2 (0.33–0.66): Maximum divergence + masking ---
		if (t >= 0.33 and: { t < 0.66 }) {
			var pt = (t - 0.33) / 0.33;

			// Formants at maximum spread, slowly shifting
			d.data_main[0][1].value_(
				(200 + (sin(pt * 2pi) * 150)).clip(80, 20000)
			);
			d.data_main[0][2].value_(1200 + (sin(pt * 2pi * 1.5) * 400));
			d.data_main[0][3].value_(
				(4000 + (sin(pt * 2pi * 0.7) * 1500)).clip(80, 20000)
			);

			// Fundamental rises into AM territory
			d.data_main[0][0].value_(pt.linexp(0, 1, 60, 300));

			// Masking becomes active: burst shrinks, rest grows
			d.data_burstMask[0][0].value_(
				pt.linlin(0, 1, 7, 3).round.asInteger.max(1)
			);
			d.data_burstMask[0][1].value_(
				pt.linlin(0, 1, 1, 5).round.asInteger.max(0)
			);

			phase = "Phase 2: divergence + masking";
		};

		// --- Phase 3 (0.66–1.0): Reconvergence + thinning ---
		if (t >= 0.66) {
			var pt = (t - 0.66) / 0.34;
			var target = 800;  // convergence target

			// Formants converge toward 800 Hz
			d.data_main[0][1].value_(
				pt.linexp(0, 1, 200, target)
			);
			d.data_main[0][2].value_(
				pt.linexp(0, 1, 1200, target)
			);
			d.data_main[0][3].value_(
				pt.linexp(0, 1, 4000, target)
			);

			// Fundamental settles
			d.data_main[0][0].value_(pt.linexp(0, 1, 300, 150));

			// Masking relaxes
			d.data_burstMask[0][0].value_(
				pt.linlin(0, 1, 3, 1).round.asInteger.max(1)
			);
			d.data_burstMask[0][1].value_(
				pt.linlin(0, 1, 5, 0).round.asInteger.max(0)
			);

			// Probability thinning increases
			d.data_probabilityMaskSingular[0].value_(
				pt.linlin(0, 1, 1.0, 0.15)
			);

			phase = "Phase 3: convergence + thinning";
		};

		// Progress reporting
		if (step % (steps / 6).asInteger == 0) {
			("  " ++ (t * 100).round(1) ++ "% | " ++ phase
				++ " | fund: " ++ d.data_main[0][0].value.round(1) ++ " Hz"
				++ " | formants: " ++ d.data_main[0][1].value.round(1)
				++ " / " ++ d.data_main[0][2].value.round(1)
				++ " / " ++ d.data_main[0][3].value.round(1)
			).postln;
		};

		(1 / updateRate).wait;
	};

	"--- Part D complete ---".postln;
	~stopSynth.(0);
}).play(AppClock);
)

// --- Stop Part D ---
(
~partDRoutine.stop;
~app.data.data_probabilityMaskSingular[0].value_(1.0);
~app.data.data_burstMask[0][0].value_(1);
~app.data.data_burstMask[0][1].value_(0);
~stopAll.(0);
)

// =====================================================================
// Listening guide:
//
// PART A — Spatial-Spectral Spread:
//
//   A1 (static spread): Three timbral characters — warm (left),
//   bright (centre), thin (right) — sharing a single temporal
//   stream. Changing the fundamental transforms ALL THREE
//   simultaneously. This is the core architecture: one clock,
//   three spectral-spatial outcomes per emission event.
//
//   A2 (fundamental sweep): As the emission rate rises, all three
//   groups accelerate identically in time while maintaining their
//   independent spectral characters. The perceptual experience is
//   of a unified temporal process with three parallel timbral
//   dimensions — not three oscillators playing together.
//
//   A3 (isolation): Toggling groups on/off reveals that each
//   group in isolation is a monophonic pulsaret stream. Their
//   combination is richer than any individual group, and the
//   richness derives entirely from the architectural decision
//   to bind three spectral-spatial sets to one clock.
//
// PART B — Temporal Substrate Transforms All:
//
//   B1 (masking): The burst/rest pattern applies to the shared
//   emission clock, so ALL THREE groups are masked identically
//   in time. But each group's spectral response to the masking
//   is different because the sidebands interact differently with
//   each formant. The temporal structure is shared; its spectral
//   manifestation is threefold.
//
//   B2 (probability): Stochastic thinning via the shared
//   probability gate removes the SAME pulsarets from all three
//   streams. The three timbral identities thin together,
//   maintaining their relative balance. This coordinated
//   sparseness is a direct consequence of the shared clock —
//   under independent voice allocation, each voice would thin
//   independently, destroying the coordination.
//
//   B3 (sweep + masking): The fundamental sweep carries all
//   three groups through the domain crossing (rhythm → AM →
//   spectrum) simultaneously. The transition is a shared temporal
//   event experienced as three parallel spectral transformations.
//
// PART C — Divergent Trajectories, Shared Clock:
//
//   Three formant groups trace different spectral paths
//   (ascending, descending, triangular) over the same time span,
//   locked to the same emission clock. The spectral counterpoint
//   — voices crossing, converging, diverging — emerges from the
//   interaction of three independent table shapes with a shared
//   temporal substrate. Adding masking (C2) punctuates all three
//   trajectories simultaneously; probability thinning (C3) creates
//   shared stochastic texture. The counterpoint is architectural,
//   not composed note by note.
//
// PART D — Architecture as Compositional Resource:
//
//   A sixty-second formal process that exploits the coupling/
//   independence structure. Phase 1: three formants diverge
//   gradually from unison while the fundamental descends,
//   revealing the architecture as spectral diversity increases.
//   Phase 2: maximum spectral divergence with active masking —
//   three radically different timbres punctuated by the same
//   rhythmic pattern. Phase 3: spectral reconvergence with
//   stochastic thinning — the three voices dissolve into a
//   sparse unified stream, revealing the temporal substrate as
//   the spectral diversity drops away.
//
//   The formal arc — unity → divergence → punctuated divergence
//   → dissolving convergence — is generated entirely by the
//   interaction between shared temporal parameters and independent
//   spectral parameters. The architecture IS the composition.
//
// The archaeological finding: the PG's three-set architecture
// encodes a specific conception of complexity — not polyphony
// (independent voices) but parallel spectral interpretation of
// a single temporal stream. This conception is preserved in
// [title removed for anonymity] because it generates a kind of
// internal coordination that independent voice allocation cannot
// replicate: the texture's coherence derives from the emission
// clock, not from explicit synchronization between parts.
// =====================================================================
