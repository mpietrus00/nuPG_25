/*
nuPG Formant Ratio Mode
=======================

By default, formant frequencies in nuPG are absolute Hz values
(matching the original Pulsar Generator design). This file provides
an optional "ratio mode" where formant frequencies track the
fundamental frequency as multipliers.

Example: If fundamental = 100 Hz and ratio = 3, formant = 300 Hz.
When fundamental changes to 200 Hz, formant automatically becomes 600 Hz.

This is useful for:
- Harmonic relationships that stay consistent across pitch changes
- Just intonation and microtonal tuning systems
- Spectral/overtone synthesis
- Creating chords and intervals locked to fundamental

Prerequisites:
  ~app = NuPG_Application(1, 1).boot;
*/


// =====================================================================
// 1. SETUP (evaluate this block first)
// =====================================================================

(
// Persistent storage for active dependants (survives re-evaluation)
~formantRatioDeps = ~formantRatioDeps ?? { Dictionary.new };

~formantRatioEnable = { |instance=0, formantNum=1, ratio=2|
	var key = (instance.asString ++ "_" ++ formantNum).asSymbol;
	var fundCV = ~app.data.data_main[instance][0];
	var synth = ~app.synthesis.trainInstances[instance];
	var synthOscOS = ~app.synthesisOscOS.trainInstances[instance];
	var paramName = [\formant_frequency_One, \formant_frequency_Two, \formant_frequency_Three][formantNum - 1];
	var dep;

	// Remove existing dependant first (prevents duplicates)
	if (~formantRatioDeps[key].notNil) {
		fundCV.removeDependant(~formantRatioDeps[key]);
	};

	dep = { |cv, what, val|
		if (what == \value) {
			synth.set(paramName, val * ratio);
			synthOscOS.set(paramName, val * ratio);
		};
	};

	// Store reference for later removal
	~formantRatioDeps[key] = dep;

	// Apply immediately and on future changes
	dep.(fundCV, \value, fundCV.value);
	fundCV.addDependant(dep);

	("Formant" + formantNum + ": ratio mode ON (fundamental x" + ratio ++ ")").postln;
};

~formantRatioDisable = { |instance=0, formantNum=1|
	var key = (instance.asString ++ "_" ++ formantNum).asSymbol;
	var fundCV = ~app.data.data_main[instance][0];
	var formantCV = ~app.data.data_main[instance][formantNum];
	var synth = ~app.synthesis.trainInstances[instance];
	var synthOscOS = ~app.synthesisOscOS.trainInstances[instance];
	var paramName = [\formant_frequency_One, \formant_frequency_Two, \formant_frequency_Three][formantNum - 1];

	if (~formantRatioDeps[key].notNil) {
		fundCV.removeDependant(~formantRatioDeps[key]);
		~formantRatioDeps[key] = nil;
		// Restore formant slider value to synth
		synth.set(paramName, formantCV.value);
		synthOscOS.set(paramName, formantCV.value);
		("Formant" + formantNum + ": ratio mode OFF (restored to" + formantCV.value + "Hz)").postln;
	} {
		("Formant" + formantNum + ": not in ratio mode").postln;
	};
};

~formantRatioDisableAll = { |instance=0|
	3.do { |i| ~formantRatioDisable.(instance, i + 1) };
};

// Helper to set all three at once
~formantRatioSet = { |instance=0, ratios=#[1, 2, 3]|
	ratios.do { |r, i| ~formantRatioEnable.(instance, i + 1, r) };
};
)


// =====================================================================
// 2. BASIC USAGE
// =====================================================================

// Enable ratio mode for individual formants
~formantRatioEnable.(0, 1, 2);   // formant 1 = fundamental x 2
~formantRatioEnable.(0, 2, 3);   // formant 2 = fundamental x 3
~formantRatioEnable.(0, 3, 5);   // formant 3 = fundamental x 5

