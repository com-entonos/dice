//
//  SettingView.swift
//  dice
//
//  Created by G.J. Parker on 19/9/23.
//  Copyright © 2019 G.J. Parker. All rights reserved.
//

import UIKit

class HelpView : UIView {
    // show content dependent Help
    
    init(frame: CGRect, safe: CGRect, game: Game) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.black.withAlphaComponent(0.5) //0.9)
        
        // make giant button to simply dismiss view
        let dummy1Button = UIButton(frame: CGRect(x: 0, y: 0, width: frame.width, height: frame.height))
        dummy1Button.backgroundColor = .clear
        dummy1Button.setTitle("", for: .normal)
        dummy1Button.addTarget(self.superview, action: #selector(GameViewController.donePressed), for: .touchUpInside)
        self.addSubview(dummy1Button)
        
        // help for Settings
        let setting = UILabel(frame: CGRect(x: safe.origin.x + 34, y: safe.origin.y + safe.height - 34, width: 300, height: 20))
        setting.text = "Choose game, dice actions, etc..."
        setting.textAlignment = .left
        setting.textColor = .white
        setting.font = UIFont(name: "Arial", size: 18)
        self.addSubview(setting)
        
        // help for Settings
        if game.history != nil {
            let setting = UILabel(frame: CGRect(x: safe.origin.x + 34, y: safe.origin.y + safe.height - 70, width: 300, height: 20))
            setting.text = "History of results"
            setting.textAlignment = .left
            setting.textColor = .white
            setting.font = UIFont(name: "Arial", size: 18)
            self.addSubview(setting)
        }

        
        // more help?
        let helpButton = UIButton(type: .system)
        helpButton.frame = CGRect(x: safe.origin.x+safe.width - 34 - 130, y: safe.origin.y + safe.height - 40, width: 130 ,height: 30)
        helpButton.setAttributedTitle(NSAttributedString(string: "Detailed Help", attributes: [.foregroundColor: UIColor.blue, .font: UIFont(name: "Arial", size: 18)!]), for: .normal)
        helpButton.addTarget(self.superview, action: #selector(GameViewController.showHelpDetail), for: .touchUpInside)
        self.addSubview(helpButton)

        // dice actions
        let x0 = (safe.width/2 - 200)/2 + safe.origin.x
        let y0 = (safe.height - 130)/2 + safe.origin.y
        let dice1 = UILabel(frame: CGRect(x: x0+10, y: y0, width: 150, height: 20))
        dice1.textColor = .white
        dice1.textAlignment = .left
        dice1.font = UIFont(name: "Arial", size: 24)
        dice1.text = "Dice Actions:"
        self.addSubview(dice1)
        
        //let tapOpt = ["Ignore", "Throw", "Keep", "Select", "Remove", "Add"] //ignore = 0, roll, hold, select, remove
        //oldTap[0] for single tap, [1] for double tap, [2] for triple tap, [3] for long tap, [4] for pinch
        //case  ignore = 0, roll, hold, select, remove, duplicate
        let acts = [ TapOptions.duplicate: "add", .roll: "throw", .remove: "remove", .select: "select", .hold: "keep"]
        let taps = ["tap", "double tap", "triple tap", "long tap", "pinch"]
        let oldTap = game.throwOption
        var y = y0 + 20
        for i in 0..<oldTap.count {
            let tap = oldTap[i]
            if tap != .ignore {
                let dice = UILabel(frame: CGRect(x: x0, y: y, width: 200, height: 20))
                dice.textColor = .white
                dice.textAlignment = .left
                dice.text = taps[i] + " to " + acts[tap]!
                dice.font = UIFont(name: "Arial", size: 18)
                self.addSubview(dice)
                y += 20
            }
        }
        if y == y0 + 20 {
            let dice = UILabel(frame: CGRect(x: x0, y: y, width: 200, height: 20))
            dice.textColor = .white
            dice.textAlignment = .left
            dice.text = "no dice actions"
            dice.font = UIFont(name: "Arial", size: 18)
            self.addSubview(dice)
        }
        
        let game = game.game_

        // table actions
        let y11 = CGFloat((game == .freeplay) ? 200 : ((game == .horror) ? 160 : 140))
        let x1 = safe.origin.x + safe.width/2 + (safe.width/2 - 200)/2
        let y1 = (safe.height - y11)/2 + safe.origin.y
        let table0 = UILabel(frame: CGRect(x: x1+10, y: y1, width: 150, height: 20))
        table0.textColor = .white
        table0.textAlignment = .left
        table0.font = UIFont(name: "Arial", size: 24)
        table0.text = "Table Actions:"
        self.addSubview(table0)
        
        var tacts = ["tap to drop dice", "swipe to throw dice", "double tap to add", "long tap to toggle menu"]
        y = y1+20
        if game == .horror {
            tacts = ["tap to drop dice", "swipe to throw dice", "double tap to add"]
        } else if game != .freeplay {
            tacts = ["tap to drop dice", "swipe to throw dice"]
        }
        tacts.append("pinch to zoom")
        for i in 0..<tacts.count {
            let dice = UILabel(frame: CGRect(x: x1, y: y, width: 200, height: 20))
            dice.textColor = .white
            dice.textAlignment = .left
            dice.text = tacts[i]
            dice.font = UIFont(name: "Arial", size: 18)
            self.addSubview(dice)
            y += 20
        }
        
        // menu actions or current game
        if game == .freeplay {
            y += 20
            let table1 = UILabel(frame: CGRect(x: x1+10, y: y, width: 200, height: 20))
            table1.textColor = .white
            table1.textAlignment = .left
            table1.font = UIFont(name: "Arial", size: 24)
            table1.text = "Menu Actions:"
            self.addSubview(table1)
            
            let menues = ["tap to replace", "long tap to add"]
            y += 20
            for i in 0..<menues.count {
                let dice = UILabel(frame: CGRect(x: x1, y: y, width: 200, height: 20))
                dice.textColor = .white
                dice.textAlignment = .left
                dice.text = menues[i]
                dice.font = UIFont(name: "Arial", size: 18)
                self.addSubview(dice)
                y += 20
            }
        } else {
            y += 20
            let table1 = UILabel(frame: CGRect(x: x1+10, y: y, width: 200, height: 20))
            table1.textColor = .white
            table1.textAlignment = .left
            table1.font = UIFont(name: "Arial", size: 24)
            table1.text = "Current Game:"
            self.addSubview(table1)
            let games = [ Games.freeplay: "Free play", .midnight: "Midnight", .pig: "Pig", .ship: "Ship/Caption/Crew", .craps: "Casino Craps", .aces5: "Aces", .aces: "Aces (6)", .horror: "Eldritch Horror"]
            
            y += 20
            let dice = UILabel(frame: CGRect(x: x1, y: y, width: 200, height: 20))
            dice.textColor = .white
            dice.textAlignment = .left
            dice.text = games[game]
            dice.font = UIFont(name: "Arial", size: 18)
            self.addSubview(dice)
        }
    }
    
    required init(coder: NSCoder) {
        fatalError("Not yet implemented")
    }
    
}
