//
//  GameViewController.swift
//  dice
//
//  Created by G.J. Parker on 19/9/14.
//  Copyright © 2019 G.J. Parker. All rights reserved.
//

import UIKit
import SceneKit

class GameViewController: UIViewController, SCNSceneRendererDelegate {
    private var _sceneView: SCNView!
    private var _world: World!
    private var _game: Game!
    
    let soundButton = UIButton()
    let helpButton = UIButton()
    let settingButton = UIButton()
    let undoButton = UIButton()
    let redoButton = UIButton()
    var dieButton = [DieType:UIButton]()
    let allButton = UIButton()
    var dieButtonPos = CGRect()
    let historyButton = UIButton()
    var addDie = false
    var dieType : DieType = .dice6
    var overlayBounds = CGRect()
    
    var flick: UIPanGestureRecognizer?
    var pinch: UIPinchGestureRecognizer?
    var tripleTap: UITapGestureRecognizer?
    var singleTap: UITapGestureRecognizer?
    var singleTap2: UITapGestureRecognizer?
    var doubleTap: UITapGestureRecognizer?
    var longTap: UILongPressGestureRecognizer?
    
    var diceNumberView: DiceNumberView? = nil
    var diceSetView: DiceSetView? = nil
    var helpView : HelpView? = nil
    var helpDetailView: HelpDetailView? = nil
    var settingView: SettingView? = nil
    var historyView: HistoryView? = nil
    var startView: StartView? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    
    override func viewDidAppear(_ animated: Bool) {  // ok, 'safe areas' are now defined,
        super.viewDidAppear(animated)
        
        overlayBounds = self.view.safeAreaLayoutGuide.layoutFrame
        
        _game = Game(size: overlayBounds) // create the Game (which creates the HUD and World)
        _world = _game.world_
        
        _sceneView = SCNView(frame: overlayBounds)  // create a SCNView
        _sceneView.scene = _world                   // and populate it w/ the World
        _sceneView.allowsCameraControl = false
        _sceneView.showsStatistics = false
        _sceneView.backgroundColor = UIColor.black
        _sceneView.delegate = self
        _sceneView.autoenablesDefaultLighting = false   // this is the default, but make sure
// _sceneView.debugOptions = .showPhysicsShapes
// _sceneView.showsStatistics = true
        
        self.view.addSubview(_sceneView)
        _sceneView.addSubview(_game.hud!.result)        // because SKLabelNode doesn't honor NSattributedString. grrrr

        createButtons()     // create buttons (sound, help, settings and un/re/do
        createGestures()    // create gestures
        
        _sceneView.overlaySKScene = _game.hud!.scene    // overlay the HUD
        //NotificationCenter.default.addObserver(self, selector: #selector(self.physicsDone), name: NSNotification.Name("physicsDone"), object: nil) // be told when physic simulation is done
        
        //_game.setDiceNumber(diceSet: [dieType:2]) // let's place two dice to get started...
        startView = StartView(frame: self.view.frame, safe: overlayBounds, game: _game!)
        if startView != nil {
            removeGestures()
            self.view.addSubview(startView!)
        }
    
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didSimulatePhysicsAtTime time: TimeInterval) {
        _world.update(time)  // just pass off to World
    }
    
