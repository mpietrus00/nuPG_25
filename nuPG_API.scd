/*
nuPG API Reference
==================

Comprehensive guide to programmatic control of nuPG.
All examples assume the application is booted:

  ~app = NuPG_Application(1, 1).boot;

Instance index [0] is used throughout. For multi-instance setups,
replace [0] with the desired instance index (0 to numInstances-1).
*/


// =====================================================================
// 1. READING PARAMETER VALUES
// =====================================================================

// --- Scalar parameters ---
// All scalar CVs have a .value getter

~app.data.data_main[0][0].value;   // fundamental frequency (1-3000 Hz, exp)
~app.data.data_main[0][1].value;   // formant frequency 1 (0.05-16 Hz, exp)
~app.data.data_main[0][2].value;   // formant frequency 2 (0.05-16 Hz, exp)
~app.data.data_main[0][3].value;   // formant frequency 3 (0.05-16 Hz, exp)
~app.data.data_main[0][4].value;   // envelope dilation 1 (0.0-2.0, lin)
~app.data.data_main[0][5].value;   // envelope dilation 2 (0.0-2.0, lin)
~app.data.data_main[0][6].value;   // envelope dilation 3 (0.01-2.0, lin)
~app.data.data_main[0][7].value;   // pan 1 (-1.0 to 1.0, lin)
~app.data.data_main[0][8].value;   // pan 2 (-1.0 to 1.0, lin)
~app.data.data_main[0][9].value;   // pan 3 (-1.0 to 1.0, lin)
~app.data.data_main[0][10].value;  // amplitude 1 (0.0-1.0, lin)
~app.data.data_main[0][11].value;  // amplitude 2 (0.0-1.0, lin)
~app.data.data_main[0][12].value;  // amplitude 3 (0.0-1.0, lin)

// Modulators
~app.data.data_modulators[0][0].value;  // FM amount (0.0-16.0)
~app.data.data_modulators[0][1].value;  // FM ratio (0.0-16.0)
~app.data.data_modulators[0][2].value;  // flux amount (0.0-2.0)

// Group offsets
~app.data.data_groupsOffset[0][0].value;  // offset 1 (0.0-1.0)
~app.data.data_groupsOffset[0][1].value;  // offset 2 (0.0-1.0)
~app.data.data_groupsOffset[0][2].value;  // offset 3 (0.0-1.0)

// Modulators 1-4 (each has [type, freq, depth])
~app.data.data_modulator1[0][0].value;  // type (0-4: off, sine, tri, saw, square)
~app.data.data_modulator1[0][1].value;  // frequency (0.001-150 Hz)
~app.data.data_modulator1[0][2].value;  // depth (0-10)

// Same structure for data_modulator2, data_modulator3, data_modulator4

// Overlap morph (OscOS only)
~app.data.data_overlapMorph[0][0].value;  // rate (0.01-10 Hz, exp)
~app.data.data_overlapMorph[0][1].value;  // depth (0.0-1.0)
~app.data.data_overlapMorph[0][2].value;  // shape (0=sine, 1=tri, 2=saw, 3=random, 4=chaos)
~app.data.data_overlapMorph[0][3].value;  // min overlap (0.1-100)
~app.data.data_overlapMorph[0][4].value;  // max overlap (0.1-100)
~app.data.data_overlapMorph[0][5].value;  // spread (0.0-1.0)

// Masking
~app.data.data_probabilityMaskSingular[0].value;  // probability (0.0-1.0)
~app.data.data_burstMask[0][0].value;              // burst (1-2999)
~app.data.data_burstMask[0][1].value;              // rest (0-2998)
~app.data.data_channelMask[0][0].value;            // channel mask (0-1500)
~app.data.data_channelMask[0][1].value;            // center mask (0-1)
~app.data.data_sieveMask[0][0].value;              // sieve size (1-100)
~app.data.data_sieveMask[0][1].value;              // sieve sequence (array)

// Modulation matrix (4 modulators x 13 parameters)
~app.data.data_matrix[0][0][0].value;  // modulator 1 -> fundamental (0 or 1)
~app.data.data_matrix[0][1][0].value;  // modulator 2 -> fundamental
// row indices: 0=fund, 1-3=formants, 4-6=envDil, 7-9=pan, 10-12=amp

