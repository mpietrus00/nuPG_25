// NuPG_ModulationRouter.sc
// Helper classes for cleaner modulation routing
// Replaces verbose per-modulator Select.ar patterns with array-based approach

NuPG_ModulationRouter {

	// Additive modulation routing for frequency-based targets
	// (fundamental, formants) where modulation adds to the base value
	*additiveRouting { |activeParams, mods, indices|
		^activeParams.collect { |active, i|
			Select.ar(active, [K2A.ar(0), indices[i] * mods[i]])
		}.sum;
	}

	// Multiplicative modulation routing for amplitude-based targets
	// (amplitude, envelope) where modulation scales the base value
	*multiplicativeRouting { |activeParams, mods, indices, scale = 0.1|
		^activeParams.collect { |active, i|
			Select.ar(active, [
				K2A.ar(1),
				(1 + (indices[i] * scale)) * mods[i].unipolar
			])
		}.product;
	}

	// Bipolar modulation routing for pan targets
	// where modulation can go positive or negative
	*bipolarRouting { |activeParams, mods, indices, scale = 0.1|
		^activeParams.collect { |active, i|
			Select.ar(active, [K2A.ar(0), (indices[i] * scale) * mods[i]])
		}.sum;
	}
}


// NuPG_ModulatorBank: Creates an array of modulators
// Simplifies modulator instantiation from 8 separate calls to one
NuPG_ModulatorBank {

	*ar { |types, frequencies|
		^types.collect { |type, i|
			NuPG_ModulatorSet.ar(
				type: type,
				modulation_frequency: frequencies[i]
			)
		};
	}
}


// NuPG_MatrixModulation: High-level modulation matrix processor
// Provides a cleaner interface for the entire modulation matrix
NuPG_MatrixModulation {

	// Process all modulations for a single target with additive combination
	*processAdditive { |mods, indices, matrixRow|
		// matrixRow is an array of 8 active/intensity values (one per modulator)
		// Returns the sum of all active modulations
		^NuPG_ModulationRouter.additiveRouting(matrixRow, mods, indices);
	}

	// Process all modulations for a single target with multiplicative combination
	*processMultiplicative { |mods, indices, matrixRow, scale = 0.1|
		// Returns the product of all active modulations (each defaults to 1 when inactive)
		^NuPG_ModulationRouter.multiplicativeRouting(matrixRow, mods, indices, scale);
	}

	// Process all modulations for a bipolar target (like panning)
	*processBipolar { |mods, indices, matrixRow, scale = 0.1|
		^NuPG_ModulationRouter.bipolarRouting(matrixRow, mods, indices, scale);
	}

	// Process entire modulation matrix for all targets
	// targets: array of target configs [ [name, type, row], ... ]
	// type: \additive, \multiplicative, or \bipolar
	*processMatrix { |mods, indices, matrix, targetConfigs|
		var results = Dictionary.new;

		targetConfigs.do { |config|
			var name = config[0];
			var type = config[1];
			var row = config[2];
			var matrixRow = matrix[row];

			results[name] = switch(type,
				\additive, { this.processAdditive(mods, indices, matrixRow) },
				\multiplicative, { this.processMultiplicative(mods, indices, matrixRow) },
				\bipolar, { this.processBipolar(mods, indices, matrixRow) }
			);
		};

		^results;
	}
}
