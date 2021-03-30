//
//  HelpView.swift
//  dice
//
//  Created by G.J. Parker on 19/9/21.
//  Copyright © 2019 G.J. Parker. All rights reserved.
//

import UIKit


class DiceNumberView: UIView {
    // get how many dice
    
    var numberButtons  = 0
    var buttonArray = [UIButton]()
    
    init(frame: CGRect, safe: CGRect, image: UIImage, add: Bool) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.black.withAlphaComponent(0.8) //0.9)
        
        let row = CGFloat(Double(safe.height-44*2)/(ceil(Double(safe.height-44*2)/90)))
        let col = CGFloat(Double(safe.width-50)/ceil(Double(safe.width-50)/150))
        
        let numberRows = CGFloat(round((safe.height-44*2) / row))
        let numberColumns = CGFloat(round((safe.width - 50) / col))
        numberButtons = Int(numberRows * numberColumns)
        
        let cRoll = NSMutableAttributedString(string: "Choose number of ")
        let image1 = NSTextAttachment()
        image1.image = image
        image1.bounds = CGRect(x:0, y: -3, width: 40, height:40)
        cRoll.append(NSAttributedString(attachment: image1))
        if add { cRoll.append(NSAttributedString(string: " to add"))}
        cRoll.append(NSAttributedString(string: ":"))
        
        let dummyLabel = UILabel(frame: CGRect(x: safe.origin.x, y: safe.origin.y, width: safe.width, height: 40))
        dummyLabel.attributedText = cRoll
        dummyLabel.font = UIFont(name: "Arial", size: 28)
        dummyLabel.textColor = .white
        dummyLabel.textAlignment = .center
        self.addSubview(dummyLabel)
        
        let dummy1Button = UIButton(frame: CGRect(x: 0, y: 0, width: frame.width, height: frame.height)) // make giant button to simply dismiss view
        dummy1Button.backgroundColor = .clear
        dummy1Button.setTitle("", for: .normal)
        dummy1Button.addTarget(self.superview, action: #selector(GameViewController.donePressed), for: .touchUpInside)
        self.addSubview(dummy1Button)
        
        for i in 0...numberButtons+1 {
            let x = safe.origin.x + safe.width - 50
            let y = safe.origin.y + 44
            //let button1 = UIButton(frame: CGRect(x: safe.origin.x + safe.width - 50 - CGFloat(col * (1+Int((i-1)/numberRows))), y: safe.origin.y + 24 + CGFloat(((i-1) % numberRows + 0) * row), width: CGFloat(col-4), height: CGFloat(row-4)))
            let button = UIButton(frame: CGRect(x: x - col * (1 + CGFloat((i-1)/Int(numberRows))), y: y + CGFloat((i-1) % Int(numberRows))*row, width: col-4, height: row-4))

            button.backgroundColor = .clear
            button.backgroundColor = #colorLiteral(red: 0.5, green: 0.5, blue: 0.5, alpha: 1)
            button.alpha = 0.3
            //button.backgroundColor = .blue
            button.setTitle(String(i), for: .normal)
            button.setTitleColor(.white, for: .normal)
            button.setTitleColor(.red, for: .selected)
            button.titleLabel?.font = UIFont(name: "Arial", size: 30)
            self.addSubview(button)
            buttonArray.append(button)
            if i == 0 {
                buttonArray[0].setTitle("-", for: .normal)
                buttonArray[0].addTarget(self, action: #selector(self.numberPressed), for: .touchUpInside)
                buttonArray[0].isEnabled = false
                buttonArray[0].isHidden = true
                buttonArray[0].frame = CGRect(x: x - col, y: safe.origin.y, width: col-4, height: CGFloat(40) )
            } else if i > numberButtons {
                buttonArray.last!.setTitle("+", for: .normal)
                buttonArray.last!.addTarget(self, action: #selector(self.numberPressed), for: .touchUpInside)
                buttonArray.last!.isEnabled = (numberButtons < 100)
                buttonArray.last!.isHidden = (numberButtons >= 100)
                buttonArray.last!.frame = CGRect(x: x - col * numberColumns, y: y + numberRows * row, width: col-4, height: CGFloat(40))
            } else {
                button.addTarget(self.superview, action: #selector(GameViewController.numberDiePressed), for: .touchUpInside)
            }
        }
        
    }
    
    @objc func numberPressed(sender: UIButton!){
        if sender.currentTitle == "-" {
            let i = (Int(buttonArray[1].currentTitle!) ?? 1) - numberButtons - 1
            for j in 1..<(buttonArray.count - 1) { buttonArray[j].setTitle(String(i+j), for: .normal) }
            sender.isEnabled = (i != 0)
            sender.isHidden = (i == 0 )
            buttonArray.last?.isEnabled = true
            buttonArray.last?.isHidden = false
        } else if sender.currentTitle == "+" && (Int(buttonArray[buttonArray.count-2].currentTitle!) ?? 1) < 100 {
            let i = Int(buttonArray[buttonArray.count-2].currentTitle!) ?? 1
            for j in 1..<(buttonArray.count-1) { buttonArray[j].setTitle(String(i+j), for: .normal) }
            buttonArray[0].isEnabled = true
            buttonArray[0].isHidden = false
            buttonArray.last!.isEnabled = (i+buttonArray.count-2 < 100)
            buttonArray.last!.isHidden = (i+buttonArray.count-2 >= 100)
        }
    }
    
    required init(coder: NSCoder) {
        fatalError("Not yet implemented")
    }
    
}
