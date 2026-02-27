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

// --- Pulsaret: spectrally rich waveform (first 8 harmonics) ---
// This maximises aliasing potential: at high playback rates, upper
// harmonics fold back below Nyquist in the GrainBuf engine.
var pulsaretData = Signal.sineFill(2048, Array.fill(8, { |i| 1.0 / (i + 1) })).as(Array);

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

"Step 1 complete: buffers loaded with 8-harmonic pulsaret".postln;
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
// High enough that the 8-harmonic pulsaret pushes upper partials
// well above Nyquist/2, triggering aliasing in GrainBuf
d.data_main[0][0].value_(200);

// Formant: 2000 Hz (absolute Hz, independent of fundamental)
// At 2000 Hz with 8 harmonics, the 8th partial is at 16,000 Hz.
// GrainBuf's table-lookup without oversampling will produce
// aliased foldback from partials exceeding Nyquist/oversample_factor.
d.data_main[0][1].value_(2000);

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
"  Fundamental: 200 Hz | Formant: 2000 Hz | Burst: 7:1".postln;
"  8 harmonics -> highest partial at ~16 kHz".postln;
)

// =====================================================================
// Step 3A: Listen with CLASSIC (GrainBuf) engine — historical logic
// =====================================================================
// The GrainBuf engine reads the 2048-point wavetable without
// oversampling. At the playback rates required for a 2000 Hz formant,
// upper harmonics exceed the Nyquist frequency and fold back into
// the audible spectrum as inharmonic artifacts. These artifacts are
// the sonic signature of the original PG's computational constraints
// — present in every recording made with the original software.

(
~app.synthSwitcher.useStandard;
~app.synthSwitcher.activeSynth.trainInstances[0].set(
	\globalAmplitude, 1.0, \mute, 0,
	\group_1_onOff, 0
);
~app.synthSwitcher.activeSynth.trainInstances[0].play;

"--- CLASSIC (GrainBuf) engine: aliasing artifacts present ---".postln;
"    Listen for: inharmonic spectral content, metallic brightness,".postln;
"    spectral foldback in upper frequencies".postln;
)

// --- Stop Classic ---
~app.synthSwitcher.activeSynth.trainInstances[0].stop;

// =====================================================================
// Step 3B: Listen with OSCOS (Oversampling) engine — contemporary logic
// =====================================================================
// The OscOS engine uses 4x oversampled wavetable lookup. The same
// 2000 Hz formant with 8 harmonics is rendered cleanly — upper
// partials that would alias in GrainBuf are correctly attenuated.
// What remains is ONLY the temporal ontology: the discrete emission
// clock, the burst masking, the stepped parameter logic. The sonic
// character of these temporal structures is revealed without the
// spectral artifacts that historically accompanied them.

(
~app.synthSwitcher.useOscOS;
~app.synthSwitcher.activeSynth.trainInstances[0].set(
	\globalAmplitude, 1.0, \mute, 0,
	\group_1_onOff, 0
);
~app.synthSwitcher.activeSynth.trainInstances[0].play;

"--- OSCOS (Oversampling) engine: aliasing removed ---".postln;
"    Listen for: cleaner upper spectrum, same temporal structure,".postln;
"    same burst pattern, same emission-rate quantization".postln;
)

// --- Stop OscOS ---
~app.synthSwitcher.activeSynth.trainInstances[0].stop;

// =====================================================================
// Step 4: Automated A/B comparison with frequency sweep
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
	~app.data.data_main[0][1].value_(2000);

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
// Listening guide:
//
// Steps 3A/3B - Static comparison (200 Hz fundamental, 2000 Hz formant):
//
//   Classic (GrainBuf): A bright, somewhat metallic timbre with
//   inharmonic spectral content in the upper frequencies. The
//   burst pattern (7:1) creates a subtle periodic amplitude
//   modulation. The overall character has a gritty, artefactual
//   quality - the "sound of the original PG."
//
//   OscOS (Oversampling): The same pitch, the same burst pattern,
//   the same emission-rate quantization - but the upper spectrum
//   is cleaner. The 8-harmonic series is rendered accurately;
//   the inharmonic aliased content is gone. What remains is the
//   temporal structure: the discrete click of each pulsaret
//   emission, the periodic gap of the burst mask, the quantized
//   character of the emission clock.
//
// Step 4 - Formant sweep comparison:
//
//   As the formant rises from 500 to 8000 Hz, the Classic engine
//   produces increasingly dramatic aliasing: the upper harmonics
//   fold back as inharmonic spectral content, creating a metallic,
//   distorted brightness that intensifies with formant frequency.
//
//   The OscOS engine sweeps the same range cleanly. The timbral
//   evolution follows the natural harmonic series without foldback.
//   The temporal structure - burst mask, emission quantization,
//   discrete parameter stepping - sounds identical in both.
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
