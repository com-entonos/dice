//
//  Game.swift
//  dice
//
//  Created by G.J. Parker on 19/9/14.
//  Copyright © 2019 G.J. Parker. All rights reserved.
//

import UIKit
import SceneKit
import AudioToolbox.AudioServices

enum Games : Int, CaseIterable {
  //case freeplay = 0, midnight, pig, ship, craps, aces5, aces, horror
    case aces5 = 0, midnight, craps, ship, pig, aces, horror, freeplay
}

enum TapOptions : Int, CaseIterable {  // for single, double and triple tap of die, t=throw, r=remove, s=select
    case  ignore = 0, roll, hold, select, remove, duplicate
}

class Game {
   // private var _dice = [Dice]()
    private var _hud : HUD?
    private var _history : History? = nil
    private var world : World!
    private var size : CGSize!
    private var rect : CGRect!
    
    // vars for applying game rules
    private var numRolls = 0     // for craps and ship
    private var gotSCC = false   // for ship game
    private var point = 0        // for craps
    private var gameDone = true       //
    
    private var soundOn = false //true //false //true
    private var tapOpt = [TapOptions.select, TapOptions.duplicate, TapOptions.roll, TapOptions.hold, TapOptions.remove] // [0] for single tap, [1]- double, [2]- triple, [3]- long, [4]- pinch
    private var game = Games.freeplay
    private var canSelect = true
    private var canThrowOne = true
    private var canThrow = true
    private var canAddRemove = true
    private var canHold = true
    private var selectableDie = [Dice]()
    
    private var doingUnRedo = false
    private var pigUndo = false
    
    private var energyThrow = Float(1)
    
    var timerPhysics : Timer? = nil
    
    /*private let games = ["Free Play", "Midnight", "Pig", "Ship/Captain/Crew (654)", "Casino Craps", "Aces", "Aces (6 dice)", "Eldritch Horror (TM)"]
    private let defaultTap0: [[TapOptions]] = [[.select, .duplicate, .roll, .hold, .remove],
                                               [.hold, .ignore, .ignore, .ignore, .ignore],
                                               [.hold, .ignore, .ignore, .ignore, .ignore],
                                               [.hold, .select, .ignore, .roll, .ignore],
                                               [.ignore, .ignore, .ignore, .ignore, .ignore],
                                               [.ignore, .ignore, .ignore, .ignore, .ignore],
                                               [.ignore, .ignore, .ignore, .ignore, .ignore],
                                               [.roll, .remove, .ignore, .select, .remove]] */
    private let games = ["Aces", "Midnight", "Casino Craps", "Ship/Captain/Crew (654)", "Pig", "Big Aces", "Eldritch Horror (TM)", "Free Play"]
    private let defaultTap: [[TapOptions]] = [[.ignore, .ignore, .ignore, .ignore, .ignore],
                                              [.hold, .ignore, .ignore, .ignore, .ignore],
                                              [.ignore, .ignore, .ignore, .ignore, .ignore],
                                              [.hold, .select, .ignore, .roll, .ignore],
                                              [.hold, .ignore, .ignore, .ignore, .ignore],
                                              [.ignore, .ignore, .ignore, .ignore, .ignore],
                                              [.roll, .remove, .ignore, .select, .remove],
                                              [.select, .duplicate, .roll, .hold, .remove]]

    func gameName(game: Games) -> String {
        return games[game.rawValue]
    }
    func gameNames() -> [String] {
        return games
    }
    func defaultTap(game: Games) -> [TapOptions] {
        return defaultTap[game.rawValue]
    }
    var energyThrow_ : Float {
        get { return energyThrow }
        set (value) {
            energyThrow = value
            world.launch = value
        }
    }
    var game_: Games {
        get { return game }
        set (value) { game = value }
    }
    var world_: World {
        get {return world}
    }
    var throwOption : [TapOptions] {
        get {return tapOpt
        }
        set (value) {if tapOpt != value {tapOpt = value}}
    }
    var sound: Bool {
        get { return soundOn }
        set (value) { soundOn = value
            world.sound = value}
    }
    var hud: HUD? {
        get {return _hud
        }
        set (value) {_hud = value
        }
    }
    var history: History? {
        get {return _history
        }
        set (value) {_history = value
        }
    }
    
