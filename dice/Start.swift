//
//  Start.swift
//  dice
//
//  Created by G.J. Parker on 20/6/3.
//  Copyright © 2020 G.J. Parker. All rights reserved.
//

import UIKit


class StartView : UIView, UIPickerViewDataSource, UIPickerViewDelegate, UIScrollViewDelegate  {
    // let's get what game we want at start
    
    let gamePicker = UIPickerView()
    
    let descriptionLabel = UILabel()
    let dismissButton = UIButton()
    let label2 = UILabel()
    
    var games: [String]
    //case aces5 = 0, midnight, craps, ship, pig, aces, horror, freeplay
    let descriptions1 = ["Welcome!\n\nDrop, throw and spin dice and coins by tapping, swiping and curved swiping the Table. \n\nUse the Menu (right side) to select type and number of dice you want on the Table. In Settings (bottom left) you can set dice actions, game, history, size, .... Help (bottom right) is your friend. \n\nChoose a game from the list to start...",
                        "Description:\n\nA player throws five dice. Any 1s (\"Aces\") are kept. If no 1s are thrown, then the lowest value die is kept. Player continues to throw the remaining dice until none are left. The player with the lowest sum wins. \n\nThis is a pure chance game so we automatically do all the keeping for you.",
                        "Description:\n\nA player starts by throwing six dice. They must keep at least one. Player continues to throw the remaining dice in the same procedure until none remain. \n\nTo score, player must have kept a 1 and a 4. If they score, the other dice are totaled (ranging from 4 to 24). The procedure is repeated for the remaining players. The player with the highest total wins. \n\nWe'll keep the first 1 and 4, though you can un-keep them. The rest is up to you.",
                        "Description:\n\nWe simply keep track of come-out and point throws. And remind you to pass the dice if you seven-out.",
                         "Description:\n\nA player has up to three throws. The first six (Ship) then five (captain) and then four (crew) are set aside when they are thrown. The sum of the remaining two dice is the result. The player with the highest (or lowest) score wins. If 6, 5 and 4 were not achieved after three throws, there is no score (bust). \n\nWe will select the dice that can be thrown so a simple tap/swipe is sufficient.",
                         "Description:\n\nA player repeatedly throws a die until either a 1 is thrown or the player decides to \"hold\". If the player throws a 1, they score nothing and it becomes the next player's turn. If the player throws any other number, it is added to their \"Pay\" total and the player's turn continues. If the player chooses to \"hold\", their \"Pay\" total is added to their score, and it becomes the next player's turn. \n\nWe'll keep track of the Pay for you.",
                         "Description:\n\nSame as \"Aces\" but with six dice.",
                         "Description:\n\nThis is a board game from Fantasy Flight Games that uses dice. We do the evaluation of throws for you. It was the motivating factor for Dice Pro Simulator.",
                         "Description:\n\nThis is your physical dice replacement. \n\nChoose this for any game not listed. "] // \n\nIn general, use this for physical dice replacement.",
    let descriptions = ["Drop, throw and spin dice and coins by tapping, swiping and curved swiping the Table. Faster swipes for more energetic throw. Circular swipes for just spin.\n\nUse the Menu (right side) to select type and number of dice you want on the Table. \n\nIn Settings (bottom left) you can set dice actions, game, history, size, .... \n\nHelp (bottom right) is your friend. \n\nChoose a game from the list...",
                        "Description:\n\nA player throws five dice. Any 1s (\"Aces\") are kept. If no 1s are thrown, then the lowest value die is kept. Player continues to throw the remaining dice until none are left. The player with the lowest sum wins. \n\nThis is a game of pure chance, so we automatically do all the keeping for you.",
                        "Description:\n\nSix dice are rolled; the player must \"keep\" at least one. Once kept, the dice cannot be rerolled. Any dice not kept are rerolled. This procedure is then repeated until there are no more dice to roll.  \n\nPlayers must have kept a 1 and a 4, or they do not score. If they have a 1 and 4, the other dice are totaled to give the player's score (from 4 to 24). The player with the highest score wins.\n\nWe'll keep the first 1 and 4, though you can un-keep them. The rest is up to you.",
                        "Description:\n\nWe keep track of come-out and point throws. And remind you to pass the dice if you seven-out.",
                        "Description:\n\nFive dice are rolled; the player is attempting to roll a 6 (ship), 5 (captain) and 4 (crew) in that order and are \"kept\" when rolled. Player has only three rolls. \n\nIf they have a crewed ship (6,5 and 4), the sum of the two remaining dice (cargo) is their score. If they do not have a crewed ship, they score nothing. Player with largest cargo wins.\n\nWe will keep the crewed ship and select the dice that can be thrown, but you have to optimize the cargo.",
                        "Description:\n\nEach turn, a player repeatedly rolls a die until either a 1 is rolled or the player decides to \"hold\": \n\t- If the player rolls a 1, they score nothing and it becomes the next player's turn.\n\t- If the player rolls any other number, it is added to their \"Pay\" and their turn continues.\n\t- If a player chooses to \"hold\", their Pay is added to their score, and their turn ends. \n\nThe first player to score 100 or more points wins.\n\nWe'll keep track of the Pay for you.",
                        "Description:\n\nSame as \"Aces\" but with six dice.",
                        "Description:\n\nThis is a board game from Fantasy Flight Games that uses dice. We do the evaluation of throws for you. It was the motivating factor for Dice Pro Simulator.",
                        "Description:\n\nThis is your physical dice replacement. \n\nChoose this for any game not listed. "]
    