    func createGestures() {
        let tapOpt = _game.throwOption  // get throwing options, [0]- for single tap, [1]- for double, [2]- for triple, [3]- for long, [4]- for pinch
        
        flick = UIPanGestureRecognizer(target: self, action: #selector(handleFlick))
        _sceneView.addGestureRecognizer(flick!)
        flick!.minimumNumberOfTouches = 1
        flick!.maximumNumberOfTouches = 2
        _sceneView.addGestureRecognizer(flick!)
        
        if tapOpt[3] != .ignore || _game.game_ == .freeplay {
            longTap = UILongPressGestureRecognizer(target: self, action: #selector(handleLongTap))
            _sceneView.addGestureRecognizer(longTap!)
        }
        
        if tapOpt[2] != .ignore {
            tripleTap = UITapGestureRecognizer(target: self, action: #selector(handleTripleTap))
            tripleTap!.numberOfTapsRequired = 3
            _sceneView.addGestureRecognizer(tripleTap!)
        }
        
        pinch = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch))
        _sceneView.addGestureRecognizer(pinch!)
        
        // double tap is always used for table to add a die
        doubleTap = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap))
        doubleTap!.numberOfTapsRequired = 2
        if tripleTap != nil { doubleTap!.require(toFail: tripleTap!) }
        _sceneView.addGestureRecognizer(doubleTap!)
        
        // single tap is always used for table to drop dice
        singleTap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        if tripleTap != nil { singleTap!.require(toFail: tripleTap!) }
        singleTap!.require(toFail: doubleTap!)
        singleTap!.numberOfTouchesRequired = 1
        if longTap != nil { singleTap!.require(toFail: longTap!) }
        _sceneView.addGestureRecognizer(singleTap!)
        
