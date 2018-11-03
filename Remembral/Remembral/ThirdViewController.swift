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
        //print(FirebaseDatabase.sharedInstance.reminderList)
        
    }
    private func createSampleReminders(){
        reminders += ["Example1", "Example2", "Example3"]
    }
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1;
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return FirebaseDatabase.sharedInstance.reminderList.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Table view cells are reused and should be dequeued using a cell identifier.
        let cellIdentifier = "ReminderTableViewCell"
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? ReminderTableViewCell  else {
            fatalError("The dequeued cell is not an instance of ReminderTableViewCell.")
        }
        
        // Fetches the appropriate meal for the data source layout.
        let reminderData = FirebaseDatabase.sharedInstance.reminderList[indexPath.row]
        
        var labelText = "Task: " + reminderData.description as String + "\n"
        labelText.append("Time: Today @ ")
        labelText.append(String(reminderData.getHour()))
        labelText.append(":")
        labelText.append(String(reminderData.getMinute()))
        labelText.append("\nSet by: ")
        labelText.append(reminderData.sender as String)
        labelText.append("\nStatus: " )
        
        labelText.append(reminderData.status ? "Complete" : "NotComplete")
        
        cell.ReminderLabel.text = labelText
        cell.reminderDBKey = reminderData.databaseKey
        cell.delegate = self
        
        if (reminderData.status == true){
            cell.backgroundColor =  UIColor.lightGray
            cell.doneButton.isHidden = true
            cell.snoozeButton.isHidden = true
        } else {
            cell.backgroundColor = UIColor.white
            cell.doneButton.isHidden = false
            cell.snoozeButton.isHidden = false
        }
        
        return cell
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
}
