NuPG_GUI_Control_View {

	var <>window;
	var <>trainPlayStopButton;
	var <>trainDuration, <>trainPlaybackDirection;
	var <>progressSlider, <>progressDisplay;
	var <>localActivators;
	var <>instanceMenu;
	var <>stack;
	var <>classicButton, <>oversamplingButton;
	var <>switcher;
	var <>numInstances;

	draw {|dimensions, viewsList, n = 1|
		var layout, stackView, stackViewGrid;
		var loopButton;
		var trainLabel, menuItems;
		var groups;

		//get GUI defs
		var guiDefinitions = NuPG_GUI_Definitions;

		numInstances = n;

		////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
		//window
		//control window contains two separate views -> global and -> local
		//global is the same across all instances
		//local is instance specific, using stackView for multiple views
		window = Window("_control", dimensions, resizable: false);
		window.userCanClose_(0);
		//window.alwaysOnTop_(true);
		window.view.background_(guiDefinitions.bAndKGreen);
		window.layout_(layout = GridLayout.new() );
		layout.margins_([3, 2, 2, 2]);

		//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
		//global objects definition
		//instances menu
		menuItems = n.collect{|i| "train_" ++ (i + 1).asString };
		instanceMenu = guiDefinitions.nuPGMenu(menuItems, 0, 70);
		instanceMenu.action_{|mn|
			viewsList.collect{|item, i|
				item.stack.index = instanceMenu.value;
		} };

		// Synth switcher buttons (replacing group collapse buttons)
		classicButton = guiDefinitions.nuPGButton(
			[["Classic", guiDefinitions.white, guiDefinitions.darkGreen],
			 ["Classic"]],
			18, 70
		);
		classicButton.value = 0;
		classicButton.action_{|btn|
			this.switchToClassic;
		};

		oversamplingButton = guiDefinitions.nuPGButton(
			[["Oversampling"],
			 ["Oversampling", guiDefinitions.white, guiDefinitions.darkGreen]],
			18, 90
		);
		oversamplingButton.value = 0;
		oversamplingButton.action_{|btn|
			this.switchToOversampling;
		};

		//insert into the view -> global
		layout.addSpanning(instanceMenu, row: 0, column: 0);
		layout.addSpanning(guiDefinitions.nuPGStaticText("_synth", 15, 40), row: 0, column: 1);
		layout.addSpanning(classicButton, row: 0, column: 2);
		layout.addSpanning(oversamplingButton, row: 0, column: 3);

		^window.front;

	}

	// Setup the switcher with references (call after draw)
	setupSwitcher {|data, pulsaretBufs, envelopeBufs, freqBufs, numChan = 2|
		switcher = NuPG_SynthesisSwitcher.new;
		switcher.setup(numInstances, numChan, data, pulsaretBufs, envelopeBufs, freqBufs);
		"Synthesis switcher initialized".postln;
	}

	switchToClassic {
		if (switcher.notNil) {
			switcher.useStandard;
			this.updateButtonStates;
		} {
			"Switcher not setup - use setupSwitcher method first".warn;
		};
	}

	switchToOversampling {
		if (switcher.notNil) {
			if (switcher.oscOSAvailable) {
				switcher.useOscOS;
				this.updateButtonStates;
			} {
				"OscOS not available - install OversamplingOscillators quark".warn;
			};
		} {
			"Switcher not setup - use setupSwitcher method first".warn;
		};
	}

	updateButtonStates {
		if (switcher.notNil) {
			if (switcher.mode == \standard) {
				classicButton.value = 0;
				oversamplingButton.value = 0;
			} {
				classicButton.value = 1;
				oversamplingButton.value = 1;
			};
		};
	}

}