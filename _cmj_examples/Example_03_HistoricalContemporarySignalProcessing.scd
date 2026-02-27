// =====================================================================
// Example 3: Historical and Contemporary Signal Processing
//
// Renders the same pulsar configuration through both synthesis
// engines — GrainBuf (Classic) and OscOS (Oversampling) — to make
// audible the distinction between:
//
//   (a) The temporal ontology: discrete emission-rate quantization,
//       burst masking, stepped parameter updates — shared by both
//       engines, derived from the original PG's architecture.
//
//   (b) The contingent signal-processing artifacts: aliasing,
//       spectral foldback, intermodulation products — present only
//       in the GrainBuf engine, derived from the computational
//       constraints of 2001.
//
// The configuration deliberately uses conditions where aliasing
// is most pronounced: a spectrally rich pulsaret (additive harmonics),
// a high formant frequency relative to emission rate, and emission
// rates that push the pulsaret's spectral content toward Nyquist.
//
// The archaeological finding: not everything in a historical
// system's sonic signature is epistemologically significant.
// The aliasing was a contingent artifact; the discrete temporal
// logic was a conceptual framework. Both shaped the sound of
// pulsar synthesis as historically practiced, but they have
// different statuses as archaeological findings.
//
// Prerequisites: nuPG booted via ~app = NuPG_Application.new.boot
//                OscOS plugin installed for oversampling engine
//                (github.com/spluta/OversamplingOscillators)
// =====================================================================

// =====================================================================
// Step 1: Configure the shared pulsar configuration
// =====================================================================
(
var d = ~app.data;

// --- Pulsaret: spectrally rich sawtooth-like waveform (32 harmonics) ---
// Sawtooth has equal-amplitude harmonics (1/n), maximizing aliasing potential.
// At high formant frequencies, upper harmonics fold back dramatically
// in the GrainBuf engine but are cleanly filtered in OscOS.
var numHarmonics = 32;
var pulsaretData = Signal.sineFill(2048, Array.fill(numHarmonics, { |i| 1.0 / (i + 1) })).as(Array);

// Hanning envelope
var envelopeData = Signal.hanningWindow(2048).as(Array);

// Flat frequency buffer — no per-pulsaret FM
var frequencyData = Array.fill(2048, { 0.0 });

// Update data layer (for GUI display)
d.data_pulsaret[0].value = pulsaretData;
d.data_envelope[0].value = envelopeData;

// Send to audio buffers
~app.pulsaretBuffers[0].sendCollection(pulsaretData);
~app.envelopeBuffers[0].sendCollection(envelopeData);
~app.frequencyBuffers[0].sendCollection(frequencyData);

("Step 1 complete: buffers loaded with " ++ numHarmonics ++ "-harmonic sawtooth pulsaret").postln;
)

// =====================================================================
// Step 2: Set identical parameters for both engines
// =====================================================================
(
// Both engines read from the same NuPG_Data object and the same
// buffers. We configure the data layer, then the switcher handles
// mapping to whichever engine is active.
var d = ~app.data;

// Fundamental (emission rate): 200 Hz
d.data_main[0][0].value_(200);

// Three formants spread across the spectrum for richer texture
// Group 1: 3000 Hz (mid)
// Group 2: 5000 Hz (upper-mid)
// Group 3: 7000 Hz (high - maximum aliasing)
d.data_main[0][1].value_(3000);   // formant 1
d.data_main[0][2].value_(5000);   // formant 2
d.data_main[0][3].value_(7000);   // formant 3

// Envelope dilation: 1 (natural grain duration)
d.data_main[0][4].value_(1);

// All three groups active
d.data_main[0][10].value_(0.5);  // group 1 amp
d.data_main[0][11].value_(0.5);  // group 2 amp
d.data_main[0][12].value_(0.5);  // group 3 amp
d.data_main[0][7].value_(0);     // pan centre

// Burst mask: 7:1 — a periodic accent structure
// At 200 Hz emission rate, the 8-step cycle takes 40 ms:
// fast enough that the masking appears as amplitude modulation
// but still clearly periodic
d.data_burstMask[0][0].value_(7);
d.data_burstMask[0][1].value_(1);

// Full probability
d.data_probabilityMaskSingular[0].value_(1.0);

// No flux, no FM
d.data_modulators[0][2].value_(0.0);
d.data_modulators[0][0].value_(0);
d.data_modulators[0][1].value_(0);

// Sieve mask off
~app.synthSwitcher.activeSynth.trainInstances[0].set(\sieveMaskOn, 0);

"Step 2 complete: shared configuration set".postln;
"  Fundamental: 200 Hz | Formants: 3000/5000/7000 Hz | Burst: 7:1".postln;
"  Three formant groups with 32 harmonics each".postln;
)

