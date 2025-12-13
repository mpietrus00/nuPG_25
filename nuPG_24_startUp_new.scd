/*
nuPG Application Startup
========================
Simple startup script using NuPG_Application class.

Usage:
  - Set numChannels and numInstances as needed
  - Execute this file to boot the application
  - Access components via ~app (e.g., ~app.data, ~app.synthesis)

For custom paths, set before booting:
  ~app.tablesPath = "/path/to/tables/";
  ~app.filesPath = "/path/to/files/";
  ~app.presetsPath = "/path/to/presets/";
*/

(
// Configuration
~numChannels = 1;
~numInstances = 1;

// Create and boot the application
~app = NuPG_Application(~numChannels, ~numInstances).boot;
)

/*
After booting, you can access:
  ~app.data          - Data model
  ~app.synthesis     - Standard synthesis
  ~app.synthesisOscOS - Oversampling synthesis
  ~app.synthSwitcher - Synthesis switcher
  ~app.control       - Control GUI
  ~app.presets       - Presets GUI
  ... and all other components
*/
