// NuPG_Synthesis_OscOS.sc
// Non-aliasing variant using OscOS from OversamplingOscillators plugin
// Provides band-limited wavetable oscillation for cleaner high-frequency content
// Enhanced with sub-sample accurate triggering and explicit overlap control

// Pseudo-UGen for OscOS-based pulsar generation
NuPG_OscOS {

	*ar {
		arg channels_number = 2, trigger, grain_duration, pulsar_buffer, rate, panning, envelope_buffer;
		var phase, pulsaret, envelope, output;

		// Use Phasor triggered by impulse for wavetable position
		phase = Phasor.ar(trigger, rate, 0, 1);

		// OscOS provides oversampled wavetable lookup (requires OversamplingOscillators plugin)
		// Falls back to Osc if OscOS not available
		pulsaret = OscOS.ar(pulsar_buffer, rate * BufSampleRate.ir(pulsar_buffer) / BufFrames.ir(pulsar_buffer), 0, 4);

		// Envelope from buffer using same oversampled approach
		envelope = if(envelope_buffer > 0,
			{ OscOS.ar(envelope_buffer, rate * BufSampleRate.ir(envelope_buffer) / BufFrames.ir(envelope_buffer), 0, 4) },
			{ EnvGen.ar(Env.sine(grain_duration), trigger) }
		);

		// Apply grain envelope windowing
		envelope = envelope * EnvGen.ar(
			Env([0, 1, 1, 0], [0.001, grain_duration - 0.002, 0.001]),
			trigger
		);

		output = pulsaret * envelope;

		// Pan according to channels_number: mono (1) or stereo (2)
		output = if(channels_number == 1, output, Pan2.ar(output, panning));

		^output;
	}
}

// BLIT-based pseudo-UGen for truly band-limited pulsar synthesis
NuPG_BLIT {

	*ar {
		arg channels_number = 2, trigger, grain_duration, fundamental_freq, formant_freq, panning, num_harmonics = 16;
		var pulsaret, envelope, output;

		// Band-limited impulse train for the pulsaret
		// Blip provides anti-aliased impulse trains
		pulsaret = Blip.ar(formant_freq, num_harmonics);

		// Grain envelope
		envelope = EnvGen.ar(
			Env([0, 1, 1, 0], [0.001, grain_duration - 0.002, 0.001]),
			trigger
		);

		output = pulsaret * envelope;
		// Pan according to channels_number: mono (1) or stereo (2)
		output = if(channels_number == 1, output, Pan2.ar(output, panning));

		^output;
	}
}