// Playback
~app.data.data_trainDuration[0].value;  // train duration (0.3-120 sec)
~app.data.data_scrubber[0].value;       // scrubber position (0-2047)

// --- Table data (2048-sample arrays) ---
~app.data.data_pulsaret[0].value;             // pulsaret waveform
~app.data.data_envelope[0].value;             // envelope shape
~app.data.data_fundamentalFrequency[0].value; // fundamental frequency table
~app.data.data_formantFrequencyOne[0].value;  // formant 1 table
~app.data.data_formantFrequencyTwo[0].value;  // formant 2 table
~app.data.data_formantFrequencyThree[0].value;// formant 3 table
~app.data.data_panOne[0].value;               // pan 1 table
~app.data.data_panTwo[0].value;               // pan 2 table
~app.data.data_panThree[0].value;             // pan 3 table
~app.data.data_ampOne[0].value;               // amplitude 1 table
~app.data.data_ampTwo[0].value;               // amplitude 2 table
~app.data.data_ampThree[0].value;             // amplitude 3 table
~app.data.data_envelopeMulOne[0].value;       // envelope mult 1 table
~app.data.data_envelopeMulTwo[0].value;       // envelope mult 2 table
~app.data.data_envelopeMulThree[0].value;     // envelope mult 3 table
~app.data.data_modulationAmount[0].value;     // modulation amount table
~app.data.data_modulationRatio[0].value;      // modulation ratio table
~app.data.data_multiParamModulation[0].value; // multi-parameter modulation table
~app.data.data_probabilityMask[0].value;      // probability mask table
~app.data.data_fourier[0].value;              // fourier data (16 values)

// --- Table min/max ranges [max, min] ---
~app.data.data_pulsaret_maxMin[0][0].value;               // pulsaret max
~app.data.data_pulsaret_maxMin[0][1].value;               // pulsaret min
~app.data.data_fundamentalFrequency_maxMin[0][0].value;   // fund freq max (default 10)
~app.data.data_fundamentalFrequency_maxMin[0][1].value;   // fund freq min (default 0)
// Same pattern for all other _maxMin arrays


// =====================================================================
// 2. SETTING PARAMETER VALUES
// =====================================================================

// --- Set scalar values ---
// Setting .value updates the GUI and synth automatically
~app.data.data_main[0][0].value = 440;    // set fundamental to 440 Hz
~app.data.data_main[0][10].value = 0.8;   // set amplitude 1 to 0.8
~app.data.data_main[0][7].value = -0.5;   // pan 1 to left

~app.data.data_modulators[0][0].value = 4.0;    // FM amount
~app.data.data_modulators[0][1].value = 2.5;    // FM ratio
~app.data.data_groupsOffset[0][0].value = 0.5;  // offset 1

~app.data.data_modulator1[0][0].value = 1;      // modulator 1 type = sine
~app.data.data_modulator1[0][1].value = 5.0;    // modulator 1 freq = 5 Hz
~app.data.data_modulator1[0][2].value = 3;       // modulator 1 depth = 3

~app.data.data_probabilityMaskSingular[0].value = 0.7;  // probability
~app.data.data_burstMask[0][0].value = 3;    // burst
~app.data.data_burstMask[0][1].value = 1;    // rest

~app.data.data_overlapMorph[0][0].value = 2.0;   // overlap morph rate
~app.data.data_overlapMorph[0][1].value = 0.8;   // overlap morph depth
~app.data.data_overlapMorph[0][2].value = 1;     // overlap shape: triangle

~app.data.data_trainDuration[0].value = 10.0;    // train duration = 10 sec

// --- Set modulation matrix ---
// Enable modulator 1 -> fundamental
~app.data.data_matrix[0][0][0].value = 1;
// Disable modulator 2 -> pan 1
~app.data.data_matrix[0][1][7].value = 0;

// Enable all modulators for fundamental at once
4.do{|mod| ~app.data.data_matrix[0][mod][0].value = 1 };

// --- Set table data ---
// Generate a sine wave pulsaret
~app.data.data_pulsaret[0].value = Signal.sineFill(2048, [1]);

// Generate a custom envelope (hanning window)
~app.data.data_envelope[0].value = Signal.hanningWindow(2048);

// Generate a frequency ramp table
~app.data.data_fundamentalFrequency[0].value = (0..2047).normalize(0, 1);

