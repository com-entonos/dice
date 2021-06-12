//
//  SettingView.swift
//  dice
//
//  Created by G.J. Parker on 19/9/23.
//  Copyright © 2019 G.J. Parker. All rights reserved.
//

import UIKit

class SettingView : UIView, UIPickerViewDataSource, UIPickerViewDelegate, UIScrollViewDelegate {
    
    //view to set options in settings
    
    let gamePicker = UIPickerView()
    let tapPicker = UIPickerView()
    let scrollView = UIScrollView()
    let settingView = UIView()
    
    let pulseSwitch = UISwitch()
    let historySwitch = UISwitch()
    let diceSegment = UISegmentedControl()
    let undoSegment = UISegmentedControl()
    let energySegment = UISegmentedControl()
    let launchSegment = UISegmentedControl()
    
    let games : [String]
    let tapOpt = ["Ignore", "Throw", "Keep", "Select", "Remove", "Add"] //ignore = 0, roll, hold, select, remove
    var oldTap = [TapOptions]()
    let undoOpt = ["Off", "1", "10", "100", "∞"]
    let dieOpt = ["Tiny", "Small", "Normal", "Large", "Huge"]
    let pulseOpt = ["On", "Off"]
    let energyOpt = ["Casual", "Nominal", "Excited"]
    let launchOpt = ["Gather", "Scatter"]
    var defaultTap = [[TapOptions]]()
    
