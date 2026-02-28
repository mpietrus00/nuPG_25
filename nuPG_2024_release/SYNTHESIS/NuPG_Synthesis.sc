NuPG_AdC {

	*ar {
		arg channels_number = 2, trigger, grain_duration, pulsar_buffer, rate, panning, envelope_buffer;
		var output;
		output = GrainBuf.ar(
			numChannels: channels_number,
			trigger: trigger,
			dur: grain_duration,
			sndbuf: pulsar_buffer,
			//rate modulation
			rate: rate,
			pos: 0,
			interp: 4,
			pan: panning,
			envbufnum: envelope_buffer,
			maxGrains: 2048,
			mul: 0.9);

		//output = output * amp;
		^output;
	}

}

NuPG_CJ {

	*ar {
		arg channels_number = 1, trigger, grain_duration, pulsar_buffer, rate, panning, envelope_buffer;
		var pulsar, envelope, output;

		pulsar = PlayBuf.ar(
			numChannels: 1,
			bufnum: pulsar_buffer,
			rate: rate,
			trigger: trigger,
			startPos: 0,
			loop: -1);

		envelope = PlayBuf.ar(
			numChannels: 1,
			bufnum: envelope_buffer,
			rate: rate,
			trigger: trigger,
			startPos: 0,
			loop: 1);

		output = pulsar * envelope;

		^output;
	}
}

NuPG_ModulatorSet {

	*ar {
		arg type = 0, modulation_frequency = 1;

		// Clip type to valid range (0-16)
		type = type.clip(0, 16);

		var mod = Select.ar(type,
			[
				// 0-4: Original types
				SinOsc.ar(modulation_frequency),
				LFSaw.ar(modulation_frequency),
				LatoocarfianC.ar(
					freq: modulation_frequency,
					a: LFNoise2.kr(2,1.5,1.5),
					b: LFNoise2.kr(2,1.5,1.5),
					c: LFNoise2.kr(2,0.5,1.5),
					d: LFNoise2.kr(2,0.5,1.5)
				),
				Gendy3.ar(6, 4, 0.3, 0.5, modulation_frequency),
				HenonC.ar(
					freq: modulation_frequency,
					a:  LFNoise2.kr(1, 0.2, 1.2),
					b: LFNoise2.kr(1, 0.15, 0.15)
				),
				// 5-8: LFDNoise variants
				LFDNoise0.ar(modulation_frequency),  // Sample-and-hold
				LFDNoise1.ar(modulation_frequency),  // Linear interpolation
				LFDNoise2.ar(modulation_frequency),  // Quadratic interpolation
				LFDNoise3.ar(modulation_frequency),  // Cubic interpolation
				// 9-10: Sparse random
				Dust.ar(modulation_frequency) * 2 - 1,  // Scale to -1 to 1
				Crackle.ar(1.5 + (modulation_frequency * 0.003).clip(0, 0.5)),  // Chaos parameter varies
				// 11-14: More chaos (core SuperCollider)
				LorenzL.ar(
					s: 10, r: 28, b: 2.667,
					h: 0.05,
					xi: 0.1, yi: 0, zi: 0
				) * 0.1,  // Lorenz attractor, scaled down
				GbmanL.ar(
					freq: modulation_frequency,
					xi: 1.2, yi: 2.1
				),  // Gingerbreadman map
				StandardL.ar(
					freq: modulation_frequency,
					k: LFNoise2.kr(0.5, 0.5, 1.5),
					xi: 0.5, yi: 0
				),  // Standard map
				CuspL.ar(
					freq: modulation_frequency,
					a: LFNoise2.kr(0.3, 0.3, 1.0),
					b: 1.9,
					xi: 0
				),  // Cusp map
				// 15-16: Complex
				FBSineC.ar(
					freq: modulation_frequency,
					im: 1, fb: 0.1,
					a: 1.1, c: 0.5,
					xi: 0.1, yi: 0.1
				),  // Feedback sine
				LinCongC.ar(
					freq: modulation_frequency,
					a: 1.1, c: 0.13,
					m: 1.0, xi: 0
				)   // Linear congruential
		]);

		^mod;

	}
}