// Set amplitude table to random values
~app.data.data_ampOne[0].value = { 1.0.rand }.dup(2048);

// After setting pulsaret or envelope tables, update the buffers:
~app.pulsaretBuffers[0].sendCollection(~app.data.data_pulsaret[0].value);
~app.envelopeBuffers[0].sendCollection(~app.data.data_envelope[0].value);

// --- Set multiple parameters at once ---
(
~app.data.data_main[0][0].value = 220;   // fundamental
~app.data.data_main[0][1].value = 3.0;   // formant 1
~app.data.data_main[0][10].value = 0.9;  // amp 1
~app.data.data_main[0][7].value = 0;     // pan 1 center
)


// =====================================================================
// 3. SYNTHESIS SWITCHING
// =====================================================================

// Switch to standard GrainBuf synthesis (default)
~app.synthSwitcher.useStandard;

// Switch to OscOS oversampled synthesis (requires OversamplingOscillators plugin)
~app.synthSwitcher.useOscOS;

// Toggle between modes
~app.synthSwitcher.toggle;

// Check current mode
~app.synthSwitcher.mode;         // returns \standard or \oscos
~app.synthSwitcher.activeMode;   // same

// Get active synthesis object
~app.synthSwitcher.current;

// Check if OscOS is available
~app.synthSwitcher.oscOSAvailable;

// Print detailed status
~app.synthSwitcher.status;

// Play / stop all trains
~app.synthSwitcher.play;
~app.synthSwitcher.stop;

// Set OscOS oversample factor (1, 2, 4, or 8)
~app.synthSwitcher.oversample_(4);

// Set group state (group: 1-3, value: 0=off, 1=on)
~app.synthSwitcher.setGroupState(0, 1, 1);  // instance 0, group 1, on
~app.synthSwitcher.setGroupState(0, 2, 0);  // instance 0, group 2, off


// =====================================================================
// 4. DIRECT SYNTH CONTROL
// =====================================================================

// Access Ndef instances directly
~app.synthesis.trainInstances[0];         // standard synth instance 0
~app.synthesisOscOS.trainInstances[0];    // OscOS synth instance 0

// Set parameters directly on the synth (bypasses GUI)
~app.synthesis.trainInstances[0].set(\fundamental_frequency, 440);
~app.synthesis.trainInstances[0].set(\amplitude_One, 0.8);
~app.synthesis.trainInstances[0].set(\pan_One, -0.5);
~app.synthesis.trainInstances[0].set(\fmAmt, 4.0);
~app.synthesis.trainInstances[0].set(\fmRatio, 2.0);
~app.synthesis.trainInstances[0].set(\group_1_onOff, 1);
~app.synthesis.trainInstances[0].set(\group_2_onOff, 0);

// Play and stop individual train instances
~app.synthesis.trainInstances[0].play;
~app.synthesis.trainInstances[0].stop;

// OscOS-specific parameters
~app.synthesisOscOS.trainInstances[0].set(\oversample, 4);
~app.synthesisOscOS.trainInstances[0].set(\overlapMorphRate, 2.0);
~app.synthesisOscOS.trainInstances[0].set(\overlapMorphDepth, 0.7);
~app.synthesisOscOS.trainInstances[0].set(\overlapMorphShape, 1);  // triangle
~app.synthesisOscOS.trainInstances[0].set(\overlapMorphMin, 2);
~app.synthesisOscOS.trainInstances[0].set(\overlapMorphMax, 20);


// =====================================================================
// 5. FILTERING OUTPUT WITH Ndef filterIn
// =====================================================================

// nuPG outputs through Ndefs. You can route this into filter Ndefs using
// the \filterIn role. This lets you add effects without modifying nuPG.

// --- Get the active train Ndef name ---
// Standard mode: \nuPG_train_0, \nuPG_train_1, \nuPG_train_2
// OscOS mode:    \nuPG_train_oscos_0, \nuPG_train_oscos_1, \nuPG_train_oscos_2

// Helper to get the current Ndef for an instance
~getNdefName = {|instance=0|
	if (~app.synthSwitcher.mode == \oscos) {
		(\nuPG_train_oscos_ ++ instance).asSymbol
	} {
		(\nuPG_train_ ++ instance).asSymbol
	};
};

