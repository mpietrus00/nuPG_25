/*
nuPG MIDI Learn Examples
========================

MIDI learn is built into nuPG. After booting, Ctrl+click or
right-click any slider/numberbox to enter learn mode, then
move a MIDI controller to create the mapping.

Below are code examples for programmatic MIDI control.
*/

// ==================== MIDI LEARN ====================

// Enter learn mode for a specific CV - move a MIDI knob to map it
~app.midiMapper.learn(~app.data.data_main[0][0]); // fundamental frequency

// Learn with callback (prints confirmation)
~app.midiMapper.learn(~app.data.data_main[0][0], {|cc, chan|
	("Mapped CC" + cc + "channel" + chan + "to fundamental frequency").postln;
});

// Cancel learn mode
~app.midiMapper.cancelLearn;

// ==================== DIRECT MAPPING ====================

// Map CC 1 (mod wheel) on channel 0 to fundamental frequency
~app.midiMapper.map(1, 0, ~app.data.data_main[0][0]);

// Map CC 74 on any channel to formant frequency one
~app.midiMapper.map(74, nil, ~app.data.data_main[0][1]);

// Map CC 71 on channel 0 to FM amount
~app.midiMapper.map(71, 0, ~app.data.data_modulators[0][0]);

// ==================== MANAGE MAPPINGS ====================

// View all current mappings
~app.midiMapper.getMappings;

// Remove a specific mapping
~app.midiMapper.unmap(74, nil);

// Clear all mappings
~app.midiMapper.clearAll;

// Save mappings to file
~app.midiMapper.save(~app.presetsPath ++ "midi_map.txt");

// ==================== CV EXTENSION METHODS ====================

// You can also call midiLearn directly on any CV
~app.data.data_main[0][0].midiLearn;  // fundamental freq
~app.data.data_main[0][7].midiLearn;  // pan one

// Or map directly on a CV
~app.data.data_main[0][10].mapMIDI(7, 0);  // amplitude one -> CC 7 ch 0

// ==================== PARAMETER REFERENCE ====================

/*
data_main[instance][index]:
  0  - fundamental frequency
  1  - formant frequency one
  2  - formant frequency two
  3  - formant frequency three
  4  - envelope dilation one
  5  - envelope dilation two
  6  - envelope dilation three
  7  - pan one
  8  - pan two
  9  - pan three
  10 - amplitude one
  11 - amplitude two
  12 - amplitude three

data_modulators[instance][index]:
  0 - FM amount
  1 - FM ratio
  2 - flux amount

data_groupsOffset[instance][index]:
  0 - offset 1
  1 - offset 2
  2 - offset 3

data_modulator1..4[instance][index]:
  1 - modulation frequency
  2 - modulation depth

data_overlapMorph[instance][index]:  (OscOS only)
  0 - rate
  1 - depth
  2 - shape
  3 - min
  4 - max
  5 - spread

data_probabilityMaskSingular[instance] - probability
data_burstMask[instance][0..1] - burst, rest
data_channelMask[instance][0] - channel mask
*/
