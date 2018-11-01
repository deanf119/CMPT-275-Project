//
//  ThirdViewController.swift
//  Remembral
//
//  Created by Dean Fernandes on 2018-10-28.
//  Copyright © 2018 Aayush Malhotra. All rights reserved.
//
// ******For Reminders Page

import UIKit

class ThirdViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    var reminders = [String]()
    
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        createSampleReminders()
        
    }
    private func createSampleReminders(){
        reminders += ["Example1", "Example2", "Example3"]
    }
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1;
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return reminders.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Table view cells are reused and should be dequeued using a cell identifier.
        let cellIdentifier = "ReminderTableViewCell"
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? ReminderTableViewCell  else {
            fatalError("The dequeued cell is not an instance of ReminderTableViewCell.")
        }
        
        // Fetches the appropriate meal for the data source layout.
        let reminder = reminders[indexPath.row]
        
        cell.ReminderLabel.text = reminder
        
        return cell
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
}