// --- Basic lowpass filter ---
(
Ndef(\nuPG_filter, {
	var sig = \filterIn.ar(0!2);  // receives stereo from nuPG
	var freq = \cutoff.kr(2000);
	var rq = \rq.kr(0.5);
	RLPF.ar(sig, freq, rq)
});
Ndef(\nuPG_filter) <<>.filterIn Ndef(~getNdefName.(0));
Ndef(\nuPG_filter).play;
)

// Modulate filter cutoff
Ndef(\nuPG_filter).set(\cutoff, 800);
Ndef(\nuPG_filter).set(\rq, 0.2);

// Stop filter (reverts to dry nuPG output)
Ndef(\nuPG_filter).stop;

// --- Resonant bandpass filter ---
(
Ndef(\nuPG_bandpass, {
	var sig = \filterIn.ar(0!2);
	var freq = \freq.kr(1000);
	var bw = \bw.kr(200);
	BPF.ar(sig, freq, bw / freq)
});
Ndef(\nuPG_bandpass) <<>.filterIn Ndef(~getNdefName.(0));
Ndef(\nuPG_bandpass).play;
)

// --- Reverb effect ---
(
Ndef(\nuPG_reverb, {
	var sig = \filterIn.ar(0!2);
	var wet = \wet.kr(0.3);
	var room = \room.kr(0.7);
	var damp = \damp.kr(0.5);
	var rev = FreeVerb2.ar(sig[0], sig[1], wet, room, damp);
	rev
});
Ndef(\nuPG_reverb) <<>.filterIn Ndef(~getNdefName.(0));
Ndef(\nuPG_reverb).play;
)

// --- Delay effect ---
(
Ndef(\nuPG_delay, {
	var sig = \filterIn.ar(0!2);
	var delayTime = \delayTime.kr(0.25);
	var feedback = \feedback.kr(0.4);
	var wet = \wet.kr(0.5);
	var delayed = CombL.ar(sig, 2, delayTime, feedback * 4);
	(sig * (1 - wet)) + (delayed * wet)
});
Ndef(\nuPG_delay) <<>.filterIn Ndef(~getNdefName.(0));
Ndef(\nuPG_delay).play;
)

// --- Chain multiple filters ---
(
// Create filter chain: nuPG -> filter -> reverb -> output
Ndef(\nuPG_lpf, {
	var sig = \filterIn.ar(0!2);
	RLPF.ar(sig, \cutoff.kr(3000), \rq.kr(0.7))
});
Ndef(\nuPG_verb, {
	var sig = \filterIn.ar(0!2);
	FreeVerb2.ar(sig[0], sig[1], \wet.kr(0.2), 0.8, 0.5)
});

// Connect the chain
Ndef(\nuPG_lpf) <<>.filterIn Ndef(~getNdefName.(0));
Ndef(\nuPG_verb) <<>.filterIn Ndef(\nuPG_lpf);
Ndef(\nuPG_verb).play;
)

// --- Disconnect filter (return to dry output) ---
Ndef(\nuPG_filter).stop;
Ndef(\nuPG_filter).clear;

// Or reconnect nuPG directly to hardware
Ndef(~getNdefName.(0)).play;

// --- Dynamic filter switching when synth mode changes ---
// When switching between standard/OscOS, reconnect filters:
(
~reconnectFilter = {|filterNdef, instance=0|
	filterNdef <<>.filterIn Ndef(~getNdefName.(instance));
};

// After switching synth mode:
~app.synthSwitcher.useOscOS;
~reconnectFilter.(Ndef(\nuPG_filter), 0);

// Or switch back:
~app.synthSwitcher.useStandard;
~reconnectFilter.(Ndef(\nuPG_filter), 0);
)

// --- Filter multiple instances ---
(
// Create a mixer that combines filtered outputs from multiple instances
~app.numInstances.do{|i|
	Ndef((\nuPG_filt_ ++ i).asSymbol, {
		var sig = \filterIn.ar(0!2);
		RLPF.ar(sig, \cutoff.kr(2000 + (i * 500)), 0.5)
	});
	Ndef((\nuPG_filt_ ++ i).asSymbol) <<>.filterIn Ndef(~getNdefName.(i));
};

// Mix all filtered outputs
Ndef(\nuPG_mix, {
	var sigs = ~app.numInstances.collect{|i|
		Ndef((\nuPG_filt_ ++ i).asSymbol).ar
	};
	sigs.sum / ~app.numInstances
});
Ndef(\nuPG_mix).play;
)


