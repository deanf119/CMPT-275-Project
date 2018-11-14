//
//  CaretakerReminderViewController.swift
//  Remembral
//
//Team: Group 2
//  Created by Alwin Leong on 11/2/18.
//  Edited: Alwin Leong
//
// For Caretaker Reminder list page
//  Known bugs:
//
//

import UIKit

class CaretakerReminderViewController: ReminderViewController {

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        FirebaseDatabase.sharedInstance.updateRemindersThen {
            (dict) in
            self.reminders = dict
            self.tableView.reloadData()
        }
    }
}