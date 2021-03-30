//
//  HUD.swift
//  dice
//
//  Created by G.J. Parker on 19/9/11.
//  Copyright © 2019 G.J. Parker. All rights reserved.
//

import SpriteKit

enum HudState {
    case empty, rolled
}

class HUD {
    private var _scene: SKScene!

    private var topleft = SKLabelNode(text: "")
    private var topcenter = SKLabelNode(text: "")
    private var topright = SKLabelNode(text: "")
    private var bottomleft = SKLabelNode(text: "")
    private var bottomcenter = SKLabelNode(text: "")
    private var bottomright = SKLabelNode(attributedText: NSAttributedString(string: ""))
    private var message = SKLabelNode(text: "")
    private var info = SKLabelNode(text: "")
    
    private var resultLabel = UILabel()
    
    
    private var hudState = HudState.empty

    var scene: SKScene {
        get { return _scene }
    }
    
    var result: UILabel {
        get { return resultLabel }
    }


    func toRoll() {
        toClear()
        topleft.text = "Rolling..."
        topleft.fontColor = UIColor.darkGray
        topleft.isHidden = false
    }
    func toClear() {
        topleft.isHidden = true
        topcenter.isHidden = true
        topright.isHidden = true
        bottomleft.isHidden = true
        bottomcenter.isHidden = true
        bottomright.isHidden = true
        message.isHidden = true
        info.isHidden = true
        resultLabel.isHidden = true
    }
    
    func start(game: Games) {
        //print("start HUD: \(game)")
        if game == Games.horror || game == Games.freeplay {
            hudState = .empty
            toClear()
        }
    }
    
    func message(_ string: String, color: UIColor) {
        message.text = string
        message.fontColor = color
        message.isHidden = false
    }
    func info(_ string: String, color: UIColor) {
        info.text = string
        info.fontColor = color
        info.isHidden = false
    }
    func tl(_ string: String, color: UIColor) {
        topleft.text = string
        topleft.fontColor = color
        topleft.isHidden = false
    }
    func tc(_ string: String, color: UIColor) {
        topcenter.text = string
        topcenter.fontColor = color
        topcenter.isHidden = false
    }
    func tr(_ string: String, color: UIColor) {
        topright.text = string
        topright.fontColor = color
        topright.isHidden = false
    }
    func bl(_ string: String, color: UIColor) {
        bottomleft.text = string
        bottomleft.fontColor = color
        bottomleft.isHidden = false
    }
    func bc(_ string: String, color: UIColor) {
        bottomcenter.text = string
        bottomcenter.fontColor = color
        bottomcenter.isHidden = false
    }
    func br(_ string: String, color: UIColor) {
        bottomright.text = string
        bottomright.fontColor = color
        bottomright.isHidden = false
    }
    func result(_ string: NSMutableAttributedString) {
        resultLabel.attributedText = string
        let x = resultLabel.intrinsicContentSize
        let r = x.height * ceil(x.width / resultLabel.frame.width)
        resultLabel.frame.size.height = r
        resultLabel.frame.origin.y = _scene.frame.height - r + 2.5
        resultLabel.isHidden = false
//print(resultLabel.intrinsicContentSize,resultLabel.frame)
        
    }

    init(size: CGRect) {
        //print("size: \(size)")
        _scene = SKScene(size: size.size)
        
        // test PASS or FAIL
        message.position = CGPoint(x: size.width/2, y: size.height/2)
        message.horizontalAlignmentMode = .center
        message.fontName = "Arial"
        message.fontSize = 80
        message.fontColor = UIColor.black
        message.isHidden = true
        _scene.addChild(message)

        info.position = CGPoint(x: size.width/2, y: size.height/2-35)
        info.horizontalAlignmentMode = .center
        info.fontName = "Arial"
        info.fontSize = 32
        info.fontColor = UIColor.black
        info.isHidden = true
        _scene.addChild(info)
        
        topcenter.position = CGPoint(x: size.width/2, y: size.height-0)
        topcenter.horizontalAlignmentMode = .center
        topcenter.verticalAlignmentMode = .top
        topcenter.fontName = "Arial"
        topcenter.fontSize = 18
        topcenter.fontColor = UIColor.white
        topcenter.isHidden = true
        _scene.addChild(topcenter)
        
        topright.position = CGPoint(x: size.width-32, y: size.height-0)
        topright.horizontalAlignmentMode = .right
        topright.verticalAlignmentMode = .top
        topright.fontName = "Arial"
        topright.fontSize = 18
        topright.fontColor = UIColor.red
        topright.isHidden = true
        _scene.addChild(topright)
        
        topleft.position = CGPoint(x: 32, y: size.height-0)
        topleft.horizontalAlignmentMode = .left
        topleft.verticalAlignmentMode = .top
        topleft.fontName = "Arial"
        topleft.fontSize = 18
        topleft.fontColor = UIColor.blue
        topleft.isHidden = true
        _scene.addChild(topleft)
        
        bottomleft.position = CGPoint(x: 32, y: 0)
        bottomleft.horizontalAlignmentMode = .left
        bottomleft.verticalAlignmentMode = .bottom
        bottomleft.fontName = "Arial"
        bottomleft.fontSize = 18
        bottomleft.fontColor = UIColor.darkGray
        bottomleft.isHidden = true
        _scene.addChild(bottomleft)
        
        bottomcenter.position = CGPoint(x: size.width/2, y: 0)
        bottomcenter.horizontalAlignmentMode = .center
        bottomcenter.verticalAlignmentMode = .bottom
        bottomcenter.fontName = "Arial"
        bottomcenter.fontSize = 18
        bottomcenter.fontColor = UIColor.white
        bottomcenter.isHidden = true
        _scene.addChild(bottomcenter)
        
        bottomright.position = CGPoint(x: size.width-32, y: 0)
        bottomright.horizontalAlignmentMode = .right
        bottomright.verticalAlignmentMode = .bottom
        bottomright.fontName = "Arial"
        bottomright.fontSize = 18
        bottomright.fontColor = UIColor.white
        bottomright.isHidden = true
        _scene.addChild(bottomright)
        
        resultLabel.textAlignment = .center
        resultLabel.textColor = .white
        resultLabel.font = UIFont(name: "Arial", size: 20)
        resultLabel.frame = CGRect(x: 32, y: size.height-20, width: size.width-64, height: 20)
        resultLabel.numberOfLines = 0
        resultLabel.lineBreakMode = .byWordWrapping
        
        hudState = .empty
        toClear()
    }
}

