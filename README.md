# nuPG 25 - Pulsar Synthesis for SuperCollider

nuPG is a pulsar synthesis instrument for SuperCollider featuring multiple grain trains, modulation matrices, real-time GUI control, and dual synthesis engines.

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

Or create a symlink to the repository location.

### 3. Recompile

Recompile class library after copying files.

## Usage

### Quick Start

Execute `nuPG_25_startUp.scd` - this uses the `NuPG_Application` class for clean initialization:

```supercollider
// Configuration
~numChannels = 1;
~numInstances = 1;

// Get the directory containing this startup script
~basePath = thisProcess.nowExecutingPath.dirname;

// Create and boot the application
~app = NuPG_Application(~numChannels, ~numInstances).boot(~basePath);
```

After booting, access components via `~app`:
- `~app.data` - Data model
- `~app.synthesis` - Standard synthesis
- `~app.synthesisOscOS` - Oversampling synthesis
- `~app.synthSwitcher` - Synthesis switcher
- `~app.control` - Control GUI
- `~app.presets` - Presets GUI

### Legacy Startup

The original startup script `nuPG_24_startUp.scd` is still available for backwards compatibility.

### Basic Controls

After startup, use the GUI to control synthesis parameters. Each train has:
- Fundamental and formant frequencies
- Envelope multipliers (dilation)
- Pan and amplitude per formant group
- Burst/rest masking
- Probability masking
- Sieve-based rhythmic patterns
- 4 modulators with routing matrix

### Synthesis Switching

Toggle between GrainBuf (Classic) and OscOS (Oversampling) synthesis using the `_classic`/`_oversampling` button in the nuPG control GUI.

Or via code:
```supercollider
~app.synthSwitcher.useOscOS;       // Non-aliasing synthesis
~app.synthSwitcher.useStandard;    // GrainBuf-based (default)
~app.synthSwitcher.toggle;         // Toggle between modes
~app.synthSwitcher.status;         // Print current status
```

### Table Editor

The table editor provides waveform manipulation tools:

| Button | Function |
|--------|----------|
| **S** | Save table to file |
| **L** | Load table from file |
| **RS** | Resize (normalize to -1 to 1) |
| **R** | Reverse (horizontal flip) |
| **I** | Invert (vertical flip) |
| **SM** | Smooth (8-point moving average) |
| **QT** | Quantize (8 discrete levels) |
| **PW** | Power (squared curve) |
| **RND** | Random (generate new waveform) |
| **SIN** | Sine waveshaping |
| **+N** | Add noise (±10% random) |
| **← → ↑ ↓** | Shift table position |

### Presets

The presets GUI provides:
- **S** - Save new preset with auto-generated name
- **L** - Load selected preset
- **U** - Update/overwrite selected preset
- **_size** / **_cur** - Preset count and current index
- **_prev** / **_nxt** - Navigate presets
- **+** / **-** - Add/remove preset slots
- Interpolation slider for morphing between presets

## File Structure

```
nuPG_25/
├── nuPG_25_startUp.scd          - New startup script (recommended)
├── nuPG_24_startUp.scd          - Legacy startup script
├── README.md
└── nuPG_2024_release/
    ├── NuPG_Application.sc      - Application class
    ├── DATA/                    - Data structures and CV extensions
    ├── SYNTHESIS/               - Synthesis engines (GrainBuf, OscOS)
    ├── GUI/                     - GUI components
    ├── MIDI_OSC/                - MIDI and OSC control interfaces
    ├── PRESET_MANAGER/          - Preset save/load system
    ├── TABLES/                  - Wavetable files
    ├── FILES/                   - Sieve and other data files
    └── PRESETS/                 - Saved presets
```

## Architecture

### NuPG_Application

The `NuPG_Application` class provides organized initialization:

- `init` - Configuration and server options
- `initBuffers` - Create envelope, pulsaret, frequency buffers
- `initData` - Setup data model and conductors
- `initSynthesis` - Create standard and OscOS synths + switcher
- `initTasks` - Loop, scrub, progress tasks
- `initGUI` - All GUI components
- `connectDataToGUI` - Wire data to GUI components
- `connectBuffersToSynths` - Wire buffers to synth instances
- `connectControlsToSynths` - Wire control parameters

### Synthesis Engines

- **GrainBuf (Classic)** - Standard SuperCollider grain synthesis
- **OscOS (Oversampling)** - Non-aliasing synthesis via OversamplingOscillators quark

## License

See LICENSE file for details.
