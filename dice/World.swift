//
//  World.swift
//  dice
//
//  Created by G.J. Parker on 19/9/19.
//  Copyright © 2019 G.J. Parker. All rights reserved.
//

import UIKit
import SceneKit
import AudioToolbox.AudioServices

enum WorldState {
    case rolling, rolled, moving
}

enum LaunchType: Int, CaseIterable {
    case gather = 0, scatter
}

class World: SCNScene, SCNPhysicsContactDelegate {
    
    class Undo {  //class to keep track for undo and redo
        private var pos : simd_float3
        private var or: simd_quatf
        private var hold: Bool
        private var dieType: DieType
        
        var position: simd_float3 {
            get { return pos }
            set (value) { pos = value }
        }
        var orientation: simd_quatf {
            get { return or }
            set (value) { or = value }
        }
        var held: Bool {
            get { return hold }
            set (value) { hold = value }
        }
        var type: DieType {
            get { return dieType }
            set (value) { dieType = value }
        }
        init(position: simd_float3, orientation: simd_quatf, held: Bool, type: DieType) {
            self.pos = position
            self.or = orientation
            self.hold = held
            self.dieType = type
        }
    }
    
    private var _dice = [Dice]()  // the current dice on the table
    private var _state = WorldState.rolled  // are we rolling or not?
    
    private var dieHold = [Dice]()      // list of held dice
    private var dieSelection = [Dice]() // list of selected dice
    private var throwResults = [[Undo]]()   // the previous results (for undo/redo)
    private var nUndo = 1               // number of undos to keep track of, -1 is infinity
    private var whichUndo = 0           // the index of which thrownResults we're on
    private var pulse = true
    private var lastType = DieType.dice6
    
    private var launchHeight : Float    // default height to throw dice
    private var scaleLH = Float(1)         // and it's scaling
    private var _launchType = LaunchType.gather
    
    private var running = 1             // a 'trick' to not exit .rolling state prematurely
    
    private let dieSize = Float(0.1)    // die side length (yes, 10cm!)
    private var numberDiceShortSide = Float(10) // number of dice that could fit in the short side of the table
    
    var wScale = CGFloat(0)  // table width (m)
    var hScale = CGFloat(0)  // table height (m)
    
    private var height = CGFloat(0)  // screen size in pixels
    private var width = CGFloat(0)
    private var otherFOV = CGFloat(0)  // the wide FOV is 35 and this is calculated
    private var rect : CGRect!       // rectangle giving the 'safe' area
    
    var _undoButton = UIButton()  // undo button
    var _redoButton = UIButton()  // redo button
    
    var state: WorldState {
        get {return _state}
    }
    var launchType: LaunchType {
        get { return _launchType}
        set (value) { _launchType = value }
    }
    var launch: Float {
        get { return scaleLH }
        set (value) { scaleLH = value }
    }
    var pulsing: Bool {
        get { return pulse }
        set (value) {
            if pulse != value {
                pulse = value
                holdColor()  // update any select/held dice
                selectColor()
            }
        }
    }
    var numUndo : Int {  // set/get number of undos
        get { return nUndo }
        set (value) {
            if value != nUndo {
                nUndo = value
                if value == 0 {
                    throwResults.removeAll()
                    clearUnReDo()
                    whichUndo = 0
                } else if value > 0 {
                    if throwResults.count > value + 1 {  // limited undo?
                        for _ in 0..<(throwResults.count - value - 1) {
                            throwResults[value+1].removeAll()
                            throwResults.remove(at: value+1)
                        }
                    }
                    if whichUndo > value {whichUndo = min(whichUndo,value)}
                }
                nUndo = value
            }
        }
    }
    var undoButton: UIButton { // so we can turn it on/off
        get { return _undoButton }
        set (value) { _undoButton = value }
    }
    var redoButton: UIButton { // se we can turn it on/off
        get { return _redoButton }
        set (value) { _redoButton = value }
    }
    var dice: [Dice] { // return the array of dice on the table
        get { return _dice }
    }
    var sound: Bool { // turn on/off sound by being contactDelegate nor not
        get { return self.physicsWorld.contactDelegate != nil }
        set (value) {
            if value {
                self.physicsWorld.contactDelegate = self
            } else {
                self.physicsWorld.contactDelegate = nil
            }
        }
    }
    var numDiePerSide : Float { // resize the table?)
        get {
            return numberDiceShortSide
        }
        set (value) {
            if numberDiceShortSide != value {
                let scale = value / numberDiceShortSide
                numberDiceShortSide = value
                adjustGameBoard()
                if _dice.count > 0 {
                    for die in _dice {
                        let r = die.presentation.simdPosition
                        die.simdPosition = simd_float3(r.x * scale, r.y * 1.001, r.z * scale)
                        die.physicsBody!.resetTransform()
                        if numberDiceShortSide < 6 {
                            die.physicsBody?.restitution = 0.5 // too many collisions for size of box, increase energy loss
                        } else {
                            die.physicsBody?.restitution = die.restitution
                        }
                    }
                }
            }
        }
    }
    