    func setDiceNumber(diceSet: [DieType:Int]) {
//print(diceSet)
        for (type, number) in diceSet {
            setDiceNumber(num: number, type: type)
        }
        for type in DieType.allCases {
            if diceSet[type] == nil { setDiceNumber(num: 0, type: type)}
        }
    }
    func setDiceNumber(num: Int, type: DieType = .dice6) {  // reset number of dice on table
//print(num,type)
        timerPhysics?.invalidate()
        let dice = world.dice
        if dice.filter({$0.dieType == type}).count > num {
            for (i,d) in dice.filter({$0.dieType == type}).enumerated() {
                if i+1 > num { world.destroyDie(d)}
            }
        } else if dice.filter({$0.dieType == type}).count < num {
            for _ in 1...(num-dice.filter({$0.dieType == type}).count) {
                world.addDie(CGPoint(x: CGFloat.random(in: 0.1...0.9) * size.width, y: CGFloat.random(in: 0.1...0.9) * size.height), type: type)
            }
        }
        world.unselectDie(die: nil) //clear any selection or hold
        world.unholdDie(die: nil)
    }
    
    func tapped(_ pos: CGPoint) {  // not needed
    }
    
    func tapped(_ objectTapped: SCNNode,_ pos: CGPoint) {  // something was single tapped
        var die = objectTapped as? Dice
        if die == nil { die = world.nearestDie(pos: pos, tolerance: 22) }
        if die != nil {    // a die?
            doTapp(die!, pos: pos, tap: tapOpt[0])
        } else if world.numToRoll() > 0 && canThrow {       //tap table- roll dice (either all non-held or the selection)
            hud!.toRoll()
            timerPhysics?.invalidate()
            world.roll(pos)
        }
    }
    
    func doubleTapped(_ objectTapped: SCNNode,_ pos: CGPoint) { // something was double tapped
        var die = objectTapped as? Dice
        if die == nil { die = world.nearestDie(pos: pos, tolerance: 22) }
        if die != nil {        // a die?
            doTapp(die!, pos: pos, tap: tapOpt[1])
        } else { //double tap table                 // double tapped table, add a die
            addDie(objectTapped, pos)
        }
    }
    
    func tripleTapped(_ objectTapped: SCNNode,_ pos: CGPoint) { // something was tripled tapped
        var die = objectTapped as? Dice
        if die == nil { die = world.nearestDie(pos: pos, tolerance: 22) }
        if die != nil {        // only a die can be tripled tapped
            doTapp(die!, pos: pos, tap: tapOpt[2])
        }
    }
    
    func longTapped(_ objectTapped: SCNNode,_ pos: CGPoint) -> Bool { // something was long tapped
        var die = objectTapped as? Dice
        if die == nil { die = world.nearestDie(pos: pos, tolerance: 22) }
        if die != nil {        // only a die can be long tapped
            doTapp(die!, pos: pos, tap: tapOpt[3])
            return true
        }
        return false
    }
    
    func flicked(_ velOfFlick: CGPoint, pos: CGPoint, speed: CGFloat, angle: CGFloat) {   // we were 'flicked' - roll if dice are on the table
        if world.numToRoll() > 0 && canThrow {
            hud!.toRoll()
            // set the direction and magnitude of throwing direction
            let psi = Float(atan2(velOfFlick.y, velOfFlick.x))  // direction of flick
            let fvel = Float(min(2.5, max(0.5, (2.5 - 0.5) * (speed - 200) / (4000.0 - 200.0) + 0.5)))   // scale over nominal speed
            let frot = Float(min(1.0, max(0.0, angle / (2 * CGFloat.pi))))                                  // how much in rotation vs translation
            //print("fvel: \(fvel) \(frot) \(speed)")
            timerPhysics?.invalidate()
            world.roll(v: SCNVector3(x: fvel * max(0.25, 1 - frot) * cos(psi), y: 0, z: fvel * max(0.25,1 - frot) * sin(psi)), frot: max(0.75,frot * fvel), pos: pos)
        }
    }
    
    func pinched(_ objectTapped: SCNNode,_ pos: CGPoint) {  // something was single tapped
        var die = objectTapped as? Dice
        if die == nil { die = world.nearestDie(pos: pos, tolerance: 22) }
        if die != nil {    // a die?
            doTapp(die!, pos: pos, tap: tapOpt[4])
        }
    }
    
