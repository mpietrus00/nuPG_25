/*
nuPG Rungler & Ring Divisions
=============================

Implementations inspired by Rob Hordijk's Rungler circuit and ring divider
concepts from the Benjolin and Blippoo Box synthesizers.

RUNGLER:
--------
The Rungler creates chaotic but deterministic patterns by:
1. Comparing two oscillators (when osc1 crosses osc2)
2. Feeding comparison result into an 8-bit shift register
3. Summing shift register bits through a resistor ladder -> stepped CV
4. Output is neither random nor periodic - depends on oscillator ratio

When oscillators are harmonically related: periodic patterns
When slightly detuned: slowly evolving chaos
When unrelated: complex non-repeating sequences

RING DIVISIONS:
---------------
Divide a frequency by integers to create subharmonic triggers.
Creates polyrhythmic relationships when multiple dividers interact.

Prerequisites:
  ~app = NuPG_Application(1, 1).boot;
*/


// =====================================================================
// 1. BASIC RUNGLER IMPLEMENTATION
// =====================================================================

// The Rungler uses two oscillators and an 8-bit shift register
// This implementation uses LocalBuf for the shift register state

(
~makeRungler = { |osc1Freq=100, osc2Freq=103, clockFreq=50|
	{
		var osc1 = LFTri.ar(osc1Freq);
		var osc2 = LFTri.ar(osc2Freq);
		var clock = Impulse.ar(clockFreq);

		// Comparator: 1 when osc1 > osc2, else 0
		var compare = (osc1 > osc2);

		// 8-bit shift register using Demand + Dbufrd/Dbufwr
		var buf = LocalBuf(8).clear;
		var index = Dseries(0, 1, inf) % 8;

		// Shift and write new bit on each clock
		var shiftedBit = Demand.ar(clock, 0, Dbufrd(buf, (index - 1) % 8));
		var newBit = Demand.ar(clock, 0, Dbufwr(compare, buf, index));

		// Read all 8 bits and sum with different weights (resistor ladder)
		var bits = 8.collect { |i|
			Demand.ar(clock, 0, Dbufrd(buf, i)) * (2 ** i)
		};

		// Normalize to 0-1 range
		var rungler = Latch.ar(bits.sum / 255, clock);

		rungler
	}.play;
};
)

// Test basic rungler
~rungler = ~makeRungler.(100, 103, 50);
~rungler.free;


// =====================================================================
// 2. RUNGLER USING NUPG OSCILLATORS
// =====================================================================

// Use fundamental and formant as the two rungler oscillators
// This creates chaos that's locked to your synthesis parameters

(
SynthDef(\nuPG_rungler, { |out=0, osc1Freq=100, osc2Freq=200, clockDiv=4|
	var osc1 = LFTri.ar(osc1Freq);
	var osc2 = LFTri.ar(osc2Freq);
	var clock = Impulse.ar(osc1Freq / clockDiv);

	// Comparator
	var compare = (osc1 > osc2);

	// Simplified shift register using feedback delay
	var sr = LocalBuf(8).clear;

	// Shift register bits (using Latch for sample-and-hold behavior)
	var bit0 = Latch.ar(compare, clock);
	var bit1 = Latch.ar(Delay1.ar(bit0), clock);
	var bit2 = Latch.ar(Delay1.ar(bit1), clock);
	var bit3 = Latch.ar(Delay1.ar(bit2), clock);
	var bit4 = Latch.ar(Delay1.ar(bit3), clock);
	var bit5 = Latch.ar(Delay1.ar(bit4), clock);
	var bit6 = Latch.ar(Delay1.ar(bit5), clock);
	var bit7 = Latch.ar(Delay1.ar(bit6), clock);

	// DAC - weighted sum (resistor ladder)
	var rungler = (bit0 * 1) + (bit1 * 2) + (bit2 * 4) + (bit3 * 8) +
	              (bit4 * 16) + (bit5 * 32) + (bit6 * 64) + (bit7 * 128);

	// Normalize to 0-1
	rungler = rungler / 255;

	// Smooth slightly to reduce zipper noise
	rungler = Lag.ar(rungler, 0.001);

	Out.ar(out, rungler);
}).add;
)


// =====================================================================
// 3. RUNGLER AS FILTERÍN MODULATION SOURCE
// =====================================================================