// Disable individual formants (back to absolute Hz from slider)
~formantRatioDisable.(0, 1);
~formantRatioDisable.(0, 2);
~formantRatioDisable.(0, 3);

// Disable all at once
~formantRatioDisableAll.(0);

// Set all three with one call
~formantRatioSet.(0, [2, 3, 4]);

// Re-enabling is safe (removes old dependant first)
~formantRatioEnable.(0, 1, 8);   // change formant 1 to fund x 8


// =====================================================================
// 3. HARMONIC SERIES
// =====================================================================

// Natural overtone series (partials 1, 2, 3, 4, 5, 6...)
// These are the frequencies present in most acoustic instruments

// First three harmonics
~formantRatioSet.(0, [1, 2, 3]);

// Harmonics 2, 3, 4
~formantRatioSet.(0, [2, 3, 4]);

// Harmonics 3, 4, 5
~formantRatioSet.(0, [3, 4, 5]);

// Harmonics 4, 5, 6
~formantRatioSet.(0, [4, 5, 6]);

// Higher harmonics (brighter, more metallic)
~formantRatioSet.(0, [5, 7, 9]);
~formantRatioSet.(0, [6, 8, 10]);
~formantRatioSet.(0, [8, 10, 12]);

// Very high harmonics (bell-like, inharmonic feeling)
~formantRatioSet.(0, [11, 13, 17]);
~formantRatioSet.(0, [16, 19, 23]);


// =====================================================================
// 4. ODD HARMONICS (Clarinet-like, Square wave spectrum)
// =====================================================================

// Odd harmonics have a hollow, clarinet-like quality
// Square waves contain only odd harmonics

~formantRatioSet.(0, [1, 3, 5]);
~formantRatioSet.(0, [3, 5, 7]);
~formantRatioSet.(0, [5, 7, 9]);
~formantRatioSet.(0, [7, 9, 11]);
~formantRatioSet.(0, [9, 11, 13]);


// =====================================================================
// 5. EVEN HARMONICS (Octave-rich, Organ-like)
// =====================================================================

// Even harmonics reinforce octave relationships
~formantRatioSet.(0, [2, 4, 6]);
~formantRatioSet.(0, [2, 4, 8]);
~formantRatioSet.(0, [4, 8, 16]);


// =====================================================================
// 6. SUBHARMONICS (Undertone series)
// =====================================================================

// Frequencies below the fundamental - creates depth and weight
// Subharmonics occur in throat singing, trombones, etc.

// Simple subharmonics
~formantRatioSet.(0, [0.5, 1, 2]);      // octave below, fundamental, octave above
~formantRatioSet.(0, [0.5, 0.75, 1]);   // sub-octave region
~formantRatioSet.(0, [0.25, 0.5, 1]);   // two octaves of subs

// Deep subharmonics
~formantRatioSet.(0, [0.125, 0.25, 0.5]);
~formantRatioSet.(0, [0.0625, 0.125, 0.25]);

// Mixed sub and harmonics
~formantRatioSet.(0, [0.5, 2, 4]);
~formantRatioSet.(0, [0.25, 1, 4]);


// =====================================================================
// 7. JUST INTONATION - Triads
// =====================================================================

// Just intonation uses simple whole-number ratios
// These intervals are "pure" - no beating

// --- Major triads ---
// Major triad: 1 : 5/4 : 3/2  (root, major 3rd, perfect 5th)
~formantRatioSet.(0, [1, 1.25, 1.5]);

// First inversion: 5/4 : 3/2 : 2
~formantRatioSet.(0, [1.25, 1.5, 2]);

// Second inversion: 3/2 : 2 : 5/2
~formantRatioSet.(0, [1.5, 2, 2.5]);

// --- Minor triads ---
// Minor triad: 1 : 6/5 : 3/2  (root, minor 3rd, perfect 5th)
~formantRatioSet.(0, [1, 1.2, 1.5]);

// First inversion
~formantRatioSet.(0, [1.2, 1.5, 2]);