    func convert(pos: CGPoint) -> simd_float3 {  // convert screen point into World point
        //let minmaxW = (Float(wScale) - sqrt(3)*dieSize)/2
        //let minmaxH = (Float(hScale) - sqrt(3)*dieSize)/2
        let size = (_dice.count>0) ? 2*_dice.map({$0.circumR}).max()! : 0.0
        let minmaxW = (Float(wScale) - size)/2
        let minmaxH = (Float(hScale) - size)/2
        return simd_float3(min(minmaxW,max(-minmaxW,convert(d: pos.x - width/2))), 0, min(minmaxH,max(-minmaxH,convert(d: pos.y - height/2))))
    }
    func convert(pos: simd_float3) -> CGPoint {  // convert World point into screen point
        return CGPoint(x: convert(d: pos.x) + width/2, y: convert(d: pos.z) + height/2)
    }
    func convert(d: CGFloat) -> Float {     // convert screen distance to World distance
        return Float(d * wScale / width) //(wScale - CGFloat(sqrt(3)*dieSize)) / width)
    }
    func convert(d: Float) -> CGFloat {     // convert World distance to screen distance
        return CGFloat(d) * width / wScale  //(wScale - CGFloat(sqrt(3)*dieSize))
    }
    
    func scoreDice(type: DieType) -> [Int] {
        var vals = [Int](repeating: 0, count: type.rawValue)
        for die in _dice.filter( {$0.dieType == type}) {
            let score = die.value(up: simd_float3(x: 0, y: 1, z: 0))
            if score > 0 { vals[ score - 1] += 1 } else {vals[1] += 1}
        }
        return vals
    }
    func scoreDice() -> [Int] { // return an array of 1s, 2s, ..., 6s
        var vals = [Int](repeating: 0, count: 20)
        for die in _dice {
            let score = die.value(up: simd_float3(x: 0, y: 1, z: 0))
            if score > 0 { vals[ score - 1] += 1 }
        }
        return vals
    }
    func freeze(_ die: Dice? = nil) { // called by timer after transition from .rolling to .rolled
        if _state == .rolled { // only do this if we're .rolled
            if let d = die {
                d.physicsBody?.type = .static
                d.physicsBody?.clearAllForces()
            } else {
                for d in _dice {
//print(d.physicsBody?.type == .static, d.physicsBody!.isResting)
                    d.physicsBody?.type = .static     // stop dynamic moving
                    d.physicsBody?.clearAllForces()   // we need this to stop scenekit renderer...
                }
            }
        }
    }
    func resultDice() -> [Int] { // list of individual die results
        var vals = [Int]()
        for die in _dice {
            vals.append(die.value(up: simd_float3(x: 0, y: 1, z: 0)))
        }
        return vals
    }
    func resultDie(_ die: Dice) -> Int { //value of this die
        return die.value(up: simd_float3(x: 0, y: 1, z: 0))
    }
    
    func sumDice() -> Int {  // sum of all dice
        var sum = 0
        for die in _dice {
            sum += die.value(up: simd_float3(x: 0, y: 1, z: 0))
        }
        return sum
    }
    func findVal(val: Int) -> [Dice] {
        var dice = [Dice]()
        for die in _dice {
            if resultDie(die) == val { dice.append(die) }
        }
        return dice
    }
    func holdColor() {   // held dice appearance
        for d in dieHold {
            d.defaultColor()
            d.holdColor(pulse: pulse)
        }
    }
    func selectColor() { // selected dice appearance
        for d in dieSelection {
            d.defaultColor()
            d.selectColor(pulse: pulse)
        }
    }
    
    var startTime : TimeInterval = 0
    func update(_ time: TimeInterval) {  // called when physics engine is running...
        if _state == .rolling {  // get out if state is not .rolling
            if running < 1 {    // hack to avoid premature not following
                var allRest = true  // physics engine says all dynamic bodies are at rest?
                var allStop = false // all stopped moving/rotatin, essentially?
                for die in _dice {  // loop over all dice
                    if die.physicsBody?.type == .dynamic {  // we might be doing animation to move dice around, so don't get confused.
                        let y = die.presentation.simdPosition.y
                        if y > launchHeight/4 { startTime = time }
                        let v = die.physicsBody!.velocity  // get linear velocity
                        let I = die.inertiaByMass
                        let w = die.physicsBody!.angularVelocity
                        if v.x * v.x + v.y * v.y + v.z * v.z + (w.x*I.x*w.x + w.y*I.y*w.y + w.z*I.z*w.z)*w.w*w.w > max(1e-4,2*9.8*(die.midR-y)) {
//print("\(die.physicsBody!.angularVelocity.w) \(v.x * v.x + v.y * v.y + v.z * v.z)")
                            allStop = false; allRest = false; break  // stuff still moving
                        }
                        allStop = true  // there are dynamic dice and at least one is not moving
                    }
                    allRest = allRest && die.physicsBody!.isResting // is physic engine saying things stopped?
                }
                if (allStop || allRest || time - startTime > 30) { // everything stopped or we've been rolling for 30 seconds?
//print("\(allStop) \(allRest) \(time-startTime) \(running)")
                    _state = .rolled  // not rolling any more
                    for die in _dice {  // turn all dice static and update position and orientation to what is displayed
//print(die.physicsBody?.type == .static, die.physicsBody?.type == .dynamic)
                        die.simdPosition = die.presentation.simdPosition
                        die.simdOrientation = die.presentation.simdOrientation
                        die.physicsBody!.resetTransform()
                    }
                    DispatchQueue.main.async { // so we can deal w/ UI updates...
                        NotificationCenter.default.post(name: NSNotification.Name("physicsDone"), object: nil)
                    }
                }
            } else { startTime = time }
            running = max(0, running-1)  // trick to avoid premature decision that physics engin is done
        }
    }
    