// Rungler modulating filter cutoff - locked to fundamental/formant
(
Ndef(\nuPG_train_0)[1] = \filterIn -> { |in|
	var fund = \fundamental_frequency.kr(100);
	var formant = \formant_frequency_One.kr(400);
	var amp = \amplitude_One.kr(0.8);

	// Two oscillators for rungler
	var osc1 = LFTri.ar(fund);
	var osc2 = LFTri.ar(formant);
	var clock = Impulse.ar(fund / 4);  // clock at 1/4 fundamental

	// Comparator
	var compare = (osc1 > osc2);

	// Simple 4-bit shift register (lighter CPU)
	var bit0 = Latch.ar(compare, clock);
	var bit1 = Latch.ar(DelayN.ar(bit0, 0.1, fund.reciprocal), clock);
	var bit2 = Latch.ar(DelayN.ar(bit1, 0.1, fund.reciprocal), clock);
	var bit3 = Latch.ar(DelayN.ar(bit2, 0.1, fund.reciprocal), clock);

	// 4-bit DAC
	var rungler = ((bit0 * 1) + (bit1 * 2) + (bit2 * 4) + (bit3 * 8)) / 15;
	rungler = Lag.ar(rungler, 0.005);

	// Use rungler to modulate filter cutoff
	var cutoff = rungler.linexp(0, 1, 200, 8000);

	RLPF.ar(in, cutoff, 0.3) * amp
};
)


// =====================================================================
// 4. RING DIVISIONS (Frequency Dividers)
// =====================================================================

// Ring divisions create subharmonic triggers by dividing the fundamental

(
~ringDivisions = { |baseFreq=100, divisions=#[1, 2, 3, 4, 5, 6, 7, 8]|
	{
		var triggers = divisions.collect { |div|
			Impulse.ar(baseFreq / div)
		};
		triggers
	}.value;
};
)

// Ring division triggers as filterIn
(
Ndef(\nuPG_train_0)[1] = \filterIn -> { |in|
	var fund = \fundamental_frequency.kr(100);
	var amp = \amplitude_One.kr(0.8);

	// Triggers at fundamental and divisions
	var trig1 = Impulse.ar(fund);        // fundamental
	var trig2 = Impulse.ar(fund / 2);    // octave below
	var trig3 = Impulse.ar(fund / 3);    // fifth below octave
	var trig4 = Impulse.ar(fund / 4);    // two octaves below

	// Use ring divisions to create polyrhythmic grains
	var grain1 = GrainIn.ar(2, trig1, 0.02, in, 0, 0.25);
	var grain2 = GrainIn.ar(2, trig2, 0.04, in, -0.5, 0.25);
	var grain3 = GrainIn.ar(2, trig3, 0.06, in, 0.5, 0.25);
	var grain4 = GrainIn.ar(2, trig4, 0.08, in, 0, 0.25);

	(grain1 + grain2 + grain3 + grain4) * amp
};
)


// =====================================================================
// 5. RUNGLER-DRIVEN PARAMETER MODULATION
// =====================================================================

// Create a rungler Ndef that outputs control signals for other parameters
(
Ndef(\rungler, {
	var fund = \osc1Freq.kr(100);
	var formant = \osc2Freq.kr(103);  // slight detune for chaos
	var clockDiv = \clockDiv.kr(4);

	var osc1 = LFTri.ar(fund);
	var osc2 = LFTri.ar(formant);
	var clock = Impulse.ar(fund / clockDiv);

	var compare = (osc1 > osc2);

	// 8-bit shift register
	var bits = Array.fill(8, { |i|
		var delay = (fund.reciprocal * (i + 1)).min(0.1);
		Latch.ar(DelayN.ar(compare, 0.1, delay), clock)
	});

	// Weighted sum
	var rungler = bits.collect({ |b, i| b * (2 ** i) }).sum / 255;
	rungler = Lag.kr(A2K.kr(rungler), 0.01);

	// Output 3 different "rungs" (tap points in the shift register)
	var rung1 = (bits[0] + bits[1] * 2 + bits[2] * 4) / 7;
	var rung2 = (bits[2] + bits[3] * 2 + bits[4] * 4) / 7;
	var rung3 = (bits[5] + bits[6] * 2 + bits[7] * 4) / 7;

	[rungler, A2K.kr(Lag.ar(rung1, 0.01)), A2K.kr(Lag.ar(rung2, 0.01)), A2K.kr(Lag.ar(rung3, 0.01))]
});

// Map rungler to nuPG fundamental
Ndef(\rungler).set(\osc1Freq, 100, \osc2Freq, 103);
)