        singleTap2 = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        singleTap2!.numberOfTouchesRequired = 2
        if tripleTap != nil { singleTap2!.require(toFail: tripleTap!) }
        singleTap2!.require(toFail: doubleTap!)
        if longTap != nil { singleTap!.require(toFail: longTap!) }
        _sceneView.addGestureRecognizer(singleTap2!)
        
    }
    
    func removeGestures() {
        if singleTap != nil { _sceneView.removeGestureRecognizer(singleTap!) }
        if singleTap2 != nil { _sceneView.removeGestureRecognizer(singleTap2!) }
        _sceneView.removeGestureRecognizer(doubleTap!)
        if tripleTap != nil { _sceneView.removeGestureRecognizer(tripleTap!) }
        if longTap != nil { _sceneView.removeGestureRecognizer(longTap!) }
        _sceneView.removeGestureRecognizer(flick!)
        if pinch != nil { _sceneView.removeGestureRecognizer(pinch!)}
    }
    
    @objc func handleLongTap(_ gestureRecognize: UIGestureRecognizer) {  // handle long tap (either long tap a die or table)
      //if gestureRecognize.state == .ended {
        if gestureRecognize.state == .began {
            let pos = gestureRecognize.location(in: _sceneView) //CGPoint
            let hits = _sceneView.hitTest(pos, options: nil)
            if let object = hits.first?.node {
                if !_game.longTapped(object,pos, gestureRecognize.numberOfTouches > 1) && _game.game_ == .freeplay {  // try to do long tap on die, if we fail ...
                    if !allButton.isEnabled || pos.x < dieButtonPos.origin.x || pos.y < dieButtonPos.origin.y || pos.x > dieButtonPos.origin.x + dieButtonPos.width || pos.y > dieButtonPos.origin.y + dieButtonPos.height {
                        toggleDieButton()  // simply toggle dieButtons
                    } else {               // want to add
                        let ind = Int((pos.y - dieButtonPos.origin.y) * CGFloat(dieButton.count) / dieButtonPos.height)
                        dieType = .dice6
                        for (i,type) in DieType.allCases.enumerated() {
                            if ind == i { dieType = type; break}
                        }
                        diceNumberView = DiceNumberView(frame: self.view.frame, safe: overlayBounds, image: smallIcon[dieType]!, add: true)
                        if diceNumberView != nil {
                            removeGestures()
                            self.view.addSubview(diceNumberView!)
                            addDie = true
                        }
                    }
                }
            }
        }
    }
    
    @objc func handleDoubleTap(_ gestureRecognize: UIGestureRecognizer) { // handle double tap
        if gestureRecognize.state == .ended {
            let pos = gestureRecognize.location(in: _sceneView) //CGPoint
            let hits = _sceneView.hitTest(pos, options: nil)
            if let object = hits.first?.node {
                _game.doubleTapped(object,pos,gestureRecognize.numberOfTouches > 1)
            }
        }
    }
    
    // for moving a die with swipes
    var movingDie : Dice? = nil
    var initialY = Float(-1)
    var toggle = false
    
    // for tracking swipe itself for throw
    var numSample = CGFloat(0)
    var lastAngle = CGFloat(0)
    var aveSpeed = CGFloat(0)
    var aveR = CGPoint(x: 0, y: 0)
    var aveV = CGPoint(x: 0, y: 0)
    var cumAng = CGFloat(0)
    
    func helpMoveDie(die: Dice, pos: CGPoint) { // continuously update position of moving die
        let r = die.presentation.simdPosition
        if initialY < 0 {initialY = r.y}
        die.simdPosition = simd_float3(0, 1.5*initialY, 0) + _world.convert(pos: pos)
        die.physicsBody!.resetTransform()
    }
    func trackSwipe(v: CGPoint, R: CGPoint) {  // keep cumulative angle change (hack) and average speed and position of swipe
        let ang = atan2(v.y, v.x)
        numSample += 1; cumAng += abs(abs(ang)-lastAngle); lastAngle = abs(ang)
        aveSpeed = aveSpeed + (sqrt(v.x*v.x+v.y*v.y)-aveSpeed)/numSample
        aveV = CGPoint(x: aveV.x+(v.x-aveV.x)/numSample, y: aveV.y+(v.y-aveR.y)/numSample)
        aveR = CGPoint(x: aveR.x+(R.x-aveR.x)/numSample, y: aveR.y+(R.y-aveR.y)/numSample)
    }
    
    @objc func handlePinch(_ gestureRecognize: UIPinchGestureRecognizer) {
        if _world.state == .rolled {
            if gestureRecognize.state == .ended || gestureRecognize.state == .cancelled {  // done with pinch
                if movingDie != nil && gestureRecognize.scale < numSample {
                    let pos = gestureRecognize.location(in: _sceneView)
                    let hits = _sceneView.hitTest(pos, options: nil)
                    if let die = hits.first?.node as? Dice { _game.pinched(die, pos) } else { _game.pinched(movingDie!, aveR) }
                }
                movingDie = nil; initialY = -1.0
                for die in _world.dice { die.physicsBody?.type = .static }
            } else if gestureRecognize.state == .began {  // scaling the Table or pinch action on die
                numSample = gestureRecognize.scale
                initialY = _world.numDiePerSide
                let pos = gestureRecognize.location(in: _sceneView)
                let hits = _sceneView.hitTest(pos, options: nil)
                if let object = hits.first?.node {      // get object we're touching (centroid)
                    movingDie = object as? Dice         // are we on a die?
                    if movingDie == nil { movingDie = _world.nearestDie(pos: pos, tolerance: 22) } // are we close to a die?
                    let tapOpt = _game.throwOption
                    if movingDie != nil && tapOpt[4] != .ignore {   // there is a die and pinch is a die action
                        aveR = pos
                    } else {                                        // just scale the Table
                        movingDie = nil
                        for die in _world.dice { die.physicsBody?.type = .dynamic }
                    }
                }
            } else if gestureRecognize.state == .changed && movingDie == nil {  // scaling the Table
                _world.numDiePerSide  = max(5.2, min( 60, initialY * Float(numSample / gestureRecognize.scale)))
                numSample = gestureRecognize.scale
                initialY = _world.numDiePerSide
            }
        }
    }
    @objc func handleFlick(_ gestureRecognize: UIPanGestureRecognizer,_ pos: CGPoint) { // handle flicking
        if gestureRecognize.state == .ended && movingDie == nil {  // done with swipe
            toggle = toggle || gestureRecognize.numberOfTouches > 1
            trackSwipe(v: gestureRecognize.velocity(in: _sceneView), R: gestureRecognize.location(in: _sceneView))
            //print("end cumAng V R N: \(cumAng) \(aveSpeed) \(aveV) \(aveR) \(numSample) \(gestureRecognize.velocity(in: _sceneView))")
            _game.flicked(aveV, pos: aveR, speed: aveSpeed, angle: cumAng, toggle)
            toggle = false
        } else if (gestureRecognize.state == .ended || gestureRecognize.state == .cancelled) && movingDie != nil  {
            if !(gestureRecognize.state == .cancelled) { helpMoveDie(die: movingDie!, pos: gestureRecognize.location(in: _sceneView)) }
            _world.movingDice(type: .static, movingDie: movingDie!)
            let r = movingDie!.presentation.simdPosition
            movingDie!.simdPosition = simd_float3(r.x, initialY, r.z)
            movingDie!.physicsBody!.resetTransform()
            movingDie = nil; initialY = -1.0; toggle = false
        } else if gestureRecognize.state == .began {  // moving dice or rolling?
            let startFlick = gestureRecognize.location(in: _sceneView)  // initial position of pan
            let hits = _sceneView.hitTest(startFlick, options: nil)
            if let object = hits.first?.node {      // get object we're touching
                movingDie = object as? Dice         // are we on a die?
                toggle = gestureRecognize.numberOfTouches > 1
                if movingDie == nil { movingDie = _world.nearestDie(pos: startFlick, tolerance: 22) } // are we close to a die?
                if movingDie == nil || toggle { // || _world.state == .rolling {  // we're swiping, keep track of it...
                    let v = gestureRecognize.velocity(in: _sceneView)
                    let ang = atan2(v.y, v.x)
                    cumAng = 0; numSample = 1; aveSpeed = sqrt(v.x*v.x+v.y*v.y); lastAngle = abs(ang); aveR = startFlick; aveV = v
                    movingDie = nil
                    
                } else {                                       // let's drag the die
                    _world.movingDice(type: .dynamic, movingDie: movingDie!)
                    helpMoveDie(die: movingDie!, pos: startFlick)
                    toggle = false
                }
            }
        } else if gestureRecognize.state == .changed {
            if movingDie != nil {   // moving the die
                helpMoveDie(die: movingDie!, pos: gestureRecognize.location(in: _sceneView))
            } else {                // tracking the swipe
                toggle = toggle || gestureRecognize.numberOfTouches > 1
                trackSwipe(v: gestureRecognize.velocity(in: _sceneView), R: gestureRecognize.location(in: _sceneView))
            }
        }
    }
    
    @objc func handleTripleTap(_ gestureRecognize: UIGestureRecognizer) { // handle triple tap
        if gestureRecognize.state == .ended {
            let pos = gestureRecognize.location(in: _sceneView) //CGPoint
            let hits = _sceneView.hitTest(pos, options: nil)
            if let object = hits.first?.node {
                _game.tripleTapped(object, pos, gestureRecognize.numberOfTouches > 1)
            }
        }
    }
    
    @objc func handleTap(_ gestureRecognize: UIGestureRecognizer) { // handle single tap
        if gestureRecognize.state == .ended {
            let pos = gestureRecognize.location(in: _sceneView) //CGPoint
            let hits = _sceneView.hitTest(pos, options: nil)
            if let objectTap = hits.first?.node {
                _game.tapped(objectTap, pos, gestureRecognize.numberOfTouches > 1)
            } else {
                _game.tapped(pos, gestureRecognize.numberOfTouches > 1)
            }
        }
    }

    func createButtons() { // create help, sound, setting and un/re/do buttons

        //sound button
        soundButton.frame = CGRect(x: overlayBounds.width - 39, y: 0, width: 34, height: 34)
        soundButton.backgroundColor = UIColor.clear
        soundButton.setImage(UIImage(named: "mute"), for: .normal)
        soundButton.contentVerticalAlignment = .fill; soundButton.contentHorizontalAlignment = .fill
        soundButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: 34/2, bottom: 34/2, right: 0)
        soundButton.addTarget(self, action: #selector(toggleSound), for: .touchUpInside)
        _sceneView.addSubview(soundButton)
        
        //settings button
        settingButton.frame = CGRect(x: 0, y: overlayBounds.height - 34, width: 34, height: 34)
        settingButton.backgroundColor = UIColor.clear
        settingButton.setImage(UIImage(named: "gear"), for: .normal)
        settingButton.contentVerticalAlignment = .fill; settingButton.contentHorizontalAlignment = .fill
        settingButton.imageEdgeInsets = UIEdgeInsets(top: 34/4, left: 0, bottom: 0, right: 34/4)
        settingButton.addTarget(self, action: #selector(showSettings), for: .touchUpInside)
        _sceneView.addSubview(settingButton)
        
        //history button
        historyButton.frame = CGRect(x: 0, y: overlayBounds.height - 70, width: 34, height: 34)
        historyButton.backgroundColor = UIColor.clear
        historyButton.setImage(UIImage(named: "receipt"), for: .normal)
        historyButton.contentVerticalAlignment = .fill; historyButton.contentHorizontalAlignment = .fill
        historyButton.imageEdgeInsets = UIEdgeInsets(top: 34/4, left: 0, bottom: 0, right: 34/4)
        historyButton.addTarget(self, action: #selector(showHistory), for: .touchUpInside)
        historyButton.isEnabled = false
        historyButton.isHidden = true
        _sceneView.addSubview(historyButton)
        
        //help button
        helpButton.frame = CGRect(x: overlayBounds.width - 34, y: overlayBounds.height - 34, width: 34, height: 34)
        helpButton.backgroundColor = UIColor.clear
        helpButton.setImage(UIImage(named: "help"), for: .normal)
        helpButton.contentVerticalAlignment = .fill; helpButton.contentHorizontalAlignment = .fill
        helpButton.imageEdgeInsets = UIEdgeInsets(top: 34/4, left: 34/4, bottom: 0, right: 0)
        helpButton.addTarget(self, action: #selector(showHelp), for: .touchUpInside)
        _sceneView.addSubview(helpButton)
        
        //undo button
        undoButton.frame = CGRect(x: 0, y: 2, width: 34, height: 34)
        undoButton.backgroundColor = UIColor.clear
        undoButton.setImage(UIImage(named: "undo"), for: .normal)
        undoButton.contentVerticalAlignment = .fill; undoButton.contentHorizontalAlignment = .fill
        undoButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 34/4, right: 34/4)
        undoButton.addTarget(self, action: #selector(doUndo), for: .touchUpInside)
        _sceneView.addSubview(undoButton)
        _world.undoButton = undoButton
        undoButton.isEnabled = false
        undoButton.isHidden = true

        //redo button
        //redoButton.frame = CGRect(x: 0, y: 54, width: 34, height: 34)
        //redoButton.frame = CGRect(x: 54, y: 2, width: 34, height: 34)
        redoButton.frame = CGRect(x: 0, y: 36, width: 34, height: 34)
        redoButton.backgroundColor = UIColor.clear
        redoButton.setImage(UIImage(named: "redo"), for: .normal)
        redoButton.contentVerticalAlignment = .fill; redoButton.contentHorizontalAlignment = .fill
        //redoButton.imageEdgeInsets = UIEdgeInsets(top: 34/8, left: 0, bottom: 34/8, right: 34/4)
        redoButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 34/4, right: 34/4)
        redoButton.addTarget(self, action: #selector(doRedo), for: .touchUpInside)
        _sceneView.addSubview(redoButton)
        _world.redoButton = redoButton
        redoButton.isEnabled = false
        redoButton.isHidden = true
        
        toggleDieButton()
    }
    
    
    func toggleDieButton() {
        if dieButton.isEmpty {
            let y0 = CGFloat(54)
            let dyy = (overlayBounds.height - 44 - y0) / CGFloat(DieType.allCases.count + 1)
            let dy = (dyy < 65) ? dyy : 65
            let sz = dy * 50/65
            let x0 = overlayBounds.width - sz
            dieButtonPos = CGRect(x: x0, y: y0, width: sz, height: dy*CGFloat(DieType.allCases.count))
            for (i,type) in DieType.allCases.enumerated() {
                dieButton[type] = UIButton(frame: CGRect(x: x0, y: y0+dy*CGFloat(i), width: sz, height: sz))
                dieButton[type]?.backgroundColor = UIColor.clear
                dieButton[type]!.setImage(smallIcon[type], for: .normal)
                dieButton[type]!.addTarget(self, action: #selector(doDie), for: .touchUpInside)
                _sceneView.addSubview(dieButton[type]!)
                dieButton[type]!.isEnabled = true
            }
            //all button
            allButton.frame = CGRect(x: x0, y: y0+dy*CGFloat(DieType.allCases.count), width: sz, height: sz)
            allButton.backgroundColor = UIColor.clear
            allButton.setImage(UIImage(named: "allSMALL"), for: .normal)
            allButton.addTarget(self, action: #selector(doAllDie), for: .touchUpInside)
            _sceneView.addSubview(allButton)
            allButton.isEnabled = true
        } else {
            let p = allButton.isEnabled
            allButton.isEnabled = !p
            allButton.isHidden = p
            for (_,v) in dieButton {
                v.isHidden = p
                v.isEnabled = !p
            }
        }
    }
    
    @objc func doAllDie(sender: UIButton!) {
        diceSetView = DiceSetView(frame: self.view.frame, safe: overlayBounds, image: smallIcon, inventory: _world.inventory(), max: 25)
        if diceSetView != nil {
            removeGestures()
            self.view.addSubview(diceSetView!)
        }
    }
    
    @objc func doDie(sender: UIButton!) { // user wants to select a number of dice
        if diceNumberView != nil {return}  // long tap, don't do button!
        dieType = (dieButton.first(where: { $1 == sender })?.key)!
        diceNumberView = DiceNumberView(frame: self.view.frame, safe: overlayBounds, image: sender.currentImage!, add: false)
        if diceNumberView != nil {
            removeGestures()
            self.view.addSubview(diceNumberView!)
        }
    }
    
    @objc func toggleSound(sender: UIButton!){  // toggle sound
        //print("toggle sound")
        let sound = !_game.sound
        _game.sound = sound
        if sound {
            soundButton.setImage(UIImage(named: "sound"), for: .normal)
        } else {
            soundButton.setImage(UIImage(named: "mute"), for: .normal)
        }
    }
    
    @objc func doUndo(sender: UIButton!){   // Undo was pressed
        _game.undo()
    }
    @objc func doRedo(sender: UIButton!){   // Redo was pressed
        _game.redo()
    }
    @objc func showHistory(sender: UIButton!){ // settings was pressed
        if _game.history == nil {return}
        historyView = HistoryView(frame: self.view.frame, safe: overlayBounds, history: _game.history!, gvc: self)
        if historyView != nil {
            removeGestures()
            self.view.addSubview(historyView!)
        }
    }
    @objc func showSettings(sender: UIButton!){ // settings was pressed
        settingView = SettingView(frame: self.view.frame, safe: overlayBounds, game: _game!)
        if settingView != nil {
            removeGestures()
            self.view.addSubview(settingView!)
        }
    }
    
    @objc func showHelpDetail(sender: UIButton!){ // help was pressed
        if helpView != nil {helpView!.removeFromSuperview()}; helpView = nil
        helpDetailView = HelpDetailView(frame: self.view.frame, safe: overlayBounds)
        if helpDetailView != nil {
            removeGestures()
            self.view.addSubview(helpDetailView!)
        }
    }
    
    @objc func showHelp(sender: UIButton!){ // help was pressed
        helpView = HelpView(frame: self.view.frame, safe: overlayBounds, game: _game!)
        if helpView != nil {
            removeGestures()
            self.view.addSubview(helpView!)
        }
    }
    
    @objc func dieSetPressed(sender: UIButton!) {
        let set = diceSetView!.newDieSet()
        donePressed(sender: sender)
        if set != _world.inventory() {
            if sender.currentTitle == "Drop dice" {
                _game.setDiceNumber(diceSet: set)
            } else {
                _game.setDiceNumber(diceSet: set)
                _game.hud!.toRoll()
                _world.rollRandom()
            }
        }
    }
    @objc func numberDiePressed(sender: UIButton!) { // number of dice wanted on the table
        if addDie {
            var inv = _world.inventory()
            inv[dieType]! += Int(sender.currentTitle!)!
            _game.setDiceNumber(diceSet: inv)
        } else {
            _game.setDiceNumber(diceSet: [dieType:Int(sender.currentTitle!)!])
            _game.hud!.toRoll()
            _world.rollRandom()
        }
        donePressed(sender: sender)
    }
    func startNewGame(game: Games) {
        _game.game_ = game
        _game.startGame()
        let fp = (game == .freeplay)
        for (_,b) in dieButton { b.isHidden = !fp; b.isEnabled = fp}
        dieButton[.dice6]!.isHidden = !(fp || game == .horror)
        dieButton[.dice6]!.isEnabled = fp || game == .horror
        allButton.isHidden = !fp
        allButton.isEnabled = fp
        if game == .horror {
            var inv = _world.inventory()
            for (k,_) in inv { if k != .dice6 {inv[k] = 0} }
            _game.setDiceNumber(diceSet: inv)
        }
    }
    @objc func donePressed(sender: UIButton!){  // generic dismissal of a view (help, setting, # of dice
        if helpDetailView != nil { helpDetailView!.removeFromSuperview()}; helpDetailView = nil  // dismiss help
        if helpView != nil { helpView!.removeFromSuperview()}; helpView = nil  // dismiss help
        if startView != nil {
//print(startView!.game())
            let game = startView!.game()
            startNewGame(game: game)
            _game.throwOption = _game.defaultTap(game: game)
            startView!.removeFromSuperview()
            if game == .horror || game == .freeplay {_game.history = History(button: historyButton)}
        }; startView = nil
        if settingView != nil { // setting
            if _game.game_ != settingView!.game() { // game changed
                startNewGame(game: settingView!.game())
            }
            if settingView!.history() && _game.history == nil {
                _game.history = History(button: historyButton)
            } else if !settingView!.history() && _game.history != nil {
                _game.history = nil
            }
            if let nDPS = settingView!.numDiePerSide() {
                _world.numDiePerSide = nDPS
            }
            _game.throwOption = settingView!.throwOption()
            _world.numUndo = settingView!.numUndo()
            _world.pulsing = settingView!.pulsing()
            _game.energyThrow_ = settingView!.energy()
            _world.launchType = settingView!.launch()
            settingView!.removeFromSuperview() // dismiss setting view
        }; settingView = nil
        if diceNumberView != nil { diceNumberView!.removeFromSuperview()}; diceNumberView = nil
        if diceSetView != nil { diceSetView!.removeFromSuperview()}; diceSetView = nil
        if historyView != nil { historyView!.removeFromSuperview()}; historyView = nil

        addDie = false
        createGestures() // recreate gestures
    }
    
    override var shouldAutorotate: Bool {
        return true
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .landscape
    }
    
    func supportedInterfaceOrientations(for window: UIWindow?) -> UIInterfaceOrientationMask {
        return .landscape
    }
    
    override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        return .landscapeLeft
    }
    
    override var prefersStatusBarHidden: Bool {
        //return false
        return true
    }
    
}