    init(frame: CGRect, safe: CGRect, game: Game) {
        self.games = game.gameNames()
        super.init(frame: frame)
        self.backgroundColor = #colorLiteral(red: 0.7843137255, green: 0.7843137255, blue: 0.7843137255, alpha: 1) //#colorLiteral(red: 0.8313021064, green: 0.8314192891, blue: 0.8312650919, alpha: 1) #colorLiteral(red: 0.9254121184, green: 0.9255419374, blue: 0.9253712296, alpha: 1) #colorLiteral(red: 0.9488393664, green: 0.9491292834, blue: 0.9530405402, alpha: 1)
        
        let tapWidth =  (safe.width-110 < 540) ? safe.width-110 : CGFloat(540)
        
        let dw = max(0, (safe.width - tapWidth)/2 - 110)
//print(tapWidth,dw,safe)
        //if safe.origin.x == 0 { dw = max(0, (safe.width - 100 - tapWidth)/2 - 110) }
        
        gamePicker.frame =    CGRect(x: dw+110 + (tapWidth-250)/2, y: 0, width: 250, height: 150)
        tapPicker.frame =     CGRect(x: dw+110,                    y: 165, width: tapWidth, height: 150)
        diceSegment.frame =   CGRect(x: dw+110 + (tapWidth-400)/2, y: 330, width: 400, height: 35)
        energySegment.frame = CGRect(x: dw+110 + (tapWidth-300)/2, y: 380, width: 300, height: 35)
        pulseSwitch.frame =   CGRect(x: dw+110 + (tapWidth-70)/2,  y: 430, width: 70, height: 35)
        undoSegment.frame =   CGRect(x: dw+110 + (tapWidth-300)/2, y: 480, width: 300, height: 35)
        historySwitch.frame = CGRect(x: dw+110 + (tapWidth-70)/2,  y: 530, width: 70, height: 35)
        launchSegment.frame = CGRect(x: dw+100 + (tapWidth-200)/2, y: 580, width: 200, height: 35)
        
        let label1 = UILabel(frame: CGRect(x: dw+0, y: 0, width: 100, height: 150)); label1.text = "Game:";         label1.font = .systemFont(ofSize: 18); label1.textAlignment = .right
        let label4 = UILabel(frame: CGRect(x: dw+100, y: 125, width: tapWidth, height: 100)); label4.text = "single tap          double tap           triple tap            long tap               pinch"//; label4.textColor = .black;
        label4.font = .systemFont(ofSize: 15); label4.textAlignment = .center
        let label3 = UILabel(frame: CGRect(x: dw+0, y: 165, width: 100, height: 150)); label3.text = "Die action:"; label3.font = .systemFont(ofSize: 18); label3.textAlignment = .right
        let label2 = UILabel(frame: CGRect(x: dw+0, y: 330, width: 100, height: 35)); label2.text = "Dice size:";  label2.font = .systemFont(ofSize: 18); label2.textAlignment = .right
        let label7 = UILabel(frame: CGRect(x: dw+0, y: 380, width: 100, height: 35)); label7.text = "Throw:";      label7.font = .systemFont(ofSize: 18); label7.textAlignment = .right
        let label6 = UILabel(frame: CGRect(x: dw+0, y: 430, width: 100, height: 35)); label6.text = "Pulse dice:"; label6.font = .systemFont(ofSize: 18); label6.textAlignment = .right
        let label5 = UILabel(frame: CGRect(x: dw+0, y: 480, width: 150, height: 35)); label5.text = "Number of undo:"; label5.font = .systemFont(ofSize: 18)
        let label8 = UILabel(frame: CGRect(x: dw+0, y: 530, width: 100, height: 35)); label8.text = "History:"; label8.font = .systemFont(ofSize: 18); label8.textAlignment = .right
        let label9 = UILabel(frame: CGRect(x: dw+0, y: 580, width: 100, height: 35)); label9.text = "Launch:"; label9.font = .systemFont(ofSize: 18); label9.textAlignment = .right
        
        let doneButton = UIButton(type: .system) //UIButton()
        let donateButton = UIButton(type: .system) //UIButton()
        if safe.origin.x == 0 {
            doneButton.frame = CGRect(x: safe.width - 160, y: safe.height-50, width: 110, height: 40)
            donateButton.frame = CGRect(x: 40, y: safe.height-50, width: 200, height: 40)
        } else {
            doneButton.frame = CGRect(x: safe.origin.x + safe.width - 160, y: safe.origin.y + safe.height-50, width: 160, height: 40)
            donateButton.frame = CGRect(x: safe.origin.x, y: safe.origin.y + safe.height-50, width: 200, height: 40)
        }

        scrollView.contentSize = CGSize(width: safe.width, height: 625)
        settingView.frame = CGRect(x: 0, y: 0, width: safe.width, height: 600)
        scrollView.frame = CGRect(x: safe.origin.x, y: 0, width: safe.width, height: safe.height-60)
        settingView.translatesAutoresizingMaskIntoConstraints = false
        settingView.backgroundColor = UIColor.clear

        gamePicker.delegate=self
        gamePicker.dataSource = self
        
        tapPicker.delegate = self
        tapPicker.dataSource = self
        
        gamePicker.selectRow(game.game_.rawValue, inComponent: 0, animated: true)
        
        let dieSize = game.world_.numDiePerSide
        //print("dieSize: \(dieSize) \(dicePicker.selectedRow(inComponent: 0))")
        for i in 0..<dieOpt.count {
            //diceSegment.setTitle(dieOpt[i], forSegmentAt: i)
            diceSegment.insertSegment(withTitle: dieOpt[i], at: i, animated: true)
        }
        if dieSize == 5.2 {
            diceSegment.selectedSegmentIndex = 4
        } else if dieSize == 7.5 {
            diceSegment.selectedSegmentIndex = 3
        } else if dieSize == 10 {
            diceSegment.selectedSegmentIndex = 2
        } else if dieSize == 20 {
            diceSegment.selectedSegmentIndex = 1
        } else if dieSize == 30 {
            diceSegment.selectedSegmentIndex = 0
        } else {
            diceSegment.selectedSegmentIndex = -1 //2
        }
        
        for i in 0..<launchOpt.count {
            launchSegment.insertSegment(withTitle: launchOpt[i], at: i, animated: true)
        }
        launchSegment.selectedSegmentIndex = (game.world_.launchType == .gather) ? 0 : 1
        
        for eachGame in Games.allCases {
            self.defaultTap.append(game.defaultTap(game: eachGame))
        }
        oldTap = game.throwOption  //["Ignore", "Throw", "Hold", "Select", "Remove"] //ignore = 0, roll, hold, select, remove
        tapPicker.selectRow(oldTap[0].rawValue, inComponent: 0, animated: true)
        tapPicker.selectRow(oldTap[1].rawValue, inComponent: 1, animated: true)
        tapPicker.selectRow(oldTap[2].rawValue, inComponent: 2, animated: true)
        tapPicker.selectRow(oldTap[3].rawValue, inComponent: 3, animated: true)
        tapPicker.selectRow(oldTap[4].rawValue, inComponent: 4, animated: true)
        
        let numUndo = game.world_.numUndo //["Off", "1", "10", "100", "∞"]
        //print("undo: \(numUndo) \(undoPicker.selectedRow(inComponent: 0))")
        for i in 0..<undoOpt.count {
            undoSegment.insertSegment(withTitle: undoOpt[i], at: i, animated: true)
        }
        if numUndo == 0 {
            undoSegment.selectedSegmentIndex = 0
        } else if numUndo == 100 {
            undoSegment.selectedSegmentIndex = 3
        } else if numUndo == 10 {
            undoSegment.selectedSegmentIndex = 2
        } else if numUndo == 1 {
            undoSegment.selectedSegmentIndex = 1
        } else {
            undoSegment.selectedSegmentIndex = 4
        }
        
        let pulse = game.world_.pulsing //pulseOpt = ["On", "Off"]
        pulseSwitch.setOn(pulse, animated: true)
        
        historySwitch.setOn(game.history != nil, animated: true)
        
        let energy = game.energyThrow_ //pulseOpt = ["On", "Off"]
        for i in 0..<energyOpt.count {
            energySegment.insertSegment(withTitle: energyOpt[i], at: i, animated: true)
        }
        if energy < 1 {
            energySegment.selectedSegmentIndex = 0
        } else if energy > 1 {
            energySegment.selectedSegmentIndex = 2
        } else {
            energySegment.selectedSegmentIndex = 1
        }
        
        doneButton.backgroundColor = UIColor.clear
        doneButton.setTitle("Let's Play!", for: .normal)
        doneButton.titleLabel?.font = UIFont(name: "Arial", size: 18)
        doneButton.titleLabel?.textAlignment = .right
        doneButton.addTarget(self.superview, action: #selector(GameViewController.donePressed), for: .touchUpInside)
        
        donateButton.backgroundColor = UIColor.clear
        //donateButton.setTitle("Donate", for: .normal)
        //donateButton.setTitleColor(.red, for: .normal)
        donateButton.setTitle("Say \"hi\" to Entonos!", for: .normal)
        donateButton.titleLabel?.textAlignment = .left
        donateButton.titleLabel?.font = UIFont(name: "Arial", size: 18)
        donateButton.addTarget(self, action: #selector(self.donate), for: .touchUpInside)
        
        settingView.addSubview(gamePicker)
        settingView.addSubview(diceSegment)
        settingView.addSubview(tapPicker)
        settingView.addSubview(undoSegment)
        settingView.addSubview(pulseSwitch)
        settingView.addSubview(energySegment)
        settingView.addSubview(historySwitch)
        settingView.addSubview(launchSegment)
        settingView.addSubview(label5)
        settingView.addSubview(label1)
        settingView.addSubview(label2)
        settingView.addSubview(label4)
        settingView.addSubview(label3)
        settingView.addSubview(label6)
        settingView.addSubview(label7)
        settingView.addSubview(label8)
        settingView.addSubview(label9)
        scrollView.addSubview(settingView)
        self.addSubview(doneButton)
        self.addSubview(donateButton)
        self.addSubview(scrollView)
    }
    
    @objc func donate(sender: UIButton!){
        //UIApplication.shared.open(URL(string: "http://entonos.com/d")!)
        UIApplication.shared.open(URL(string: "https://entonos.com/index.php/the-geek-shop/")!)
    }

    func game() -> Games { // game changed
        return Games(rawValue: gamePicker.selectedRow(inComponent: 0))!
    }
    
    func pulsing() -> Bool { //pulseOpt = ["On", "Off"]
        //return pulsePicker.selectedRow(inComponent: 0) == 0
        return pulseSwitch.isOn
    }
    func history() -> Bool {
        return historySwitch.isOn
    }
    func launch() -> LaunchType {
        return (launchSegment.selectedSegmentIndex == 0) ? .gather : .scatter
    }
    
    func numDiePerSide() -> Float? { // table size changed
        switch diceSegment.selectedSegmentIndex {
        case 0:
            return Float(30)
        case 1:
            return Float(20)
        case 2:
            return Float(10)
        case 3:
            return Float(7.5)
        case 4:
            return Float(5.2) // minimum so that dice in hexagon pattern can fit: i.e. > 3 * sqrt(3) * die.size
        default:
            return nil //Float(10)
        }
    }
    
    func throwOption()  -> [TapOptions] { // tapping die options changed
        return oldTap
    }
    
    func energy() -> Float {
        switch energySegment.selectedSegmentIndex {
        case 0:
            return Float(0.5)
        case 1:
            return Float(1)
        case 2:
            return Float(1.5)
        default:
            return Float(1)
        }
    }
    
    func numUndo() -> Int { // changed number of undo
        let num = undoSegment.selectedSegmentIndex  //undoOpt = ["Off", "1", "10", "100", "∞"] : 0, 1, 10, 100, -1
        if num == 0 {
            return 0
        } else if num == 1 {
            return 1
        } else if num == 2 {
            return 10
        } else if num == 3 {
            return 100
        } else {
            return -1
        }
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        if pickerView == tapPicker {
            return 5
        } else {
            return 1
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if pickerView == gamePicker {
            return games.count
        } else {
            return tapOpt.count
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, attributedTitleForRow row: Int, forComponent component: Int) -> NSAttributedString? {
        switch pickerView {
        case gamePicker:
            return NSAttributedString(string: games[row],    attributes: [.foregroundColor: UIColor.black, .font: UIFont(name: "Arial", size: 18)!])
        case tapPicker:
            return NSAttributedString(string: tapOpt[row],   attributes: [.foregroundColor: UIColor.black, .font: UIFont(name: "Arial", size: 18)!])
        default:
            return NSAttributedString(string: "INTERNAL ERROR", attributes: [.foregroundColor: UIColor.black, .font: UIFont(name: "Arial", size: 18)!])
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if pickerView == gamePicker {
            //print(games[row])
            /*switch row { //games = ["Free Play"0, "Midnight"1, "Pig"2, "Ship/Captain/Crew (654)"3, "Casino Craps"4, "Aces (5)"5, "Aces (6)"6, "Eldritch Horror (TM)7"]
                // oldTap[0] for single tap, [1] for double tap, [2] for triple tap, [3] for long tap
            case 0:
                oldTap = [.select, .duplicate, .roll, .hold, .remove]
            case 1,2:
                oldTap = [.hold, .ignore, .ignore, .ignore, .ignore]
            case 3:
                oldTap = [.hold, .select, .ignore, .roll, .ignore]
            case 4,5,6:
                oldTap = [.ignore, .ignore, .ignore, .ignore, .ignore]
            case 7:
                oldTap = [.roll, .remove, .ignore, .select, .remove]
            default:
                oldTap = [.roll, .remove, .select, .hold]
            } */
            oldTap = defaultTap[row]
            for i in 0..<oldTap.count {
                tapPicker.selectRow(oldTap[i].rawValue, inComponent: i, animated: true)
            }
        } else if pickerView == tapPicker {
            let actOpt = [ tapPicker.selectedRow(inComponent: 0), tapPicker.selectedRow(inComponent: 1), tapPicker.selectedRow(inComponent: 2), tapPicker.selectedRow(inComponent: 3), tapPicker.selectedRow(inComponent: 4)]
            if TapOptions(rawValue: row)! != .ignore {
                for i in 0..<oldTap.count {
                    if i != component && actOpt[i] == row {oldTap[i] = oldTap[component]}
                }
            }
            oldTap[component] = TapOptions(rawValue: row)!
            for i in 0..<oldTap.count {
                tapPicker.selectRow(oldTap[i].rawValue, inComponent: i, animated: true)
            }
        }
    }
    
    required init(coder: NSCoder) {
        fatalError("Not yet implemented")
    }
    
}