    func doTapp(_ die: Dice, pos: CGPoint, tap: TapOptions) { // do whatever a single tap is suppose to do
        if tap == .select  {
            selectDie(die)
        } else if tap == .remove {
            deleteDie(die)
        } else if tap == .roll  {
            rollOneDie(die)
        } else if tap == .hold {
            holdDie(die)
        } else if tap == .duplicate {
            addDie(die, pos)
        } // otherwise .ignore
    }
    
    func holdDie(_ die: Dice) {  // want to hold a die
        if canHold {
            if game == .pig {
                hud!.toClear()
                hud!.message("Collect " + String(point), color: UIColor.blue)
                hud!.info("(next player)", color: UIColor.darkGray)
                gameDone = true
            } else if game != .ship && game != .midnight || (game == .ship && selectableDie.contains(die)) || (game == .midnight && selectableDie.contains(die)) {
                world.holdDie(die)
                if game == .ship && !world.isHeld(die: die) {  // we just unheld a die, let's select it then...
                    world.selectDie(die)
                } else if game == .ship && world.numToRoll() == 0 {  // are all the dice held?
                    if numRolls == 1 { world.unholdDie(die: die); world.newUndo() } // lucky, only took one throw
                    world.newUndo()   // pretend we threw so undo works
                    numRolls = 2
                    physicsDone()
                } else if game == .midnight {
                    canThrow = false
                    var all = true
                    for d in selectableDie { canThrow = canThrow || world.isHeld(die: d); all = all && world.isHeld(die: d)}
                    if all { world.newUndo()}
                    if world.numToRoll() == 0 {physicsDone()}
                }
            }
//print("added die to selection")
        }
    }
    
    func rollOneDie(_ die: Dice) {  // want to roll just one die
        if canThrowOne && !world.isHeld(die: die) {
            if game != .ship || (game == .ship && selectableDie.contains(die)) {
                hud!.toRoll()
                timerPhysics?.invalidate()
                world.roll(die: die)
            }
        }
    }
    
    func selectDie(_ die: Dice) {  // want to select die
        if canSelect {
            if game != .ship || (game == .ship && selectableDie.contains(die)) {
                world.selectDie(die)
            }
        }
    }
  
    func addDie(_ objectTapped: SCNNode,_ pos: CGPoint) {  // want to add/remove a die
        if canAddRemove {
            if let die = objectTapped as? Dice {     // tap table, add a die
                world.addDie(pos, type: die.dieType)
            } else if game == .horror {
                world.addDie(pos, type: .dice6)
            } else {
                world.addDie(pos, type: nil)
            }
            hud!.toClear()
        }
    }
    func deleteDie(_ objectTapped: SCNNode) {  // want to add/remove a die
        if canAddRemove {
            if let die = objectTapped as? Dice { // remove the die
                world.destroyDie(die)
                die.die()
                hud!.toClear()
            }
        }
    }

    
    func undo() { // need to roll back to pre-roll configuration...
        doingUnRedo = true
        hud!.toClear()
        if game == .ship {
            numRolls = (numRolls + 1) % 3
            gotSCC = false
            canThrowOne = false
            canSelect = false
            canHold = false
        } else if game == .midnight {
            canThrow = false
        } else if game == .craps {
            numRolls -= 2
            gameDone = false
        } else if game == .pig {
            let sum = world.sumDice()
            if sum > 1 { point -= sum }
            numRolls -= 1
            hud!.tl("Pay: " + String(point) + " (" + String(numRolls) + ")" , color: UIColor.darkGray)
            if point > 0 {hud!.bl("Select to collect Pass", color: UIColor.darkGray)}
            gameDone = false // just in case
            pigUndo = true
        }
        world.undo()
    }
    func redo() { // need to roll forward to pre-roll configuration... (only possible if we had done an Undo previously)
        doingUnRedo = true
        hud!.toClear()
        if game == .ship {
            gotSCC = false
            canThrowOne = false
            canSelect = false
            canHold = false
        }
        world.redo()
    }
    
    
    