// Use rungler output to modulate formant frequency
(
~runglerToFormant = fork {
	loop {
		var rung = Ndef(\rungler).bus.getSynchronous;
		if (rung.notNil) {
			var formantHz = rung.linexp(0, 1, 100, 2000);
			~app.data.data_main[0][1].value = formantHz;
		};
		0.05.wait;
	};
};
)

// Stop rungler modulation
~runglerToFormant.stop;


// =====================================================================
// 6. BENJOLIN-STYLE DUAL RUNGLER
// =====================================================================

// The Benjolin has two oscillators that can modulate each other
// through the rungler, creating complex feedback

(
Ndef(\nuPG_train_0)[1] = \filterIn -> { |in|
	var fund = \fundamental_frequency.kr(100);
	var formant = \formant_frequency_One.kr(400);

	// Two oscillators with cross-modulation
	var osc1Freq = fund;
	var osc2Freq = formant;

	// Rungler from osc1 vs osc2
	var osc1 = LFTri.ar(osc1Freq);
	var osc2 = LFTri.ar(osc2Freq);
	var clock = Impulse.ar(fund / 2);
	var compare = (osc1 > osc2);

	// 6-bit shift register
	var bit0 = Latch.ar(compare, clock);
	var bit1 = Latch.ar(DelayN.ar(bit0, 0.1, fund.reciprocal.min(0.1)), clock);
	var bit2 = Latch.ar(DelayN.ar(bit1, 0.1, fund.reciprocal.min(0.1)), clock);
	var bit3 = Latch.ar(DelayN.ar(bit2, 0.1, fund.reciprocal.min(0.1)), clock);
	var bit4 = Latch.ar(DelayN.ar(bit3, 0.1, fund.reciprocal.min(0.1)), clock);
	var bit5 = Latch.ar(DelayN.ar(bit4, 0.1, fund.reciprocal.min(0.1)), clock);

	// Two rungler outputs from different tap points
	var rungler1 = ((bit0 * 1) + (bit1 * 2) + (bit2 * 4)) / 7;
	var rungler2 = ((bit3 * 1) + (bit4 * 2) + (bit5 * 4)) / 7;

	rungler1 = Lag.ar(rungler1, 0.002);
	rungler2 = Lag.ar(rungler2, 0.002);

	// Use runglers to modulate filter and amplitude
	var cutoff = rungler1.linexp(0, 1, 300, 6000);
	var modAmp = rungler2.linlin(0, 1, 0.3, 1);

	RLPF.ar(in, cutoff, 0.2) * modAmp * \amplitude_One.kr(0.8)
};
)


// =====================================================================
// 7. RING DIVISION POLYRHYTHMS
// =====================================================================

// Create complex polyrhythmic patterns using ring divisions
(
Ndef(\nuPG_train_0)[1] = \filterIn -> { |in|
	var fund = \fundamental_frequency.kr(100);
	var formant = \formant_frequency_One.kr(400);
	var amp = \amplitude_One.kr(0.8);
	var pan = \pan_One.kr(0);

	// Ring divisions of fundamental
	var div1 = 1, div2 = 2, div3 = 3, div4 = 5, div5 = 7;

	var trig1 = Impulse.ar(fund / div1);
	var trig2 = Impulse.ar(fund / div2);
	var trig3 = Impulse.ar(fund / div3);
	var trig4 = Impulse.ar(fund / div4);
	var trig5 = Impulse.ar(fund / div5);

	// Grain durations proportional to division
	var dur1 = formant.reciprocal.clip(0.01, 0.1);
	var dur2 = dur1 * 1.5;
	var dur3 = dur1 * 2;
	var dur4 = dur1 * 2.5;
	var dur5 = dur1 * 3;

	// Panning spread across divisions
	var g1 = GrainIn.ar(2, trig1, dur1, in, pan, amp * 0.3);
	var g2 = GrainIn.ar(2, trig2, dur2, in, pan - 0.5, amp * 0.25);
	var g3 = GrainIn.ar(2, trig3, dur3, in, pan + 0.5, amp * 0.2);
	var g4 = GrainIn.ar(2, trig4, dur4, in, pan - 0.3, amp * 0.15);
	var g5 = GrainIn.ar(2, trig5, dur5, in, pan + 0.3, amp * 0.1);

	g1 + g2 + g3 + g4 + g5
};
)