// =====================================================================
// Step 3: Automated A/B comparison with formant sweep
// =====================================================================
// Sweeps all three formants from low to high while the fundamental
// remains at 200 Hz. Aliasing increases dramatically as formants
// rise. Plays each engine for 15 seconds with the same sweep.

(
var dur = 15;
var updateRate = 20;
var steps = (dur * updateRate).asInteger;
// Three formants sweep in parallel, maintaining spread
var startFormants = [500, 800, 1200];
var endFormants = [4000, 6000, 8000];

~abRoutine = Routine({
	// --- Phase A: Classic engine ---
	"=== A/B COMPARISON ===".postln;
	"Phase A: CLASSIC (GrainBuf) - 3 formants sweeping up".postln;

	~app.synthSwitcher.useStandard;
	~app.synthSwitcher.activeSynth.trainInstances[0].set(
		\globalAmplitude, 1.0, \mute, 0,
		\group_1_onOff, 0, \group_2_onOff, 0, \group_3_onOff, 0
	);
	~app.synthSwitcher.activeSynth.trainInstances[0].play;

	steps.do { |step|
		var t = step / (steps - 1);
		~app.data.data_main[0][1].value_(t.linexp(0, 1, startFormants[0], endFormants[0]));
		~app.data.data_main[0][2].value_(t.linexp(0, 1, startFormants[1], endFormants[1]));
		~app.data.data_main[0][3].value_(t.linexp(0, 1, startFormants[2], endFormants[2]));
		(1 / updateRate).wait;
	};

	~app.synthSwitcher.activeSynth.trainInstances[0].stop;
	1.wait;

	// --- Phase B: OscOS engine ---
	"Phase B: OSCOS (Oversampling) - same 3-formant sweep".postln;

	~app.synthSwitcher.useOscOS;
	~app.synthSwitcher.activeSynth.trainInstances[0].set(
		\globalAmplitude, 1.0, \mute, 0,
		\group_1_onOff, 0, \group_2_onOff, 0, \group_3_onOff, 0
	);
	~app.synthSwitcher.activeSynth.trainInstances[0].play;

	steps.do { |step|
		var t = step / (steps - 1);
		~app.data.data_main[0][1].value_(t.linexp(0, 1, startFormants[0], endFormants[0]));
		~app.data.data_main[0][2].value_(t.linexp(0, 1, startFormants[1], endFormants[1]));
		~app.data.data_main[0][3].value_(t.linexp(0, 1, startFormants[2], endFormants[2]));
		(1 / updateRate).wait;
	};

	~app.synthSwitcher.activeSynth.trainInstances[0].stop;

	// Reset formants
	~app.data.data_main[0][1].value_(3000);
	~app.data.data_main[0][2].value_(5000);
	~app.data.data_main[0][3].value_(7000);

	"=== A/B comparison complete ===".postln;
	"The temporal structure (burst pattern, emission-rate".postln;
	"quantization, discrete parameter updates) is identical".postln;
	"in both renderings. The difference - aliased spectral".postln;
	"foldback vs. clean harmonics - is the contingent artifact".postln;
	"of 2001's computational constraints, separated from the".postln;
	"epistemologically significant temporal ontology.".postln;
}).play(AppClock);
)

// --- Emergency stop ---
(
~abRoutine.stop;
~app.synthSwitcher.stop;
)