    func movingDice(type: SCNPhysicsBodyType, movingDie: Dice) {
        _state = (type == .static) ? .rolled : .moving
        //print("in movingDice \(type == .static)  \(movingDie.physicsBody?.type == .static) \(movingDie.physicsBody?.type == .dynamic)")
        for die in _dice {
            if die != movingDie {
                //print("\(die.physicsBody?.type == .static) \(die.physicsBody?.type == .dynamic)")
                die.physicsBody?.type = type
                if type != .static {
                    let constraint1 = SCNSliderConstraint()
                    constraint1.offset = SCNVector3(die.circumR, die.inR, die.circumR)
                    constraint1.radius = CGFloat(die.inR) //* 1.1
                    constraint1.collisionCategoryBitMask = 4
                    let constraint2 = SCNDistanceConstraint(target: movingDie)
                    constraint2.maximumDistance = 1000
                    constraint2.minimumDistance = CGFloat(die.midR)
                    constraint2.influenceFactor = 0.5
                    die.constraints = [constraint1, constraint2]
                } else {
                    die.constraints = nil
                }
            } else {
                die.physicsBody?.type = (type == .dynamic) ? .static : .dynamic // the die we're moving...
            }
            die.physicsBody?.clearAllForces()
            die.simdPosition = die.presentation.simdPosition
            die.simdOrientation = die.presentation.simdOrientation
            die.physicsBody!.resetTransform()
        }
        if type == .static {
            Timer.scheduledTimer(withTimeInterval: 1.5, repeats: false, block: {_ in
                if self._state == .rolled {
                    movingDie.physicsBody?.type = .static
                    self.freeze(movingDie)
                    self.replaceUndo()
                }
            })
        }
        //print("done w/ movingDice \(type == .static) \(movingDie.physicsBody?.type == .static) \(movingDie.constraints == nil)\n")
    }
    
    func destroyDie(_ die: Dice) {
        unselectDie(die: die)
        unholdDie(die: die)
        _dice.removeAll(where: { $0 == die })
        die.die()
    }
    
    func addDie(_ pos: CGPoint, type: DieType?) {
        var itype = lastType
        if type != nil {itype = type!}
        switch itype {
        case .dice4:
            _dice.append(Tet(size: CGFloat(dieSize)))
        case .dice6:
            _dice.append(Cube(size: CGFloat(dieSize)))
        case .dice8:
            _dice.append(Oct(size: CGFloat(dieSize)))
        case .dice10:
            _dice.append(Dec(size: CGFloat(dieSize)))
        case .dice12:
            _dice.append(Dod(size: CGFloat(dieSize)))
        case .dice20:
            _dice.append(Ico(size: CGFloat(dieSize)))
        default:
            _dice.append(Coin(size: CGFloat(dieSize)))
        }
        lastType = itype
        let die = _dice.last!
        if numberDiceShortSide < 6 { die.physicsBody?.restitution = 0.5 }
        die.simdOrientation = die.randomOrientation()  // create random orientation
        //let size = sqrt(3*die.size)+0.5*die.size  // place it just above the floor
        //let size = 1.5*die.size
        let size = 2.5*die.circumR
        die.simdPosition = convert(pos: pos) + simd_float3(0, size, 0)
        die.physicsBody!.resetTransform()
        self.rootNode.addChildNode(die)  // add the new node to rootnode
        Timer.scheduledTimer(withTimeInterval: 3, repeats: false, block: {_ in
            if self._state == .rolled {
                die.physicsBody?.type = .static
                self.freeze(die)
            }
        })
    }
    
    func nearestDie(pos: CGPoint, tolerance: Float) -> Dice? {
        let r0 = convert(pos: pos)
        
        var d = (tolerance + 1) * Float(wScale / width) // only care about die this close or closer
        var nearDie : Dice? = nil
        for die in _dice {
            let r = die.presentation.simdPosition
            let d0 = simd_length(r - r0 - simd_float3(0,r.y,0))
            if d0 < d {
                d = d0
                nearDie = die
            }
        }
        return nearDie
    }
    
    func holdDie(_ die : Dice) {
        if dieHold.contains(die) {
            unholdDie(die: die)
        } else {
            dieHold.append(die)
            unselectDie(die: die)
            holdColor()
            //print("did hold die \(die)")
        }
    }
    func unholdDie(die : Dice?) {
        if let d = die {
            d.defaultColor()
            dieHold.removeAll(where: { $0 == d })
        } else {
            for d in dieHold { d.defaultColor() }
            dieHold.removeAll()
        }
    }
    func isHeld(die: Dice) -> Bool {
        return dieHold.contains(die)
    }
    
    func selectDie(_ newDie: Dice) {
        if dieHold.contains(newDie) {return}
        if dieSelection.contains(newDie) {
            unselectDie(die: newDie)
        } else {
            dieSelection.append(newDie)
            selectColor()
        }
    }
    func unselectDie(die : Dice?) {
        if let d = die {
            d.defaultColor()
            dieSelection.removeAll(where: { $0 == d })
        } else {
            for d in dieSelection { d.defaultColor() }
            dieSelection.removeAll()
        }
    }
    func inSelection(die: Dice) -> Bool {
        return dieSelection.contains(die)
    }
    
    func clearUnReDo() {
        _undoButton.isEnabled = false
        _undoButton.isHidden = true
        _redoButton.isEnabled = false
        _redoButton.isHidden = true
    }
    
    func deleteUndo() {
        throwResults.removeAll()
        whichUndo = 0
        clearUnReDo()
    }

