//
//  history.swift
//  dice
//
//  Created by G.J. Parker on 20/6/2.
//  Copyright © 2020 G.J. Parker. All rights reserved.
//

import UIKit

class History {
    // store history of results
    
    var history = [NSAttributedString]()
    var time = [String]()
    
    var historyButton : UIButton? = nil
    
    init(button: UIButton) {
        historyButton = button
        historyButton!.isHidden = false
        historyButton!.isEnabled = (history.count > 0)
    }
    
    func add(result: NSAttributedString, game: String) {
        history.insert(result, at: 0)
        let dateF = DateFormatter()
        dateF.dateStyle = .medium
        dateF.timeStyle = .medium
        time.insert(dateF.string(from: Date()) + " (" + game + ")", at: 0)
        historyButton!.isEnabled = (history.count > 0)
    }
    
    func getHistory() -> [NSAttributedString] {
        return history
    }
    
    func getTimeHistory() -> [String] {
        return time
    }
    
    func get() -> ([NSAttributedString], [String]) {
        return (history, time)
    }
    
 
    deinit {
        historyButton!.isEnabled = false
        historyButton!.isHidden = true
    }
    
    
}
class HistoryView : UIView, UITableViewDelegate, UITableViewDataSource  {
    // display result history
    
    let cellReuseIdentifier = "cell"
    var historyTV = UITableView()
    
    var history = [NSAttributedString]()
    var time = [String]()
    var GVC = GameViewController()
    
    init(frame: CGRect, safe: CGRect, history: History, gvc: GameViewController) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.black.withAlphaComponent(0.8)
        (self.history, self.time) = history.get()
        self.GVC = gvc
        
        let dismissButton = UIButton(frame: frame)
        dismissButton.backgroundColor = .clear
        dismissButton.setTitle("", for: .normal)
        dismissButton.addTarget(self.superview, action: #selector(GameViewController.donePressed), for: .touchUpInside)
        self.addSubview(dismissButton)
        
        historyTV.frame = CGRect(x: safe.origin.x+50, y: safe.origin.y+50, width: safe.width-100, height: safe.height-100)
        //self.historyTV.frame.size.height = self.historyTV.contentSize.height
        self.addSubview(historyTV)
        
        //historyTV.frame = CGRectMake(0, 50, 320, 200)
        historyTV.delegate = self
        historyTV.dataSource = self
        historyTV.register(UITableViewCell.self, forCellReuseIdentifier: cellReuseIdentifier)
        historyTV.backgroundColor = .clear
        
        historyTV.reloadData()
        historyTV.sizeToFit()
        let size = historyTV.contentSize
//print(size)
        historyTV.frame.size = CGSize(width: safe.width-100, height: min(safe.height - 100, size.height*7/5))
        
    }

    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return history.count
    }
    
    // create a cell for each table view row
    internal func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        //let cell:UITableViewCell = tableView.dequeueReusableCell(withIdentifier: cellReuseIdentifier) as UITableViewCell!
        //let cell2:UITableViewCell = tableView.dequeueReusableCell(withIdentifier: cellReuseIdentifier)!
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: cellReuseIdentifier)
        
        cell.backgroundColor = .clear
        //cell.detailTextLabel?.backgroundColor = .clear
        cell.detailTextLabel?.textColor = .white
        //cell.textLabel?.backgroundColor = .clear
        cell.textLabel?.textColor = .white
        cell.textLabel?.font = UIFont(name: "Arial", size: 20)
        cell.textLabel?.numberOfLines = 0
        cell.textLabel?.lineBreakMode = .byWordWrapping
        cell.selectionStyle = .none
        
        cell.detailTextLabel?.text = time[indexPath.row]
        cell.textLabel?.attributedText = history[indexPath.row]
        
        return cell
    }
    
    // method to run when table view cell is tapped
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //print("You tapped cell number \(indexPath.row).")
        GVC.donePressed(sender: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

/*final class ContentSizedTableView : UITableView {
    override var contentSize: CGSize {
        didSet {
            invalidateIntrinsicContentSize()
        }
    }
    
    override var intrinsicContentSize: CGSize {
        layoutIfNeeded()
        return CGSize(width: UIView.noIntrinsicMetric, height: contentSize.height)
    }
}*/