    @objc func physicsDonePost() { // called after dice stop moving (either via physics and/or eye-candy animations
        
        // to save cpu (?) turn everything static in a few seconds, assuming we're still in rolled (could be a different rolled...)
        /**/
        timerPhysics = Timer.scheduledTimer(withTimeInterval: 3, repeats: false, block: {_ in self.world.freeze() })
        /**/
        if !doingUnRedo { world.newUndo() } // save the result of the roll
        if !pigUndo {   // do game scoring
            hud!.toClear()
            physicsDone()
        }
        doingUnRedo = false; pigUndo = false
        
        
    }
    
    func getResultString(pre: NSMutableAttributedString, type: DieType) -> NSMutableAttributedString {
        let cRoll = pre
        let inv = world.inventory()
        if inv[type]! == 0 { return cRoll}
        let vals = world.scoreDice(type: type)
        
       // print(vals.count)
        if type == .dice2 {
                let image1Att = NSTextAttachment()
                image1Att.image = UIImage(named: tinyIcon[.dice2]! + "1")
                image1Att.bounds = CGRect(x: 0, y: -3, width: 20, height: 20)
                cRoll.append(NSAttributedString(attachment: image1Att))
                cRoll.append(NSAttributedString(string: " " + String(vals[0]) + "   "))
                let image2Att = NSTextAttachment()
                image2Att.image = UIImage(named: tinyIcon[.dice2]! + "2")
                image2Att.bounds = CGRect(x: 0, y: -3, width: 20, height: 20)
                cRoll.append(NSAttributedString(attachment: image2Att))
                cRoll.append(NSAttributedString(string: " " + String(vals[1]) + "   "))
        } else {
            for i in 0..<vals.count {
                if vals[vals.count-i-1] > 0 {
                    let image1Att = NSTextAttachment()
                    image1Att.image = UIImage(named: tinyIcon[type]! + String(vals.count-i))
                    image1Att.bounds = CGRect(x: 0, y: -3, width: 20, height: 20)
                    cRoll.append(NSAttributedString(attachment: image1Att))
                    cRoll.append(NSAttributedString(string: " " + String(vals[vals.count-i-1]) + "   "))
                }
            }
        }
        return cRoll
    }
    
    
    func physicsDone() {
        //print("in physicsDone \(game)")
        
        var vals = world.scoreDice()
        //print(vals)
        if !(vals.reduce(0, +) > 0) && game != .freeplay { hud!.toClear(); return}
        var sum = 0
        for i in 0..<vals.count { sum += (i+1) * vals[i] }

        var cRoll = NSMutableAttributedString(string: String(sum) + " : ")
        for type in DieType.allCases {
            cRoll = getResultString(pre: cRoll, type: type)
        }
        if (!doingUnRedo) {_history?.add(result: cRoll as NSAttributedString, game: gameName(game: game))}
        
        // sorry for the mess...
        if game == .freeplay {
            hud!.result(cRoll)
        } else if game == .aces || game == .aces5 {
            hud!.toClear()
            selectableDie.removeAll()  // construct dice list that are still in play
            world.unselectDie(die: nil)
            sum = 0
            var smallVal = 8
            for die in world.dice {
                let value = die.value(up: simd_float3(0, 1, 0))
                if  value == 1 && !world.isHeld(die: die) { world.holdDie(die); smallVal = 0} // 1's always removed
                if !world.isHeld(die: die) {
                    selectableDie.append(die)
                    smallVal = min(smallVal, value)  // keep track of the smallest value still active
                    if !world.inSelection(die: die) { world.selectDie(die) }
                } else { sum += value}
            }
            if smallVal > 0 && smallVal < 7 { // no 1 was found and there was a smallest value
                sum += smallVal
                for die in selectableDie {  // find and hold the smallest
                    if smallVal == die.value(up: simd_float3(0, 1, 0)) {
                        world.holdDie(die)
                        selectableDie.removeAll(where: { $0 == die })
                        break
                    }
                }
            }
            if selectableDie.count < 1 {
                hud!.message("Score: " + String(sum), color: UIColor.blue)
                hud!.info("(next player)", color: UIColor.darkGray)
                world.unholdDie(die: nil)
                hud!.tl("Need some aces (do first throw)", color: UIColor.darkGray)
            } else {
                if game == .aces {
                    if selectableDie.count == 1 && vals[0] == 0 {
                        hud!.tl("At least one ace? ("+String(sum)+")", color: UIColor.darkGray)
                    } else if selectableDie.count == 1 && vals[0] == 5 {
                        hud!.tl("One more ace for perfect! ("+String(sum)+")", color: UIColor.darkGray)
                    } else if selectableDie.count == 1 {
                        hud!.tl("One more ace? ("+String(sum)+")", color: UIColor.darkGray)
                    } else if vals[0] + selectableDie.count == 6 {
                        hud!.tl("Can you get all aces? ("+String(sum)+")", color: UIColor.darkGray)
                    } else if vals[0] < 3 {
                        hud!.tl("Need some aces ("+String(sum)+")", color: UIColor.darkGray)
                    } else if vals[0] < 5 {
                        hud!.tl("Still more aces? ("+String(sum)+")", color: UIColor.darkGray)
                    }
                } else { // 5 dice aces
                    if selectableDie.count == 1 && vals[0] == 0 {
                        hud!.tl("At least one ace? ("+String(sum)+")", color: UIColor.darkGray)
                    } else if selectableDie.count == 1 && vals[0] == 4 {
                        hud!.tl("One more ace for perfect! ("+String(sum)+")", color: UIColor.darkGray)
                    } else if selectableDie.count == 1 {
                        hud!.tl("One more ace? ("+String(sum)+")", color: UIColor.darkGray)
                    } else if vals[0] + selectableDie.count == 5 {
                        hud!.tl("Can you get all aces? ("+String(sum)+")", color: UIColor.darkGray)
                    } else if vals[0] < 2 {
                        hud!.tl("Need some aces ("+String(sum)+")", color: UIColor.darkGray)
                    } else if vals[0] < 4 {
                        hud!.tl("Still more aces? ("+String(sum)+")", color: UIColor.darkGray)
                    }
                }
                
            }
        } else if game == .midnight {
            hud!.toClear() // clear HUD
            selectableDie.removeAll()  // construct dice list that are still in play
            for die in world.dice {
                if !world.isHeld(die: die) { selectableDie.append(die) }
            }
            if selectableDie.count < 2 { // game done
                if vals[0] > 0 && vals[3] > 0 { // score!
                    hud!.message("Score: " + String(sum-5), color: UIColor.blue)
                } else {
                    hud!.message("No Score!", color: UIColor.red)
                }
                hud!.info("(next player)", color: UIColor.darkGray)
                hud!.tl("Need a 1 and 4 (do first throw)", color: UIColor.darkGray)
                world.unholdDie(die: nil)
                canThrow = true
            } else { // game still going
                canThrow = false
                var info = "Maximize score ("+String(sum-5)+")"
                if vals[0] < 1 && vals[3] < 1 {
                    info = "Still need a 1 and 4"
                } else if vals[0] < 1 {
                    info = "Still need a 1"
                } else if vals[3] < 1 {
                    info = "Still need a 4"
                }
                var kept = ""
                for i in [1, 4] {
                    if vals[i-1] > 0 {
                        var anyHeld = false
                        let dieWithVal = world.findVal(val: i)
                        for die in dieWithVal { anyHeld = anyHeld || world.isHeld(die: die) }
                        if !anyHeld {
                            world.holdDie(dieWithVal[0])
                            canThrow = true
                            if kept == "" { kept = " (Kept a \(i)"} else { kept += " and \(i)"}
                        }
                    }
                }
                if kept == "" { kept = " (Keep one or more dice, then" } else { kept += ", can" }
                hud!.tl(info + kept + " throw)", color: UIColor.darkGray)
            }
        } else if game == .pig {
            if gameDone {
                world.deleteUndo()
                world.newUndo()
                world.newUndo()
                point = 0
                numRolls = 0
                gameDone = false
            }
            numRolls += 1
            if sum == 1 {
                hud!.toClear()
                hud!.message("Collect " + String(0), color: UIColor.red)
                hud!.info("(next player)", color: UIColor.darkGray)
                gameDone = true
            } else {
                point += sum
                hud!.toClear()
                hud!.tl("Pay: " + String(point) + " (" + String(numRolls) + ")" , color: UIColor.darkGray)
                hud!.bl("Select to collect Pass", color: UIColor.darkGray)
            }
        } else if game == .horror {
            //hud!.br(String(sum) + " =  " + roll, color: UIColor.white)
            //resultLabel.isHidden = false
            
            hud!.result(getResultString(pre: NSMutableAttributedString(string: String(sum) + " =  "), type: .dice6))
            
            hud!.tr("Bane: " + String(vals[5]), color: UIColor.red)
            hud!.tc("Hit: " + String(vals[5] + vals[4]), color: UIColor.white)
            hud!.tl("Bless: " + String(vals[5] + vals[4] + vals[3]), color: UIColor.blue)
            
            if vals[5] + vals[4] > 0 {
                hud!.message("PASS!", color: UIColor.blue)
                if vals[5] < 1 {
                    hud!.info("(unless Bane)", color: UIColor.red)
                }
            } else {
                hud!.message("FAIL!", color: UIColor.red)
                if vals[3] > 0 {
                    hud!.info("(unless Blessed)", color: UIColor.blue)
                }
            }
        } else if game == .craps {
            //print("craps: \(numRolls) \(gameDone)")
            if gameDone {
                numRolls = 0
                world.deleteUndo()
                world.newUndo()
                world.newUndo()
                gameDone = false
            }
            numRolls += 1
            if numRolls == 1 && (sum == 7 || sum == 11 || sum == 2 || sum == 3 || sum == 12) {
                if sum == 7 || sum == 11 {
                    hud!.message("NATURAL!", color: UIColor.blue)
                } else {
                    hud!.message("CRAPS!", color: UIColor.red)
                }
                hud!.tl("Do come-out throw", color: UIColor.darkGray)
                world.deleteUndo()  // if first roll is end of round, no undo!
                gameDone = true
            } else if numRolls == 1 {
                point = sum
                hud!.tl("Point is " + String(point), color: UIColor.darkGray)
            } else if numRolls < 1 {
                hud!.tl("Do come-out throw", color: UIColor.darkGray)
            } else {
                if sum == 7 {
                    hud!.message("SEVEN-OUT!", color: UIColor.red)
                    hud!.info("(new shooter!)", color: UIColor.darkGray)
                    hud!.tl("Do come-out throw", color: UIColor.darkGray)
                    gameDone = true
                } else if sum == point {
                    hud!.message("WINNER!", color: UIColor.blue)
                    hud!.tl("Do come-out throw", color: UIColor.darkGray)
                    gameDone = true
                } else {
                    hud!.tl("Point is " + String(point), color: UIColor.darkGray)
                }
            }
        } else if game == .ship {
            numRolls += 1
            var roll = "second"; if numRolls == 2 { roll = "third" }
            var need = 6
            
            if vals[5] > 0 && vals[4] > 0 && vals[3] > 0 {  // got 6,5 and 4
                hud!.tl("Maximize value (do " + roll + " throw)", color: UIColor.darkGray)
                if vals[3] == 1 {need = 4}
                if vals[4] == 1 {need = 5}
                hud!.bl("Keep all to pass", color: UIColor.darkGray)
                need = 0
                gotSCC = true
                canThrowOne = true
                canSelect = true
                canHold = true
            } else if vals[5] > 0 && vals[4] > 0 { // got 6 and 5
                hud!.tl("Need a 4 (do " + roll + " throw)", color: UIColor.darkGray)
                need = 4
            } else if vals[5] > 0 { // got 6
                hud!.tl("Need a 5 (do " + roll + " throw)", color: UIColor.darkGray)
                need = 5
            } else { // still need a six
                hud!.tl("Need a 6 (do " + roll + " throw)", color: UIColor.darkGray)
                need = 6
            }
            var all = true
            for die in world.dice { all = (all && world.isHeld(die: die)) }
            if numRolls > 2 || all {
                hud!.toClear() // clear HUD
                if gotSCC { // score!
                    hud!.message("Score: " + String(sum-15), color: UIColor.blue)
                } else {
                    hud!.message("No Score!", color: UIColor.red)
                }
                hud!.info("(next player)", color: UIColor.darkGray)
                hud!.tl("Need a 6 (do first throw)", color: UIColor.darkGray)
                world.unselectDie(die: nil)
                numRolls = 0
                gotSCC = false
                canThrowOne = false
                canSelect = false
                canHold = false
                world.unholdDie(die: nil)
                world.unselectDie(die: nil)
                selectableDie.removeAll()
            } else { // still rolling
                if need == 0 { // hold any 6, 5, 4 first time they come up
                    for i in max(4,(need+1))...6 {
                        var anyHeld = false
                        let dieWithVal = world.findVal(val: i)
                        for die in dieWithVal { anyHeld = anyHeld || world.isHeld(die: die) }
                        if !anyHeld { world.holdDie(dieWithVal[0]) }
                    }
                }
                let dice = world.dice
                selectableDie.removeAll()
                for die in dice {
                    let val = die.value(up: simd_float3(0, 1, 0))
                    if val == 6 {
                        if vals[5] > 1 { if !world.isHeld(die: die) {world.selectDie(die); vals[5] -= 1; selectableDie.append(die)}}
                    } else if val == 5 {
                        if vals[4] > 1 || need > 5 { if !world.isHeld(die: die) {world.selectDie(die); vals[4] -= 1; selectableDie.append(die)}}
                    } else if val == 4 {
                        if vals[3] > 1 || need > 4 { if !world.isHeld(die: die) {world.selectDie(die); vals[3] -= 1; selectableDie.append(die)}}
                    } else {
                        if !world.isHeld(die: die) {world.selectDie(die); selectableDie.append(die)}
                    }
                }
            }
        }
    }
    