    func newUndo() {
        if nUndo == 0 { return }
        if _state != .rolling { // don't save anything in motion...
            if whichUndo > 0 {  // delete any future we have...
                for _ in 0..<whichUndo {
                    throwResults.remove(at: 0)
                }
                whichUndo = 0
            }
            throwResults.insert([], at: 0)
            for die in _dice {
                throwResults[0].append(Undo.init(position: die.presentation.simdPosition,
                                                 orientation: die.presentation.simdOrientation,
                                                 held: dieHold.contains(die),
                                                 type: die.dieType))
            }
            if nUndo != -1 && throwResults.count > nUndo + 1 {  // limited undo?
                for _ in 0..<(throwResults.count - nUndo - 1) {
                    throwResults[nUndo+1].removeAll()
                    throwResults.remove(at: nUndo+1)
                }
            }
            redoButton.isEnabled = false
            _redoButton.isHidden = true
            _undoButton.isEnabled = (throwResults.count > 1)
            _undoButton.isHidden = !(throwResults.count > 1)
            //print("newUndo: \(throwResults.count) \(_dice.count)")
        }
    }
    func replaceUndo() { // if dice moved since last roll, just replace the undo w/ the new moved positions
        if nUndo == 0 || !throwResults.indices.contains(whichUndo) {return}  //punt if undo doesn't exist
        throwResults[whichUndo].removeAll()
        for die in _dice {
            throwResults[whichUndo].append(Undo.init(position: die.presentation.simdPosition,
                                             orientation: die.presentation.simdOrientation,
                                             held: dieHold.contains(die),
                                             type: die.dieType))
        }
    }
    
    func redo() {
        if _state != .rolling {
            //print("redo: \(whichUndo)")
            whichUndo -= 1
            resetDieNum()
            if whichUndo == 0 {
                _redoButton.isEnabled = false
                _redoButton.isHidden = true
            }
            _undoButton.isEnabled = (whichUndo + 1 < throwResults.count)
            _undoButton.isHidden = !(whichUndo + 1 < throwResults.count)
        }
    }
    
    func undo() {
        if _state != .rolling {
            //print("doing something in world.undo \(whichUndo) \(throwResults.count) \(_dice.count)  \(throwResults[0].count)")
            if whichUndo+1 < throwResults.count {
                whichUndo += 1
                resetDieNum()
                _undoButton.isEnabled = (whichUndo + 1 < throwResults.count)
                _undoButton.isHidden = !(whichUndo + 1 < throwResults.count)
                _redoButton.isEnabled = true
                _redoButton.isHidden = false
                //print("end of world.undo \(throwResults.count) \(_dice.count)")
            }
        }
    }
    
    func inventory() -> [DieType:Int] {
        var inv = Dictionary<DieType, Int>()
        for type in DieType.allCases {
            inv[type] = _dice.filter({$0.dieType == type}).count
        }
        return inv
    }

    func resetDieNum() {  // doing either undo or redo
        
        //clear selection and hold
        unselectDie(die: nil)
        unholdDie(die: nil)
        
        // get correct number and type of dice on table
        for type in DieType.allCases {
            let correctTR = throwResults[whichUndo].filter({$0.type == type})  // corresponding list of throwResults
            let need = correctTR.count
            let current = _dice.filter({$0.dieType == type}).count
            if need != current {
                if current > need {
                    for (i,d) in _dice.filter({$0.dieType == type}).enumerated() {
                        if i+1 > need { destroyDie(d)}
                    }
                } else {
                    for i in current..<need {
                        addDie(CGPoint(x: 0, y: 0), type: type)
                        let die = _dice.last!
                        die.simdPosition = correctTR[i].position
                        die.simdOrientation = correctTR[i].orientation
                    }
                }
            }
       
            for (i,die) in _dice.filter({$0.dieType == type}).enumerated() {  // for each die of type
                
                die.physicsBody?.type = .static // don't want them to do physics (yet)
                let r = correctTR[i].position  // we're going to this final position
                let q = correctTR[i].orientation
                if correctTR[i].held {  // was it a held die?
                    holdDie(die)
                } else {
                    die.defaultColor()
                }
                let newRot = simd_mul(q,die.presentation.simdOrientation.inverse)
                // eye-candy for moving the dice from current to final position
                let composite = SCNAction.group([SCNAction.move(to: SCNVector3(x: r.x, y: r.y, z: r.z), duration: 0.5 ),
                                                 SCNAction.rotate(by: CGFloat(newRot.angle),
                                                                  around: SCNVector3(newRot.axis.x, newRot.axis.y, newRot.axis.z), duration: 0.5)])
                die.physicsBody?.collisionBitMask = 0  // don't care about collisions
                die.runAction(composite, completionHandler: { () in
                    die.physicsBody?.type = .dynamic
                    die.physicsBody?.clearAllForces()  // in case it has any physics forces on them
                    die.simdPosition = r                // make sure we're at the position
                    die.simdOrientation = q             // and orientation
                    die.physicsBody?.resetTransform()
                    die.physicsBody?.collisionBitMask = 3  // turn collisions back on
                    })
            }
        }
        _state = .rolling  // rendering will take care of re0scoring
        running = 2
    }

    func numToRoll() -> Int {
        if dieSelection.count > 0 { return dieSelection.count}
        return Array(Set(_dice).subtracting(dieHold)).count
    }
    
    func randomThrow() -> SCNVector3 { return SCNVector3Zero}
    