// --- Diminished triad ---
// 1 : 6/5 : 36/25
~formantRatioSet.(0, [1, 1.2, 1.44]);

// --- Augmented triad ---
// 1 : 5/4 : 25/16
~formantRatioSet.(0, [1, 1.25, 1.5625]);

// --- Suspended chords ---
// Sus4: 1 : 4/3 : 3/2
~formantRatioSet.(0, [1, 1.333333, 1.5]);

// Sus2: 1 : 9/8 : 3/2
~formantRatioSet.(0, [1, 1.125, 1.5]);


// =====================================================================
// 8. JUST INTONATION - Seventh chords
// =====================================================================

// Major 7th: 1 : 5/4 : 3/2 : 15/8
// (using 3 formants, pick three of the four notes)
~formantRatioSet.(0, [1, 1.25, 1.875]);      // root, 3rd, 7th
~formantRatioSet.(0, [1.25, 1.5, 1.875]);    // 3rd, 5th, 7th
~formantRatioSet.(0, [1, 1.5, 1.875]);       // root, 5th, 7th

// Dominant 7th: 1 : 5/4 : 3/2 : 7/4
~formantRatioSet.(0, [1, 1.25, 1.75]);       // root, 3rd, b7
~formantRatioSet.(0, [1.25, 1.5, 1.75]);     // 3rd, 5th, b7
~formantRatioSet.(0, [1, 1.5, 1.75]);        // root, 5th, b7

// Minor 7th: 1 : 6/5 : 3/2 : 9/5
~formantRatioSet.(0, [1, 1.2, 1.8]);         // root, m3, m7
~formantRatioSet.(0, [1.2, 1.5, 1.8]);       // m3, 5th, m7


// =====================================================================
// 9. JUST INTONATION - Intervals
// =====================================================================

// All intervals based on fundamental (formant 1 = root)

// Unison
~formantRatioSet.(0, [1, 1, 1]);

// Octaves
~formantRatioSet.(0, [1, 2, 4]);
~formantRatioSet.(0, [0.5, 1, 2]);

// Perfect fifth: 3/2
~formantRatioSet.(0, [1, 1.5, 2]);
~formantRatioSet.(0, [1, 1.5, 3]);      // with octave above

// Perfect fourth: 4/3
~formantRatioSet.(0, [1, 1.333333, 2]);

// Major third: 5/4
~formantRatioSet.(0, [1, 1.25, 2]);

// Minor third: 6/5
~formantRatioSet.(0, [1, 1.2, 2]);

// Major second: 9/8
~formantRatioSet.(0, [1, 1.125, 2]);

// Minor second: 16/15
~formantRatioSet.(0, [1, 1.066667, 2]);

// Major sixth: 5/3
~formantRatioSet.(0, [1, 1.666667, 2]);

// Minor sixth: 8/5
~formantRatioSet.(0, [1, 1.6, 2]);

// Major seventh: 15/8
~formantRatioSet.(0, [1, 1.875, 2]);

// Minor seventh (harmonic): 7/4
~formantRatioSet.(0, [1, 1.75, 2]);

// Tritone: 7/5 or 10/7
~formantRatioSet.(0, [1, 1.4, 2]);
~formantRatioSet.(0, [1, 1.428571, 2]);


// =====================================================================
// 10. PYTHAGOREAN TUNING
// =====================================================================

// Based on stacking perfect fifths (3/2)
// Slightly different from just intonation

// Pythagorean major third: 81/64 (sharper than 5/4)
~formantRatioSet.(0, [1, 1.265625, 1.5]);

// Pythagorean minor third: 32/27
~formantRatioSet.(0, [1, 1.185185, 1.5]);

// Pythagorean major second: 9/8
~formantRatioSet.(0, [1, 1.125, 1.5]);

// Pythagorean tritone: 729/512
~formantRatioSet.(0, [1, 1.423828, 2]);

