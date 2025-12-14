NuPG_GUI_Modulators {

	var <>window;
	var <>stack;
	var <>modeButton;
	var <>tablesButton;
	var <>tables;
	var <>slider;
	var <>numberDisplay;
	var <>data;
	// Overlap morph controls
	var <>overlapMorphRate;
	var <>overlapMorphDepth;
	var <>overlapMorphShape;
	var <>overlapMorphMin;
	var <>overlapMorphMax;
	var <>overlapMorphSpread;

	draw {|name, dimensions, synthesis, n = 1|
		var view, viewLayout, labels;
		//get GUI defs
		var guiDefinitions = NuPG_GUI_Definitions;


		///////////////////////////////////////////////////////////////////////////////////////////////////////////
		//window
		window = Window(name, dimensions, resizable: false);
		window.userCanClose = false;
		window.view.background_(guiDefinitions.bAndKGreen);
		window.userCanClose = false;

		//load stackLayaut to display multiple instances on top of each other
		window.layout_(stack = StackLayout.new() );
		//Unlike other layouts, StackLayout can not contain another layout, but only subclasses of View
		//solution - load a CompositeView and use GridLayout as its layout
		//n = number of instances set a build time, default n = 1, we need at least one instance
		//maximum of instances is 10
		view = n.collect{|i| guiDefinitions.nuPGView(guiDefinitions.colorArray[i])};
		//generate corresponding number of gridLayouts to load in to CompositeView
		//Grid Laayout
		viewLayout = n.collect{|i|
			GridLayout.new()
			.hSpacing_(3)
			.vSpacing_(3)
			.spacing_(1)
			.margins_([5, 5, 5, 5]);

		};
		//load gridLayouts into corresponding views
		n.collect{|i| view[i].layout_(viewLayout[i])};
		/////////////////////////////////////////////////////////////////////////////////////////////////////
		data = n.collect{};
		/////////////////////////////////////////////////////////////////////////////////////////////////////
		//define objects
		//generate empty placeholders for objects of size = n
		//3 - > number of parameters of modulation unit
		modeButton = n.collect{};
		tablesButton = n.collect{};
		slider = n.collect{ 3.collect{} };
		numberDisplay = n.collect{ 3.collect{} };
		// Overlap morph control arrays
		overlapMorphRate = n.collect{};
		overlapMorphDepth = n.collect{};
		overlapMorphShape = n.collect{};
		overlapMorphMin = n.collect{};
		overlapMorphMax = n.collect{};
		overlapMorphSpread = n.collect{};

		n.collect{|i|

			modeButton[i] = guiDefinitions.nuPGButton(
				[["mode -> samp+hold rm"],["mode -> rm"]], 20, 120)
			.action_({|butt|
				var st = butt.value; st.postln;
				switch(st,
					0, {synthesis.trainInstances[i].set(\modulationMode, 0)},
					1, {synthesis.trainInstances[i].set(\modulationMode, 1)}
				)
			});

			tablesButton[i] = guiDefinitions.nuPGButton(
				[["tables"],["tables"]], 20, 50)
			.action_({|butt|
				var st = butt.value; st.postln;
				switch(st,
					0, {tables.collect{|item| item.visible(0)}},
					1, {tables.collect{|item| item.visible(1)}}
				)
			});

			3.collect{|l|

				slider[i][l] = guiDefinitions.sliderView(width: 270, height: 20);
				slider[i][l].action_{|sl| };
				slider[i][l].mouseDownAction_{|sl| };
				slider[i][l].mouseUpAction_{|sl| };

				numberDisplay[i][l] = guiDefinitions.numberView(width: 25, height: 20);
				numberDisplay[i][l].action_{|num|};
			};

			// Overlap morph controls (no actions yet - just widgets)
			overlapMorphRate[i] = guiDefinitions.nuPGSlider(18, 100);
			overlapMorphDepth[i] = guiDefinitions.nuPGSlider(18, 100);
			overlapMorphShape[i] = guiDefinitions.nuPGMenu(["sine", "tri", "saw", "random", "chaos"], 0, 60);
			overlapMorphMin[i] = guiDefinitions.nuPGNumberBox(18, 35);
			overlapMorphMax[i] = guiDefinitions.nuPGNumberBox(18, 35);
			overlapMorphSpread[i] = guiDefinitions.nuPGSlider(18, 60);
		};

		//////////////////////////////////////////////////////////////////////////////////////////////////////////
		//place objects on view
		n.collect{|i|
			//parameters' labels
			var names = [
				"_rate modulation amount",
				"_rate modulation ratio",
				"_multiparameter modulation"
			];
			viewLayout[i].addSpanning(item: tablesButton[i], row: 0, column: 0);
			viewLayout[i].addSpanning(item: modeButton[i], row: 0, column: 1);
			3.collect{|l|
				//shift values to distribute objects on a view
				var shiftT = [1, 3, 5];
				var shiftS = [2, 4, 6];
				viewLayout[i].addSpanning(item: guiDefinitions.nuPGStaticText(names[l], 11, 150), row: shiftT[l], column: 0);
				viewLayout[i].addSpanning(item: slider[i][l], row: shiftS[l], column: 0, columnSpan: 4);
				viewLayout[i].addSpanning(item: numberDisplay[i][l], row: shiftS[l], column: 5);

			};

			// Overlap morph layout (rows 7-10)
			viewLayout[i].addSpanning(
				item: guiDefinitions.nuPGStaticText("_overlap morph", 10, 100),
				row: 7, column: 0, columnSpan: 2
			);
			// Row 8: Rate and Depth
			viewLayout[i].addSpanning(item: guiDefinitions.nuPGStaticText("rate", 10, 30), row: 8, column: 0);
			viewLayout[i].addSpanning(item: overlapMorphRate[i], row: 8, column: 1);
			viewLayout[i].addSpanning(item: guiDefinitions.nuPGStaticText("depth", 10, 35), row: 8, column: 2);
			viewLayout[i].addSpanning(item: overlapMorphDepth[i], row: 8, column: 3, columnSpan: 2);
			// Row 9: Shape, Min, Max
			viewLayout[i].addSpanning(item: overlapMorphShape[i], row: 9, column: 0, columnSpan: 2);
			viewLayout[i].addSpanning(item: guiDefinitions.nuPGStaticText("min", 10, 25), row: 9, column: 2);
			viewLayout[i].addSpanning(item: overlapMorphMin[i], row: 9, column: 3);
			viewLayout[i].addSpanning(item: guiDefinitions.nuPGStaticText("max", 10, 25), row: 9, column: 4);
			viewLayout[i].addSpanning(item: overlapMorphMax[i], row: 9, column: 5);
			// Row 10: Spread
			viewLayout[i].addSpanning(item: guiDefinitions.nuPGStaticText("spread", 10, 40), row: 10, column: 0);
			viewLayout[i].addSpanning(item: overlapMorphSpread[i], row: 10, column: 1, columnSpan: 2);
		};

		//load views into stacks
		n.collect{|i|
			stack.add(view[i])
		};

		//^window.front;
	}

	visible {|boolean|
		^window.visible = boolean
	}
}