    func rollRandom () {
        let phi = Float.random(in: 0...(2*Float.pi))
        roll(v: SCNVector3(x: cos(phi), y: 0, z: sin(phi)), frot: Float(1.0), pos: CGPoint(x: width/2, y: height/2))
    }
    func roll( die: Dice) { // selected one dice

        if !dieHold.contains(die) {
            unselectDie(die: nil)
            selectDie(die)
            let phi = Float.random(in: 0...(2*Float.pi))
            roll(v: SCNVector3(x: cos(phi), y: 0, z: sin(phi)), frot: Float(1.0), pos: convert(pos: die.presentation.simdPosition)) // extra lateral speed or spin
        }
    }
    
    func roll(_ pos: CGPoint) { roll(v: randomThrow(), frot: 0, pos: pos) }
    
    func roll() { roll(v: randomThrow(), frot: 0, pos: CGPoint(x: width/2, y: height/2)) }
    
    func roll(v: SCNVector3, frot: Float, pos: CGPoint) {  // roll all dice (or just the selection if exists
        if !(dieSelection.count > 0) { dieSelection = Array(Set(_dice).subtracting(dieHold)) }
        if !(dieSelection.count > 0) { return }
        clearUnReDo()
        
        for die in _dice { die.physicsBody?.type = .static } // assume they don't move
        
        let poly = min(6, dieSelection.count - 1)
        let dphi = (poly == 2) ? Float.pi / 3 : 2 * Float.pi / Float(poly)
        var phi = Float(0)
        let vperp = 0.5 * sqrt(2.0*9.8*launchHeight*scaleLH)  // 1/2 energy in perpendicular velocity as potential energy\
        
        let maxR = _dice.map({$0.circumR}).max()!
        let buffer = 2.5 * maxR
        let r00 = convert(pos: pos)
        let r0 = simd_float3(min(Float(wScale/2) - buffer, max(Float(-wScale/2) + buffer, r00.x)), 0,
                             min(Float(hScale/2) - buffer, max(Float(-hScale/2) + buffer, r00.z)))
        
        var i = -1
        var ri = Float(0)
        
        if _launchType == .gather {
            for die in dieSelection.shuffled() {  // shuffle dice
                i += 1
                let nO = die.randomOrientation()    // random starting orientation
                let size = 1.2 * die.circumR
                var rt = r0 + simd_float3(0, Float(Int(i/(poly+1)))*maxR*2.5 + launchHeight*scaleLH, 0) // group seven dice together, increase height for every group
                if i % (poly+1) == 0  {
                    ri = 1.2 * die.circumR
                    phi = Float.random(in: 0.0...(2*Float.pi))  // set initial phi for other dice
                } else {
                    rt += simd_float3((ri+size)*cos(phi+Float(i%poly)*dphi),0,(ri+size)*sin(phi+Float(i%poly)*dphi)) // not center die, put in hexagon arrangement
                }
                let r = rt
                die.simdOrientation = die.presentation.simdOrientation
                die.simdPosition = die.presentation.simdPosition
                die.physicsBody?.type = .static
                die.physicsBody?.resetTransform()
                
                // let's move the die from their positions to throwing positions- translation then rotations, ignoring collisions. just eye candy
                let newRot = simd_mul(nO,die.presentation.simdOrientation.inverse)  // this is rotation to current orientation to new random orentation: q = q_new * inverse(q_current)
                //let composite = SCNAction.group([SCNAction.move(to: SCNVector3(x: r.x, y: r.y, z: r.z), duration: 0.1 ),
                /*let composite = SCNAction.sequence([SCNAction.move(to: SCNVector3(x: r.x, y: r.y, z: r.z), duration: 0.15 ),
                                                    SCNAction.rotate(by: CGFloat(newRot.angle),
                                                                     around: SCNVector3(newRot.axis.x, newRot.axis.y, newRot.axis.z), duration: 0.15)])*/
                let composite = SCNAction.group([SCNAction.move(to: SCNVector3(x: r.x, y: r.y, z: r.z), duration: 0.2 ),
                                                 SCNAction.rotate(by: CGFloat(newRot.angle), around: SCNVector3(newRot.axis.x, newRot.axis.y, newRot.axis.z), duration: 0.21)])
                die.physicsBody?.collisionBitMask = 0
    //print("\(icc) \(die.physicsBody!.collisionBitMask) \(die)")
                die.runAction(composite, completionHandler: { () in
    //print(die.presentation.simdPosition-r,die.presentation.simdOrientation-nO)
                    die.physicsBody?.type = .dynamic
                    die.physicsBody!.clearAllForces() // moving into position may have caused collision forces, ignore them!
                    die.simdPosition = r
                    die.simdOrientation = nO
                    die.physicsBody!.resetTransform()
                    // create random vector of v and omega and add
                    let rndv = SCNVector3(x: vperp*Float.random(in: -0.25...0.25), y: vperp*Float.random(in: -0.25...0.25), z: vperp*Float.random(in: -0.25...0.25)) // upto 1/8 the potential energy is random in each component (max is 3/8)
                    let rndo = Float.random(in: -1...1) //Float.random(in: 0.25...1)*Float(Int.random(in: 0...1)*2-1)
                    die.randomVelocity(SCNVector3(vperp * v.x * Float.random(in: 0.9...1.1) + rndv.x,
                                                  0.1*vperp*Float.random(in: 0.9...1.1)     + rndv.y,
                                                  vperp * v.z * Float.random(in: 0.9...1.1) + rndv.z))                  // random linear velocity
                    let inertia = die.physicsBody?.momentOfInertia
                    let mass = Float(die.physicsBody!.mass)*2*9.8*self.launchHeight
                    die.randomOmega((frot*Float.random(in: 0.9...1.1)+rndo)*sqrt(mass/inertia!.y)*0.5)
                    die.physicsBody?.collisionBitMask = 3
                })
            }
        } else {
            for die in dieSelection.shuffled() {
                die.simdOrientation = die.presentation.simdOrientation
                let pos = die.presentation.simdPosition
                die.simdPosition = convert(pos: convert(pos: simd_float3( pos.x, pos.y + 1.1 * die.circumR, pos.z)))
                die.physicsBody!.resetTransform()
                let rndv = SCNVector3(x: vperp*Float.random(in: -0.25...0.25), y: vperp*Float.random(in: 0...0.25), z: vperp*Float.random(in: -0.25...0.25))
                die.physicsBody?.type = .dynamic
                die.physicsBody!.clearAllForces()
                die.randomVelocity(SCNVector3(vperp * v.x * Float.random(in: 0.9...1.1) + rndv.x,
                                              vperp * 2.5 * Float.random(in: 0.9...1.1) + rndv.y,
                                              vperp * v.z * Float.random(in: 0.9...1.1) + rndv.z))
                let inertia = die.physicsBody?.momentOfInertia
                let mass = Float(die.physicsBody!.mass)*2*9.8*self.launchHeight
                die.randomOmega((max(0.25, frot) * Float.random(in: 0.8...1.4))*sqrt(mass/inertia!.y)*0.5)
                die.physicsBody?.collisionBitMask = 3
            }
                            
        }
        unselectDie(die: nil)
        _state = .rolling  // set state to .rolling
        running = 2  // trick to avoid premature finish
//print("rolling \(dieSelection) dice")
    }