// Circle of fifths stack
~formantRatioSet.(0, [1, 1.5, 2.25]);       // fund, 5th, 9th (M2 up octave)


// =====================================================================
// 11. EQUAL TEMPERAMENT
// =====================================================================

// 12-tone equal temperament (standard Western tuning)
// Each semitone = 2^(1/12) = 1.059463...

// Semitone
~formantRatioSet.(0, [1, 1.059463, 2]);

// Whole tone
~formantRatioSet.(0, [1, 1.122462, 2]);

// Minor third (3 semitones)
~formantRatioSet.(0, [1, 1.189207, 2]);

// Major third (4 semitones)
~formantRatioSet.(0, [1, 1.259921, 2]);

// Perfect fourth (5 semitones)
~formantRatioSet.(0, [1, 1.334840, 2]);

// Tritone (6 semitones)
~formantRatioSet.(0, [1, 1.414214, 2]);

// Perfect fifth (7 semitones)
~formantRatioSet.(0, [1, 1.498307, 2]);

// Major sixth (9 semitones)
~formantRatioSet.(0, [1, 1.681793, 2]);

// Major seventh (11 semitones)
~formantRatioSet.(0, [1, 1.887749, 2]);


// =====================================================================
// 12. MICROTONAL - Quarter tones
// =====================================================================

// 24-tone equal temperament
// Each quarter tone = 2^(1/24) = 1.029302...

~formantRatioSet.(0, [1, 1.029302, 2]);         // quarter tone
~formantRatioSet.(0, [1, 1.059463, 2]);         // half tone
~formantRatioSet.(0, [1, 1.090508, 2]);         // 3/4 tone
~formantRatioSet.(0, [1, 1.122462, 2]);         // whole tone

// Neutral third (between major and minor) - common in Arabic music
~formantRatioSet.(0, [1, 1.148698, 2]);         // ~350 cents


// =====================================================================
// 13. MICROTONAL - Other divisions
// =====================================================================

// 19-TET (19 equal divisions of octave)
// step = 2^(1/19) = 1.037155
~formantRatioSet.(0, [1, 1.037155, 2]);
~formantRatioSet.(0, [1, 1.223462, 2]);         // 19-TET "major third"

// 31-TET (excellent for just intonation approximation)
// step = 2^(1/31) = 1.022611
~formantRatioSet.(0, [1, 1.022611, 2]);

// 53-TET (very close to Pythagorean)
// step = 2^(1/53) = 1.013164
~formantRatioSet.(0, [1, 1.013164, 2]);

// Bohlen-Pierce scale (divides 3:1 into 13 steps)
// step = 3^(1/13) = 1.088182
~formantRatioSet.(0, [1, 1.088182, 3]);


// =====================================================================
// 14. WORLD MUSIC SCALES
// =====================================================================

// --- Indonesian Gamelan (approximate) ---
// Slendro (5-tone)
~formantRatioSet.(0, [1, 1.22, 1.52]);
~formantRatioSet.(0, [1, 1.52, 1.87]);

// Pelog (7-tone, using 3 notes)
~formantRatioSet.(0, [1, 1.07, 1.26]);
~formantRatioSet.(0, [1, 1.54, 1.85]);

// --- Indian Classical (Shruti approximations) ---
// Sa-Ga-Pa (root, major 3rd, 5th)
~formantRatioSet.(0, [1, 1.25, 1.5]);

// Sa-komal Ga-Pa (root, minor 3rd, 5th)
~formantRatioSet.(0, [1, 1.185185, 1.5]);

// --- Arabic Maqam (approximate) ---
// Maqam Rast (quarter-tone scale)
~formantRatioSet.(0, [1, 1.122, 1.335]);

// Maqam Bayati
~formantRatioSet.(0, [1, 1.09, 1.335]);

// --- Thai classical (7-TET approximation) ---
// step = 2^(1/7) = 1.104089
~formantRatioSet.(0, [1, 1.104089, 1.219014]);


