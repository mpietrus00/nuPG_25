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
	var <>overlapMorphRateNum;
	var <>overlapMorphDepth;
	var <>overlapMorphDepthNum;
	var <>overlapMorphShape;
	var <>overlapMorphMin;
	var <>overlapMorphMax;
	var <>overlapMorphSpread;
	var <>overlapMorphSpreadNum;

	draw {|name, dimensions, synthesis, dataModel, n = 1|
		var view, viewLayout, labels;
		//get GUI defs
		var guiDefinitions = NuPG_GUI_Definitions;

		data = dataModel;


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
			.vSpacing_(2)
			.spacing_(1)
			.margins_([5, 3, 5, 3]);

		};
		//load gridLayouts into corresponding views
		n.collect{|i| view[i].layout_(viewLayout[i])};
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
		overlapMorphRateNum = n.collect{};
		overlapMorphDepth = n.collect{};
		overlapMorphDepthNum = n.collect{};
		overlapMorphShape = n.collect{};
		overlapMorphMin = n.collect{};
		overlapMorphMax = n.collect{};
		overlapMorphSpread = n.collect{};
		overlapMorphSpreadNum = n.collect{};

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

			// Overlap morph controls - connected to data CVs
			// Rate slider + numberbox [CV index 0]
			overlapMorphRate[i] = guiDefinitions.sliderView(width: 270, height: 20);
			overlapMorphRateNum[i] = guiDefinitions.numberView(width: 25, height: 20);
			// Depth slider + numberbox [CV index 1]
			overlapMorphDepth[i] = guiDefinitions.sliderView(width: 270, height: 20);
			overlapMorphDepthNum[i] = guiDefinitions.numberView(width: 25, height: 20);
			// Spread slider + numberbox [CV index 5]
			overlapMorphSpread[i] = guiDefinitions.sliderView(width: 270, height: 20);
			overlapMorphSpreadNum[i] = guiDefinitions.numberView(width: 25, height: 20);
			// Shape menu [CV index 2], min/max numberboxes [CV indices 3, 4]
			overlapMorphShape[i] = guiDefinitions.nuPGMenu(["sine", "tri", "saw", "random", "chaos"], 0, 60);
			overlapMorphMin[i] = guiDefinitions.nuPGNumberBox(18, 35);
			overlapMorphMax[i] = guiDefinitions.nuPGNumberBox(18, 35);

			// Connect to data CVs if dataModel and overlapMorph data exist
			if (data.notNil and: { data.data_overlapMorph.notNil } and: { data.data_overlapMorph[i].notNil }) {
				// Rate [0]: connect slider and numberbox
				data.data_overlapMorph[i][0].connect(overlapMorphRate[i]);
				data.data_overlapMorph[i][0].connect(overlapMorphRateNum[i]);
				// Depth [1]
				data.data_overlapMorph[i][1].connect(overlapMorphDepth[i]);
				data.data_overlapMorph[i][1].connect(overlapMorphDepthNum[i]);
				// Shape [2]: menu needs special handling
				overlapMorphShape[i].value = data.data_overlapMorph[i][2].value.asInteger;
				overlapMorphShape[i].action = { |menu|
					data.data_overlapMorph[i][2].value = menu.value;
				};
				data.data_overlapMorph[i][2].addDependant({ |cv, what, val|
					if (what == \value) { defer { overlapMorphShape[i].value = val.asInteger } };
				});
				// Min [3]
				data.data_overlapMorph[i][3].connect(overlapMorphMin[i]);
				// Max [4]
				data.data_overlapMorph[i][4].connect(overlapMorphMax[i]);
				// Spread [5]
				data.data_overlapMorph[i][5].connect(overlapMorphSpread[i]);
				data.data_overlapMorph[i][5].connect(overlapMorphSpreadNum[i]);
			};
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

			// Overlap morph layout (rows 7-14)
			// Row 7: Header
			viewLayout[i].addSpanning(
				item: guiDefinitions.nuPGStaticText("_overlap morph", 11, 150),
				row: 7, column: 0
			);
			// Row 8: _rate label
			viewLayout[i].addSpanning(item: guiDefinitions.nuPGStaticText("_rate", 11, 150), row: 8, column: 0);
			// Row 9: rate slider + numberbox
			viewLayout[i].addSpanning(item: overlapMorphRate[i], row: 9, column: 0, columnSpan: 4);
			viewLayout[i].addSpanning(item: overlapMorphRateNum[i], row: 9, column: 5);
			// Row 10: _depth label
			viewLayout[i].addSpanning(item: guiDefinitions.nuPGStaticText("_depth", 11, 150), row: 10, column: 0);
			// Row 11: depth slider + numberbox
			viewLayout[i].addSpanning(item: overlapMorphDepth[i], row: 11, column: 0, columnSpan: 4);
			viewLayout[i].addSpanning(item: overlapMorphDepthNum[i], row: 11, column: 5);
			// Row 12: _spread label
			viewLayout[i].addSpanning(item: guiDefinitions.nuPGStaticText("_spread", 11, 150), row: 12, column: 0);
			// Row 13: spread slider + numberbox
			viewLayout[i].addSpanning(item: overlapMorphSpread[i], row: 13, column: 0, columnSpan: 4);
			viewLayout[i].addSpanning(item: overlapMorphSpreadNum[i], row: 13, column: 5);
			// Row 14: shape menu, (space), min/max
			viewLayout[i].addSpanning(item: overlapMorphShape[i], row: 14, column: 0);
			// column 1 left blank for spacing
			viewLayout[i].addSpanning(item: guiDefinitions.nuPGStaticText("_min", 11, 30), row: 14, column: 2);
			viewLayout[i].addSpanning(item: overlapMorphMin[i], row: 14, column: 3);
			viewLayout[i].addSpanning(item: guiDefinitions.nuPGStaticText("_max", 11, 30), row: 14, column: 4);
			viewLayout[i].addSpanning(item: overlapMorphMax[i], row: 14, column: 5);
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