// =====================================================================
// 6. PLAYBACK TASKS
// =====================================================================

// --- Loop playback ---
// Loop tasks read through the 2048-sample tables over trainDuration

// Start/stop loop for instance 0
~app.loopTask.tasks[0].play;
~app.loopTask.tasks[0].stop;

// Check if playing
~app.loopTask.tasks[0].isPlaying;

// Set playback direction: 0 = forward, 1 = reverse
~app.loopTask.tasks[0].set(\playbackDirection, 0);  // forward
~app.loopTask.tasks[0].set(\playbackDirection, 1);  // reverse

// Set train duration (how long one pass through the tables takes)
~app.data.data_trainDuration[0].value = 15.0;  // 15 seconds

// --- Scrubbing ---
// Scrub tasks let you manually drive the playback position

// Start/stop scrubbing
~app.scrubbTask.tasks[0].play;
~app.scrubbTask.tasks[0].stop;

// Set scrub position (0-2047)
~app.data.data_scrubber[0].value = 1024;  // middle of tables

// Automate scrubbing from code
(
fork {
	~app.scrubbTask.tasks[0].play;
	2048.do{|i|
		~app.data.data_scrubber[0].value = i;
		0.01.wait;
	};
	~app.scrubbTask.tasks[0].stop;
};
)


// =====================================================================
// 7. PRESETS
// =====================================================================

// Access the preset manager for instance 0
~preset = ~app.data.conductor[(\con_0).asSymbol].preset;

// --- Store and recall ---

// Add current state as a new preset
~preset.addPreset;

// Store to a specific slot (overwrites if exists)
~preset.store(0);
~preset.store(1);

// Recall a preset
~preset.recall(0);

// Check number of presets
~preset.presets.size;

// Remove a preset
~preset.removePreset(2);

// --- Interpolation ---

// Blend between two presets (0.0 = preset A, 1.0 = preset B)
~preset.interpolate(0, 1, 0.5);  // 50% blend

// Animate blend over time
(
fork {
	100.do{|i|
		var blend = i / 99;
		~preset.interpolate(0, 1, blend);
		0.05.wait;
	};
};
)

// --- Timed morphing with easing curves ---
// morphPresets(slotA, slotB, duration, curve)
// curves: \linear, \sine, \quad, \cubic, \quart, \expo, \circ, \back, \elastic
~app.data.morphPresets(0, 1, 5.0, \sine);    // 5 sec sine eased morph
~app.data.morphPresets(0, 1, 10.0, \linear); // 10 sec linear morph
~app.data.morphPresets(0, 1, 3.0, \elastic); // 3 sec elastic eased morph

// --- Save/load preset files ---

// Save all presets to file
~preset.save(~app.presetsPath ++ "my_presets");

// Load presets from file
~preset.load(~app.presetsPath ++ "my_presets");

// Direct data-level preset save/load (all instances)
~app.data.savePresetsToFile(~app.presetsPath ++ "all_presets");
~app.data.loadPresetsFromFile(~app.presetsPath ++ "all_presets");


// =====================================================================
// 8. BUFFERS
// =====================================================================

// Access buffers directly
~app.pulsaretBuffers[0];    // Buffer for pulsaret waveform
~app.envelopeBuffers[0];    // Buffer for envelope
~app.frequencyBuffers[0];   // Buffer for frequency table

// Send new data to buffers (required after changing table CVs)
~app.pulsaretBuffers[0].sendCollection(Signal.sineFill(2048, [1, 0.5, 0.25]));
~app.envelopeBuffers[0].sendCollection(Signal.hanningWindow(2048));

// Load from a sound file into the buffer
~app.pulsaretBuffers[0].read(~app.tablesPath ++ "my_waveform.wav");


// =====================================================================
// 9. MIDI MAPPING
// =====================================================================

// MIDI is initialized automatically on boot.
// GUI method: Ctrl+click (or right-click) any slider -> move a MIDI knob.

// --- Learn mode ---
~app.midiMapper.learn(~app.data.data_main[0][0]);  // learn for fundamental
~app.midiMapper.learn(~app.data.data_main[0][0], {|cc, chan|
	("Mapped CC" + cc + "ch" + chan).postln;
});
~app.midiMapper.cancelLearn;

