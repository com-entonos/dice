Brief outline of structure of code<br>

	Dice.swift                base class for Dice and specific die (coin, d4, d6, d8, d10, d12 and d20)- all methods concerning die themselves, including result
	World.swift               creates Table, box, lights, camera, sound of rolling; decides when physics simulation is done; deals with undo and redo; allows dragging die around table
	Game.swift                logic for different dice games
	HUD.swift                 overlay to display help during games; results of throws; info messages on state of simulation
	Start.swift               initial screen for selecting which game and general instructions
	History.swift             keeps track of throws and displays list of throws
	GameViewController.swift  deals with constructing buttons and user input on buttons, die and Table
	HelpView.swift            overlay of content sensitive help
	HelpDetailView.swift      detailed help view
	SettingView.swift         view for Settings button- game, die actions, die size, throw speed, pulse/not pulse die, number of undos, history tracking
	DiceSet.swift             view for allowing multiple types of die to be added at once
	DiceNumber.swift          overlay view for selecting the number of die of a particle type to add/replace
	
	art.scnassets             3d models of different die
	MyAssets                  buttons, icons, sounds, die textures
  
  