    func adjustGameBoard() { // zooming camera in or out, adjust box accordingly.
        let ar = width / height  // aspect ratio
        wScale = CGFloat(numberDiceShortSide * dieSize) * max(1,ar)             //horizontal
        hScale = CGFloat(numberDiceShortSide * dieSize) * max(1,height/width)   //vertical
        
        let cameraY = (convert(d: CGFloat(30)) + Float(min(wScale,hScale))) / 2 / Float(tan(otherFOV))  // add 30 points for a border
        launchHeight = cameraY * 10 / 18  // launch dice below the camera
        launchHeight = min(8 * dieSize, launchHeight)
        let dScale = CGFloat(launchHeight*scaleLH*5 + 45 * dieSize)
//      let dScale = CGFloat(launchHeight*scaleLH + 125 * dieSize) // height of the box, so dice can never escape (right apple?)
        for node in self.rootNode.childNodes {
            if node.name! == "camera" {
                node.position = SCNVector3(x: 0, y: cameraY, z: 0)
            } else if node.name! == "lid" {
                node.position = SCNVector3(x: 0, y: Float(dScale), z: 0)
            } else if node.name! == "wall-left" {
                node.position = SCNVector3(x: Float(-wScale/2), y: Float(dScale/2), z: 0)
            } else if node.name! == "wall-right" {
                node.position = SCNVector3(x: Float(wScale/2), y: Float(dScale/2), z: 0)
            } else if node.name! == "wall-front" {
                node.position = SCNVector3(x: 0, y: Float(dScale/2), z: Float(-hScale/2))
            } else if node.name! == "wall-back" {
                node.position = SCNVector3(x: 0, y: Float(dScale/2), z: Float(hScale/2))
            }
        }
//print("ar:\(ar), width:\(width), height:\(height)")
//print("wS:\(wScale), hS:\(hScale), camera:\(cameraY), launchHeight:\(launchHeight), scaleLH:\(scaleLH), dScale:\(dScale)")
    }
    