// =====================================================================
// Step 4 (optional): A/B fundamental sweep comparison
// =====================================================================
// Keeps formants high, sweeps fundamental from 50 to 400 Hz.
// Higher fundamental = faster wavetable playback = more aliasing.
// Uses same A/B format as Step 3 for easy comparison.

(
var d = ~app.data;
var dur = 12;
var updateRate = 20;
var steps = (dur * updateRate).asInteger;
var startFund = 50;
var endFund = 400;

// Set high formants on all three groups
d.data_main[0][1].value_(5000);
d.data_main[0][2].value_(6500);
d.data_main[0][3].value_(8000);

~fundSweepRoutine = Routine({
	"=== STEP 4: A/B Fundamental Sweep (3 formants at 5k/6.5k/8k Hz) ===".postln;

	// --- Phase A: Classic engine ---
	"--- A: Classic engine (fundamental 50->400 Hz) ---".postln;
	~app.synthSwitcher.useStandard;
	~app.synthSwitcher.activeSynth.trainInstances[0].set(
		\globalAmplitude, 1.0, \mute, 0,
		\group_1_onOff, 0, \group_2_onOff, 0, \group_3_onOff, 0
	);
	~app.synthSwitcher.activeSynth.trainInstances[0].play;

	steps.do { |step|
		var fund = step.linexp(0, steps - 1, startFund, endFund);
		d.data_main[0][0].value_(fund);
		(1 / updateRate).wait;
	};

	~app.synthSwitcher.activeSynth.trainInstances[0].stop;
	1.wait;

	// --- Phase B: OscOS engine ---
	"--- B: OscOS engine (fundamental 50->400 Hz) ---".postln;
	~app.synthSwitcher.useOscOS;
	~app.synthSwitcher.activeSynth.trainInstances[0].set(
		\globalAmplitude, 1.0, \mute, 0,
		\group_1_onOff, 0, \group_2_onOff, 0, \group_3_onOff, 0
	);
	~app.synthSwitcher.activeSynth.trainInstances[0].play;

	steps.do { |step|
		var fund = step.linexp(0, steps - 1, startFund, endFund);
		d.data_main[0][0].value_(fund);
		(1 / updateRate).wait;
	};

	~app.synthSwitcher.activeSynth.trainInstances[0].stop;

	// Reset
	d.data_main[0][0].value_(200);
	d.data_main[0][1].value_(3000);
	d.data_main[0][2].value_(5000);
	d.data_main[0][3].value_(7000);

	"=== Fundamental sweep complete ===".postln;
}).play(AppClock);
)

// --- Stop Step 4 ---
(
~fundSweepRoutine.stop;
~app.synthSwitcher.stop;
)

// =====================================================================
// Listening guide:
//
// Step 3 - A/B formant sweep (3 formants sweeping in parallel):
//
//   Classic (GrainBuf): Aliasing intensifies as formants rise.
//   With three formant groups (32 harmonics each), spectral
//   foldback creates dense inharmonic content - the "digital
//   dirt" characteristic of historical pulsar implementations.
//
//   OscOS (Oversampling): Clean sweep throughout. Same temporal
//   structure (burst pattern, emission quantization) but natural
//   timbral brightening without the metallic artifacts.
//
// Step 4 (optional) - A/B fundamental sweep (3 formants fixed high):
//
//   Higher fundamental = faster wavetable playback = more aliasing.
//   With three high formants, Classic becomes increasingly harsh.
//   OscOS maintains consistent clean timbre throughout.
//
// The archaeological distinction:
//
//   SHARED (temporal ontology, epistemologically significant):
//   - Discrete emission clock at 200 Hz
//   - Burst/rest masking (7:1 pattern)
//   - Stepped parameter updates
//   - Pulsaret-as-discrete-event architecture
//
//   DIVERGENT (contingent artifact, historically characteristic):
//   - Aliased spectral foldback (Classic only)
//   - Inharmonic upper-frequency content (Classic only)
//   - Metallic brightness at high formant rates (Classic only)
//
//   The dual-engine design makes this distinction audible,
//   transforming an analytical claim into a perceptual experience.
// =====================================================================