// Main synthesis class with OscOS variant
// Enhanced with sub-sample accurate triggering from reference implementation
NuPG_Synthesis_OscOS {

	var <>trainInstances;

	// Create train instances using OscOS for non-aliasing synthesis
	trains {|numInstances = 3, numChannels = 2|

		trainInstances = numInstances.collect{|i|

			Ndef((\nuPG_train_oscos_ ++ i).asSymbol, {
				//buffers
				arg pulsaret_buffer, envelope_buffer = -1, frequency_buffer,
				//flux, modulations
				allFluxAmt = 0.0, allFluxAmt_loop = 1, fluxRate = 40,
				fmRatio = 5, fmRatio_loop = 1, fmAmt = 5, fmAmt_loop = 1,
				modMul = 3, modAdd = 3,
				modulationMode = 0,  // fmIndex removed - unused
				//fundamental modulation on/off
				fundamentalMod_one_active = 0, fundamentalMod_two_active = 0, fundamentalMod_three_active = 0, fundamentalMod_four_active = 0,
				fundamentalMod_five_active = 0, fundamentalMod_six_active = 0, fundamentalMod_seven_active = 0, fundamentalMod_eight_active = 0,
				//modulation
				modulator_type_one = 0, modulation_frequency_one = 1, modulation_index_one = 0.0,
				modulator_type_two = 0, modulation_frequency_two = 1, modulation_index_two = 0.0,
				modulator_type_three = 0, modulation_frequency_three = 1, modulation_index_three = 0.0,
				modulator_type_four = 0, modulation_frequency_four = 1, modulation_index_four = 0.0,
				modulator_type_five = 0, modulation_frequency_five = 1, modulation_index_five = 0.0,
				modulator_type_six = 0, modulation_frequency_six = 1, modulation_index_six = 0.0,
				modulator_type_seven = 0, modulation_frequency_seven = 1, modulation_index_seven = 0.0,
				modulator_type_eight = 0, modulation_frequency_eight = 1, modulation_index_eight = 0.0,
				//fundamental, formant, phase
				fundamental_frequency = 5, fundamental_frequency_loop = 1,
				phase = 0.0,
				//probability
				probability = 1.0, probability_loop = 1.0,
				//probability modulators
				probabilityMod_one_active = 0, probabilityMod_two_active = 0, probabilityMod_three_active = 0, probabilityMod_four_active = 0,
				probabilityMod_five_active = 0, probabilityMod_six_active = 0, probabilityMod_seven_active = 0, probabilityMod_eight_active = 0,
				//masks
				burst = 5, rest = 0,
				chanMask = 0, centerMask = 1,
				sieveMaskOn = 0, sieveSequence = #[1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1],
				sieveMod = 16,
				//formants (formantModel removed - unused)
				formant_frequency_One  = 150, formant_frequency_Two = 20, formant_frequency_Three = 90,
				formant_frequency_One_loop = 1, formant_frequency_Two_loop = 1, formant_frequency_Three_loop =1,
				formantOneMod_one_active = 0, formantOneMod_two_active = 0, formantOneMod_three_active = 0, formantOneMod_four_active = 0,
				formantOneMod_five_active = 0, formantOneMod_six_active = 0, formantOneMod_seven_active = 0, formantOneMod_eight_active = 0,
				formantTwoMod_one_active = 0, formantTwoMod_two_active = 0, formantTwoMod_three_active = 0, formantTwoMod_four_active = 0,
				formantTwoMod_five_active = 0, formantTwoMod_six_active = 0, formantTwoMod_seven_active = 0, formantTwoMod_eight_active = 0,
				formantThreeMod_one_active = 0, formantThreeMod_two_active = 0, formantThreeMod_three_active = 0, formantThreeMod_four_active = 0,
				formantThreeMod_five_active = 0, formantThreeMod_six_active = 0, formantThreeMod_seven_active = 0, formantThreeMod_eight_active = 0,
				//env
				envMul_One = 1, envMul_Two = 1, envMul_Three = 1,
				envMul_One_loop = 1, envMul_Two_loop = 1, envMul_Three_loop = 1,
				//env modulators
				envOneMod_one_active = 0, envOneMod_two_active = 0, envOneMod_three_active = 0, envOneMod_four_active = 0,
				envOneMod_five_active = 0, envOneMod_six_active = 0, envOneMod_seven_active = 0, envOneMod_eight_active = 0,
				envTwoMod_one_active = 0, envTwoMod_two_active = 0, envTwoMod_three_active = 0, envTwoMod_four_active = 0,
				envTwoMod_five_active = 0, envTwoMod_six_active = 0, envTwoMod_seven_active = 0, envTwoMod_eight_active = 0,
				envThreeMod_one_active = 0, envThreeMod_two_active = 0, envThreeMod_three_active = 0, envThreeMod_four_active = 0,
				envThreeMod_five_active = 0, envThreeMod_six_active = 0, envThreeMod_seven_active = 0, envThreeMod_eight_active = 0,
				//amp
				amplitude_One = 1, amplitude_Two = 1, amplitude_Three = 1,
				amplitude_One_loop = 1, amplitude_Two_loop = 1, amplitude_Three_loop = 1,
				//amp modulators
				ampOneMod_one_active = 0, ampOneMod_two_active = 0, ampOneMod_three_active = 0, ampOneMod_four_active = 0,
				ampOneMod_five_active = 0, ampOneMod_six_active = 0, ampOneMod_seven_active = 0, ampOneMod_eight_active = 0,
				ampTwoMod_one_active = 0, ampTwoMod_two_active = 0, ampTwoMod_three_active = 0, ampTwoMod_four_active = 0,
				ampTwoMod_five_active = 0, ampTwoMod_six_active = 0, ampTwoMod_seven_active = 0, ampTwoMod_eight_active = 0,
				ampThreeMod_one_active = 0, ampThreeMod_two_active = 0, ampThreeMod_three_active = 0, ampThreeMod_four_active = 0,
				ampThreeMod_five_active = 0, ampThreeMod_six_active = 0, ampThreeMod_seven_active = 0, ampThreeMod_eight_active = 0,
				globalAmplitude = 1.0,
				mute = 0,
				amplitude_local_One = 1, amplitude_local_Two = 1, amplitude_local_Three = 1,
				//panning
				pan_One = 0, pan_Two = 0, pan_Three = 0,
				pan_One_loop = 0, pan_Two_loop = 0, pan_Three_loop = 0,
				//pan modulators
				panOneMod_one_active = 0, panOneMod_two_active = 0, panOneMod_three_active = 0, panOneMod_four_active = 0,
				panOneMod_five_active = 0, panOneMod_six_active = 0, panOneMod_seven_active = 0, panOneMod_eight_active = 0,
				panTwoMod_one_active = 0, panTwoMod_two_active = 0, panTwoMod_three_active = 0, panTwoMod_four_active = 0,
				panTwoMod_five_active = 0, panTwoMod_six_active = 0, panTwoMod_seven_active = 0, panTwoMod_eight_active = 0,
				panThreeMod_one_active = 0, panThreeMod_two_active = 0, panThreeMod_three_active = 0, panThreeMod_four_active = 0,
				panThreeMod_five_active = 0, panThreeMod_six_active = 0, panThreeMod_seven_active = 0, panThreeMod_eight_active = 0,
				//offset
				offset_1 = 0, offset_2 = 0, offset_3 = 0,
				//offset modulators
				offset_1_one_active = 0, offset_1_two_active = 0, offset_1_three_active = 0, offset_1_four_active = 0,
				offset_1_five_active = 0, offset_1_six_active = 0, offset_1_seven_active = 0, offset_1_eight_active = 0,
				offset_2_one_active = 0, offset_2_two_active = 0, offset_2_three_active = 0, offset_2_four_active = 0,
				offset_2_five_active = 0, offset_2_six_active = 0, offset_2_seven_active = 0, offset_2_eight_active = 0,
				offset_3_one_active = 0, offset_3_two_active = 0, offset_3_three_active = 0, offset_3_four_active = 0,
				offset_3_five_active = 0, offset_3_six_active = 0, offset_3_seven_active = 0, offset_3_eight_active = 0,
				// Flux rate modulation (row 13)
				fluxRateMod_one_active = 0, fluxRateMod_two_active = 0, fluxRateMod_three_active = 0, fluxRateMod_four_active = 0,
				fluxRateMod_five_active = 0, fluxRateMod_six_active = 0, fluxRateMod_seven_active = 0, fluxRateMod_eight_active = 0,
				// Flux amount modulation (row 14)
				fluxAmtMod_one_active = 0, fluxAmtMod_two_active = 0, fluxAmtMod_three_active = 0, fluxAmtMod_four_active = 0,
				fluxAmtMod_five_active = 0, fluxAmtMod_six_active = 0, fluxAmtMod_seven_active = 0, fluxAmtMod_eight_active = 0,
				// FM ratio modulation (row 15)
				fmRatioMod_one_active = 0, fmRatioMod_two_active = 0, fmRatioMod_three_active = 0, fmRatioMod_four_active = 0,
				fmRatioMod_five_active = 0, fmRatioMod_six_active = 0, fmRatioMod_seven_active = 0, fmRatioMod_eight_active = 0,
				// FM amount modulation (row 16)
				fmAmtMod_one_active = 0, fmAmtMod_two_active = 0, fmAmtMod_three_active = 0, fmAmtMod_four_active = 0,
				fmAmtMod_five_active = 0, fmAmtMod_six_active = 0, fmAmtMod_seven_active = 0, fmAmtMod_eight_active = 0,
				// Phase modulation (row 17)
				phaseMod_one_active = 0, phaseMod_two_active = 0, phaseMod_three_active = 0, phaseMod_four_active = 0,
				phaseMod_five_active = 0, phaseMod_six_active = 0, phaseMod_seven_active = 0, phaseMod_eight_active = 0,

				group_1_onOff = 0, group_2_onOff = 0, group_3_onOff = 0,
				// Oversampling factor for OscOS (2, 4, or 8)
				oversample = 4,
				// Overlap morph (fmIndex + formantModel removed to make room)
				overlapMorphRate = 0.1,
				overlapMorphDepth = 0,
				overlapMorphMin = 1,
				overlapMorphMax = 10,
				overlapPhaseOffset = 0,
				overlapMorphShape = 0;

				// Sub-sample accurate trigger generation variables
				var stepPhase, stepTrigger, stepSlope;
				var subSampleOffset, accumulator;
				var triggerFreq;
				// Formant/grain variables
				var ffreq_One, ffreq_Two, ffreq_Three;
				var grainSlope_One, grainSlope_Two, grainSlope_Three;
				// Overlap derived from envMul (dilation control)
				var overlap_One, overlap_Two, overlap_Three;
				var maxOverlap_One, maxOverlap_Two, maxOverlap_Three;
				var windowSlope_One, windowSlope_Two, windowSlope_Three;
				var windowPhase_One, windowPhase_Two, windowPhase_Three;
				var grainPhase_One, grainPhase_Two, grainPhase_Three;
				// Envelope and pulsaret
				var pulsaret_One, pulsaret_Two, pulsaret_Three;
				var envelope_One, envelope_Two, envelope_Three;
				var pulsar_1, pulsar_2, pulsar_3;
				// FM
				var freqEnvPlayBuf_One, freqEnvPlayBuf_Two, freqEnvPlayBuf_Three;
				var ffreq_One_modulated, ffreq_Two_modulated, ffreq_Three_modulated;
				// Legacy variables
				var envM_One, envM_Two, envM_Three;
				var grainDur_One, grainDur_Two, grainDur_Three;
				var trigFreqFlux, grainFreqFlux, ampFlux;
				var channelMask;
				var sieveMask;
				var mix;
				var sendTrigger;
				//mod
				var mod_one, mod_two, mod_three, mod_four;
				var mod_five, mod_six, mod_seven, mod_eight;
				//fund
				var fundamentalMod_one, fundamentalMod_two, fundamentalMod_three, fundamentalMod_four;
				var fundamentalMod_five, fundamentalMod_six, fundamentalMod_seven, fundamentalMod_eight;
				//for 1
				var formantOneMod_one, formantOneMod_two, formantOneMod_three, formantOneMod_four;
				var formantOneMod_five, formantOneMod_six, formantOneMod_seven, formantOneMod_eight;
				//for 2
				var formantTwoMod_one, formantTwoMod_two, formantTwoMod_three, formantTwoMod_four;
				var formantTwoMod_five, formantTwoMod_six, formantTwoMod_seven, formantTwoMod_eight;
				//for 3
				var formantThreeMod_one, formantThreeMod_two, formantThreeMod_three, formantThreeMod_four;
				var formantThreeMod_five, formantThreeMod_six, formantThreeMod_seven, formantThreeMod_eight;
				//pan
				var panOneMod_one, panOneMod_two, panOneMod_three, panOneMod_four;
				var panOneMod_five, panOneMod_six, panOneMod_seven, panOneMod_eight;
				var panTwoMod_one, panTwoMod_two, panTwoMod_three, panTwoMod_four;
				var panTwoMod_five, panTwoMod_six, panTwoMod_seven, panTwoMod_eight;
				var panThreeMod_one, panThreeMod_two, panThreeMod_three, panThreeMod_four;
				var panThreeMod_five, panThreeMod_six, panThreeMod_seven, panThreeMod_eight;
				//amp
				var ampOneMod_one, ampOneMod_two, ampOneMod_three, ampOneMod_four;
				var ampOneMod_five, ampOneMod_six, ampOneMod_seven, ampOneMod_eight;
				var ampTwoMod_one, ampTwoMod_two, ampTwoMod_three, ampTwoMod_four;
				var ampTwoMod_five, ampTwoMod_six, ampTwoMod_seven, ampTwoMod_eight;
				var ampThreeMod_one, ampThreeMod_two, ampThreeMod_three, ampThreeMod_four;
				var ampThreeMod_five, ampThreeMod_six, ampThreeMod_seven, ampThreeMod_eight;
				// New targets: flux, FM, phase, offset, probability modulation vars
				var fluxRateMod_one, fluxRateMod_two, fluxRateMod_three, fluxRateMod_four;
				var fluxRateMod_five, fluxRateMod_six, fluxRateMod_seven, fluxRateMod_eight;
				var fluxAmtMod_one, fluxAmtMod_two, fluxAmtMod_three, fluxAmtMod_four;
				var fluxAmtMod_five, fluxAmtMod_six, fluxAmtMod_seven, fluxAmtMod_eight;
				var fmRatioMod_one, fmRatioMod_two, fmRatioMod_three, fmRatioMod_four;
				var fmRatioMod_five, fmRatioMod_six, fmRatioMod_seven, fmRatioMod_eight;
				var fmAmtMod_one, fmAmtMod_two, fmAmtMod_three, fmAmtMod_four;
				var fmAmtMod_five, fmAmtMod_six, fmAmtMod_seven, fmAmtMod_eight;
				var phaseMod_one, phaseMod_two, phaseMod_three, phaseMod_four;
				var phaseMod_five, phaseMod_six, phaseMod_seven, phaseMod_eight;
				var offsetOneMod_one, offsetOneMod_two, offsetOneMod_three, offsetOneMod_four;
				var offsetOneMod_five, offsetOneMod_six, offsetOneMod_seven, offsetOneMod_eight;
				var offsetTwoMod_one, offsetTwoMod_two, offsetTwoMod_three, offsetTwoMod_four;
				var offsetTwoMod_five, offsetTwoMod_six, offsetTwoMod_seven, offsetTwoMod_eight;
				var offsetThreeMod_one, offsetThreeMod_two, offsetThreeMod_three, offsetThreeMod_four;
				var offsetThreeMod_five, offsetThreeMod_six, offsetThreeMod_seven, offsetThreeMod_eight;
				var probabilityMod_one, probabilityMod_two, probabilityMod_three, probabilityMod_four;
				var probabilityMod_five, probabilityMod_six, probabilityMod_seven, probabilityMod_eight;
				// Group offset triggers and accumulators
				var stepTrigger_One, stepTrigger_Two, stepTrigger_Three;
				var accumulator_One, accumulator_Two, accumulator_Three;

				// ============================================================
				// HELPER FUNCTIONS for sub-sample accurate triggering
				// From reference implementation
				// ============================================================

				// Convert phase ramp to trigger at wrap-around point
				var rampToTrig = { |phaseIn|
					var history = Delay1.ar(phaseIn);
					var delta = (phaseIn - history);
					var sum = (phaseIn + history);
					var trig = (delta / max(0.0001, sum)).abs > 0.5;
					Trig1.ar(trig, SampleDur.ir);
				};

				// Get the slope (rate of change) of the phase
				var rampToSlope = { |phaseIn|
					var history = Delay1.ar(phaseIn);
					var delta = (phaseIn - history);
					delta.wrap(-0.5, 0.5);
				};

				// Sample counter with sub-sample offset for precise timing
				var accumulatorSubSample = { |trig, subSampleOff|
					var accum = Duty.ar(SampleDur.ir, trig, Dseries(0, 1));
					accum + subSampleOff;
				};

				// Calculate sub-sample offset for trigger precision
				var getSubSampleOffset = { |phaseIn, slope, trig|
					var sampleCount = phaseIn - (slope < 0) / max(0.0001, slope);
					Latch.ar(sampleCount, trig);
				};

				// ============================================================
				// FLUX AND MODULATION SETUP
				// ============================================================

				//flux
				allFluxAmt = allFluxAmt * allFluxAmt_loop;
				trigFreqFlux = allFluxAmt;
				grainFreqFlux = allFluxAmt;
				ampFlux = allFluxAmt;

				//fm
				fmRatio = fmRatio * fmRatio_loop;
				fmAmt = fmAmt * fmAmt_loop;

				//additional modulators
				mod_one = NuPG_ModulatorSet.ar(
					type: modulator_type_one,
					modulation_frequency: modulation_frequency_one);
				mod_two = NuPG_ModulatorSet.ar(
					type: modulator_type_two,
					modulation_frequency: modulation_frequency_two);
				mod_three = NuPG_ModulatorSet.ar(
					type: modulator_type_three,
					modulation_frequency: modulation_frequency_three);
				mod_four = NuPG_ModulatorSet.ar(
					type: modulator_type_four,
					modulation_frequency: modulation_frequency_four);
				mod_five = NuPG_ModulatorSet.ar(
					type: modulator_type_five,
					modulation_frequency: modulation_frequency_five);
				mod_six = NuPG_ModulatorSet.ar(
					type: modulator_type_six,
					modulation_frequency: modulation_frequency_six);
				mod_seven = NuPG_ModulatorSet.ar(
					type: modulator_type_seven,
					modulation_frequency: modulation_frequency_seven);
				mod_eight = NuPG_ModulatorSet.ar(
					type: modulator_type_eight,
					modulation_frequency: modulation_frequency_eight);

				// Flux rate modulation (row 13) - additive
				fluxRateMod_one = Select.ar(fluxRateMod_one_active, [K2A.ar(0), (modulation_index_one * mod_one)]);
				fluxRateMod_two = Select.ar(fluxRateMod_two_active, [K2A.ar(0), (modulation_index_two * mod_two)]);
				fluxRateMod_three = Select.ar(fluxRateMod_three_active, [K2A.ar(0), (modulation_index_three * mod_three)]);
				fluxRateMod_four = Select.ar(fluxRateMod_four_active, [K2A.ar(0), (modulation_index_four * mod_four)]);
				fluxRateMod_five = Select.ar(fluxRateMod_five_active, [K2A.ar(0), (modulation_index_five * mod_five)]);
				fluxRateMod_six = Select.ar(fluxRateMod_six_active, [K2A.ar(0), (modulation_index_six * mod_six)]);
				fluxRateMod_seven = Select.ar(fluxRateMod_seven_active, [K2A.ar(0), (modulation_index_seven * mod_seven)]);
				fluxRateMod_eight = Select.ar(fluxRateMod_eight_active, [K2A.ar(0), (modulation_index_eight * mod_eight)]);
				fluxRate = fluxRate + (fluxRateMod_one + fluxRateMod_two + fluxRateMod_three + fluxRateMod_four +
					fluxRateMod_five + fluxRateMod_six + fluxRateMod_seven + fluxRateMod_eight);

				// Flux amount modulation (row 14) - multiplicative
				fluxAmtMod_one = Select.ar(fluxAmtMod_one_active, [K2A.ar(1), (1 + (modulation_index_one * 0.1)) * mod_one.unipolar]);
				fluxAmtMod_two = Select.ar(fluxAmtMod_two_active, [K2A.ar(1), (1 + (modulation_index_two * 0.1)) * mod_two.unipolar]);
				fluxAmtMod_three = Select.ar(fluxAmtMod_three_active, [K2A.ar(1), (1 + (modulation_index_three * 0.1)) * mod_three.unipolar]);
				fluxAmtMod_four = Select.ar(fluxAmtMod_four_active, [K2A.ar(1), (1 + (modulation_index_four * 0.1)) * mod_four.unipolar]);
				fluxAmtMod_five = Select.ar(fluxAmtMod_five_active, [K2A.ar(1), (1 + (modulation_index_five * 0.1)) * mod_five.unipolar]);
				fluxAmtMod_six = Select.ar(fluxAmtMod_six_active, [K2A.ar(1), (1 + (modulation_index_six * 0.1)) * mod_six.unipolar]);
				fluxAmtMod_seven = Select.ar(fluxAmtMod_seven_active, [K2A.ar(1), (1 + (modulation_index_seven * 0.1)) * mod_seven.unipolar]);
				fluxAmtMod_eight = Select.ar(fluxAmtMod_eight_active, [K2A.ar(1), (1 + (modulation_index_eight * 0.1)) * mod_eight.unipolar]);
				allFluxAmt = allFluxAmt * (fluxAmtMod_one * fluxAmtMod_two * fluxAmtMod_three * fluxAmtMod_four *
					fluxAmtMod_five * fluxAmtMod_six * fluxAmtMod_seven * fluxAmtMod_eight);

				// FM ratio modulation (row 15) - additive
				fmRatioMod_one = Select.ar(fmRatioMod_one_active, [K2A.ar(0), (modulation_index_one * mod_one)]);
				fmRatioMod_two = Select.ar(fmRatioMod_two_active, [K2A.ar(0), (modulation_index_two * mod_two)]);
				fmRatioMod_three = Select.ar(fmRatioMod_three_active, [K2A.ar(0), (modulation_index_three * mod_three)]);
				fmRatioMod_four = Select.ar(fmRatioMod_four_active, [K2A.ar(0), (modulation_index_four * mod_four)]);
				fmRatioMod_five = Select.ar(fmRatioMod_five_active, [K2A.ar(0), (modulation_index_five * mod_five)]);
				fmRatioMod_six = Select.ar(fmRatioMod_six_active, [K2A.ar(0), (modulation_index_six * mod_six)]);
				fmRatioMod_seven = Select.ar(fmRatioMod_seven_active, [K2A.ar(0), (modulation_index_seven * mod_seven)]);
				fmRatioMod_eight = Select.ar(fmRatioMod_eight_active, [K2A.ar(0), (modulation_index_eight * mod_eight)]);
				fmRatio = fmRatio + (fmRatioMod_one + fmRatioMod_two + fmRatioMod_three + fmRatioMod_four +
					fmRatioMod_five + fmRatioMod_six + fmRatioMod_seven + fmRatioMod_eight);

				// FM amount modulation (row 16) - multiplicative
				fmAmtMod_one = Select.ar(fmAmtMod_one_active, [K2A.ar(1), (1 + (modulation_index_one * 0.1)) * mod_one.unipolar]);
				fmAmtMod_two = Select.ar(fmAmtMod_two_active, [K2A.ar(1), (1 + (modulation_index_two * 0.1)) * mod_two.unipolar]);
				fmAmtMod_three = Select.ar(fmAmtMod_three_active, [K2A.ar(1), (1 + (modulation_index_three * 0.1)) * mod_three.unipolar]);
				fmAmtMod_four = Select.ar(fmAmtMod_four_active, [K2A.ar(1), (1 + (modulation_index_four * 0.1)) * mod_four.unipolar]);
				fmAmtMod_five = Select.ar(fmAmtMod_five_active, [K2A.ar(1), (1 + (modulation_index_five * 0.1)) * mod_five.unipolar]);
				fmAmtMod_six = Select.ar(fmAmtMod_six_active, [K2A.ar(1), (1 + (modulation_index_six * 0.1)) * mod_six.unipolar]);
				fmAmtMod_seven = Select.ar(fmAmtMod_seven_active, [K2A.ar(1), (1 + (modulation_index_seven * 0.1)) * mod_seven.unipolar]);
				fmAmtMod_eight = Select.ar(fmAmtMod_eight_active, [K2A.ar(1), (1 + (modulation_index_eight * 0.1)) * mod_eight.unipolar]);
				fmAmt = fmAmt * (fmAmtMod_one * fmAmtMod_two * fmAmtMod_three * fmAmtMod_four *
					fmAmtMod_five * fmAmtMod_six * fmAmtMod_seven * fmAmtMod_eight);

				// Phase modulation (row 17) - additive, bipolar
				phaseMod_one = Select.ar(phaseMod_one_active, [K2A.ar(0), (modulation_index_one * 0.1 * mod_one)]);
				phaseMod_two = Select.ar(phaseMod_two_active, [K2A.ar(0), (modulation_index_two * 0.1 * mod_two)]);
				phaseMod_three = Select.ar(phaseMod_three_active, [K2A.ar(0), (modulation_index_three * 0.1 * mod_three)]);
				phaseMod_four = Select.ar(phaseMod_four_active, [K2A.ar(0), (modulation_index_four * 0.1 * mod_four)]);
				phaseMod_five = Select.ar(phaseMod_five_active, [K2A.ar(0), (modulation_index_five * 0.1 * mod_five)]);
				phaseMod_six = Select.ar(phaseMod_six_active, [K2A.ar(0), (modulation_index_six * 0.1 * mod_six)]);
				phaseMod_seven = Select.ar(phaseMod_seven_active, [K2A.ar(0), (modulation_index_seven * 0.1 * mod_seven)]);
				phaseMod_eight = Select.ar(phaseMod_eight_active, [K2A.ar(0), (modulation_index_eight * 0.1 * mod_eight)]);
				phase = phase + (phaseMod_one + phaseMod_two + phaseMod_three + phaseMod_four +
					phaseMod_five + phaseMod_six + phaseMod_seven + phaseMod_eight);

				// Offset modulation (rows 18-20) - additive, bipolar
				offsetOneMod_one = Select.ar(offset_1_one_active, [K2A.ar(0), (modulation_index_one * 0.01 * mod_one)]);
				offsetOneMod_two = Select.ar(offset_1_two_active, [K2A.ar(0), (modulation_index_two * 0.01 * mod_two)]);
				offsetOneMod_three = Select.ar(offset_1_three_active, [K2A.ar(0), (modulation_index_three * 0.01 * mod_three)]);
				offsetOneMod_four = Select.ar(offset_1_four_active, [K2A.ar(0), (modulation_index_four * 0.01 * mod_four)]);
				offsetOneMod_five = Select.ar(offset_1_five_active, [K2A.ar(0), (modulation_index_five * 0.01 * mod_five)]);
				offsetOneMod_six = Select.ar(offset_1_six_active, [K2A.ar(0), (modulation_index_six * 0.01 * mod_six)]);
				offsetOneMod_seven = Select.ar(offset_1_seven_active, [K2A.ar(0), (modulation_index_seven * 0.01 * mod_seven)]);
				offsetOneMod_eight = Select.ar(offset_1_eight_active, [K2A.ar(0), (modulation_index_eight * 0.01 * mod_eight)]);
				offset_1 = offset_1 + (offsetOneMod_one + offsetOneMod_two + offsetOneMod_three + offsetOneMod_four +
					offsetOneMod_five + offsetOneMod_six + offsetOneMod_seven + offsetOneMod_eight);

				offsetTwoMod_one = Select.ar(offset_2_one_active, [K2A.ar(0), (modulation_index_one * 0.01 * mod_one)]);
				offsetTwoMod_two = Select.ar(offset_2_two_active, [K2A.ar(0), (modulation_index_two * 0.01 * mod_two)]);
				offsetTwoMod_three = Select.ar(offset_2_three_active, [K2A.ar(0), (modulation_index_three * 0.01 * mod_three)]);
				offsetTwoMod_four = Select.ar(offset_2_four_active, [K2A.ar(0), (modulation_index_four * 0.01 * mod_four)]);
				offsetTwoMod_five = Select.ar(offset_2_five_active, [K2A.ar(0), (modulation_index_five * 0.01 * mod_five)]);
				offsetTwoMod_six = Select.ar(offset_2_six_active, [K2A.ar(0), (modulation_index_six * 0.01 * mod_six)]);
				offsetTwoMod_seven = Select.ar(offset_2_seven_active, [K2A.ar(0), (modulation_index_seven * 0.01 * mod_seven)]);
				offsetTwoMod_eight = Select.ar(offset_2_eight_active, [K2A.ar(0), (modulation_index_eight * 0.01 * mod_eight)]);
				offset_2 = offset_2 + (offsetTwoMod_one + offsetTwoMod_two + offsetTwoMod_three + offsetTwoMod_four +
					offsetTwoMod_five + offsetTwoMod_six + offsetTwoMod_seven + offsetTwoMod_eight);

				offsetThreeMod_one = Select.ar(offset_3_one_active, [K2A.ar(0), (modulation_index_one * 0.01 * mod_one)]);
				offsetThreeMod_two = Select.ar(offset_3_two_active, [K2A.ar(0), (modulation_index_two * 0.01 * mod_two)]);
				offsetThreeMod_three = Select.ar(offset_3_three_active, [K2A.ar(0), (modulation_index_three * 0.01 * mod_three)]);
				offsetThreeMod_four = Select.ar(offset_3_four_active, [K2A.ar(0), (modulation_index_four * 0.01 * mod_four)]);
				offsetThreeMod_five = Select.ar(offset_3_five_active, [K2A.ar(0), (modulation_index_five * 0.01 * mod_five)]);
				offsetThreeMod_six = Select.ar(offset_3_six_active, [K2A.ar(0), (modulation_index_six * 0.01 * mod_six)]);
				offsetThreeMod_seven = Select.ar(offset_3_seven_active, [K2A.ar(0), (modulation_index_seven * 0.01 * mod_seven)]);
				offsetThreeMod_eight = Select.ar(offset_3_eight_active, [K2A.ar(0), (modulation_index_eight * 0.01 * mod_eight)]);
				offset_3 = offset_3 + (offsetThreeMod_one + offsetThreeMod_two + offsetThreeMod_three + offsetThreeMod_four +
					offsetThreeMod_five + offsetThreeMod_six + offsetThreeMod_seven + offsetThreeMod_eight);

				// Probability modulation (row 21) - multiplicative
				probabilityMod_one = Select.ar(probabilityMod_one_active, [K2A.ar(1), (1 + (modulation_index_one * 0.1)) * mod_one.unipolar]);
				probabilityMod_two = Select.ar(probabilityMod_two_active, [K2A.ar(1), (1 + (modulation_index_two * 0.1)) * mod_two.unipolar]);
				probabilityMod_three = Select.ar(probabilityMod_three_active, [K2A.ar(1), (1 + (modulation_index_three * 0.1)) * mod_three.unipolar]);
				probabilityMod_four = Select.ar(probabilityMod_four_active, [K2A.ar(1), (1 + (modulation_index_four * 0.1)) * mod_four.unipolar]);
				probabilityMod_five = Select.ar(probabilityMod_five_active, [K2A.ar(1), (1 + (modulation_index_five * 0.1)) * mod_five.unipolar]);
				probabilityMod_six = Select.ar(probabilityMod_six_active, [K2A.ar(1), (1 + (modulation_index_six * 0.1)) * mod_six.unipolar]);
				probabilityMod_seven = Select.ar(probabilityMod_seven_active, [K2A.ar(1), (1 + (modulation_index_seven * 0.1)) * mod_seven.unipolar]);
				probabilityMod_eight = Select.ar(probabilityMod_eight_active, [K2A.ar(1), (1 + (modulation_index_eight * 0.1)) * mod_eight.unipolar]);
				probability = probability * (probabilityMod_one * probabilityMod_two * probabilityMod_three * probabilityMod_four *
					probabilityMod_five * probabilityMod_six * probabilityMod_seven * probabilityMod_eight);

				// ============================================================
				// SUB-SAMPLE ACCURATE TRIGGER GENERATION
				// Replaces Impulse.ar with Phasor-based phase that wraps
				// ============================================================

				//trigger frequency modulators
				fundamentalMod_one = Select.ar(fundamentalMod_one_active, [K2A.ar(0), (modulation_index_one * mod_one)]);
				fundamentalMod_two = Select.ar(fundamentalMod_two_active, [K2A.ar(0), (modulation_index_two * mod_two)]);
				fundamentalMod_three = Select.ar(fundamentalMod_three_active, [K2A.ar(0), (modulation_index_three * mod_three)]);
				fundamentalMod_four = Select.ar(fundamentalMod_four_active, [K2A.ar(0), (modulation_index_four * mod_four)]);
				fundamentalMod_five = Select.ar(fundamentalMod_five_active, [K2A.ar(0), (modulation_index_five * mod_five)]);
				fundamentalMod_six = Select.ar(fundamentalMod_six_active, [K2A.ar(0), (modulation_index_six * mod_six)]);
				fundamentalMod_seven = Select.ar(fundamentalMod_seven_active, [K2A.ar(0), (modulation_index_seven * mod_seven)]);
				fundamentalMod_eight = Select.ar(fundamentalMod_eight_active, [K2A.ar(0), (modulation_index_eight * mod_eight)]);

				// Calculate trigger frequency with modulation and flux
				triggerFreq = (fundamental_frequency * fundamental_frequency_loop) +
					(fundamentalMod_one + fundamentalMod_two + fundamentalMod_three + fundamentalMod_four +
					 fundamentalMod_five + fundamentalMod_six + fundamentalMod_seven + fundamentalMod_eight);
				triggerFreq = triggerFreq * LFDNoise3.kr(fluxRate * ExpRand(0.8, 1.2), trigFreqFlux, 1);
				triggerFreq = triggerFreq.clip(0.1, 4000);

				// Generate phase ramp from fundamental frequency
				// Subtracting SampleDur.ir ensures proper wrap detection
				stepPhase = (Phasor.ar(DC.ar(0), triggerFreq * SampleDur.ir, 0, 1, phase) - SampleDur.ir).wrap(0, 1);

				// Derive trigger from phase wrap-around (sub-sample accurate)
				stepTrigger = rampToTrig.(stepPhase);

				// Get slope for sub-sample offset calculation
				stepSlope = rampToSlope.(stepPhase);

				// Calculate sub-sample offset for precise grain timing (using original trigger)
				subSampleOffset = getSubSampleOffset.(stepPhase, stepSlope, stepTrigger);

				// Apply probability and burst masking to trigger BEFORE accumulator
				// This ensures grains only start on unmasked triggers
				stepTrigger = stepTrigger * CoinGate.ar(probability * probability_loop, stepTrigger);
				stepTrigger = stepTrigger * Demand.ar(stepTrigger, 1, Dseq([Dser([1], burst), Dser([0], rest)], inf));

				//sieve masking
				sieveMask = Demand.ar(stepTrigger, 0, Dseries());
				sieveMask = Select.ar(sieveMask.mod(sieveMod), K2A.ar(sieveSequence));
				stepTrigger = stepTrigger * Select.kr(sieveMaskOn, [K2A.ar(1), sieveMask]);
				channelMask = Demand.ar(stepTrigger, 0, Dseq([Dser([-1], chanMask),
					Dser([1], chanMask), Dser([0], centerMask)], inf));

				// Accumulator counts samples since MASKED trigger, with sub-sample correction
				// Grains only start when trigger passes through all masks
				accumulator = accumulatorSubSample.(stepTrigger, subSampleOffset);

				// ============================================================
				// GROUP OFFSET TRIGGERS AND ACCUMULATORS
				// Each group can have its own timing offset
				// ============================================================

				// Apply offset delays to triggers for each group
				stepTrigger_One = DelayN.ar(stepTrigger, 1, offset_1);
				stepTrigger_Two = DelayN.ar(stepTrigger, 1, offset_2);
				stepTrigger_Three = DelayN.ar(stepTrigger, 1, offset_3);

				// Create accumulators for each offset trigger
				accumulator_One = accumulatorSubSample.(stepTrigger_One, subSampleOffset);
				accumulator_Two = accumulatorSubSample.(stepTrigger_Two, subSampleOffset);
				accumulator_Three = accumulatorSubSample.(stepTrigger_Three, subSampleOffset);

				//send trigger for language processing (after all masking)
				sendTrigger = SendTrig.ar(stepTrigger, 0);

				// ============================================================
				// FORMANT FREQUENCY CALCULATION
				// ============================================================

				//formant 1 modulators
				formantOneMod_one = Select.ar(formantOneMod_one_active, [K2A.ar(0), (modulation_index_one * mod_one)]);
				formantOneMod_two = Select.ar(formantOneMod_two_active, [K2A.ar(0), (modulation_index_two * mod_two)]);
				formantOneMod_three = Select.ar(formantOneMod_three_active, [K2A.ar(0), (modulation_index_three * mod_three)]);
				formantOneMod_four = Select.ar(formantOneMod_four_active, [K2A.ar(0), (modulation_index_four * mod_four)]);
				formantOneMod_five = Select.ar(formantOneMod_five_active, [K2A.ar(0), (modulation_index_five * mod_five)]);
				formantOneMod_six = Select.ar(formantOneMod_six_active, [K2A.ar(0), (modulation_index_six * mod_six)]);
				formantOneMod_seven = Select.ar(formantOneMod_seven_active, [K2A.ar(0), (modulation_index_seven * mod_seven)]);
				formantOneMod_eight = Select.ar(formantOneMod_eight_active, [K2A.ar(0), (modulation_index_eight * mod_eight)]);

				formant_frequency_One_loop = Select.kr(group_1_onOff, [1, formant_frequency_One_loop]);
				ffreq_One = (formant_frequency_One * formant_frequency_One_loop) +
				(formantOneMod_one + formantOneMod_two + formantOneMod_three + formantOneMod_four +
				 formantOneMod_five + formantOneMod_six + formantOneMod_seven + formantOneMod_eight);

				//formant 2 modulators
				formantTwoMod_one = Select.ar(formantTwoMod_one_active, [K2A.ar(0), (modulation_index_one * mod_one)]);
				formantTwoMod_two = Select.ar(formantTwoMod_two_active, [K2A.ar(0), (modulation_index_two * mod_two)]);
				formantTwoMod_three = Select.ar(formantTwoMod_three_active, [K2A.ar(0), (modulation_index_three * mod_three)]);
				formantTwoMod_four = Select.ar(formantTwoMod_four_active, [K2A.ar(0), (modulation_index_four * mod_four)]);
				formantTwoMod_five = Select.ar(formantTwoMod_five_active, [K2A.ar(0), (modulation_index_five * mod_five)]);
				formantTwoMod_six = Select.ar(formantTwoMod_six_active, [K2A.ar(0), (modulation_index_six * mod_six)]);
				formantTwoMod_seven = Select.ar(formantTwoMod_seven_active, [K2A.ar(0), (modulation_index_seven * mod_seven)]);
				formantTwoMod_eight = Select.ar(formantTwoMod_eight_active, [K2A.ar(0), (modulation_index_eight * mod_eight)]);

				formant_frequency_Two_loop = Select.kr(group_2_onOff, [1, formant_frequency_Two_loop]);
				ffreq_Two = (formant_frequency_Two * formant_frequency_Two_loop) +
							(formantTwoMod_one + formantTwoMod_two + formantTwoMod_three + formantTwoMod_four +
							 formantTwoMod_five + formantTwoMod_six + formantTwoMod_seven + formantTwoMod_eight);

				//formant 3 modulators
				formantThreeMod_one = Select.ar(formantThreeMod_one_active, [K2A.ar(0), (modulation_index_one * mod_one)]);
				formantThreeMod_two = Select.ar(formantThreeMod_two_active, [K2A.ar(0), (modulation_index_two * mod_two)]);
				formantThreeMod_three = Select.ar(formantThreeMod_three_active, [K2A.ar(0), (modulation_index_three * mod_three)]);
				formantThreeMod_four = Select.ar(formantThreeMod_four_active, [K2A.ar(0), (modulation_index_four * mod_four)]);
				formantThreeMod_five = Select.ar(formantThreeMod_five_active, [K2A.ar(0), (modulation_index_five * mod_five)]);
				formantThreeMod_six = Select.ar(formantThreeMod_six_active, [K2A.ar(0), (modulation_index_six * mod_six)]);
				formantThreeMod_seven = Select.ar(formantThreeMod_seven_active, [K2A.ar(0), (modulation_index_seven * mod_seven)]);
				formantThreeMod_eight = Select.ar(formantThreeMod_eight_active, [K2A.ar(0), (modulation_index_eight * mod_eight)]);

				formant_frequency_Three_loop = Select.kr(group_3_onOff, [1, formant_frequency_Three_loop]);
				ffreq_Three = (formant_frequency_Three * formant_frequency_Three_loop) +
							(formantThreeMod_one + formantThreeMod_two + formantThreeMod_three + formantThreeMod_four +
							 formantThreeMod_five + formantThreeMod_six + formantThreeMod_seven + formantThreeMod_eight);

				// Apply formant flux
				ffreq_One = ffreq_One * LFDNoise3.ar(fluxRate * ExpRand(0.01, 2.9), grainFreqFlux, 1);
				ffreq_Two = ffreq_Two * LFDNoise3.ar(fluxRate * ExpRand(0.01, 2.9), grainFreqFlux, 1);
				ffreq_Three = ffreq_Three * LFDNoise3.ar(fluxRate * ExpRand(0.01, 2.9), grainFreqFlux, 1);

				// ============================================================
				// OVERLAP AND PHASE CALCULATIONS
				// Overlap is derived from envMul (dilation) - controlled by GUI
				// ============================================================

				// First calculate envMul values (including loop from group tables)
				// These come from the dilation GUI sliders
				envMul_One_loop = Select.kr(group_1_onOff, [1, envMul_One_loop]);
				envMul_Two_loop = Select.kr(group_2_onOff, [1, envMul_Two_loop]);
				envMul_Three_loop = Select.kr(group_3_onOff, [1, envMul_Three_loop]);

				// Derive overlap from envMul (dilation control)
				// envMul controls how many pulsaret cycles play per grain
				// Envelope multiplier modulation (rows 4-6 in matrix)
				var envMulOneMod_one, envMulOneMod_two, envMulOneMod_three, envMulOneMod_four;
				var envMulOneMod_five, envMulOneMod_six, envMulOneMod_seven, envMulOneMod_eight;
				var envMulTwoMod_one, envMulTwoMod_two, envMulTwoMod_three, envMulTwoMod_four;
				var envMulTwoMod_five, envMulTwoMod_six, envMulTwoMod_seven, envMulTwoMod_eight;
				var envMulThreeMod_one, envMulThreeMod_two, envMulThreeMod_three, envMulThreeMod_four;
				var envMulThreeMod_five, envMulThreeMod_six, envMulThreeMod_seven, envMulThreeMod_eight;

				// Envelope Mul One modulation
				envMulOneMod_one = Select.ar(envOneMod_one_active, [
					K2A.ar(1), ((1 + (modulation_index_one * 0.1)) * mod_one.unipolar)
				]);
				envMulOneMod_two = Select.ar(envOneMod_two_active, [
					K2A.ar(1), ((1 + (modulation_index_two * 0.1)) * mod_two.unipolar)
				]);
				envMulOneMod_three = Select.ar(envOneMod_three_active, [
					K2A.ar(1), ((1 + (modulation_index_three * 0.1)) * mod_three.unipolar)
				]);
				envMulOneMod_four = Select.ar(envOneMod_four_active, [
					K2A.ar(1), ((1 + (modulation_index_four * 0.1)) * mod_four.unipolar)
				]);
				envMulOneMod_five = Select.ar(envOneMod_five_active, [
					K2A.ar(1), ((1 + (modulation_index_five * 0.1)) * mod_five.unipolar)
				]);
				envMulOneMod_six = Select.ar(envOneMod_six_active, [
					K2A.ar(1), ((1 + (modulation_index_six * 0.1)) * mod_six.unipolar)
				]);
				envMulOneMod_seven = Select.ar(envOneMod_seven_active, [
					K2A.ar(1), ((1 + (modulation_index_seven * 0.1)) * mod_seven.unipolar)
				]);
				envMulOneMod_eight = Select.ar(envOneMod_eight_active, [
					K2A.ar(1), ((1 + (modulation_index_eight * 0.1)) * mod_eight.unipolar)
				]);

				// Envelope Mul Two modulation
				envMulTwoMod_one = Select.ar(envTwoMod_one_active, [
					K2A.ar(1), ((1 + (modulation_index_one * 0.1)) * mod_one.unipolar)
				]);
				envMulTwoMod_two = Select.ar(envTwoMod_two_active, [
					K2A.ar(1), ((1 + (modulation_index_two * 0.1)) * mod_two.unipolar)
				]);
				envMulTwoMod_three = Select.ar(envTwoMod_three_active, [
					K2A.ar(1), ((1 + (modulation_index_three * 0.1)) * mod_three.unipolar)
				]);
				envMulTwoMod_four = Select.ar(envTwoMod_four_active, [
					K2A.ar(1), ((1 + (modulation_index_four * 0.1)) * mod_four.unipolar)
				]);
				envMulTwoMod_five = Select.ar(envTwoMod_five_active, [
					K2A.ar(1), ((1 + (modulation_index_five * 0.1)) * mod_five.unipolar)
				]);
				envMulTwoMod_six = Select.ar(envTwoMod_six_active, [
					K2A.ar(1), ((1 + (modulation_index_six * 0.1)) * mod_six.unipolar)
				]);
				envMulTwoMod_seven = Select.ar(envTwoMod_seven_active, [
					K2A.ar(1), ((1 + (modulation_index_seven * 0.1)) * mod_seven.unipolar)
				]);
				envMulTwoMod_eight = Select.ar(envTwoMod_eight_active, [
					K2A.ar(1), ((1 + (modulation_index_eight * 0.1)) * mod_eight.unipolar)
				]);

				// Envelope Mul Three modulation
				envMulThreeMod_one = Select.ar(envThreeMod_one_active, [
					K2A.ar(1), ((1 + (modulation_index_one * 0.1)) * mod_one.unipolar)
				]);
				envMulThreeMod_two = Select.ar(envThreeMod_two_active, [
					K2A.ar(1), ((1 + (modulation_index_two * 0.1)) * mod_two.unipolar)
				]);
				envMulThreeMod_three = Select.ar(envThreeMod_three_active, [
					K2A.ar(1), ((1 + (modulation_index_three * 0.1)) * mod_three.unipolar)
				]);
				envMulThreeMod_four = Select.ar(envThreeMod_four_active, [
					K2A.ar(1), ((1 + (modulation_index_four * 0.1)) * mod_four.unipolar)
				]);
				envMulThreeMod_five = Select.ar(envThreeMod_five_active, [
					K2A.ar(1), ((1 + (modulation_index_five * 0.1)) * mod_five.unipolar)
				]);
				envMulThreeMod_six = Select.ar(envThreeMod_six_active, [
					K2A.ar(1), ((1 + (modulation_index_six * 0.1)) * mod_six.unipolar)
				]);
				envMulThreeMod_seven = Select.ar(envThreeMod_seven_active, [
					K2A.ar(1), ((1 + (modulation_index_seven * 0.1)) * mod_seven.unipolar)
				]);
				envMulThreeMod_eight = Select.ar(envThreeMod_eight_active, [
					K2A.ar(1), ((1 + (modulation_index_eight * 0.1)) * mod_eight.unipolar)
				]);

				// Higher envMul = more cycles = higher overlap potential (with modulation)
				overlap_One = envMul_One * envMul_One_loop *
					(envMulOneMod_one * envMulOneMod_two * envMulOneMod_three * envMulOneMod_four *
					 envMulOneMod_five * envMulOneMod_six * envMulOneMod_seven * envMulOneMod_eight);
				overlap_Two = envMul_Two * envMul_Two_loop *
					(envMulTwoMod_one * envMulTwoMod_two * envMulTwoMod_three * envMulTwoMod_four *
					 envMulTwoMod_five * envMulTwoMod_six * envMulTwoMod_seven * envMulTwoMod_eight);
				overlap_Three = envMul_Three * envMul_Three_loop *
					(envMulThreeMod_one * envMulThreeMod_two * envMulThreeMod_three * envMulThreeMod_four *
					 envMulThreeMod_five * envMulThreeMod_six * envMulThreeMod_seven * envMulThreeMod_eight);

				// Overlap morphing modulation
				// overlapMorphDepth controls mix between dilation and LFO
				// overlapPhaseOffset controls phase spread between groups (0=sync, 1=120° spread)
				// overlapMorphShape: 0=sine, 1=tri, 2=saw, 3=random, 4=chaos
				overlap_One = overlap_One + (overlapMorphDepth * (
					Select.kr(overlapMorphShape, [
						SinOsc.kr(overlapMorphRate),
						LFTri.kr(overlapMorphRate),
						LFSaw.kr(overlapMorphRate),
						LFNoise1.kr(overlapMorphRate),
						LFNoise2.kr(overlapMorphRate)
					]).linlin(-1, 1, overlapMorphMin, overlapMorphMax) - overlap_One
				));
				overlap_Two = overlap_Two + (overlapMorphDepth * (
					Select.kr(overlapMorphShape, [
						SinOsc.kr(overlapMorphRate, 2pi/3 * overlapPhaseOffset),
						LFTri.kr(overlapMorphRate, 2/3 * overlapPhaseOffset),
						LFSaw.kr(overlapMorphRate, 2/3 * overlapPhaseOffset),
						LFNoise1.kr(overlapMorphRate),
						LFNoise2.kr(overlapMorphRate)
					]).linlin(-1, 1, overlapMorphMin, overlapMorphMax) - overlap_Two
				));
				overlap_Three = overlap_Three + (overlapMorphDepth * (
					Select.kr(overlapMorphShape, [
						SinOsc.kr(overlapMorphRate, 4pi/3 * overlapPhaseOffset),
						LFTri.kr(overlapMorphRate, 4/3 * overlapPhaseOffset),
						LFSaw.kr(overlapMorphRate, 4/3 * overlapPhaseOffset),
						LFNoise1.kr(overlapMorphRate),
						LFNoise2.kr(overlapMorphRate)
					]).linlin(-1, 1, overlapMorphMin, overlapMorphMax) - overlap_Three
				));

				// Calculate grain slopes (phase increment per sample)
				grainSlope_One = ffreq_One * SampleDur.ir;
				grainSlope_Two = ffreq_Two * SampleDur.ir;
				grainSlope_Three = ffreq_Three * SampleDur.ir;

				// Calculate max overlap: limited by ratio of grain freq to trigger freq
				// maxOverlap = min(userOverlap, grainSlope / stepSlope)
				maxOverlap_One = min(overlap_One, grainSlope_One / max(0.0001, stepSlope));
				maxOverlap_Two = min(overlap_Two, grainSlope_Two / max(0.0001, stepSlope));
				maxOverlap_Three = min(overlap_Three, grainSlope_Three / max(0.0001, stepSlope));

				// Window (envelope) slope: how fast envelope progresses
				// Latch values at trigger for consistent grain duration
				// Use group-specific triggers for proper offset timing
				windowSlope_One = Latch.ar(grainSlope_One, stepTrigger_One) / max(0.001, Latch.ar(maxOverlap_One, stepTrigger_One));
				windowSlope_Two = Latch.ar(grainSlope_Two, stepTrigger_Two) / max(0.001, Latch.ar(maxOverlap_Two, stepTrigger_Two));
				windowSlope_Three = Latch.ar(grainSlope_Three, stepTrigger_Three) / max(0.001, Latch.ar(maxOverlap_Three, stepTrigger_Three));

				// Window phase: envelope position (0->1 over grain duration)
				// clip(0,1) makes it one-shot (stays at end after grain completes)
				// Use group-specific accumulators for proper offset timing
				windowPhase_One = (windowSlope_One * accumulator_One).clip(0, 1);
				windowPhase_Two = (windowSlope_Two * accumulator_Two).clip(0, 1);
				windowPhase_Three = (windowSlope_Three * accumulator_Three).clip(0, 1);

				// Grain phase: pulsaret oscillation tied to envelope duration
				// wrap(0,1) allows multiple cycles during grain
				grainPhase_One = (windowPhase_One * Latch.ar(maxOverlap_One, stepTrigger_One)).wrap(0, 1);
				grainPhase_Two = (windowPhase_Two * Latch.ar(maxOverlap_Two, stepTrigger_Two)).wrap(0, 1);
				grainPhase_Three = (windowPhase_Three * Latch.ar(maxOverlap_Three, stepTrigger_Three)).wrap(0, 1);

				// Legacy grain duration calculation (for compatibility)
				envM_One = ffreq_One * overlap_One * (2048/Server.default.sampleRate);
				envM_Two = ffreq_Two * overlap_Two * (2048/Server.default.sampleRate);
				envM_Three = ffreq_Three * overlap_Three * (2048/Server.default.sampleRate);

				grainDur_One = 2048 / Server.default.sampleRate / max(0.0001, envM_One);
				grainDur_Two = 2048 / Server.default.sampleRate / max(0.0001, envM_Two);
				grainDur_Three = 2048 / Server.default.sampleRate / max(0.0001, envM_Three);

				// ============================================================
				// AMPLITUDE CALCULATION
				// ============================================================

				//amplitude 1
				amplitude_One_loop = Select.kr(group_1_onOff, [1, amplitude_One_loop]);
				ampOneMod_one = Select.ar(ampOneMod_one_active, [K2A.ar(1), ((1 + (modulation_index_one * 0.1)) * mod_one.unipolar)]);
				ampOneMod_two = Select.ar(ampOneMod_two_active, [K2A.ar(1), ((1 + (modulation_index_two * 0.1)) * mod_two.unipolar)]);
				ampOneMod_three = Select.ar(ampOneMod_three_active, [K2A.ar(1), ((1 + (modulation_index_three * 0.1)) * mod_three.unipolar)]);
				ampOneMod_four = Select.ar(ampOneMod_four_active, [K2A.ar(1), ((1 + (modulation_index_four * 0.1)) * mod_four.unipolar)]);
				ampOneMod_five = Select.ar(ampOneMod_five_active, [K2A.ar(1), ((1 + (modulation_index_five * 0.1)) * mod_five.unipolar)]);
				ampOneMod_six = Select.ar(ampOneMod_six_active, [K2A.ar(1), ((1 + (modulation_index_six * 0.1)) * mod_six.unipolar)]);
				ampOneMod_seven = Select.ar(ampOneMod_seven_active, [K2A.ar(1), ((1 + (modulation_index_seven * 0.1)) * mod_seven.unipolar)]);
				ampOneMod_eight = Select.ar(ampOneMod_eight_active, [K2A.ar(1), ((1 + (modulation_index_eight * 0.1)) * mod_eight.unipolar)]);
				amplitude_One = amplitude_One * amplitude_One_loop *
				(ampOneMod_one * ampOneMod_two * ampOneMod_three * ampOneMod_four *
				 ampOneMod_five * ampOneMod_six * ampOneMod_seven * ampOneMod_eight) * (1 - mute);
				amplitude_One = amplitude_One.clip(0, 1);

				//amplitude 2
				amplitude_Two_loop = Select.kr(group_2_onOff, [1, amplitude_Two_loop]);
				ampTwoMod_one = Select.ar(ampTwoMod_one_active, [K2A.ar(1), ((1 + (modulation_index_one * 0.1)) * mod_one.unipolar)]);
				ampTwoMod_two = Select.ar(ampTwoMod_two_active, [K2A.ar(1), ((1 + (modulation_index_two * 0.1)) * mod_two.unipolar)]);
				ampTwoMod_three = Select.ar(ampTwoMod_three_active, [K2A.ar(1), ((1 + (modulation_index_three * 0.1)) * mod_three.unipolar)]);
				ampTwoMod_four = Select.ar(ampTwoMod_four_active, [K2A.ar(1), ((1 + (modulation_index_four * 0.1)) * mod_four.unipolar)]);
				ampTwoMod_five = Select.ar(ampTwoMod_five_active, [K2A.ar(1), ((1 + (modulation_index_five * 0.1)) * mod_five.unipolar)]);
				ampTwoMod_six = Select.ar(ampTwoMod_six_active, [K2A.ar(1), ((1 + (modulation_index_six * 0.1)) * mod_six.unipolar)]);
				ampTwoMod_seven = Select.ar(ampTwoMod_seven_active, [K2A.ar(1), ((1 + (modulation_index_seven * 0.1)) * mod_seven.unipolar)]);
				ampTwoMod_eight = Select.ar(ampTwoMod_eight_active, [K2A.ar(1), ((1 + (modulation_index_eight * 0.1)) * mod_eight.unipolar)]);
				amplitude_Two = amplitude_Two * amplitude_Two_loop *
				(ampTwoMod_one * ampTwoMod_two * ampTwoMod_three * ampTwoMod_four *
				 ampTwoMod_five * ampTwoMod_six * ampTwoMod_seven * ampTwoMod_eight) * (1 - mute);
				amplitude_Two = amplitude_Two.clip(0, 1);

				//amplitude 3
				amplitude_Three_loop = Select.kr(group_3_onOff, [1, amplitude_Three_loop]);
				ampThreeMod_one = Select.ar(ampThreeMod_one_active, [K2A.ar(1), ((1 + (modulation_index_one * 0.1)) * mod_one.unipolar)]);
				ampThreeMod_two = Select.ar(ampThreeMod_two_active, [K2A.ar(1), ((1 + (modulation_index_two * 0.1)) * mod_two.unipolar)]);
				ampThreeMod_three = Select.ar(ampThreeMod_three_active, [K2A.ar(1), ((1 + (modulation_index_three * 0.1)) * mod_three.unipolar)]);
				ampThreeMod_four = Select.ar(ampThreeMod_four_active, [K2A.ar(1), ((1 + (modulation_index_four * 0.1)) * mod_four.unipolar)]);
				ampThreeMod_five = Select.ar(ampThreeMod_five_active, [K2A.ar(1), ((1 + (modulation_index_five * 0.1)) * mod_five.unipolar)]);
				ampThreeMod_six = Select.ar(ampThreeMod_six_active, [K2A.ar(1), ((1 + (modulation_index_six * 0.1)) * mod_six.unipolar)]);
				ampThreeMod_seven = Select.ar(ampThreeMod_seven_active, [K2A.ar(1), ((1 + (modulation_index_seven * 0.1)) * mod_seven.unipolar)]);
				ampThreeMod_eight = Select.ar(ampThreeMod_eight_active, [K2A.ar(1), ((1 + (modulation_index_eight * 0.1)) * mod_eight.unipolar)]);
				amplitude_Three = amplitude_Three * amplitude_Three_loop *
				(ampThreeMod_one * ampThreeMod_two * ampThreeMod_three * ampThreeMod_four *
				 ampThreeMod_five * ampThreeMod_six * ampThreeMod_seven * ampThreeMod_eight) * (1 - mute);
				amplitude_Three = amplitude_Three.clip(0, 1);

				// ============================================================
				// PANNING CALCULATION
				// ============================================================

				//pan 1
				panOneMod_one = Select.ar(panOneMod_one_active, [K2A.ar(0), ((modulation_index_one * 0.1) * mod_one)]);
				panOneMod_two = Select.ar(panOneMod_two_active, [K2A.ar(0), ((modulation_index_two * 0.1) * mod_two)]);
				panOneMod_three = Select.ar(panOneMod_three_active, [K2A.ar(0), ((modulation_index_three * 0.1) * mod_three)]);
				panOneMod_four = Select.ar(panOneMod_four_active, [K2A.ar(0), ((modulation_index_four * 0.1) * mod_four)]);
				panOneMod_five = Select.ar(panOneMod_five_active, [K2A.ar(0), ((modulation_index_five * 0.1) * mod_five)]);
				panOneMod_six = Select.ar(panOneMod_six_active, [K2A.ar(0), ((modulation_index_six * 0.1) * mod_six)]);
				panOneMod_seven = Select.ar(panOneMod_seven_active, [K2A.ar(0), ((modulation_index_seven * 0.1) * mod_seven)]);
				panOneMod_eight = Select.ar(panOneMod_eight_active, [K2A.ar(0), ((modulation_index_eight * 0.1) * mod_eight)]);
				pan_One_loop = Select.kr(group_1_onOff, [0, pan_One_loop]);
				pan_One = pan_One + pan_One_loop + (panOneMod_one + panOneMod_two + panOneMod_three + panOneMod_four +
					panOneMod_five + panOneMod_six + panOneMod_seven + panOneMod_eight);
				pan_One = pan_One.fold(-1, 1);
				pan_One = pan_One + channelMask;

				//pan 2
				pan_Two_loop = Select.kr(group_2_onOff, [0, pan_Two_loop]);
				panTwoMod_one = Select.ar(panTwoMod_one_active, [K2A.ar(0), ((modulation_index_one * 0.1) * mod_one)]);
				panTwoMod_two = Select.ar(panTwoMod_two_active, [K2A.ar(0), ((modulation_index_two * 0.1) * mod_two)]);
				panTwoMod_three = Select.ar(panTwoMod_three_active, [K2A.ar(0), ((modulation_index_three * 0.1) * mod_three)]);
				panTwoMod_four = Select.ar(panTwoMod_four_active, [K2A.ar(0), ((modulation_index_four * 0.1) * mod_four)]);
				panTwoMod_five = Select.ar(panTwoMod_five_active, [K2A.ar(0), ((modulation_index_five * 0.1) * mod_five)]);
				panTwoMod_six = Select.ar(panTwoMod_six_active, [K2A.ar(0), ((modulation_index_six * 0.1) * mod_six)]);
				panTwoMod_seven = Select.ar(panTwoMod_seven_active, [K2A.ar(0), ((modulation_index_seven * 0.1) * mod_seven)]);
				panTwoMod_eight = Select.ar(panTwoMod_eight_active, [K2A.ar(0), ((modulation_index_eight * 0.1) * mod_eight)]);
				pan_Two = pan_Two + pan_Two_loop + (panTwoMod_one + panTwoMod_two + panTwoMod_three + panTwoMod_four +
					panTwoMod_five + panTwoMod_six + panTwoMod_seven + panTwoMod_eight);
				pan_Two = pan_Two.fold(-1, 1);
				pan_Two = pan_Two + channelMask;

				//pan 3
				pan_Three_loop = Select.kr(group_3_onOff, [0, pan_Three_loop]);
				panThreeMod_one = Select.ar(panThreeMod_one_active, [K2A.ar(0), ((modulation_index_one * 0.1) * mod_one)]);
				panThreeMod_two = Select.ar(panThreeMod_two_active, [K2A.ar(0), ((modulation_index_two * 0.1) * mod_two)]);
				panThreeMod_three = Select.ar(panThreeMod_three_active, [K2A.ar(0), ((modulation_index_three * 0.1) * mod_three)]);
				panThreeMod_four = Select.ar(panThreeMod_four_active, [K2A.ar(0), ((modulation_index_four * 0.1) * mod_four)]);
				panThreeMod_five = Select.ar(panThreeMod_five_active, [K2A.ar(0), ((modulation_index_five * 0.1) * mod_five)]);
				panThreeMod_six = Select.ar(panThreeMod_six_active, [K2A.ar(0), ((modulation_index_six * 0.1) * mod_six)]);
				panThreeMod_seven = Select.ar(panThreeMod_seven_active, [K2A.ar(0), ((modulation_index_seven * 0.1) * mod_seven)]);
				panThreeMod_eight = Select.ar(panThreeMod_eight_active, [K2A.ar(0), ((modulation_index_eight * 0.1) * mod_eight)]);
				pan_Three = pan_Three + pan_Three_loop + (panThreeMod_one + panThreeMod_two + panThreeMod_three + panThreeMod_four +
					panThreeMod_five + panThreeMod_six + panThreeMod_seven + panThreeMod_eight);
				pan_Three = pan_Three.fold(-1, 1);
				pan_Three = pan_Three + channelMask;

				// ============================================================
				// FM ENVELOPE (frequency modulation from buffer)
				// ============================================================

				freqEnvPlayBuf_One = PlayBuf.ar(1, frequency_buffer,
					(ffreq_One * 2048/Server.default.sampleRate), stepTrigger, 0, loop: 0);
				freqEnvPlayBuf_Two = PlayBuf.ar(1, frequency_buffer,
					(ffreq_Two * 2048/Server.default.sampleRate), stepTrigger, 0, loop: 0);
				freqEnvPlayBuf_Three = PlayBuf.ar(1, frequency_buffer,
					(ffreq_Three * 2048/Server.default.sampleRate), stepTrigger, 0, loop: 0);

				// Calculate FM-modulated grain phase scaling
				ffreq_One_modulated = 1 + (freqEnvPlayBuf_One * fmAmt) +
					Select.kr(modulationMode, [
						Latch.ar(LFSaw.ar(ffreq_One * fmRatio, 0, fmAmt/modMul, fmAmt/modAdd), stepTrigger),
						Latch.ar(LFSaw.ar(ffreq_One - fmAmt * fmRatio, 0, fmAmt/modMul, fmAmt/modAdd) - fmAmt, stepTrigger)
					]);

				ffreq_Two_modulated = 1 + (freqEnvPlayBuf_Two * fmAmt) +
					Select.kr(modulationMode, [
						Latch.ar(LFSaw.ar(ffreq_Two * fmRatio, 0, fmAmt/modMul, fmAmt/modAdd), stepTrigger),
						Latch.ar(LFSaw.ar(ffreq_Two - fmAmt * fmRatio, 0, fmAmt/modMul, fmAmt/modAdd) - fmAmt, stepTrigger)
					]);

				ffreq_Three_modulated = 1 + (freqEnvPlayBuf_Three * fmAmt) +
					Select.kr(modulationMode, [
						Latch.ar(LFSaw.ar(ffreq_Three * fmRatio, 0, fmAmt/modMul, fmAmt/modAdd), stepTrigger),
						Latch.ar(LFSaw.ar(ffreq_Three - fmAmt * fmRatio, 0, fmAmt/modMul, fmAmt/modAdd) - fmAmt, stepTrigger)
					]);

				// Apply FM modulation to grain phase
				grainPhase_One = (grainPhase_One * ffreq_One_modulated).wrap(0, 1);
				grainPhase_Two = (grainPhase_Two * ffreq_Two_modulated).wrap(0, 1);
				grainPhase_Three = (grainPhase_Three * ffreq_Three_modulated).wrap(0, 1);

				// ============================================================
				// PULSARET AND ENVELOPE
				// ============================================================

				// Pulsaret: use OscOS for anti-aliased wavetable oscillation
				// OscOS.ar(buffer, phase, numSubTables, subTablePos, oversample, mul)
				// numSubTables=1 (single 2048-sample wavetable), subTablePos=0, oversample=1
				pulsaret_One = OscOS.ar(pulsaret_buffer, grainPhase_One, 1, 0, 1);
				pulsaret_Two = OscOS.ar(pulsaret_buffer, grainPhase_Two, 1, 0, 1);
				pulsaret_Three = OscOS.ar(pulsaret_buffer, grainPhase_Three, 1, 0, 1);

				// Envelope: use OscOS for anti-aliased one-shot reading
				// windowPhase is clipped 0-1 (one-shot), so it reads through buffer once
				// OscOS.ar(buffer, phase, numSubTables=1, subTablePos=0, oversample=1)
				envelope_One = OscOS.ar(envelope_buffer, windowPhase_One, 1, 0, 1);
				envelope_Two = OscOS.ar(envelope_buffer, windowPhase_Two, 1, 0, 1);
				envelope_Three = OscOS.ar(envelope_buffer, windowPhase_Three, 1, 0, 1);

				// ============================================================
				// OUTPUT MIX
				// ============================================================

				// Pulsar outputs
				// Scale by 0.9 to match classic GrainBuf amplitude level
				// Respect numChannels setting: mono (1) or stereo (2)
				pulsar_1 = pulsaret_One * envelope_One * 0.9;
				pulsar_1 = if(numChannels == 1, pulsar_1, Pan2.ar(pulsar_1, pan_One));
				pulsar_1 = pulsar_1 * amplitude_One * amplitude_local_One;

				pulsar_2 = pulsaret_Two * envelope_Two * 0.9;
				pulsar_2 = if(numChannels == 1, pulsar_2, Pan2.ar(pulsar_2, pan_Two));
				pulsar_2 = pulsar_2 * amplitude_Two * amplitude_local_Two;

				pulsar_3 = pulsaret_Three * envelope_Three * 0.9;
				pulsar_3 = if(numChannels == 1, pulsar_3, Pan2.ar(pulsar_3, pan_Three));
				pulsar_3 = pulsar_3 * amplitude_Three * amplitude_local_Three;

				mix = Mix.new([pulsar_1, pulsar_2, pulsar_3]) * globalAmplitude;

				LeakDC.ar(mix).softclip
			});
		};

		^trainInstances
	}
}