    let maxDescSize : CGSize
    
    let color : [UIColor] = [.white, .green, .green, .green, .green, .green, .green, .red, .white]
    var welcome = NSMutableAttributedString()
    
    init(frame: CGRect, safe: CGRect, game: Game) {
        
        let dw = (safe.origin.x > 0) ? safe.origin.x : 50
        let dh = safe.height / 3 //4
        let w = safe.width - dw*2
        self.games = game.gameNames()
        self.games.insert("Choose a game...", at: 0)
        self.maxDescSize = CGSize(width: w, height: 2000)
        
        super.init(frame: frame)
        self.backgroundColor = UIColor.black.withAlphaComponent(0.65) //8)
        
        welcome.append(NSAttributedString(string: "Drop, throw and spin dice and coins by tapping, swiping and curved swiping the Table. Faster swipes for more energetic throw. Circular swipes for just spin.\n\nUse "))
        let imagea = NSTextAttachment()
        imagea.image = smallIcon[.dice6]
        imagea.bounds = CGRect(x: 0, y: -3, width: 15, height: 15)
        welcome.append(NSAttributedString(attachment: imagea))
        welcome.append(NSAttributedString(string: ", "))
        let imageb = NSTextAttachment()
        imageb.image = smallIcon[.dice2]
        imageb.bounds = CGRect(x: 0, y: -3, width: 15, height: 15)
        welcome.append(NSAttributedString(attachment: imageb))
        welcome.append(NSAttributedString(string: ", ... (right side) to select type and number of dice you want on the Table. \n\n"))
        let image1 = NSTextAttachment()
        image1.image = UIImage(named: "gear")
        image1.bounds = CGRect(x: 0, y: -3, width: 15, height: 15)
        welcome.append(NSAttributedString(attachment: image1))
        welcome.append(NSAttributedString(string: " (bottom left) sets dice actions, game, history, size, .... \n\n"))
        let image2 = NSTextAttachment()
        image2.image = UIImage(named: "help")
        image2.bounds = CGRect(x: 0, y: -3, width: 15, height: 15)
        welcome.append(NSAttributedString(attachment: image2))
        welcome.append(NSAttributedString(string: " (bottom right) is your friend. \n\nChoose a game from the list to start..."))
        
        gamePicker.frame =    CGRect(x: dw, y: safe.origin.y+20, width: w, height: dh)
        gamePicker.backgroundColor = .clear
        gamePicker.delegate=self
        gamePicker.dataSource = self
        //gamePicker.selectRow(Games.freeplay.rawValue, inComponent: 0, animated: true) // freeplay!
        gamePicker.selectRow(0, inComponent: 0, animated: true) // freeplay!
        
        descriptionLabel.frame = CGRect(x: dw, y: safe.origin.y + 20 + dh, width: w, height: 2000) //safe.height-dh-15-20 - 40)
        descriptionLabel.text =  descriptions[0]
        descriptionLabel.textColor = #colorLiteral(red: 0.5, green: 0.5, blue: 0.5, alpha: 1) //.white
        descriptionLabel.font = UIFont(name: "Arial", size: 12)
        descriptionLabel.backgroundColor = .clear
        descriptionLabel.numberOfLines = 0
        descriptionLabel.lineBreakMode = .byWordWrapping
        self.addSubview(descriptionLabel)
        descriptionLabel.sizeToFit()
        
        var maxh = frame.height
        var font = CGFloat(18)
        while maxh > safe.height-dh-20 - 40 {
            font -= 1; maxh = 0
            descriptionLabel.font = UIFont(name: "Arial", size: font)
            descriptionLabel.attributedText = welcome
            for desc in descriptions {
                descriptionLabel.text = desc
                descriptionLabel.frame.size = maxDescSize
                descriptionLabel.sizeToFit()
                maxh = (descriptionLabel.frame.height > maxh) ? descriptionLabel.frame.height : maxh
                descriptionLabel.attributedText = nil
            }
        }
        descriptionLabel.text = descriptions[0]
        descriptionLabel.attributedText = welcome
        descriptionLabel.frame.size = maxDescSize
        descriptionLabel.sizeToFit()
        
        label2.frame = CGRect(x: dw, y: safe.origin.y + safe.height - 40, width: w, height: 20)
        label2.text = "Tap to play!"; label2.font = UIFont(name: "Arial", size: 20); label2.textColor = .red; label2.textAlignment = .center
        self.addSubview(label2)
        label2.isEnabled = false
        label2.isHidden = true
        
        dismissButton.frame = frame
        dismissButton.backgroundColor = .clear
        dismissButton.setTitle("", for: .normal)
        dismissButton.addTarget(self.superview, action: #selector(GameViewController.donePressed), for: .touchUpInside)
        self.addSubview(dismissButton)
        dismissButton.isEnabled = false
        dismissButton.isHidden = true
        
        self.addSubview(gamePicker)

    }
    
    func game() -> Games { // game changed
        return Games(rawValue: gamePicker.selectedRow(inComponent: 0)-1)!
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
            return 1
    }
    
     func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return games.count
    }
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return games[row]
    }
    
    
    func pickerView(_ pickerView: UIPickerView, attributedTitleForRow row: Int, forComponent component: Int) -> NSAttributedString? {
        return NSAttributedString(string: games[row],    attributes: [.foregroundColor: color[row % color.count], .font: UIFont(name: "Arial", size: 48)!])
        
        //let color : UIColor = (Games(rawValue: row) == .horror) ? .red : .green
        //return NSAttributedString(string: games[row],    attributes: [.foregroundColor: color, .font: UIFont(name: "Arial", size: 48)!])
        //return NSAttributedString(string: games[row],    attributes: [.foregroundColor: UIColor.white, .font: UIFont(name: "Arial", size: 48)!])//18)!])
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        descriptionLabel.attributedText = nil
        if row == 0 { descriptionLabel.attributedText = welcome } else { descriptionLabel.text = descriptions[row] }
        descriptionLabel.frame.size = maxDescSize
        descriptionLabel.sizeToFit()
        let truth = (row > 0)
        dismissButton.isEnabled = truth
        dismissButton.isHidden = !truth
        label2.isEnabled = truth
        label2.isHidden = !truth
    }
    
    required init(coder: NSCoder) {
        fatalError("Not yet implemented")
    }

}
