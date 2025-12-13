NuPG_GUI_Extensions_View {

	var <>window;
	var <>stack;
	var <>classicButton, <>oversamplingButton;
	var <>switcher;
	var <>numInstances;

	draw {|dimensions, viewsList, n = 1|
		var layout, stackView, stackViewGrid;
		var extensionsButtons;

		//get GUI defs
		var guiDefinitions = NuPG_GUI_Definitions;

		numInstances = n;

		////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
		//window
		//control window contains two separate views -> global and -> local
		//global is the same across all instances
		window = Window("_extensions", dimensions, resizable: false);
		window.userCanClose_(0);
		//window.alwaysOnTop_(true);
		window.view.background_(guiDefinitions.bAndKGreen);
		window.layout_(layout = GridLayout.new() );
		layout.margins_([3, 2, 2, 2]);

		//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
		//global objects definition
		extensionsButtons = 6.collect{|i|
			var extensions = ["MODULATORS", "FOURIER", "MASKING", "SIEVES", "GROUPS\n OFFSET", "MATRIX\n MODULATION "];
			guiDefinitions.nuPGButton([
				[extensions[i], Color.black, Color.white],
				[extensions[i], Color.black, Color.new255(250, 100, 90)]], 40, 80)
			.action_{|butt|
						var st = butt.value; st.postln;
						switch(st,
					0, { viewsList[i].visible(0) },
					1, { viewsList[i].visible(1)  }
						)
					};
		};

		// Synth switcher buttons
		classicButton = guiDefinitions.nuPGButton(
			[["Classic", guiDefinitions.white, guiDefinitions.darkGreen],
			 ["Classic"]],
			20, 80
		);
		classicButton.value = 0;
		classicButton.action_{|btn|
			this.switchToClassic;
		};

		oversamplingButton = guiDefinitions.nuPGButton(
			[["Oversampling"],
			 ["Oversampling", guiDefinitions.white, guiDefinitions.darkGreen]],
			20, 80
		);
		oversamplingButton.value = 0;
		oversamplingButton.action_{|btn|
			this.switchToOversampling;
		};

		//insert into the view
		6.collect{|i|
			var row = [0, 0, 0, 1, 1, 1];
			var col = [0, 1, 2, 0, 1, 2];
			layout.addSpanning(extensionsButtons[i], row: row[i], column: col[i])
		};

		// Add synth switcher buttons on row 2
		layout.addSpanning(guiDefinitions.nuPGStaticText("_synth", 15, 40), row: 2, column: 0);
		layout.addSpanning(classicButton, row: 2, column: 1);
		layout.addSpanning(oversamplingButton, row: 2, column: 2);

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