// --- Direct mapping ---
// map(ccNumber, channel, cv)
// channel: 0-15 for specific, nil for any
~app.midiMapper.map(1, 0, ~app.data.data_main[0][0]);    // CC1 ch0 -> fundamental
~app.midiMapper.map(74, nil, ~app.data.data_main[0][1]);  // CC74 any ch -> formant 1

// --- Managing mappings ---
~app.midiMapper.printMappings;  // print all mappings
~app.midiMapper.getMappings;    // get as Dictionary
~app.midiMapper.unmap(74, nil); // remove specific mapping
~app.midiMapper.clearAll;       // remove all mappings

// --- Save / load ---
~app.midiMapper.save(~app.presetsPath ++ "midi_map.txt");
~app.midiMapper.load(~app.presetsPath ++ "midi_map.txt");

// --- Enable / disable ---
~app.midiMapper.enable;
~app.midiMapper.disable;


// =====================================================================
// 10. LISTENING TO PARAMETER CHANGES
// =====================================================================

// Use addDependant to watch for value changes on any CV
(
~app.data.data_main[0][0].addDependant({|cv, what, val|
	if (what == \value) {
		("Fundamental changed to:" + val).postln;
	};
});
)

// Remove the listener
~app.data.data_main[0][0].removeDependant(~myListener);

// Watch multiple parameters
(
var names = ["fund", "form1", "form2", "form3"];
4.do{|i|
	~app.data.data_main[0][i].addDependant({|cv, what, val|
		if (what == \value) {
			(names[i] + "=" + val).postln;
		};
	});
};
)


// =====================================================================
// 11. AUTOMATION EXAMPLES
// =====================================================================

// --- Sweep fundamental frequency ---
(
fork {
	var dur = 10;
	var steps = (dur * 30).asInteger;
	steps.do{|i|
		var t = i / (steps - 1);
		~app.data.data_main[0][0].value = t.linexp(0, 1, 50, 2000);
		(dur / steps).wait;
	};
};
)

// --- Random parameter walker ---
(
~walker = fork {
	loop {
		~app.data.data_main[0][0].value = exprand(50, 1000);
		~app.data.data_main[0][1].value = exprand(0.1, 10);
		~app.data.data_main[0][7].value = rrand(-1.0, 1.0);
		rrand(0.1, 0.5).wait;
	};
};
)
~walker.stop;  // stop the walker

// --- Sequence through table positions ---
(
~seq = fork {
	var positions = [0, 512, 1024, 1536, 2047];
	~app.scrubbTask.tasks[0].play;
	loop {
		positions.do{|pos|
			~app.data.data_scrubber[0].value = pos;
			0.5.wait;
		};
	};
};
)
~seq.stop;

// --- Crossfade between two parameter sets ---
(
var stateA = [220, 2.0, 0.8, 0.0];   // [fund, formant1, amp1, pan1]
var stateB = [880, 8.0, 0.3, 0.7];
var indices = [0, 1, 10, 7];

fork {
	100.do{|i|
		var blend = i / 99;
		indices.do{|idx, j|
			~app.data.data_main[0][idx].value = stateA[j].blend(stateB[j], blend);
		};
		0.05.wait;
	};
};
)

// --- Modulate with code (bypass internal modulators) ---
(
~codeMod = fork {
	var phase = 0;
	loop {
		~app.data.data_main[0][0].value = 200 + (sin(phase) * 100);
		phase = phase + 0.1;
		0.03.wait;
	};
};
)
~codeMod.stop;


// =====================================================================
// 12. APPLICATION INFO
// =====================================================================

// Number of instances
~app.numInstances;

// Number of channels
~app.numChannels;

// Paths
~app.tablesPath;
~app.filesPath;
~app.presetsPath;

// Install path (class method)
NuPG_Application.installPath;

// Access GUI components
~app.main;         // main slider GUI
~app.modulators;   // modulators GUI
~app.control;      // control view
~app.presets;      // presets view
~app.groupsOffset; // group offset GUI
~app.masking;      // masking GUI
~app.fourier;      // fourier GUI
~app.sieves;       // sieves GUI


// =====================================================================
// PARAMETER SPEC REFERENCE
// =====================================================================