NuPG_Synthesis {

	var <>trainInstances;

	//adjustable number of instances of synthesis graph
	trains {|numInstances = 3, numChannels = 2|

		trainInstances = numInstances.collect{|i|

			Ndef((\nuPG_train_ ++ i).asSymbol, {
				//buffers
				arg pulsaret_buffer, envelope_buffer = -1, frequency_buffer,
				//flux, modulations
				allFluxAmt = 0.0, allFluxAmt_loop = 1, fluxRate = 40,
				fmRatio = 5, fmRatio_loop = 1, fmAmt = 5, fmAmt_loop = 1,
				modMul = 3, modAdd = 3,
				fmIndex = 0, modulationMode = 0,
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
				//formants
				formantModel = 0,
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
				//env
				envOneMod_one_active = 0, envOneMod_two_active = 0, envOneMod_three_active = 0, envOneMod_four_active = 0,
				envOneMod_five_active = 0, envOneMod_six_active = 0, envOneMod_seven_active = 0, envOneMod_eight_active = 0,
				envTwoMod_one_active = 0, envTwoMod_two_active = 0, envTwoMod_three_active = 0, envTwoMod_four_active = 0,
				envTwoMod_five_active = 0, envTwoMod_six_active = 0, envTwoMod_seven_active = 0, envTwoMod_eight_active = 0,
				envThreeMod_one_active = 0, envThreeMod_two_active = 0, envThreeMod_three_active = 0, envThreeMod_four_active = 0,
				envThreeMod_five_active = 0, envThreeMod_six_active = 0, envThreeMod_seven_active = 0, envThreeMod_eight_active = 0,
				//amp
				amplitude_One = 1, amplitude_Two = 1, amplitude_Three = 1,
				amplitude_One_loop = 1, amplitude_Two_loop = 1, amplitude_Three_loop = 1,
				//amp  modulators
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
				//offset modulator
				offset_1_one_active = 0, offset_1_two_active = 0, offset_1_three_active = 0, offset_1_four_active = 0,
				offset_1_five_active = 0, offset_1_six_active = 0, offset_1_seven_active = 0, offset_1_eight_active = 0,
				offset_2_one_active = 0, offset_2_two_active = 0, offset_2_three_active = 0, offset_2_four_active = 0,
				offset_2_five_active = 0, offset_2_six_active = 0, offset_2_seven_active = 0, offset_2_eight_active = 0,
				offset_3_one_active = 0, offset_3_two_active = 0, offset_3_three_active = 0, offset_3_four_active = 0,
				offset_3_five_active = 0, offset_3_six_active = 0, offset_3_seven_active = 0, offset_3_eight_active = 0,

				group_1_onOff = 0, group_2_onOff = 0, group_3_onOff = 0,
				pulsarVersion = 0;


				var trigger, sendTrigger;
				var ffreq_One, ffreq_Two, ffreq_Three;
				var envM_One, envM_Two, envM_Three;
				var trigFreqFlux, grainFreqFlux, ampFlux;
				var grainDur_One, grainDur_Two, grainDur_Three;
				var channelMask;
				var sieveMask;
				var rate_One, rate_Two, rate_Three;
				var pulsar_1, pulsar_2, pulsar_3;
				var freqEnvPlayBuf_One, freqEnvPlayBuf_Two, freqEnvPlayBuf_Three;
				var mix;
				var group_1_env, group_2_env, group_3_env;
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

				/*definition*/

				//flux
				allFluxAmt = allFluxAmt * allFluxAmt_loop;

				trigFreqFlux = allFluxAmt;
				grainFreqFlux = allFluxAmt;
				ampFlux = allFluxAmt;

				//fm
				fmRatio = fmRatio * fmRatio_loop;
				fmAmt = fmAmt * fmAmt_loop;

				//additional moddulators
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

				//trigger frequency
				//modulators
				fundamentalMod_one = Select.ar(fundamentalMod_one_active, [K2A.ar(0), (modulation_index_one * mod_one)]);
				/*fundamentalMod_one = fundamentalMod_one.range(
					(modulation_frequency_one * modulation_index_one).neg,
					(modulation_frequency_one * modulation_index_one)
				);*/

				fundamentalMod_two = Select.ar(fundamentalMod_two_active, [K2A.ar(0), (modulation_index_two * mod_two)]);
				/*fundamentalMod_two = fundamentalMod_two.range(
					(modulation_frequency_two * modulation_index_two).neg,
					(modulation_frequency_two * modulation_index_two)
				);*/

				fundamentalMod_three = Select.ar(fundamentalMod_three_active, [K2A.ar(0), (modulation_index_three * mod_three)]);
				/*fundamentalMod_three = fundamentalMod_three.range(
					(modulation_frequency_three * modulation_index_three).neg,
					(modulation_frequency_three * modulation_index_three)
				);*/

				fundamentalMod_four = Select.ar(fundamentalMod_four_active, [K2A.ar(0), (modulation_index_four * mod_four)]);
				fundamentalMod_five = Select.ar(fundamentalMod_five_active, [K2A.ar(0), (modulation_index_five * mod_five)]);
				fundamentalMod_six = Select.ar(fundamentalMod_six_active, [K2A.ar(0), (modulation_index_six * mod_six)]);
				fundamentalMod_seven = Select.ar(fundamentalMod_seven_active, [K2A.ar(0), (modulation_index_seven * mod_seven)]);
				fundamentalMod_eight = Select.ar(fundamentalMod_eight_active, [K2A.ar(0), (modulation_index_eight * mod_eight)]);

				trigger = (fundamental_frequency * fundamental_frequency_loop) +
				(fundamentalMod_one + fundamentalMod_two + fundamentalMod_three + fundamentalMod_four +
				 fundamentalMod_five + fundamentalMod_six + fundamentalMod_seven + fundamentalMod_eight);

				trigger = Impulse.ar(trigger *
					LFDNoise3.kr(fluxRate * ExpRand(0.8, 1.2), trigFreqFlux, 1), phase);

				trigger = trigger.clip(0, 4000);
				//probability mask
				trigger = trigger * CoinGate.ar(probability * probability_loop, trigger);
				//burst masking
				trigger = trigger * Demand.ar(trigger, 1, Dseq([Dser([1], burst), Dser([0], rest)], inf));

				//send trigger for language processing
				sendTrigger = SendTrig.ar(trigger, 0);
				trigger = Delay1.ar(trigger);

				//sieve masing
				sieveMask = Demand.ar(trigger, 0, Dseries());
				sieveMask = Select.ar(sieveMask.mod(sieveMod), K2A.ar(sieveSequence));
				trigger = trigger * Select.kr(sieveMaskOn, [K2A.ar(1), sieveMask]);
				channelMask = Demand.ar(trigger, 0, Dseq([Dser([-1], chanMask),
					Dser([1], chanMask), Dser([0], centerMask)], inf));

				//formant 1
				formantOneMod_one = Select.ar(formantOneMod_one_active, [K2A.ar(0), (modulation_index_one * mod_one)]);
				/*formantOneMod_one = formantOneMod_one.range(
					(modulation_frequency_one * modulation_index_one).neg,
					(modulation_frequency_one * modulation_index_one)
				);*/

				formantOneMod_two = Select.ar(formantOneMod_two_active, [K2A.ar(0), (modulation_index_two * mod_two)]);
				/*formantOneMod_two = formantOneMod_two.range(
					(modulation_frequency_two * modulation_index_two).neg,
					(modulation_frequency_two * modulation_index_two)
				);*/

				formantOneMod_three = Select.ar(formantOneMod_three_active, [K2A.ar(0), (modulation_index_three * mod_three)]);
				/*formantOneMod_three = formantOneMod_three.range(
					(modulation_frequency_three * modulation_index_three).neg,
					(modulation_frequency_three * modulation_index_three)
				);*/

				formantOneMod_four = Select.ar(formantOneMod_four_active, [K2A.ar(0), (modulation_index_four * mod_four)]);
				formantOneMod_five = Select.ar(formantOneMod_five_active, [K2A.ar(0), (modulation_index_five * mod_five)]);
				formantOneMod_six = Select.ar(formantOneMod_six_active, [K2A.ar(0), (modulation_index_six * mod_six)]);
				formantOneMod_seven = Select.ar(formantOneMod_seven_active, [K2A.ar(0), (modulation_index_seven * mod_seven)]);
				formantOneMod_eight = Select.ar(formantOneMod_eight_active, [K2A.ar(0), (modulation_index_eight * mod_eight)]);

				formant_frequency_One_loop = Select.kr(group_1_onOff, [1, formant_frequency_One_loop]);
				ffreq_One = (formant_frequency_One * formant_frequency_One_loop) +
				(formantOneMod_one + formantOneMod_two + formantOneMod_three + formantOneMod_four +
				 formantOneMod_five + formantOneMod_six + formantOneMod_seven + formantOneMod_eight);

				//formant 2
				formantTwoMod_one = Select.ar(formantTwoMod_one_active, [K2A.ar(0), (modulation_index_one * mod_one)]);
				/*formantTwoMod_one = formantTwoMod_one.range(
					(modulation_frequency_one * modulation_index_one).neg,
					(modulation_frequency_one * modulation_index_one)
				);*/

				formantTwoMod_two = Select.ar(formantTwoMod_two_active, [K2A.ar(0), (modulation_index_two * mod_two)]);
				/*formantTwoMod_two = formantTwoMod_two.range(
					(modulation_frequency_two * modulation_index_two).neg,
					(modulation_frequency_two * modulation_index_two)
				);*/

				formantTwoMod_three = Select.ar(formantTwoMod_three_active, [K2A.ar(0), (modulation_index_three * mod_one)]);
				/*formantTwoMod_three = formantTwoMod_three.range(
					(modulation_frequency_three * modulation_index_three).neg,
					(modulation_frequency_three * modulation_index_three)
				);*/

				formantTwoMod_four = Select.ar(formantTwoMod_four_active, [K2A.ar(0), (modulation_index_four * mod_four)]);
				formantTwoMod_five = Select.ar(formantTwoMod_five_active, [K2A.ar(0), (modulation_index_five * mod_five)]);
				formantTwoMod_six = Select.ar(formantTwoMod_six_active, [K2A.ar(0), (modulation_index_six * mod_six)]);
				formantTwoMod_seven = Select.ar(formantTwoMod_seven_active, [K2A.ar(0), (modulation_index_seven * mod_seven)]);
				formantTwoMod_eight = Select.ar(formantTwoMod_eight_active, [K2A.ar(0), (modulation_index_eight * mod_eight)]);

				formant_frequency_Two_loop = Select.kr(group_2_onOff, [1, formant_frequency_Two_loop]);
				ffreq_Two = (formant_frequency_Two * formant_frequency_Two_loop) +
							(formantTwoMod_one + formantTwoMod_two + formantTwoMod_three + formantTwoMod_four +
							 formantTwoMod_five + formantTwoMod_six + formantTwoMod_seven + formantTwoMod_eight);
				//formant 3
				formantThreeMod_one = Select.ar(formantThreeMod_one_active, [K2A.ar(0), (modulation_index_one * mod_one)]);
				/*formantThreeMod_one = formantThreeMod_one.range(
					(modulation_frequency_one * modulation_index_one).neg,
					(modulation_frequency_one * modulation_index_one)
				);*/

				formantThreeMod_two = Select.ar(formantThreeMod_two_active, [K2A.ar(0), (modulation_index_two * mod_two)]);
				/*formantThreeMod_two = formantThreeMod_two.range(
					(modulation_frequency_two * modulation_index_two).neg,
					(modulation_frequency_two * modulation_index_two)
				);*/

				formantThreeMod_three = Select.ar(formantThreeMod_three_active, [K2A.ar(0), (modulation_index_three * mod_three)]);
				/*formantThreeMod_three = formantThreeMod_three.range(
					(modulation_frequency_three * modulation_index_three).neg,
					(modulation_frequency_three * modulation_index_three)
				);*/

				formantThreeMod_four = Select.ar(formantThreeMod_four_active, [K2A.ar(0), (modulation_index_four * mod_four)]);
				formantThreeMod_five = Select.ar(formantThreeMod_five_active, [K2A.ar(0), (modulation_index_five * mod_five)]);
				formantThreeMod_six = Select.ar(formantThreeMod_six_active, [K2A.ar(0), (modulation_index_six * mod_six)]);
				formantThreeMod_seven = Select.ar(formantThreeMod_seven_active, [K2A.ar(0), (modulation_index_seven * mod_seven)]);
				formantThreeMod_eight = Select.ar(formantThreeMod_eight_active, [K2A.ar(0), (modulation_index_eight * mod_eight)]);

				formant_frequency_Three_loop = Select.kr(group_3_onOff, [1, formant_frequency_Three_loop]);
				ffreq_Three = (formant_frequency_Three * formant_frequency_Three_loop) +
							(formantThreeMod_one + formantThreeMod_two + formantThreeMod_three + formantThreeMod_four +
							 formantThreeMod_five + formantThreeMod_six + formantThreeMod_seven + formantThreeMod_eight);

				// Envelope multiplier modulation (rows 4-6 in matrix)
				// Uses multiplicative modulation similar to amplitude
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

				//envelope multiplication 1 (with modulation)
				envMul_One_loop = Select.kr(group_1_onOff, [1, envMul_One_loop]);
				envM_One = ffreq_One * (envMul_One * envMul_One_loop *
					(envMulOneMod_one * envMulOneMod_two * envMulOneMod_three * envMulOneMod_four *
					 envMulOneMod_five * envMulOneMod_six * envMulOneMod_seven * envMulOneMod_eight)) *
					(2048/Server.default.sampleRate);
				//envelope multiplication 2 (with modulation)
				envMul_Two_loop = Select.kr(group_2_onOff, [1, envMul_Two_loop]);
				envM_Two = ffreq_Two * (envMul_Two * envMul_Two_loop *
					(envMulTwoMod_one * envMulTwoMod_two * envMulTwoMod_three * envMulTwoMod_four *
					 envMulTwoMod_five * envMulTwoMod_six * envMulTwoMod_seven * envMulTwoMod_eight)) *
					(2048/Server.default.sampleRate);
				//envelope multiplication 3 (with modulation)
				envMul_Three_loop = Select.kr(group_3_onOff, [1, envMul_Three_loop]);
				envM_Three = ffreq_Three * (envMul_Three * envMul_Three_loop *
					(envMulThreeMod_one * envMulThreeMod_two * envMulThreeMod_three * envMulThreeMod_four *
					 envMulThreeMod_five * envMulThreeMod_six * envMulThreeMod_seven * envMulThreeMod_eight)) *
					(2048/Server.default.sampleRate);

				//grain duration 1
				grainDur_One = 2048 / Server.default.sampleRate / envM_One;
				//grain duration 2
				grainDur_Two = 2048 / Server.default.sampleRate / envM_Two;
				//grain duration 3
				grainDur_Three = 2048 / Server.default.sampleRate / envM_Three;

				//formant 1 flux
				ffreq_One = ffreq_One * LFDNoise3.ar(fluxRate * ExpRand(0.01, 2.9), grainFreqFlux, 1);
				//formant 2 flux
				ffreq_Two = ffreq_Two * LFDNoise3.ar(fluxRate * ExpRand(0.01, 2.9), grainFreqFlux, 1);
				//formant 3 flux
				ffreq_Three = ffreq_Three * LFDNoise3.ar(fluxRate * ExpRand(0.01, 2.9), grainFreqFlux, 1);

				//amplitude 1
				amplitude_One_loop = Select.kr(group_1_onOff, [1, amplitude_One_loop]);

				ampOneMod_one = Select.ar(ampOneMod_one_active, [
					K2A.ar(1),
					((1 + (modulation_index_one * 0.1)) * mod_one.unipolar)
				]);
				ampOneMod_two = Select.ar(ampOneMod_two_active, [
					K2A.ar(1),
					((1 + (modulation_index_two * 0.1)) * mod_two.unipolar)
				]);
				ampOneMod_three = Select.ar(ampOneMod_three_active, [
					K2A.ar(1),
					((1 + (modulation_index_three * 0.1)) * mod_three.unipolar)
				]);
				ampOneMod_four = Select.ar(ampOneMod_four_active, [
					K2A.ar(1),
					((1 + (modulation_index_four * 0.1)) * mod_four.unipolar)
				]);
				ampOneMod_five = Select.ar(ampOneMod_five_active, [
					K2A.ar(1),
					((1 + (modulation_index_five * 0.1)) * mod_five.unipolar)
				]);
				ampOneMod_six = Select.ar(ampOneMod_six_active, [
					K2A.ar(1),
					((1 + (modulation_index_six * 0.1)) * mod_six.unipolar)
				]);
				ampOneMod_seven = Select.ar(ampOneMod_seven_active, [
					K2A.ar(1),
					((1 + (modulation_index_seven * 0.1)) * mod_seven.unipolar)
				]);
				ampOneMod_eight = Select.ar(ampOneMod_eight_active, [
					K2A.ar(1),
					((1 + (modulation_index_eight * 0.1)) * mod_eight.unipolar)
				]);

				amplitude_One = amplitude_One * amplitude_One_loop *
				(ampOneMod_one * ampOneMod_two * ampOneMod_three * ampOneMod_four *
				 ampOneMod_five * ampOneMod_six * ampOneMod_seven * ampOneMod_eight) * (1 - mute);
				amplitude_One = amplitude_One.clip(0, 1);

				//amplitude 2
				amplitude_Two_loop = Select.kr(group_2_onOff, [1, amplitude_Two_loop]);
				ampTwoMod_one = Select.ar(ampTwoMod_one_active, [
					K2A.ar(1),
					((1 + (modulation_index_one * 0.1)) * mod_one.unipolar)
				]);
				ampTwoMod_two = Select.ar(ampTwoMod_two_active, [
					K2A.ar(1),
					((1 + (modulation_index_two * 0.1)) * mod_two.unipolar)
				]);
				ampTwoMod_three = Select.ar(ampTwoMod_three_active, [
					K2A.ar(1),
					((1 + (modulation_index_three * 0.1)) * mod_three.unipolar)
				]);
				ampTwoMod_four = Select.ar(ampTwoMod_four_active, [
					K2A.ar(1),
					((1 + (modulation_index_four * 0.1)) * mod_four.unipolar)
				]);
				ampTwoMod_five = Select.ar(ampTwoMod_five_active, [
					K2A.ar(1),
					((1 + (modulation_index_five * 0.1)) * mod_five.unipolar)
				]);
				ampTwoMod_six = Select.ar(ampTwoMod_six_active, [
					K2A.ar(1),
					((1 + (modulation_index_six * 0.1)) * mod_six.unipolar)
				]);
				ampTwoMod_seven = Select.ar(ampTwoMod_seven_active, [
					K2A.ar(1),
					((1 + (modulation_index_seven * 0.1)) * mod_seven.unipolar)
				]);
				ampTwoMod_eight = Select.ar(ampTwoMod_eight_active, [
					K2A.ar(1),
					((1 + (modulation_index_eight * 0.1)) * mod_eight.unipolar)
				]);
				amplitude_Two = amplitude_Two * amplitude_Two_loop *
				(ampTwoMod_one * ampTwoMod_two * ampTwoMod_three * ampTwoMod_four *
				 ampTwoMod_five * ampTwoMod_six * ampTwoMod_seven * ampTwoMod_eight) * (1 - mute);
				amplitude_Two = amplitude_Two.clip(0, 1);

				//amplitude 3
				amplitude_Three_loop = Select.kr(group_3_onOff, [1, amplitude_Three_loop]);
				ampThreeMod_one = Select.ar(ampThreeMod_one_active, [
					K2A.ar(1),
					((1 + (modulation_index_one * 0.1)) * mod_one.unipolar)
				]);
				ampThreeMod_two = Select.ar(ampThreeMod_two_active, [
					K2A.ar(1),
					((1 + (modulation_index_two * 0.1)) * mod_two.unipolar)
				]);
				ampThreeMod_three = Select.ar(ampThreeMod_three_active, [
					K2A.ar(1),
					((1 + (modulation_index_three * 0.1)) * mod_three.unipolar)
				]);
				ampThreeMod_four = Select.ar(ampThreeMod_four_active, [
					K2A.ar(1),
					((1 + (modulation_index_four * 0.1)) * mod_four.unipolar)
				]);
				ampThreeMod_five = Select.ar(ampThreeMod_five_active, [
					K2A.ar(1),
					((1 + (modulation_index_five * 0.1)) * mod_five.unipolar)
				]);
				ampThreeMod_six = Select.ar(ampThreeMod_six_active, [
					K2A.ar(1),
					((1 + (modulation_index_six * 0.1)) * mod_six.unipolar)
				]);
				ampThreeMod_seven = Select.ar(ampThreeMod_seven_active, [
					K2A.ar(1),
					((1 + (modulation_index_seven * 0.1)) * mod_seven.unipolar)
				]);
				ampThreeMod_eight = Select.ar(ampThreeMod_eight_active, [
					K2A.ar(1),
					((1 + (modulation_index_eight * 0.1)) * mod_eight.unipolar)
				]);
				amplitude_Three = amplitude_Three * amplitude_Three_loop *
				(ampThreeMod_one * ampThreeMod_two * ampThreeMod_three * ampThreeMod_four *
				 ampThreeMod_five * ampThreeMod_six * ampThreeMod_seven * ampThreeMod_eight) * (1 - mute);
				amplitude_Three = amplitude_Three.clip(0, 1);

				//pan 1
				panOneMod_one = Select.ar(panOneMod_one_active, [
					K2A.ar(0),
					((modulation_index_one * 0.1) * mod_one)
				]);
				panOneMod_two = Select.ar(panOneMod_two_active, [
					K2A.ar(0),
					((modulation_index_two * 0.1) * mod_two)
				]);
				panOneMod_three = Select.ar(panOneMod_three_active, [
					K2A.ar(0),
					((modulation_index_three * 0.1) * mod_three)
				]);
				panOneMod_four = Select.ar(panOneMod_four_active, [
					K2A.ar(0),
					((modulation_index_four * 0.1) * mod_four)
				]);
				panOneMod_five = Select.ar(panOneMod_five_active, [
					K2A.ar(0),
					((modulation_index_five * 0.1) * mod_five)
				]);
				panOneMod_six = Select.ar(panOneMod_six_active, [
					K2A.ar(0),
					((modulation_index_six * 0.1) * mod_six)
				]);
				panOneMod_seven = Select.ar(panOneMod_seven_active, [
					K2A.ar(0),
					((modulation_index_seven * 0.1) * mod_seven)
				]);
				panOneMod_eight = Select.ar(panOneMod_eight_active, [
					K2A.ar(0),
					((modulation_index_eight * 0.1) * mod_eight)
				]);

				pan_One_loop = Select.kr(group_1_onOff, [0, pan_One_loop]);
				pan_One = pan_One + pan_One_loop + (panOneMod_one + panOneMod_two + panOneMod_three + panOneMod_four +
					panOneMod_five + panOneMod_six + panOneMod_seven + panOneMod_eight);
				pan_One = pan_One.fold(-1, 1);
				pan_One = pan_One + channelMask;

				//pan 2
				pan_Two_loop = Select.kr(group_2_onOff, [0, pan_Two_loop]);
				panTwoMod_one = Select.ar(panTwoMod_one_active, [
					K2A.ar(0),
					((modulation_index_one * 0.1) * mod_one)
				]);
				panTwoMod_two = Select.ar(panTwoMod_two_active, [
					K2A.ar(0),
					((modulation_index_two * 0.1) * mod_two)
				]);
				panTwoMod_three = Select.ar(panTwoMod_three_active, [
					K2A.ar(0),
					((modulation_index_three * 0.1) * mod_three)
				]);
				panTwoMod_four = Select.ar(panTwoMod_four_active, [
					K2A.ar(0),
					((modulation_index_four * 0.1) * mod_four)
				]);
				panTwoMod_five = Select.ar(panTwoMod_five_active, [
					K2A.ar(0),
					((modulation_index_five * 0.1) * mod_five)
				]);
				panTwoMod_six = Select.ar(panTwoMod_six_active, [
					K2A.ar(0),
					((modulation_index_six * 0.1) * mod_six)
				]);
				panTwoMod_seven = Select.ar(panTwoMod_seven_active, [
					K2A.ar(0),
					((modulation_index_seven * 0.1) * mod_seven)
				]);
				panTwoMod_eight = Select.ar(panTwoMod_eight_active, [
					K2A.ar(0),
					((modulation_index_eight * 0.1) * mod_eight)
				]);

				pan_Two = pan_Two + pan_Two_loop + (panTwoMod_one + panTwoMod_two + panTwoMod_three + panTwoMod_four +
					panTwoMod_five + panTwoMod_six + panTwoMod_seven + panTwoMod_eight);
				pan_Two = pan_Two.fold(-1, 1);
				pan_Two = pan_Two + channelMask;
				//pan 3
				pan_Three_loop = Select.kr(group_3_onOff, [0, pan_Three_loop]);
				panThreeMod_one = Select.ar(panThreeMod_one_active, [
					K2A.ar(0),
					((modulation_index_one * 0.1) * mod_one)
				]);
				panThreeMod_two = Select.ar(panThreeMod_two_active, [
					K2A.ar(0),
					((modulation_index_two * 0.1) * mod_two)
				]);
				panThreeMod_three = Select.ar(panThreeMod_three_active, [
					K2A.ar(0),
					((modulation_index_three * 0.1) * mod_three)
				]);
				panThreeMod_four = Select.ar(panThreeMod_four_active, [
					K2A.ar(0),
					((modulation_index_four * 0.1) * mod_four)
				]);
				panThreeMod_five = Select.ar(panThreeMod_five_active, [
					K2A.ar(0),
					((modulation_index_five * 0.1) * mod_five)
				]);
				panThreeMod_six = Select.ar(panThreeMod_six_active, [
					K2A.ar(0),
					((modulation_index_six * 0.1) * mod_six)
				]);
				panThreeMod_seven = Select.ar(panThreeMod_seven_active, [
					K2A.ar(0),
					((modulation_index_seven * 0.1) * mod_seven)
				]);
				panThreeMod_eight = Select.ar(panThreeMod_eight_active, [
					K2A.ar(0),
					((modulation_index_eight * 0.1) * mod_eight)
				]);
				pan_Three = pan_Three + pan_Three_loop + (panThreeMod_one + panThreeMod_two + panThreeMod_three + panThreeMod_four +
					panThreeMod_five + panThreeMod_six + panThreeMod_seven + panThreeMod_eight);
				pan_Three = pan_Three.fold(-1, 1);
				pan_Three = pan_Three + channelMask;

				freqEnvPlayBuf_One = PlayBuf.ar(1, frequency_buffer,
					(ffreq_One * 2048/Server.default.sampleRate), trigger, 0, loop: 0);
				freqEnvPlayBuf_Two = PlayBuf.ar(1, frequency_buffer,
					(ffreq_Two * 2048/Server.default.sampleRate), trigger, 0, loop: 0);
				freqEnvPlayBuf_Three = PlayBuf.ar(1, frequency_buffer,
					(ffreq_Three * 2048/Server.default.sampleRate), trigger, 0, loop: 0);

				//rate 1
				rate_One = (ffreq_One * 2048/Server.default.sampleRate) * (1 + (freqEnvPlayBuf_One * fmAmt));
				//rate_One = rate_One *
				//(1 + Latch.ar(LFSaw.ar(ffreq_One * fmRatio, 0, fmAmt/modMul, fmAmt/modAdd), trigger));
				//rate 2
				rate_Two = (ffreq_Two * 2048/Server.default.sampleRate) * (1 + (freqEnvPlayBuf_Two * fmAmt));
				//rate_Two = rate_Two *
				//(1 + Latch.ar(LFSaw.ar(ffreq_Two * fmRatio, 0, fmAmt/modMul, fmAmt/modAdd), trigger));
				//rate 3
				rate_Three = (ffreq_Three * 2048/Server.default.sampleRate) * (1 + (freqEnvPlayBuf_Three * fmAmt));
				//rate_Three = rate_Three *
				//(1 + Latch.ar(LFSaw.ar(ffreq_Three * fmRatio, 0, fmAmt/modMul, fmAmt/modAdd), trigger));

				fmRatio = fmRatio * fmRatio_loop;
				fmAmt = fmAmt * fmAmt_loop;

				//pulsar generator pseudo-ugen
				pulsar_1 = NuPG_AdC.ar(
					channels_number: numChannels,
					trigger:  DelayN.ar(trigger, 1, offset_1),
					grain_duration: grainDur_One,
					pulsar_buffer: pulsaret_buffer,
					rate: rate_One *
					(1 + Select.kr(modulationMode,
						[
							Latch.ar(LFSaw.ar(ffreq_One * fmRatio, 0, fmAmt/modMul, fmAmt/modAdd), DelayN.ar(trigger, 1, offset_1)),
							Latch.ar(LFSaw.ar(ffreq_One - fmAmt * fmRatio, 0, fmAmt/modMul, fmAmt/modAdd) - fmAmt, DelayN.ar(trigger, 1, offset_1))
					]))
					,
					panning: pan_One,
					envelope_buffer: envelope_buffer
				);

				pulsar_1 = pulsar_1 * amplitude_One;
				pulsar_1 = pulsar_1 * amplitude_local_One;


				pulsar_2 = NuPG_AdC.ar(
					channels_number: numChannels,
					trigger: DelayN.ar(trigger, 1, offset_2),
					grain_duration: grainDur_Two,
					pulsar_buffer: pulsaret_buffer,
					rate: rate_Two *
					(1 + Select.kr(modulationMode,
						[
							Latch.ar(LFSaw.ar(ffreq_Two * fmRatio, 0, fmAmt/modMul, fmAmt/modAdd), DelayN.ar(trigger, 1, offset_2)),
							Latch.ar(LFSaw.ar(ffreq_Two - fmAmt * fmRatio, 0, fmAmt/modMul, fmAmt/modAdd) - fmAmt, DelayN.ar(trigger, 1, offset_2))
					])),
					panning: pan_Two,
					envelope_buffer: envelope_buffer
				);
				pulsar_2 = pulsar_2 * amplitude_Two;
				pulsar_2 = pulsar_2 * amplitude_local_Two;

				pulsar_3 = NuPG_AdC.ar(
					channels_number: numChannels,
					trigger:  DelayN.ar(trigger, 1, offset_3),
					grain_duration: grainDur_Three,
					pulsar_buffer: pulsaret_buffer,
					rate: rate_Three *
					(1 + Select.kr(modulationMode,
						[
							Latch.ar(LFSaw.ar(ffreq_Three * fmRatio, 0, fmAmt/modMul, fmAmt/modAdd), DelayN.ar(trigger, 1, offset_3)),
							Latch.ar(LFSaw.ar(ffreq_Three - fmAmt * fmRatio, 0, fmAmt/modMul, fmAmt/modAdd) - fmAmt, DelayN.ar(trigger, 1, offset_3))
					])),
					panning: pan_Three,
					envelope_buffer: envelope_buffer
				);
				pulsar_3 = pulsar_3 * amplitude_Three;
				pulsar_3 = pulsar_3 * amplitude_local_Three;

				mix = Mix.new([pulsar_1, pulsar_2, pulsar_3]) * globalAmplitude;

				LeakDC.ar(mix)
			});
		};

		^trainInstances
	}
}