    // create camera, light and the box for the dice to roll around in
    func addGameBoard() {
        
        width = rect.width
        height = rect.height
        
        let ar = width / height  // aspect ratio
        
        // area of floor is (numberDiceShortSide * dieSize)^2 * max(ar, 1/ar) m^2
        wScale = CGFloat(numberDiceShortSide * dieSize) * max(1,ar)             //horizontal
        hScale = CGFloat(numberDiceShortSide * dieSize) * max(1,height/width)   //vertical
        
        //camera
        let camera = SCNCamera()
        if ar < 1{  // field of view is 35 for the largest dimension, smaller for the other
            camera.projectionDirection = .vertical
        } else {
            camera.projectionDirection = .horizontal
        }
        camera.fieldOfView = 35
        // camera.automaticallyAdjustsZRange = true
        
        otherFOV = asin(sin(camera.fieldOfView*CGFloat.pi/360) * min(ar, 1/ar))  // find the smaller field of view
//print("otherFOV: \(otherFOV * 2 * 180 / CGFloat.pi)")
        let cameraY = (convert(d: CGFloat(30)) + Float(min(wScale,hScale))) / 2 / Float(tan(otherFOV)) // add 30 points at edge for border
        launchHeight = cameraY * 10 / 18  // launch dice below the camera
        launchHeight = min(8 * dieSize, launchHeight)
        let dScale = CGFloat(launchHeight*scaleLH*5 + 45 * dieSize) // height of the box, so dice can never escape (right apple?)
//      let dScale = CGFloat(launchHeight*scaleLH + 125 * dieSize)
//print("ar:\(ar), width:\(width), height:\(height)")
//print("wS:\(wScale), hS:\(hScale), camera:\(cameraY), launchHeight:\(launchHeight), scaleLH:\(scaleLH), dScale:\(dScale)")
        
        let cameraNode = SCNNode() // create the camera
        cameraNode.camera = camera
        cameraNode.position = SCNVector3(x: 0, y: cameraY, z: 0)  // correct height
        cameraNode.eulerAngles = SCNVector3(x: -Float.pi/2, y: 0, z: 0)  // point down to the floor
        cameraNode.name = "camera"
        camera.zNear = 0.0
        
        //ambient light and attatch to the camera
        let ambientLight = SCNLight()
        ambientLight.type = SCNLight.LightType.ambient
        //ambientLight.color = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 0.2)
        ambientLight.color = UIColor(red: 0.3, green: 0.3, blue: 0.3, alpha: 1.0)
        //ambientLight.color = UIColor(red: 0.5, green: 0, blue: 0, alpha: 1.0)
        //ambientLight.intensity = 0
        cameraNode.light = ambientLight
        cameraNode.categoryBitMask = 16
        ambientLight.categoryBitMask = 1 // 3:light die and wall/floor, 1:only light die?//0x1 << 1 //2
        
        let light2 = SCNLight()
        light2.type = SCNLight.LightType.directional
        light2.categoryBitMask = 1 //0x1 << 1 // | (0x1 << 3)
        light2.intensity = 1000
        light2.castsShadow = true
        light2.shadowMapSize = CGSize(width: 2048, height: 2048)
        light2.shadowRadius = 500//10 //5
        let lightNode2 = SCNNode()
        lightNode2.light = light2
        
        lightNode2.simdOrientation = simd_quatf(angle: 1.93205, axis: float3(-0.712484, 0.701689, 0))
//print(lightNode2.simdOrientation.act(float3(0, 0, -1)))
        lightNode2.name = "spot light2"
        lightNode2.categoryBitMask = 16 //0x1 << 1 //4
        
        //create static box for dice to play in (floor, lid and four vertical walls)
        
        // floor
        let floorGeometry = SCNFloor()
        floorGeometry.firstMaterial!.diffuse.contents = UIColor.black
        floorGeometry.firstMaterial!.writesToDepthBuffer = true
        floorGeometry.firstMaterial!.readsFromDepthBuffer = true
        floorGeometry.reflectivity = 0.35
        floorGeometry.reflectionFalloffEnd = CGFloat(dScale)// cameraY)
        let floorNode = SCNNode(geometry: floorGeometry)
        floorNode.physicsBody = SCNPhysicsBody(type: .static, shape: nil)
        floorNode.physicsBody?.friction = 1.0
        floorNode.physicsBody?.restitution = 0.1
        floorNode.physicsBody?.categoryBitMask = 2+4
        floorNode.name = "floor"
        floorNode.categoryBitMask = 2+4 //0x1 << 2
        floorGeometry.reflectionCategoryBitMask = 1 //0x1 << 2
        
        //second floor (in case the die goes through the floor
        let floorNode1 = SCNNode(geometry: floorGeometry)
        floorNode1.physicsBody = SCNPhysicsBody(type: .static, shape: nil)
        floorNode1.physicsBody?.friction = 1.0
        floorNode1.physicsBody?.restitution = 0.1
        floorNode1.physicsBody?.categoryBitMask = 2
        floorNode1.position = SCNVector3(x: 0, y: Float(-2*dieSize), z: 0)
        floorNode1.name = "second-floor"
        floorNode1.categoryBitMask = 2+4 //0x1 << 2
        floorGeometry.reflectionCategoryBitMask = 0//1//0x1 << 0
        
        //lid
        let lidGeometry = SCNPlane(width: wScale * 5, height: hScale * 5)
        let lidNode = SCNNode(geometry: lidGeometry)
        lidNode.eulerAngles = SCNVector3(x: Float.pi/2, y: 0, z: 0)
        lidNode.position = SCNVector3(x: 0, y: Float(dScale), z: 0)
        lidNode.physicsBody = SCNPhysicsBody(type: .static, shape: nil)
        lidNode.physicsBody?.friction = 0.1
        lidNode.physicsBody?.categoryBitMask = 2
        lidNode.name = "lid"
        lidNode.categoryBitMask = 2 //0x1 << 2
        
        //left wall
        let sideWallGeometry = SCNPlane(width: hScale * 5, height: dScale * 5)
        let leftWallNode = SCNNode(geometry: sideWallGeometry)
        leftWallNode.eulerAngles = SCNVector3(x: 0, y: Float.pi/2, z: 0)
        leftWallNode.position = SCNVector3(x: Float(-wScale/2), y: Float(dScale/2), z: 0)
        leftWallNode.physicsBody = SCNPhysicsBody(type: .static, shape: nil)
        leftWallNode.physicsBody?.restitution = 0.9
        leftWallNode.physicsBody?.friction = 0.1
        leftWallNode.physicsBody?.categoryBitMask = 2
        leftWallNode.name = "wall-left"
        leftWallNode.categoryBitMask = 2 //0x1 << 2
        
        //right wall
        let rightWallNode = SCNNode(geometry: sideWallGeometry)
        rightWallNode.eulerAngles = SCNVector3(x: 0, y: -Float.pi/2, z: 0)
        rightWallNode.position = SCNVector3(x: Float(wScale/2), y: Float(dScale/2), z: 0)
        rightWallNode.physicsBody = SCNPhysicsBody(type: .static, shape: nil)
        rightWallNode.physicsBody?.restitution = 0.9
        rightWallNode.physicsBody?.friction = 0.1
        rightWallNode.physicsBody?.categoryBitMask = 2
        rightWallNode.name = "wall-right"
        rightWallNode.categoryBitMask = 2 //0x1 << 2
        
        //front wall
        let endWallGeometry = SCNPlane(width: wScale * 5, height: dScale * 5)
        let frontWallNode = SCNNode(geometry: endWallGeometry)
        frontWallNode.position = SCNVector3(x: 0, y: Float(dScale/2), z: Float(-hScale/2))
        frontWallNode.physicsBody = SCNPhysicsBody(type: .static, shape: nil)
        frontWallNode.physicsBody?.restitution = 0.9
        frontWallNode.physicsBody?.friction = 0.1
        frontWallNode.physicsBody?.categoryBitMask = 2
        frontWallNode.name = "wall-front"
        frontWallNode.categoryBitMask = 2//0x1 << 2
        
        //back wall
        let backWallNode = SCNNode(geometry: endWallGeometry)
        backWallNode.eulerAngles = SCNVector3(x: 0, y: Float.pi, z: 0)
        backWallNode.position = SCNVector3(x: 0, y: Float(dScale/2), z: Float(hScale/2))
        backWallNode.physicsBody = SCNPhysicsBody(type: .static, shape: nil)
        backWallNode.physicsBody?.restitution = 0.9
        backWallNode.physicsBody?.friction = 0.1
        backWallNode.physicsBody?.categoryBitMask = 2
        backWallNode.name = "wall-back"
        backWallNode.categoryBitMask = 2//0x1 << 2
        
        //color walls back
        let blackMaterial = SCNMaterial()
        blackMaterial.diffuse.contents = UIColor.clear //red //darkGray
        blackMaterial.shininess = 100
        sideWallGeometry.materials = [blackMaterial]
        endWallGeometry.materials = [blackMaterial]
        
        self.rootNode.addChildNode(cameraNode)
        self.rootNode.addChildNode(lightNode2)
        self.rootNode.addChildNode(floorNode)
        self.rootNode.addChildNode(leftWallNode)
        self.rootNode.addChildNode(rightWallNode)
        self.rootNode.addChildNode(frontWallNode)
        self.rootNode.addChildNode(backWallNode)
        self.rootNode.addChildNode(lidNode)
        self.physicsWorld.timeStep = 1.0/120.0

    }