/*
data_main[inst][index]:  (13 per instance)
  0  - fundamental frequency    1-3000 Hz    exp
  1  - formant frequency 1      0.05-16 Hz   exp
  2  - formant frequency 2      0.05-16 Hz   exp
  3  - formant frequency 3      0.05-16 Hz   exp
  4  - envelope dilation 1      0.0-2.0      lin
  5  - envelope dilation 2      0.0-2.0      lin
  6  - envelope dilation 3      0.01-2.0     lin
  7  - pan 1                    -1.0 to 1.0  lin
  8  - pan 2                    -1.0 to 1.0  lin
  9  - pan 3                    -1.0 to 1.0  lin
  10 - amplitude 1              0.0-1.0      lin
  11 - amplitude 2              0.0-1.0      lin
  12 - amplitude 3              0.0-1.0      lin

data_modulators[inst][index]:  (3 per instance)
  0 - FM amount                 0.0-16.0     lin
  1 - FM ratio                  0.0-16.0     lin
  2 - flux amount               0.0-2.0      lin

data_groupsOffset[inst][index]:  (3 per instance)
  0 - offset 1                  0.0-1.0      lin
  1 - offset 2                  0.0-1.0      lin
  2 - offset 3                  0.0-1.0      lin

data_modulator1..4[inst][index]:  (3 per modulator)
  0 - type                      0-4          lin  (0=off, 1=sine, 2=tri, 3=saw, 4=square)
  1 - frequency                 0.001-150 Hz lin
  2 - depth                     0-10         lin

data_overlapMorph[inst][index]:  (6 per instance, OscOS only)
  0 - rate                      0.01-10 Hz   exp
  1 - depth                     0.0-1.0      lin
  2 - shape                     0-4          lin  (0=sine, 1=tri, 2=saw, 3=random, 4=chaos)
  3 - min overlap               0.1-100      lin
  4 - max overlap               0.1-100      lin
  5 - spread                    0.0-1.0      lin

data_matrix[inst][mod 0-3][param 0-12]:
  Binary toggles (0 or 1) routing modulators to parameters.
  Mod columns: 0-3 (modulator 1-4)
  Param rows:  0=fund, 1-3=formants, 4-6=envDil, 7-9=pan, 10-12=amp

data_burstMask[inst]:
  [0] burst    1-2999   lin
  [1] rest     0-2998   lin

data_channelMask[inst]:
  [0] channel  0-1500   lin
  [1] center   0-1      lin

data_sieveMask[inst]:
  [0] size     1-100    lin
  [1] sequence (array of 100 values, 0-1)

data_probabilityMaskSingular[inst]:   0.0-1.0   lin
data_trainDuration[inst]:             0.3-120 s  lin
data_scrubber[inst]:                  0-2047     lin

Table CVs (2048-sample arrays, range -1 to 1):
  data_pulsaret, data_envelope, data_fundamentalFrequency,
  data_formantFrequencyOne/Two/Three,
  data_panOne/Two/Three, data_ampOne/Two/Three,
  data_envelopeMulOne/Two/Three,
  data_modulationAmount, data_modulationRatio,
  data_multiParamModulation, data_probabilityMask

Table min/max [max, min] pairs:
  data_pulsaret_maxMin          [-1, 1]
  data_envelope_maxMin          [-1, 1]
  data_fundamentalFrequency_maxMin  [0, 20]
  data_formantFrequencyOne_maxMin   [0, 10]
  data_formantFrequencyTwo_maxMin   [0, 10]
  data_formantFrequencyThree_maxMin [0, 10]
  data_panOne_maxMin            [-1, 1]
  data_panTwo_maxMin            [-1, 1]
  data_panThree_maxMin          [-1, 1]
  data_ampOne_maxMin            [0, 1]
  data_ampTwo_maxMin            [0, 1]
  data_ampThree_maxMin          [0, 1]
  data_envelopeMulOne_maxMin    [0, 1]
  data_envelopeMulTwo_maxMin    [0, 1]
  data_envelopeMulThree_maxMin  [0, 1]
  data_modulationAmount_maxMin  [0, 10]
  data_modulationRatio_maxMin   [0, 10]
  data_mulParamModulation_maxMin [0, 10]
  data_probabilityMask_maxMin   [0, 1]

Morph easing curves:
  \linear, \sine, \quad, \cubic, \quart,
  \expo, \circ, \back, \elastic
*/
