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
	var <>presets;
	var <>currentPresetCV;
	var <>targetPresetCV;
	var <>interpCV;

	*new { |data|
		^super.new.init(data);
	}

	init { |dataObj|
		data = dataObj;
		presets = Dictionary.new;

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

	// Alias for compatibility: preset.presetCV
	presetCV { ^currentPresetCV }

	// Return self for compatibility with conductor[key].preset pattern
	preset { ^this }

	store { |slot|
		presets[slot] = data.prSerializeState;
		("Preset stored at slot:" + slot).postln;
	}

	recall { |slot|
		var state = presets[slot];
		if (state.notNil) {
			data.prDeserializeState(state);
			currentPresetCV.value = slot;
			("Preset recalled from slot:" + slot).postln;
		} {
			("No preset at slot:" + slot).postln;
		};
	}

	interpolate { |slotA, slotB, blend|
		var stateA = presets[slotA];
		var stateB = presets[slotB];

		if (stateA.notNil and: stateB.notNil) {
			data.prInterpolateStates(stateA, stateB, blend);
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
			presets = content.interpret;
			("Presets loaded from:" + path).postln;
		} {
			("Preset file not found:" + path).warn;
		};
	}
}

// Conductor compatibility layer
// Mimics the old Conductor quark API for backward compatibility
NuPG_ConductorCompat {
	var <>data;
	var <>instances;  // Dictionary of instance preset managers

	*new { |dataObj|
		^super.new.init(dataObj);
	}

	init { |dataObj|
		data = dataObj;
		instances = IdentityDictionary.new;
	}

	// Mimics conductor.addCon(\name, func)
	addCon { |name, generatorFunc|
		// Convert key to symbol for consistent access
		var key = name.asSymbol;

		// Execute the generator function to create CVs
		generatorFunc.value;

		// Create a preset manager for this instance
		instances[key] = NuPG_PresetManager(data);
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