    func physicsWorld(_ world: SCNPhysicsWorld, didEnd contact: SCNPhysicsContact) {  // just for sound
        //print("contact: \(contact.nodeA.name) \(contact.nodeB.name) \(contact.collisionImpulse)")
        if contact.collisionImpulse > 0.25 {
            
            let vol = 1.3 * (Float(contact.collisionImpulse) - 0.25) / (5 - 0.25) + 0.2
            if ((contact.nodeA as? Coin) != nil) || ((contact.nodeB as? Coin) != nil) {
                //let vol = 1.3 * (Float(contact.collisionImpulse) - 0.25) / (5 - 0.25) + 0.2 //+ 0.6
                dieAudio1.volume = min(1.5, max(0.2, vol))
                contact.nodeA.runAction(SCNAction.playAudio(dieAudio1, waitForCompletion: false))
                //print("Contact: \(contact.nodeA.name) \(contact.nodeB.name) \(contact.collisionImpulse) \(vol)")
            } else { //if contact.collisionImpulse > 0.25 { /**/
                //let vol = 1.3 * (Float(contact.collisionImpulse) - 0.25) / (5 - 0.25) + 0.2
                dieAudio.volume = min(1.5, max(0.2, vol))
                //let _ = GameAudioPlayer(source: dieAudio, node: contact.nodeA)
                contact.nodeA.runAction(SCNAction.playAudio(dieAudio, waitForCompletion: false))
                //print("contact: \(contact.nodeA.name) \(contact.nodeB.name) \(contact.collisionImpulse) \(vol)")
            }
        }
    }
    
    lazy var dieAudio : SCNAudioSource = {  // sound for collisions
        let source = SCNAudioSource(fileNamed: "MyAssets/diceSound04.wav")!
        source.shouldStream = false
        source.volume = 0.0
        return source
    }()
    lazy var dieAudio1 : SCNAudioSource = {  // sound for collisions
        let source = SCNAudioSource(fileNamed: "MyAssets/coinSound.wav")!
        source.shouldStream = false
        source.volume = 0.0
        return source
    }()
    
    init(size: CGRect) {
        
        self.rect = size
        self.launchHeight = 10 // annoying- we need some value. will be reset in addGameBoard
        super.init()
        self.background.contents = UIColor.black
        addGameBoard()
        
        // damn delay!
        dieAudio.load()
        dieAudio1.load()
        self.rootNode.runAction(SCNAction.playAudio(dieAudio, waitForCompletion: false))
        self.rootNode.runAction(SCNAction.playAudio(dieAudio1, waitForCompletion: false))
    }
    
    required init(coder: NSCoder) {
        fatalError("Not yet implemented")
    }
    
}

class GameAudioPlayer : SCNAudioPlayer {
    private var _node: SCNNode!
    
    init(source: SCNAudioSource, node: SCNNode) {
        super.init(source: source)
        
        node.addAudioPlayer(self)
        _node = node
        
        self.didFinishPlayback = {
            self._node.removeAudioPlayer(self)
        }
    }
    
}