// =====================================================================
// 8. EUCLIDEAN RHYTHMS FROM RING DIVISIONS
// =====================================================================

// Euclidean rhythms distribute pulses evenly across steps
// Combined with ring divisions for complex polymetric patterns

(
// Euclidean rhythm generator
~euclidean = { |hits, steps, rotation=0|
	var pattern = Array.fill(steps, { |i|
		((i * hits) % steps) < hits
	});
	pattern.rotate(rotation)
};

// Example: E(3,8) = [1,0,0,1,0,0,1,0] - Cuban tresillo
~euclidean.(3, 8).postln;

// Example: E(5,8) = [1,0,1,1,0,1,1,0] - Cuban cinquillo
~euclidean.(5, 8).postln;
)

// Euclidean + ring division filterIn
(
Ndef(\nuPG_train_0)[1] = \filterIn -> { |in|
	var fund = \fundamental_frequency.kr(100);
	var amp = \amplitude_One.kr(0.8);

	// Base clock from fundamental
	var baseClock = Impulse.ar(fund);

	// Ring divisions
	var div2Clock = Impulse.ar(fund / 2);
	var div3Clock = Impulse.ar(fund / 3);

	// Step counter (0-7)
	var step = PulseCount.ar(baseClock) % 8;

	// Euclidean pattern E(3,8) as mask
	var euclideanMask = Select.ar(step, [1, 0, 0, 1, 0, 0, 1, 0]);

	// Masked trigger
	var euclideanTrig = baseClock * euclideanMask;

	// Grains on euclidean hits
	var grains = GrainIn.ar(2, euclideanTrig, 0.05, in, 0, amp);

	// Add div3 accents
	var accents = GrainIn.ar(2, div3Clock, 0.03, in, 0, amp * 0.5);

	grains + accents
};
)


// =====================================================================
// 9. RUNGLER-CONTROLLED TABLE GENERATION
// =====================================================================

// Generate pulsaret/envelope tables from rungler patterns
(
~runglerTable = { |osc1Freq=100, osc2Freq=103, length=2048|
	var table = Array.newClear(length);
	var shiftReg = 0;

	length.do { |i|
		var phase = i / length * 2pi;
		var osc1 = sin(phase * osc1Freq);
		var osc2 = sin(phase * osc2Freq);
		var compare = (osc1 > osc2).asInteger;

		// Shift register operation
		shiftReg = ((shiftReg << 1) | compare) & 255;  // 8-bit mask

		// Normalize to -1 to 1
		table[i] = (shiftReg / 127.5) - 1;
	};

	table
};

// Generate and apply rungler table to pulsaret
~app.data.data_pulsaret[0].value = ~runglerTable.(7, 11);  // coprime for chaos
~app.pulsaretBuffers[0].sendCollection(~app.data.data_pulsaret[0].value);
)

// Generate envelope from rungler (smoothed)
(
~runglerEnvelope = { |osc1Freq=5, osc2Freq=7, length=2048|
	var table = ~runglerTable.(osc1Freq, osc2Freq, length);
	// Smooth with moving average
	var smoothed = Array.newClear(length);
	var windowSize = 32;
	length.do { |i|
		var sum = 0;
		windowSize.do { |j|
			sum = sum + table[(i + j) % length];
		};
		smoothed[i] = sum / windowSize;
	};
	// Normalize
	var min = smoothed.minItem;
	var max = smoothed.maxItem;
	smoothed.collect { |v| (v - min) / (max - min) * 2 - 1 }
};

~app.data.data_envelope[0].value = ~runglerEnvelope.(5, 8);
~app.envelopeBuffers[0].sendCollection(~app.data.data_envelope[0].value);
)


// =====================================================================
// 10. RING MOD WITH RING DIVISIONS
// =====================================================================

// Ring modulation at subharmonic frequencies
(
Ndef(\nuPG_train_0)[1] = \filterIn -> { |in|
	var fund = \fundamental_frequency.kr(100);
	var amp = \amplitude_One.kr(0.8);

	// Ring modulators at subharmonic frequencies
	var mod1 = SinOsc.ar(fund / 2);      // octave below
	var mod2 = SinOsc.ar(fund / 3);      // fifth below octave
	var mod3 = SinOsc.ar(fund / 5);      // major third below two octaves

	// Mix of ring modulated signals
	var rm1 = in * mod1 * 0.4;
	var rm2 = in * mod2 * 0.3;
	var rm3 = in * mod3 * 0.3;

	(in * 0.5) + (rm1 + rm2 + rm3) * amp
};
)