// =====================================================================
// 15. SPECTRAL / ADDITIVE SYNTHESIS RATIOS
// =====================================================================

// FM-like metallic ratios (non-integer relationships)
~formantRatioSet.(0, [1, 1.414, 2]);       // 1 : sqrt(2) : 2
~formantRatioSet.(0, [1, 1.618, 2.618]);   // golden ratio based
~formantRatioSet.(0, [1, 2.718, 7.389]);   // e-based (natural log)
~formantRatioSet.(0, [1, 3.14159, 9.8696]); // pi-based

// Bell-like inharmonic ratios
~formantRatioSet.(0, [1, 2.0, 3.6]);
~formantRatioSet.(0, [1, 2.76, 5.4]);
~formantRatioSet.(0, [1, 3.2, 6.1]);

// Drum-like ratios (circular membrane modes)
~formantRatioSet.(0, [1, 1.593, 2.135]);
~formantRatioSet.(0, [1, 2.295, 2.917]);

// String harmonics with slight detuning (simulates real strings)
~formantRatioSet.(0, [1, 2.001, 3.003]);
~formantRatioSet.(0, [1, 1.999, 2.997]);


// =====================================================================
// 16. DISSONANCE AND TENSION
// =====================================================================

// Beating intervals (close frequencies)
~formantRatioSet.(0, [1, 1.01, 1.02]);      // slow beating
~formantRatioSet.(0, [1, 1.005, 1.01]);     // very slow
~formantRatioSet.(0, [1, 1.05, 1.1]);       // faster beating

// Cluster chords (dense dissonance)
~formantRatioSet.(0, [1, 1.059, 1.122]);    // chromatic cluster
~formantRatioSet.(0, [1, 1.029, 1.059]);    // quarter-tone cluster

// Tritone stacks
~formantRatioSet.(0, [1, 1.414, 2]);
~formantRatioSet.(0, [1, 1.414, 1.999]);    // slightly detuned


// =====================================================================
// 17. PRESET FUNCTIONS
// =====================================================================

(
// Named presets for quick access

~ratioPresets = (
	// Harmonic
	\harmonic123: [1, 2, 3],
	\harmonic234: [2, 3, 4],
	\harmonic456: [4, 5, 6],
	\oddHarmonics: [1, 3, 5],
	\evenHarmonics: [2, 4, 6],

	// Subharmonic
	\subOctave: [0.5, 1, 2],
	\deepSub: [0.25, 0.5, 1],

	// Just intonation
	\justMajor: [1, 1.25, 1.5],
	\justMinor: [1, 1.2, 1.5],
	\justDom7: [1, 1.25, 1.75],
	\justMaj7: [1, 1.25, 1.875],

	// Equal temperament
	\etMajor: [1, 1.259921, 1.498307],
	\etMinor: [1, 1.189207, 1.498307],

	// Special
	\golden: [1, 1.618, 2.618],
	\bell: [1, 2.0, 3.6],
	\beating: [1, 1.01, 1.02],
	\octaves: [1, 2, 4],
	\fifths: [1, 1.5, 2.25]
);

~ratioPreset = { |name, instance=0|
	var ratios = ~ratioPresets[name];
	if (ratios.notNil) {
		~formantRatioSet.(instance, ratios);
		("Preset" + name + "applied:" + ratios).postln;
	} {
		("Unknown preset:" + name).postln;
		("Available:" + ~ratioPresets.keys.asArray.sort).postln;
	};
};
)

// Usage:
~ratioPreset.(\justMajor);
~ratioPreset.(\oddHarmonics);
~ratioPreset.(\golden);
~ratioPreset.(\bell);

// List all presets
~ratioPresets.keys.asArray.sort.do(_.postln);


// =====================================================================
// 18. DISABLE ALL / RETURN TO ABSOLUTE Hz
// =====================================================================

// Return all formants to absolute Hz mode (slider control)
~formantRatioDisableAll.(0);