    func startGame() { // either first or user selected a new game
        
        hud!.toClear()
        world.deleteUndo()
        world.unselectDie(die: nil)
        world.unholdDie(die: nil)
        canSelect = true
        canThrowOne = true
        canAddRemove = true
        canHold = true
        canThrow = true
        point = 0
        numRolls = 0
        gameDone = false
        hud!.toClear()
        if game == .craps {
            setDiceNumber(diceSet: [.dice6:2])
            hud!.tl("Do come-out throw", color: UIColor.darkGray)
            hud!.bl("Casino craps, just keep throwing", color: UIColor.darkGray)
            gotSCC = false
            canSelect = false
            canThrowOne = false
            canAddRemove = false
            canHold = false
            gameDone = true
        } else if game == .ship {
            setDiceNumber(diceSet: [.dice6:5])
            hud!.tl("Need a 6 (do first throw)", color: UIColor.darkGray)
            hud!.bl("need 6/5/4 first", color: UIColor.darkGray)
            gotSCC = false
            canSelect = false
            canThrowOne = false
            canAddRemove = false
            canHold = false
            world.newUndo() // sure, why not
        } else if game == .pig {
            gameDone = true
            canSelect = false
            canAddRemove = false
            canHold = true
            setDiceNumber(diceSet: [.dice6:1])
            hud!.tl("Pay: " + String(point) + " (" + String(numRolls) + ")" , color: UIColor.darkGray)
            hud!.bl("Avoid throwing a 1!", color: UIColor.darkGray)
            canAddRemove = false
        } else if game == .midnight {
            setDiceNumber(diceSet: [.dice6:6])
            hud!.tl("Need 1 and 4 (do first throw)", color: UIColor.darkGray)
            hud!.bl("Need 1 and 4 to score", color: UIColor.darkGray)
            canSelect = false
            canThrowOne = false
            canAddRemove = false
            canHold = true
            world.newUndo() // sure, why not
        } else if game == .aces || game == .aces5 {
            if game == .aces { setDiceNumber(diceSet: [.dice6:6]) } else { setDiceNumber(diceSet: [.dice6:5]) }
            hud!.tl("Need some aces (do first throw)", color: UIColor.darkGray)
            hud!.bl("Lowest score wins", color: UIColor.darkGray)
            canSelect = false
            canThrowOne = false
            canAddRemove = false
            canHold = false
            world.newUndo() // sure, why not
        } else {
            hud!.tl("Tap/swipe Table to throw; long tap to toggle Menu", color: UIColor.darkGray)
            hud!.bl("Change Game, dice actions, ... in Settings", color: UIColor.darkGray)
        }
        //print("startGame: \(game)")
    }

    //init(size: CGSize) {
    init(size: CGRect) { // size is the rect that gives the 'safe area'
        self.size = size.size
        self.rect = size
        self.world = World(size: size)
        self.world.sound = soundOn
        _hud = HUD(size: size) // create HUD
        startGame() // set up HUD and set up game logic
        
        // after physical and/or animation movement, get a call back
        NotificationCenter.default.addObserver(self, selector: #selector(self.physicsDonePost), name: NSNotification.Name("physicsDone"), object: nil) // be told when physic simulation is done
    }
    
    required init(coder: NSCoder) {
        fatalError("Not yet implemented")
    }

}



