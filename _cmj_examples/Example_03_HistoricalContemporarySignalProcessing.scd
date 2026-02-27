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

// Formant: 6000 Hz — HIGH formant to maximize aliasing difference
// At 6000 Hz with 32 harmonics, partials extend far beyond Nyquist.
// GrainBuf will fold these back as inharmonic content (metallic).
// OscOS will cleanly attenuate them (smooth, natural rolloff).
d.data_main[0][1].value_(6000);

// Envelope dilation: 1 (natural grain duration)
d.data_main[0][4].value_(1);

// Group 1 only, moderate amplitude
d.data_main[0][10].value_(0.6);
d.data_main[0][11].value_(0);
d.data_main[0][12].value_(0);
d.data_main[0][7].value_(0);   // pan centre

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
"  Fundamental: 200 Hz | Formant: 6000 Hz | Burst: 7:1".postln;
"  32 harmonics -> extreme aliasing in Classic engine".postln;
)

// =====================================================================
// Step 3: Automated A/B comparison with formant sweep
// =====================================================================
// Sweeps the formant from 500 Hz to 8000 Hz while the fundamental
// remains at 200 Hz. Aliasing increases dramatically as the formant
// rises. Plays each engine for 15 seconds with the same sweep.

(
var dur = 15;
var updateRate = 20;
var steps = (dur * updateRate).asInteger;
var startFormant = 500;
var endFormant = 8000;

~abRoutine = Routine({
	// --- Phase A: Classic engine ---
	"=== A/B COMPARISON ===".postln;
	"Phase A: CLASSIC (GrainBuf) - formant sweep 500->8000 Hz".postln;

	~app.synthSwitcher.useStandard;
	~app.synthSwitcher.activeSynth.trainInstances[0].set(
		\globalAmplitude, 1.0, \mute, 0,
		\group_1_onOff, 0
	);
	~app.synthSwitcher.activeSynth.trainInstances[0].play;

	steps.do { |step|
		var formant = step.linexp(0, steps - 1, startFormant, endFormant);
		~app.data.data_main[0][1].value_(formant);
		(1 / updateRate).wait;
	};

	~app.synthSwitcher.activeSynth.trainInstances[0].stop;
	1.wait;

	// --- Phase B: OscOS engine ---
	"Phase B: OSCOS (Oversampling) - same sweep 500->8000 Hz".postln;

	~app.synthSwitcher.useOscOS;
	~app.synthSwitcher.activeSynth.trainInstances[0].set(
		\globalAmplitude, 1.0, \mute, 0,
		\group_1_onOff, 0
	);
	~app.synthSwitcher.activeSynth.trainInstances[0].play;

	steps.do { |step|
		var formant = step.linexp(0, steps - 1, startFormant, endFormant);
		~app.data.data_main[0][1].value_(formant);
		(1 / updateRate).wait;
	};

	~app.synthSwitcher.activeSynth.trainInstances[0].stop;

	// Reset formant to initial value
	~app.data.data_main[0][1].value_(6000);

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
// Step 4 (optional): Harmonic complexity comparison
// =====================================================================
// Demonstrates how harmonic content affects aliasing severity.
// Plays the same formant/fundamental through both engines with
// progressively more harmonics: 4 -> 16 -> 32.
// Classic engine becomes increasingly harsh; OscOS stays clean.

(
var d = ~app.data;
var harmonicCounts = [4, 16, 32];
var formant = 6000;
var dur = 6;  // seconds per harmonic count per engine

d.data_main[0][0].value_(200);  // fundamental
d.data_main[0][1].value_(formant);

~harmonicRoutine = Routine({
	"=== STEP 4: Harmonic Complexity Comparison ===".postln;

	harmonicCounts.do { |numH|
		var pulsaretData = Signal.sineFill(2048, Array.fill(numH, { |i| 1.0 / (i + 1) })).as(Array);

		// Update pulsaret
		d.data_pulsaret[0].value = pulsaretData;
		~app.pulsaretBuffers[0].sendCollection(pulsaretData);

		// Classic engine
		("--- Classic engine: " ++ numH ++ " harmonics ---").postln;
		~app.synthSwitcher.useStandard;
		~app.synthSwitcher.activeSynth.trainInstances[0].set(
			\globalAmplitude, 1.0, \mute, 0, \group_1_onOff, 0
		);
		~app.synthSwitcher.activeSynth.trainInstances[0].play;
		dur.wait;
		~app.synthSwitcher.activeSynth.trainInstances[0].stop;
		0.5.wait;

		// OscOS engine
		("--- OscOS engine: " ++ numH ++ " harmonics ---").postln;
		~app.synthSwitcher.useOscOS;
		~app.synthSwitcher.activeSynth.trainInstances[0].set(
			\globalAmplitude, 1.0, \mute, 0, \group_1_onOff, 0
		);
		~app.synthSwitcher.activeSynth.trainInstances[0].play;
		dur.wait;
		~app.synthSwitcher.activeSynth.trainInstances[0].stop;
		1.wait;
	};

	"=== Harmonic comparison complete ===".postln;
}).play(AppClock);
)

// --- Stop Step 4 ---
(
~harmonicRoutine.stop;
~app.synthSwitcher.stop;
)

// =====================================================================
// Step 5 (optional): Fundamental frequency sweep (fixed high formant)
// =====================================================================
// Keeps formant at 8000 Hz, sweeps fundamental from 50 to 400 Hz.
// Higher fundamental = faster table playback = more aliasing.
// Demonstrates that aliasing depends on BOTH formant AND fundamental.

(
var d = ~app.data;
var dur = 12;
var updateRate = 20;
var steps = (dur * updateRate).asInteger;
var startFund = 50;
var endFund = 400;
var formant = 8000;

d.data_main[0][1].value_(formant);

~fundSweepRoutine = Routine({
	"=== STEP 5: Fundamental Sweep (formant fixed at 8000 Hz) ===".postln;

	// Classic engine
	"--- Classic engine: fundamental 50->400 Hz ---".postln;
	~app.synthSwitcher.useStandard;
	~app.synthSwitcher.activeSynth.trainInstances[0].set(
		\globalAmplitude, 1.0, \mute, 0, \group_1_onOff, 0
	);
	~app.synthSwitcher.activeSynth.trainInstances[0].play;

	steps.do { |step|
		var fund = step.linexp(0, steps - 1, startFund, endFund);
		d.data_main[0][0].value_(fund);
		(1 / updateRate).wait;
	};

	~app.synthSwitcher.activeSynth.trainInstances[0].stop;
	1.wait;

	// OscOS engine
	"--- OscOS engine: fundamental 50->400 Hz ---".postln;
	~app.synthSwitcher.useOscOS;
	~app.synthSwitcher.activeSynth.trainInstances[0].set(
		\globalAmplitude, 1.0, \mute, 0, \group_1_onOff, 0
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
	d.data_main[0][1].value_(6000);

	"=== Fundamental sweep complete ===".postln;
	"Notice: Classic engine gets increasingly harsh as fundamental rises.".postln;
	"OscOS maintains clean harmonics throughout the sweep.".postln;
}).play(AppClock);
)

// --- Stop Step 5 ---
(
~fundSweepRoutine.stop;
~app.synthSwitcher.stop;
)

// =====================================================================
// Listening guide:
//
// Step 3 - A/B formant sweep comparison (500 -> 8000 Hz):
//
//   Classic (GrainBuf): Aliasing intensifies as formant rises.
//   Upper harmonics fold back as inharmonic spectral content,
//   creating metallic brightness that worsens at high formants.
//   This is the "digital dirt" characteristic of historical
//   pulsar synthesis implementations.
//
//   OscOS (Oversampling): Clean sweep throughout. Same temporal
//   structure (burst pattern, emission quantization) but natural
//   timbral brightening without the metallic artifacts.
//
// Step 4 (optional) - Harmonic complexity comparison:
//
//   Demonstrates that aliasing severity scales with harmonic
//   content. With 4 harmonics, both engines sound similar.
//   With 32 harmonics, Classic becomes harsh while OscOS stays clean.
//
// Step 5 (optional) - Fundamental sweep (50 -> 400 Hz):
//
//   Higher fundamental = faster wavetable playback = more aliasing.
//   Classic engine becomes increasingly harsh at higher fundamentals.
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
