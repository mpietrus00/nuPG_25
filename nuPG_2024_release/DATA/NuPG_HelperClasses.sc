// NuPG_HelperClasses.sc
// Helper classes for nuPG Connection Quark migration

// Helper class for managing multiple connections
NuPG_ConnectionManager {
	var <>connections;

	*new {
		^super.new.init;
	}

	init {
		connections = List.new;
	}

	// Connect CV to view and track the connection
	connect { |cv, view|
		cv.connect(view);
		connections.add([cv, view]);
	}

	// Disconnect all managed connections
	disconnectAll {
		connections.do { |pair|
			// Connection quark handles cleanup
		};
		connections.clear;
	}
}

// Preset management class for nuPG
NuPG_PresetManager {
	var <>data;
	var <>presets;  // Array of preset states (for .size compatibility)
	var <>currentPresetCV;
	var <>targetPresetCV;
	var <>interpCV;
	var <>instanceIndex;  // Which instance this manager handles

	*new { |data, instanceIndex = 0|
		^super.new.init(data, instanceIndex);
	}

	init { |dataObj, instIdx|
		data = dataObj;
		instanceIndex = instIdx;
		presets = List.new;  // Use List for .size compatibility

		// Create CVs for preset management (compatible with old Conductor pattern)
		currentPresetCV = NumericControlValue(0, ControlSpec(0, 99, \lin, 1, 0));
		targetPresetCV = NumericControlValue(0, ControlSpec(0, 99, \lin, 1, 0));
		interpCV = NumericControlValue(0, ControlSpec(0, 1, \lin, 0.01, 0));

		// Set up interpolation action
		interpCV.addDependant({ |cv, what, val|
			if (what == \value) {
				this.interpolate(currentPresetCV.value.asInteger, targetPresetCV.value.asInteger, val);
			};
		});
	}

	// Aliases for compatibility with Conductor preset API
	presetCV { ^currentPresetCV }
	targetCV { ^targetPresetCV }

	// Return self for compatibility with conductor[key].preset pattern
	preset { ^this }

	// Add current state as new preset (Conductor compatibility)
	addPreset {
		var state = data.prSerializeStateForInstance(instanceIndex);
		presets.add(state);
		("Preset added at slot:" + (presets.size - 1)).postln;
	}

	// Remove preset at index (Conductor compatibility)
	removePreset { |index|
		if (index >= 0 and: { index < presets.size }) {
			presets.removeAt(index);
			("Preset removed at slot:" + index).postln;
		} {
			("Invalid preset index:" + index).warn;
		};
	}

	// Set/recall preset (Conductor compatibility - alias for recall)
	set { |index|
		this.recall(index);
	}

	store { |slot|
		var state = data.prSerializeStateForInstance(instanceIndex);
		// Extend list if needed
		while { presets.size <= slot } { presets.add(nil) };
		presets[slot] = state;
		("Preset stored at slot:" + slot).postln;
	}

	recall { |slot|
		if (slot >= 0 and: { slot < presets.size }) {
			var state = presets[slot];
			if (state.notNil) {
				data.prDeserializeStateForInstance(state, instanceIndex);
				currentPresetCV.value = slot;
				("Preset recalled from slot:" + slot).postln;
			} {
				("Empty preset at slot:" + slot).postln;
			};
		} {
			("Invalid preset slot:" + slot).postln;
		};
	}

	interpolate { |slotA, slotB, blend|
		if (slotA >= 0 and: { slotA < presets.size } and: { slotB >= 0 } and: { slotB < presets.size }) {
			var stateA = presets[slotA];
			var stateB = presets[slotB];
			if (stateA.notNil and: stateB.notNil) {
				data.prInterpolateStatesForInstance(stateA, stateB, blend, instanceIndex);
			};
		};
	}

	// Save presets to file
	save { |path|
		var file = File(path, "w");
		file.write(presets.asCompileString);
		file.close;
		("Presets saved to:" + path).postln;
	}

	// Load presets from file
	load { |path|
		if (File.exists(path)) {
			var file = File(path, "r");
			var content = file.readAllString;
			file.close;
			// Try to interpret as new format first
			try {
				var loaded = content.interpret;
				if (loaded.isKindOf(List) or: loaded.isKindOf(Array)) {
					presets = loaded.asList;
				} {
					// Could be old Conductor format - try to convert
					presets = this.prConvertOldFormat(loaded);
				};
				("Presets loaded from:" + path).postln;
			} { |error|
				("Error loading presets:" + error).warn;
			};
		} {
			("Preset file not found:" + path).warn;
		};
	}

	// Convert old Conductor preset format to new format
	prConvertOldFormat { |oldData|
		var newPresets = List.new;
		// Old format: [ [ 'preset', [ [], [ [ [ [ 'pulsaret', [...] ], ... ] ] ] ] ] ]
		// Try to extract preset data
		if (oldData.isKindOf(Array) and: { oldData[0].isKindOf(Array) }) {
			oldData[0].do { |presetPair|
				if (presetPair[0] == 'preset') {
					var presetData = presetPair[1];
					// Extract actual preset values
					var state = Dictionary.new;
					presetData.do { |instanceData|
						instanceData.do { |cvData|
							if (cvData.isKindOf(Array) and: { cvData.size >= 2 }) {
								var key = cvData[0];
								var val = cvData[1];
								state[key.asSymbol] = val;
							};
						};
					};
					if (state.size > 0) {
						newPresets.add(state);
					};
				};
			};
		};
		if (newPresets.size == 0) {
			"Could not parse old preset format".warn;
		};
		^newPresets;
	}
}

// Conductor compatibility layer
// Mimics the old Conductor quark API for backward compatibility
NuPG_ConductorCompat {
	var <>data;
	var <>instances;  // Dictionary of instance preset managers
	var <>instanceCount;

	*new { |dataObj|
		^super.new.init(dataObj);
	}

	init { |dataObj|
		data = dataObj;
		instances = IdentityDictionary.new;
		instanceCount = 0;
	}

	// Mimics conductor.addCon(\name, func)
	addCon { |name, generatorFunc|
		// Convert key to symbol for consistent access
		var key = name.asSymbol;
		// Extract instance index from key (e.g., \con_0 -> 0)
		var indexStr = name.asString.split($_).last;
		var index = if (indexStr.notNil) { indexStr.asInteger } { instanceCount };

		// Execute the generator function to create CVs
		generatorFunc.value;

		// Create a preset manager for this instance with its index
		instances[key] = NuPG_PresetManager(data, index);
		instanceCount = instanceCount + 1;
	}

	// Allow dictionary-style access: conductor[\con_0]
	at { |key|
		// Convert to symbol for consistent lookup
		^instances[key.asSymbol];
	}

	// Allow conductor[\con_0] = value
	put { |key, value|
		instances[key.asSymbol] = value;
	}

	// Return the preset manager for an instance (alias for compatibility)
	preset { |key|
		^instances[key.asSymbol];
	}
}
