//
//  DiceSet.swift
//  dice
//
//  Created by G.J. Parker on 20/5/25.
//  Copyright © 2020 G.J. Parker. All rights reserved.
//

import UIKit

class DiceSetView : UIView {
    // get a dice set
    
    let scrollView = UIScrollView()
    let settingView = UIView()
    
    var slider = [DieType:UISlider]()
    var sliderLabel = [DieType:UILabel]()
    var initial = [DieType:Int]()
    
    @objc func doSlide(sender: UISlider) {
        if let type = slider.first(where: { $1 == sender})?.key {
            let value = Int(sender.value)
            sliderLabel[type]?.text = String(value)
            sliderLabel[type]?.textColor = (value == initial[type] ? .white : .red)
        }
    }
    
    init(frame: CGRect, safe: CGRect, image: [DieType:UIImage], inventory: [DieType:Int], max: Int = 20) {
    //init(frame: CGRect, safe: CGRect, game: Game) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.black.withAlphaComponent(0.8)
        
        initial = inventory
        let doneButton = UIButton(type: .system)
        let dropButton = UIButton(type: .system)
        let cancelButton = UIButton(type: .system)

        let dx = (safe.origin.x == 0) ? 40 : safe.origin.x
        
        scrollView.frame = CGRect(x: safe.origin.x, y: safe.origin.y, width: safe.width, height: safe.height-50)
        
        let dhh = scrollView.frame.height / CGFloat(DieType.allCases.count)
        let dh = (dhh < 75) ? dhh : 75
        let sz = dh * (75-10)/75
//print(dhh,dh,sz)

        settingView.frame = CGRect(x: 0, y: 0, width: safe.width, height: dh * CGFloat(DieType.allCases.count))
        scrollView.contentSize = CGSize(width: scrollView.frame.width, height: dh * CGFloat(DieType.allCases.count)+dh)
        
        doneButton.frame = CGRect(x: safe.origin.x + safe.width - 160, y: safe.origin.y + safe.height-50, width: 150, height: 40)
        dropButton.frame = CGRect(x: dx + (safe.width - 150) / 2, y: safe.origin.y + safe.height-50, width: 150, height: 40)
        cancelButton.frame = CGRect(x: dx, y: safe.origin.y + safe.height-50, width: 150, height: 40)
        
        var y = CGFloat(0)//dy/2
        let w = safe.width
        if scrollView.frame.height - settingView.frame.height > 20 { y = 20}
        
        let dButton = UIButton(frame: CGRect(x: 0, y: 0, width: frame.width, height: safe.origin.y + safe.height - 50))
        dButton.backgroundColor = UIColor.clear
        dButton.setTitle("", for: .normal)
        dButton.titleLabel?.textAlignment = .left
        dButton.titleLabel?.font = UIFont(name: "Arial", size: 18)
        dButton.addTarget(self.superview, action: #selector(GameViewController.donePressed), for: .touchUpInside)
        self.addSubview(dButton)
        settingView.addSubview(dButton)
        
//print(dhh,dh,sz,w,y,w-sz)
        for type in DieType.allCases {
            slider[type] = UISlider(frame: CGRect(x: dx, y: y, width: w - dx - (50+sz+dx) , height: dh))
            slider[type]?.maximumValue = Float(max)
            slider[type]?.minimumValue = 0
            slider[type]?.setValue(min(Float(max),Float(inventory[type]!)), animated: true)
            slider[type]?.addTarget(self, action: #selector(doSlide), for: .valueChanged)
            sliderLabel[type] = UILabel(frame: CGRect(x: w - 50 - sz - dx/2 , y: y, width: 50, height: dh))
            sliderLabel[type]?.text = String(min(max,inventory[type]!))
            sliderLabel[type]?.font = .systemFont(ofSize: 36)
            sliderLabel[type]?.textColor = .white
            sliderLabel[type]?.textColor = (Int(slider[type]!.value) == initial[type] ? .white : .red)
            let iconImage = UIImageView(frame: CGRect(x: w - sz, y: y, width: sz, height: sz))
            iconImage.image = image[type]
            settingView.addSubview(slider[type]!)
            settingView.addSubview(sliderLabel[type]!)
            settingView.addSubview(iconImage)
            y += dh
        }

        settingView.translatesAutoresizingMaskIntoConstraints = false
        settingView.backgroundColor = UIColor.clear
        
        

        doneButton.backgroundColor = UIColor.clear
        doneButton.setTitle("Throw dice!", for: .normal)
        doneButton.titleLabel?.font = UIFont(name: "Arial", size: 18)
        doneButton.titleLabel?.textAlignment = .right
        doneButton.addTarget(self.superview, action: #selector(GameViewController.dieSetPressed), for: .touchUpInside)
        
        
        dropButton.backgroundColor = UIColor.clear
        //donateButton.setTitle("Donate", for: .normal)
        //donateButton.setTitleColor(.red, for: .normal)
        dropButton.setTitle("Drop dice", for: .normal)
        dropButton.titleLabel?.textAlignment = .center
        dropButton.titleLabel?.font = UIFont(name: "Arial", size: 18)
        dropButton.addTarget(self.superview, action: #selector(GameViewController.dieSetPressed), for: .touchUpInside)
        
        cancelButton.backgroundColor = UIColor.clear
        //donateButton.setTitle("Donate", for: .normal)
        //donateButton.setTitleColor(.red, for: .normal)
        cancelButton.setTitle("Cancel", for: .normal)
        cancelButton.titleLabel?.textAlignment = .left
        cancelButton.titleLabel?.font = UIFont(name: "Arial", size: 18)
        cancelButton.addTarget(self.superview, action: #selector(GameViewController.donePressed), for: .touchUpInside)
        
        scrollView.addSubview(settingView)
        self.addSubview(doneButton)
        self.addSubview(dropButton)
        self.addSubview(cancelButton)
        self.addSubview(scrollView)
    }
    
    func newDieSet() -> [DieType:Int] {
        var new = [DieType:Int]()
        for type in DieType.allCases {
            new[type] = Int(slider[type]!.value)
        }
        return new
    }
    

    
    required init(coder: NSCoder) {
        fatalError("Not yet implemented")
    }
    
}

