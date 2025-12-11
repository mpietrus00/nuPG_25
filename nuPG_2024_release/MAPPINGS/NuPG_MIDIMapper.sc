// NuPG_MIDIMapper.sc
// MIDI control mapping for nuPG
// Maps MIDI CC messages to NumericControlValue CVs

NuPG_MIDIMapper {
	classvar <>instance;

	var <>mappings;  // Dictionary of CC -> CV mappings
	var <>midiFunc;
	var <>learnMode;
	var <>learnTarget;
	var <>learnCallback;

	*new {
		if (instance.isNil) {
			instance = super.new.init;
		};
		^instance;
	}

	*initClass {
		instance = nil;
	}

	init {
		mappings = Dictionary.new;
		learnMode = false;
		learnTarget = nil;
		learnCallback = nil;
	}

	// Initialize MIDI and start listening
	enable {
		MIDIClient.init;
		MIDIIn.connectAll;

		midiFunc = MIDIFunc.cc({ |val, num, chan, src|
			if (learnMode) {
				this.prLearnCC(num, chan, val);
			} {
				this.prHandleCC(num, chan, val);
			};
		});

		"MIDI Mapper enabled".postln;
	}

	// Stop listening
	disable {
		if (midiFunc.notNil) {
			midiFunc.free;
			midiFunc = nil;
		};
		"MIDI Mapper disabled".postln;
	}

	// Map a CC to a CV
	// cc: MIDI CC number (0-127)
	// chan: MIDI channel (0-15) or nil for any channel
	// cv: NumericControlValue to control
	map { |cc, chan, cv|
		var key = this.prMakeKey(cc, chan);
		mappings[key] = cv;
		("Mapped CC" + cc + "channel" + (chan ? "any") + "to CV").postln;
	}

	// Unmap a CC
	unmap { |cc, chan|
		var key = this.prMakeKey(cc, chan);
		mappings.removeAt(key);
		("Unmapped CC" + cc + "channel" + (chan ? "any")).postln;
	}

	// Clear all mappings
	clearAll {
		mappings.clear;
		"All MIDI mappings cleared".postln;
	}

	// Enter learn mode - next CC will be mapped to target CV
	learn { |cv, callback|
		learnMode = true;
		learnTarget = cv;
		learnCallback = callback;
		"MIDI Learn mode: move a controller...".postln;
	}

	// Cancel learn mode
	cancelLearn {
		learnMode = false;
		learnTarget = nil;
		learnCallback = nil;
		"MIDI Learn cancelled".postln;
	}

	// Get all current mappings
	getMappings {
		^mappings.collect { |cv, key|
			var parts = key.split($_);
			(cc: parts[0].asInteger, chan: if (parts[1] == "any") { nil } { parts[1].asInteger }, cv: cv)
		};
	}

	// Save mappings to file
	save { |path|
		var data = mappings.collect { |cv, key|
			// Store key and CV's spec info for reconstruction
			[key, cv.spec.minval, cv.spec.maxval]
		};
		var file = File(path, "w");
		file.write(data.asCompileString);
		file.close;
		("MIDI mappings saved to:" + path).postln;
	}

	// Private: handle incoming CC
	prHandleCC { |cc, chan, val|
		var key = this.prMakeKey(cc, chan);
		var keyAny = this.prMakeKey(cc, nil);
		var cv;

		// Check for specific channel mapping first, then any channel
		cv = mappings[key] ?? mappings[keyAny];

		if (cv.notNil) {
			// Map MIDI 0-127 to CV's spec range
			var mappedVal = cv.spec.map(val / 127);
			cv.value = mappedVal;
		};
	}

	// Private: learn mode handler
	prLearnCC { |cc, chan, val|
		if (learnTarget.notNil) {
			this.map(cc, chan, learnTarget);
			if (learnCallback.notNil) {
				learnCallback.value(cc, chan);
			};
		};
		learnMode = false;
		learnTarget = nil;
		learnCallback = nil;
	}

	// Private: create mapping key
	prMakeKey { |cc, chan|
		^cc.asString ++ "_" ++ (chan ? "any").asString;
	}
}

// Extension to NumericControlValue for MIDI mapping convenience
+ NumericControlValue {

	// Map this CV to a MIDI CC
	mapMIDI { |cc, chan|
		NuPG_MIDIMapper.new.map(cc, chan, this);
		^this;
	}

	// Enter MIDI learn mode for this CV
	midiLearn { |callback|
		NuPG_MIDIMapper.new.learn(this, callback);
		^this;
	}
}
