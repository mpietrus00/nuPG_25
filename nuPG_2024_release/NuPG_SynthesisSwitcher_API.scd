// ============================================
// NuPG Synthesis Switcher - API Reference
// ============================================
// Switch between standard GrainBuf and OscOS (non-aliasing) synthesis
// Both engines are initialized automatically in nuPG_24_startUp.scd

// --------------------------------------------
// SWITCH SYNTHESIS ENGINES
// --------------------------------------------

// Use standard GrainBuf-based synthesis (default)
~synthSwitcher.useStandard;

// Use oversampled OscOS synthesis (non-aliasing)
~synthSwitcher.useOscOS;

// Toggle between modes
~synthSwitcher.toggle;

// --------------------------------------------
// QUERY STATE
// --------------------------------------------

// Get current mode (\standard or \oscos)
~synthSwitcher.mode;

// Get active synthesis object
~synthSwitcher.current;

// Get active train Ndefs
~synthSwitcher.trainInstances;

// Print detailed status
~synthSwitcher.status;

// Check if OscOS UGen is installed
~synthSwitcher.oscOSAvailable;

// --------------------------------------------
// PLAYBACK CONTROL
// --------------------------------------------

// Play all trains
~synthSwitcher.play;

// Stop all trains
~synthSwitcher.stop;

// --------------------------------------------
// OSCOS-SPECIFIC SETTINGS
// --------------------------------------------

// Set oversample factor (1-8x, higher = cleaner but more CPU)
~synthSwitcher.oversample_(4);

// --------------------------------------------
// DIRECT ACCESS TO ENGINES
// --------------------------------------------

// Standard GrainBuf synthesis
~synthesis;
~synthesis.trainInstances;

// OscOS oversampled synthesis
~synthesisOscOS;
~synthesisOscOS.trainInstances;

// --------------------------------------------
// INSTALL OSCOS (if not already installed)
// --------------------------------------------
(
// Run this once, then recompile class library
Quarks.install("OversamplingOscillators");
)

// Recompile: Cmd+Shift+L (Mac) or Ctrl+Shift+L (Win/Linux)

// --------------------------------------------
// EXAMPLE: A/B COMPARISON
// --------------------------------------------
(
// Quick A/B test between synthesis engines
fork {
    "Playing STANDARD synthesis...".postln;
    ~synthSwitcher.useStandard;
    ~synthSwitcher.play;
    3.wait;
    ~synthSwitcher.stop;
    0.5.wait;

    "Playing OSCOS synthesis...".postln;
    ~synthSwitcher.useOscOS;
    ~synthSwitcher.play;
    3.wait;
    ~synthSwitcher.stop;

    "Comparison complete. Use ~synthSwitcher.toggle to switch.".postln;
};
)

// --------------------------------------------
// PRINT HELP
// --------------------------------------------
NuPG_SynthesisSwitcher.help;
