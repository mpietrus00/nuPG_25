// NuPG_CV_Extensions.sc
// Extension methods to make Connection Quark CVs work like Conductor CVs
// Provides .connect() method for compatibility with existing GUI code

+ NumericControlValue {

	// Connect CV to a GUI View (Slider, NumberBox, MultiSliderView, etc.)
	// Mimics Conductor's cv.connect(view) behavior
	// Automatically detects view type and uses appropriate connection pattern
	connect { |view|
		// Detect view type and use appropriate connection
		case
		{ view.isKindOf(Slider) } {
			this.prConnectToSlider(view);
		}
		{ view.isKindOf(NumberBox) } {
			this.prConnectToNumberBox(view);
		}
		{ view.isKindOf(MultiSliderView) } {
			this.prConnectToMultiSlider(view);
		}
		{ view.isKindOf(TextField) } {
			this.prConnectToTextField(view);
		}
		{
			// Generic fallback - try normalized connection
			this.prConnectGeneric(view);
		};

		^this;
	}

	// Private: Connect to Slider (uses normalized 0-1 range)
	prConnectToSlider { |slider|
		// Set initial value (normalized)
		slider.value = this.spec.unmap(this.value);

		// CV -> Slider: update when CV changes
		this.addDependant({ |theCV, what, val|
			if (what == \value) {
				defer { slider.value = this.spec.unmap(val) };
			};
		});

		// Slider -> CV
		slider.action = { |sl|
			this.value = this.spec.map(sl.value);
		};
	}

	// Private: Connect to NumberBox (uses actual value)
	prConnectToNumberBox { |numberBox|
		// Set initial value
		numberBox.value = this.value;

		// CV -> NumberBox
		this.addDependant({ |theCV, what, val|
			if (what == \value) {
				defer { numberBox.value = val };
			};
		});

		// NumberBox -> CV
		numberBox.action = { |nb|
			this.value = nb.value;
		};
	}

	// Private: Connect to MultiSliderView (for table data)
	prConnectToMultiSlider { |multiSlider|
		var minVal = this.spec.minval;
		var maxVal = this.spec.maxval;

		// Set initial values (normalize array to 0-1)
		if (this.value.isArray) {
			multiSlider.value = this.value.linlin(minVal, maxVal, 0, 1);
		};

		// CV -> MultiSlider
		this.addDependant({ |theCV, what, val|
			if (what == \value) {
				defer {
					if (val.isArray) {
						multiSlider.value = val.linlin(minVal, maxVal, 0, 1);
					};
				};
			};
		});

		// MultiSlider -> CV
		multiSlider.action = { |ms|
			this.value = ms.value.linlin(0, 1, minVal, maxVal);
		};
	}

	// Private: Connect to TextField
	prConnectToTextField { |textField|
		textField.string = this.value.asString;

		this.addDependant({ |theCV, what, val|
			if (what == \value) {
				defer { textField.string = val.asString };
			};
		});

		textField.action = { |tf|
			this.value = tf.string.asFloat;
		};
	}

	// Private: Generic connection (normalized)
	prConnectGeneric { |view|
		view.value = this.spec.unmap(this.value);

		this.addDependant({ |theCV, what, val|
			if (what == \value) {
				defer { view.value = this.spec.unmap(val) };
			};
		});

		view.action = { |v|
			this.value = this.spec.map(v.value);
		};
	}

	// For array values (tables), set buffer data
	setBuffer { |buffer|
		// Write CV's array value to a buffer
		if (this.value.isArray) {
			buffer.loadCollection(this.value.as(FloatArray));
		};

		// Update buffer when CV changes
		this.addDependant({ |theCV, what, val|
			if (what == \value) {
				if (val.isArray) {
					buffer.loadCollection(val.as(FloatArray));
				};
			};
		});

		^this;
	}

	// Map CV to an Ndef parameter
	mapToNdef { |ndef, paramName|
		// Set initial value
		ndef.set(paramName, this.value);

		// Update Ndef when CV changes
		this.addDependant({ |theCV, what, val|
			if (what == \value) {
				ndef.set(paramName, val);
			};
		});

		^this;
	}

	// Create a pattern stream from the CV
	asControlStream {
		^Pfunc({ this.value });
	}
}

// Extension for Ndef to accept CVs in setControls
+ Ndef {

	// Set controls from an array of [paramName, cv] pairs
	// Compatible with Conductor's setControls pattern
	setControlsFromCVs { |pairs|
		pairs.pairsDo { |paramName, cv|
			if (cv.isKindOf(NumericControlValue)) {
				// Set initial value
				this.set(paramName, cv.value);

				// Update Ndef when CV changes
				cv.addDependant({ |theCV, what, val|
					if (what == \value) {
						this.set(paramName, val);
					};
				});
			} {
				// Not a CV, just set directly
				this.set(paramName, cv);
			};
		};
	}
}

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
		// Execute the generator function to create CVs
		generatorFunc.value;

		// Create a preset manager for this instance
		instances[name] = NuPG_PresetManager(data);
	}

	// Allow dictionary-style access: conductor[\con_0]
	at { |key|
		^instances[key];
	}

	// Allow conductor[\con_0] = value
	put { |key, value|
		instances[key] = value;
	}
}
