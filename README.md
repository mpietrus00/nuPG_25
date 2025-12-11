# nuPG - Pulsar Synthesis for SuperCollider

nuPG is a pulsar synthesis instrument for SuperCollider featuring multiple grain trains, modulation matrices, and real-time GUI control.

## Requirements

- SuperCollider 3.11+
- sc3-plugins

## Installation

### 1. Install Required Quarks

```supercollider
Quarks.install("Connection");
Quarks.install("OversamplingOscillators");  // Optional: for non-aliasing OscOS synthesis
```

Recompile class library: `Cmd+Shift+L` (Mac) or `Ctrl+Shift+L` (Win/Linux)

### 2. Install nuPG Classes

Copy the `nuPG_2024_release` folder to your SuperCollider Extensions directory:

```supercollider
Platform.userExtensionDir;  // Run this to find your Extensions path
```

### 3. Recompile

Recompile class library after copying files.

## Usage

### Startup

```supercollider
// Boot server first
s.boot;

// Execute the startup file
"nuPG_24_startUp.scd".loadRelative;
```

### Basic Controls

After startup, use the GUI to control synthesis parameters. Each train has:
- Fundamental and formant frequencies
- Envelope multipliers
- Pan and amplitude per formant
- Burst/rest masking
- 4 modulators with routing matrix

### Synthesis Switching

Switch between GrainBuf (standard) and OscOS (non-aliasing) synthesis:

```supercollider
~synthSwitcher.useOscOS;       // Non-aliasing synthesis
~synthSwitcher.useStandard;    // GrainBuf-based (default)
~synthSwitcher.toggle;         // Toggle between modes
~synthSwitcher.status;         // Print current status
~synthSwitcher.oversample_(4); // Set OscOS oversample factor (1-8)
```

## File Structure

```
nuPG_2024_release/
├── DATA/           - Data structures and CV extensions
├── SYNTHESIS/      - Synthesis engines (GrainBuf, OscOS)
├── GUI/            - GUI components
├── MIDI_OSC/       - MIDI and OSC control interfaces
└── PRESET_MANAGER/ - Preset save/load system
```

## License

See LICENSE file for details.
