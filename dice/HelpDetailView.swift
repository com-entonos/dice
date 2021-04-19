//
//  SettingView.swift
//  dice
//
//  Created by G.J. Parker on 19/9/23.
//  Copyright © 2019 G.J. Parker. All rights reserved.
//

import UIKit

class HelpDetailView : UIView {
    // detailed Help
    
    let scrollView = UITextView()
    let settingView = UIView()
    
    init(frame: CGRect, safe: CGRect) {
        //super.init(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height))
        super.init(frame: frame)
        self.backgroundColor = #colorLiteral(red: 0.7843137255, green: 0.7843137255, blue: 0.7843137255, alpha: 1)// #colorLiteral(red: 0.8313021064, green: 0.8314192891, blue: 0.8312650919, alpha: 1)//  #colorLiteral(red: 0.9488393664, green: 0.9491292834, blue: 0.9530405402, alpha: 1) //.white //nil
        
        let doneButton = UIButton(type: .system) //UIButton()
        let donateButton = UIButton(type: .system) //UIButton()
        
        if safe.origin.x == 0 {
            scrollView.frame = CGRect(x: 40, y: 0, width: safe.width-40*2, height: safe.height-60)
            doneButton.frame = CGRect(x: safe.width - 160, y: safe.height-50, width: 110, height: 40)
            donateButton.frame = CGRect(x: 40, y: safe.height-50, width: 200, height: 40)
        } else {
            scrollView.frame = CGRect(x: safe.origin.x, y: safe.origin.y, width: safe.width, height: safe.height-60)
            doneButton.frame = CGRect(x: safe.origin.x + safe.width - 150, y: safe.origin.y + safe.height-50, width: 150, height: 40)
            donateButton.frame = CGRect(x: safe.origin.x, y: safe.origin.y + safe.height-50, width: 200, height: 40)
        }
        
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.backgroundColor = UIColor.clear
        scrollView.isEditable = false
        scrollView.isSelectable = false
        scrollView.allowsEditingTextAttributes = false
        
        self.addSubview(scrollView)
        
        if let rtfPath = Bundle.main.url(forResource: "MyAssets/helpText", withExtension: "rtf") {
            let attributedStringWithRtf: NSAttributedString = try! NSAttributedString(url: rtfPath, options: [.documentType: NSAttributedString.DocumentType.rtf], documentAttributes: nil)
            self.scrollView.attributedText = attributedStringWithRtf
        }
        
        doneButton.backgroundColor = UIColor.clear
        doneButton.setTitle("Let's Play!", for: .normal)
        //doneButton.setTitleColor(.black, for: .normal)
        doneButton.titleLabel?.font = UIFont(name: "Arial", size: 18)
        doneButton.titleLabel?.textAlignment = .right
        doneButton.addTarget(self.superview, action: #selector(GameViewController.donePressed), for: .touchUpInside)
        self.addSubview(doneButton)
        
        donateButton.backgroundColor = UIColor.clear
        //donateButton.setTitle("Donate", for: .normal)
        donateButton.setTitle("Say \"hi\" to Entonos!", for: .normal)
        //donateButton.setTitleColor(.red, for: .normal)
        donateButton.titleLabel?.textAlignment = .left
        donateButton.titleLabel?.font = UIFont(name: "Arial", size: 18)
        donateButton.addTarget(self, action: #selector(self.donate), for: .touchUpInside)
        self.addSubview(donateButton)
    }
    
    @objc func donate(sender: UIButton!){
        //UIApplication.shared.open(URL(string: "http://entonos.com/d")!)
        UIApplication.shared.open(URL(string: "https://entonos.com/index.php/the-geek-shop/")!)
    }
    
    required init(coder: NSCoder) {
        fatalError("Not yet implemented")
    }
    
}