// =====================================================================
// 11. HORDIJK-STYLE TWIN PEAK FILTER WITH RUNGLER
// =====================================================================

// Hordijk's Twin Peak filter has two resonant peaks that can be
// modulated independently - we'll use rungler outputs for this

(
Ndef(\nuPG_train_0)[1] = \filterIn -> { |in|
	var fund = \fundamental_frequency.kr(100);
	var formant = \formant_frequency_One.kr(400);
	var amp = \amplitude_One.kr(0.8);

	// Rungler for modulation
	var osc1 = LFTri.ar(fund);
	var osc2 = LFTri.ar(formant * 1.03);  // slight detune
	var clock = Impulse.ar(fund / 3);
	var compare = (osc1 > osc2);

	// 4-bit shift register for two 2-bit outputs
	var bit0 = Latch.ar(compare, clock);
	var bit1 = Latch.ar(DelayN.ar(bit0, 0.1, 0.01), clock);
	var bit2 = Latch.ar(DelayN.ar(bit1, 0.1, 0.01), clock);
	var bit3 = Latch.ar(DelayN.ar(bit2, 0.1, 0.01), clock);

	var rung1 = Lag.ar((bit0 + bit1 * 2) / 3, 0.005);
	var rung2 = Lag.ar((bit2 + bit3 * 2) / 3, 0.005);

	// Twin peak frequencies modulated by rungler
	var peak1Freq = rung1.linexp(0, 1, 200, 2000);
	var peak2Freq = rung2.linexp(0, 1, 500, 5000);

	// Two resonant bandpass filters
	var peak1 = BPF.ar(in, peak1Freq, 0.1);
	var peak2 = BPF.ar(in, peak2Freq, 0.1);

	// Mix peaks with dry signal
	((in * 0.3) + (peak1 * 0.4) + (peak2 * 0.3)) * amp
};
)


// =====================================================================
// 12. CHAOS MODES - FREQUENCY RATIOS
// =====================================================================

// Different oscillator ratios create different chaos behaviors
(
~chaosPresets = (
	// Harmonic ratios = periodic patterns
	\octave: [1, 2],
	\fifth: [2, 3],
	\fourth: [3, 4],
	\majorThird: [4, 5],

	// Slightly detuned = slow evolving chaos
	\slowChaos1: [100, 103],
	\slowChaos2: [100, 107],
	\slowChaos3: [100, 113],

	// Irrational ratios = maximum chaos
	\golden: [1, 1.618034],
	\sqrt2: [1, 1.414214],
	\pi: [1, 3.141593],

	// Coprime integers = complex patterns
	\coprime1: [7, 11],
	\coprime2: [11, 13],
	\coprime3: [13, 17],
	\coprime4: [17, 19]
);

~setChaosMode = { |mode, baseFreq=100|
	var ratio = ~chaosPresets[mode];
	if (ratio.notNil) {
		var freq1 = baseFreq * ratio[0];
		var freq2 = baseFreq * ratio[1];
		Ndef(\rungler).set(\osc1Freq, freq1, \osc2Freq, freq2);
		("Chaos mode:" + mode + "- freqs:" + freq1 + "," + freq2).postln;
	} {
		"Unknown chaos mode".postln;
	};
};
)

// Usage:
~setChaosMode.(\slowChaos1, 1);
~setChaosMode.(\golden, 100);
~setChaosMode.(\coprime2, 10);


// =====================================================================
// 13. CLEAR ALL FILTERS
// =====================================================================

(
~clearFilters = { |instance=0|
	Ndef((\nuPG_train_ ++ instance).asSymbol)[1] = nil;
	Ndef((\nuPG_train_ ++ instance).asSymbol)[2] = nil;
	Ndef((\nuPG_train_oscos_ ++ instance).asSymbol)[1] = nil;
	Ndef((\nuPG_train_oscos_ ++ instance).asSymbol)[2] = nil;
	("Filters cleared for instance" + instance).postln;
};

~clearFilters.(0);
)

// Stop rungler Ndef
Ndef(\rungler).clear;
