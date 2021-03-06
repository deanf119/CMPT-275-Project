//
//  FirebaseDatabases.swift
//  Remembral
//
//Team: Group 2
//  Created: Aayush Malhotra on 11/1/18.
//  Edited: Aayush Malhotra, Alwin Leong, Laurent Gracia
//
//  Contains a Reminder object to be associated with the data.
//  Initializes Notifications for the phone.
//  Known bugs:
//
//

import UIKit
import FirebaseCore
import FirebaseDatabase
import FirebaseAuth
import UserNotifications
import FirebaseStorage

// Table structure for Reminders
struct Reminder {
    var sender:String!
    var reciever:String!
    var description:String!
    var date: Double! //Epoch time
    var recurrence: String!
    var status = false
    var databaseKey: String!
    func getDay() -> Int!{
        let nsDate = Date(timeIntervalSince1970: date)
        let day = Calendar.current.dateComponents([.day], from: nsDate)
        return Int(day.day ?? 0)
    }
    func getHour() -> Int!{
        let nsDate = Date(timeIntervalSince1970: date)
        let hour = Calendar.current.dateComponents([.hour], from: nsDate)
        return Int(hour.hour ?? 0)
    }
    func getMinute() -> Int!{
        let nsDate = Date(timeIntervalSince1970: date)
        let minute = Calendar.current.dateComponents([.minute], from: nsDate)
        return Int(minute.minute ?? 0)
    }
    func getDateOf() -> Date{
        return Date(timeIntervalSince1970: date)
    }
    func getMonth() -> Int!{
        let nsDate = Date(timeIntervalSince1970: date)
        let month = Calendar.current.dateComponents([.month], from: nsDate)
        return Int(month.month ?? 0)
    }
    func getWeekDay() -> Int!{
        let nsDate = Date(timeIntervalSince1970: date)
        let weekday = Calendar.current.dateComponents([.weekday], from: nsDate)
        return Int(weekday.weekday ?? 0)
    }
    
}

extension Date {
    
    func getMonthName() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMMM"
        let strMonth = dateFormatter.string(from: self)
        return strMonth
    }
    
    
}

// Table structure for users
struct User {
    var name:String!
    var address: String!
    var phNo: String!
    var caretakerName: String!
    var caretakerPhNo: String!
    var type: String!
    var imageURL: String!
    static let CARETAKER = "Caretaker"
    static let PATIENT   = "Patient"
}

// Implementation of Firebase Database.
class FirebaseDatabase: NSObject, UICollectionViewDelegate ,UNUserNotificationCenterDelegate{
    
    
    let reminderRef = Database.database().reference(fromURL: "https://remembral-c17af.firebaseio.com/").root.child("reminders")
    let usersRef = Database.database().reference(fromURL: "https://remembral-c17af.firebaseio.com/").root.child("users")
    let locationRef = Database.database().reference(fromURL: "https://remembral-c17af.firebaseio.com/").root.child("locations")
    let contactsRef = Database.database().reference(fromURL: "https://remembral-c17af.firebaseio.com/").root.child("contacts")
    let rootRef = Database.database().reference(fromURL: "https://remembral-c17af.firebaseio.com/")
    
    var userObj: User!
    var reminderList = [Reminder]()
    
    var contactList = [ContactPerson]()
    //Key, Name
    var selectedContacts = 0
    
    // Initialize
    override init()
    {
        super.init()
        /*self.UpdateFromFirebase{
            (isFinish) in print(isFinish)
        }*/
        
    }
    
    // Instance of Firebase
    class var sharedInstance: FirebaseDatabase {
        struct Static {
            static var instance: FirebaseDatabase = FirebaseDatabase()
        }
        return Static.instance
    }
    
    //Check for new reminders, add new reminders to database
    func updateReminders(){
        updateRemindersThen{
            (dict) in
            FirebaseDatabase.sharedInstance.reminderList = dict
        }
    }
    
    //Grab 24 hours worth of Reminders. Get all the attribues of the Reminder Struct.
    func grabPast24Hours(withStatus: Bool = true, completion:(([Reminder]) -> Void)?){
        reminderList.removeAll()
        let timeSpan = 60 * 60 * 24;
        let todayDate = Int(Date().timeIntervalSince1970)
        if(!FirebaseDatabase.sharedInstance.isSelectedPatientValid()){
            completion?(reminderList)
            return
        }
        

        reminderRef.child(FirebaseDatabase.sharedInstance.getSelectedPatientID()).queryOrdered(byChild: "date").queryStarting(atValue: todayDate - timeSpan).queryEnding( atValue: todayDate ).observe(.value, with: { (snapshot: DataSnapshot) in
            var newListReminders = [Reminder]()
            for snap in snapshot.children {
                if let rData = (snap as! DataSnapshot).value as? [String:Any]{
                    
                    let newR = Reminder(sender: rData["sender"] as? String,
                                        reciever: rData["reciever"] as? String,
                                        description: rData["description"] as? String,
                                        date: rData["date"] as? Double,
                                        recurrence: rData["recurrence"] as? String,
                                        status: rData["status"] as! Bool,
                                        databaseKey: (snap as! DataSnapshot).key)
                    if newR.status == withStatus{
                        continue;
                    }
                    newListReminders += [newR]
                }
            }
            completion? (newListReminders)
        })
    }
    
    // Update all reminders
    func updateRemindersThen(completion:(([Reminder]) -> Void)?){
        reminderList.removeAll()
        if(!FirebaseDatabase.sharedInstance.isSelectedPatientValid()){
            return
        }
        let userID = (userObj.type == User.CARETAKER ?  FirebaseDatabase.sharedInstance.getSelectedPatientID() : Auth.auth().currentUser?.uid)
        
        reminderRef.child(userID!).queryOrdered(byChild: "date").observe(.value, with: { (snapshot: DataSnapshot) in
            var asdf = [Reminder]()
            for snap in snapshot.children {
                if let rData = (snap as! DataSnapshot).value as? [String:Any]{
                    
                    let newR = Reminder(sender: rData["sender"] as? String,
                                        reciever: rData["reciever"] as? String,
                                        description: rData["description"] as? String,
                                        date: rData["date"] as? Double,
                                        recurrence: rData["recurrence"] as? String,
                                        status: rData["status"] as! Bool,
                                        databaseKey: (snap as! DataSnapshot).key)
                   asdf += [newR]
                }
            }
            completion? (asdf)
            //let postDict = snapshot.value as? [String : AnyObject] ?? [:]
            // ...
        })
    }
    
    // Setup notifications for Reminders in app, should have done and snooze(5min) functionality.
    func initializeReminderNotificaions(){
        let uid = Auth.auth().currentUser?.uid
        reminderRef.child(uid!).observe(.childAdded, with: { (snapshot: DataSnapshot) in
                if let rData = snapshot.value as? [String:Any]{
                    
                    let newR = Reminder(sender: rData["sender"] as? String,
                                        reciever: rData["reciever"] as? String,
                                        description: rData["description"] as? String,
                                        date: rData["date"] as? Double,
                                        recurrence: rData["recurrence"] as? String,
                                        status: rData["status"] as! Bool,
                                        databaseKey: snapshot.key)
                    if(newR.status == true){
                        return
                    }
                    let content = UNMutableNotificationContent()
                    
                    ///should be puled from one of the list arrays list[indexPath.row]
                    content.title = newR.sender
                    content.categoryIdentifier = "ReminderNotif"
                    content.body = newR.description///should be puled from one of the list arrays
                    content.sound = UNNotificationSound.default
                    content.userInfo = ["Key": newR.databaseKey]
                    
                    var dateComponents = DateComponents()
                    
                    let trigger : UNCalendarNotificationTrigger
                    if(newR.recurrence == "No Recurrence"){

                        dateComponents.day = newR.getDay()
                        dateComponents.month  = newR.getMonth()
                        dateComponents.hour = newR.getHour() /// pulled from
                        dateComponents.minute = newR.getMinute()
                        trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)///This should be a calendar notification
                    }
                        
                    else if(newR.recurrence == "Daily"){
                        dateComponents.hour = newR.getHour() /// pulled from
                        dateComponents.minute = newR.getMinute()
                        print(dateComponents)
                        trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)///This should be a calendar notification
                    }
                        
                    else if(newR.recurrence == "Weekly"){
                        dateComponents.weekday = newR.getWeekDay()
                        dateComponents.hour = newR.getHour() /// pulled from
                        dateComponents.minute = newR.getMinute()
                        print(dateComponents)
                        trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)///This should be a calendar notification
                    }
                        
                    else{
                        dateComponents.day = newR.getDay()
                        dateComponents.hour = newR.getHour() /// pulled from
                        dateComponents.minute = newR.getMinute()
                        print(dateComponents)
                        trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)///This should be a calendar notification
                    }
                    
                    let request = UNNotificationRequest(identifier: newR.databaseKey, content: content, trigger: trigger)
                    
                    UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
                }
        })
    }
    
    // Deals with Notification action done by user. Updates Reminders based on the action done. Eg) Done task updates database on status of Reminder
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void)
    {
        if (response.actionIdentifier == UNNotificationDismissActionIdentifier){
            let firebaseKey = response.notification.request.content.userInfo["Key"] as! String
            let uid = Auth.auth().currentUser?.uid
            let reminderRef = FirebaseDatabase.sharedInstance.reminderRef.child(uid!).child(firebaseKey)
            let date = response.notification.date.timeIntervalSince1970
            reminderRef.updateChildValues(["status":false, "date": date])
        }
        else if response.actionIdentifier == choices.answer1.identifier{
            let date = response.notification.date.addingTimeInterval(5.0 * 60.0)
            let firebaseKey = response.notification.request.content.userInfo["Key"] as! String
            
            let content = UNMutableNotificationContent()
            ///should be puled from one of the list arrays list[indexPath.row]
            content.title = response.notification.request.content.title
            content.categoryIdentifier = "ReminderNotif"
            content.body = response.notification.request.content.body///should be puled from one of the list arrays
            content.userInfo = ["Key": firebaseKey]
            let calendar = Calendar.current
            content.sound = UNNotificationSound.default
            let dateComponents = calendar.dateComponents(
                [.hour, .minute, .second],
                from: date)
            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
            var id = firebaseKey
            id.append("Snooze")
            let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
            UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
            
        }
        else if response.actionIdentifier == choices.answer2.identifier {
            let firebaseKey = response.notification.request.content.userInfo["Key"] as! String
            let uid = Auth.auth().currentUser?.uid
            let reminderRef = FirebaseDatabase.sharedInstance.reminderRef.child(uid!).child(firebaseKey)
            let date = response.notification.date.timeIntervalSince1970
            reminderRef.updateChildValues(["status":true, "date": date])
        }
    }
    
    // Add a reminder to the database
    func setReminder(arg: Reminder!, forID: String) {
        let childRef = reminderRef.child(forID).childByAutoId()
        let values : [String:Any] = ["sender": arg!.sender as Any,
                                     "reciever": arg!.reciever as Any,
                                     "description": arg!.description as Any,
                                     "recurrence": arg!.recurrence as Any,
                                     "status": arg!.status,
                                     "date": arg.date as Any]
        childRef.setValue(values)
    }
    
    // Change home page user information to the database
    func setUserData(arg: User!){
        self.userObj = arg
        let userID = Auth.auth().currentUser?.uid
        let childRef = usersRef.child(userID!)
        let values : [String:Any] = ["name": arg.name,
                      "address": arg.address,
                      "phNo": arg.phNo,
                      "caretakerName": arg.caretakerName,
                      "caretakerPhNo": arg.caretakerPhNo]
        childRef.updateChildValues(values)
    }

    // Update Home Page Information from Firebase
    func UpdateFromFirebase(completion: ((Bool) -> Void)?){
        let userID = Auth.auth().currentUser?.uid
        let childRef = usersRef.child(userID!)
        childRef.observeSingleEvent(of: .value, with: { (snapshot) in
            if let userDict = snapshot.value as? [String:String]{
                self.userObj = User(name: userDict["name"],
                                    address: userDict["address"],
                                    phNo: userDict["phNo"],
                                    caretakerName: userDict["caretakerName"],
                                    caretakerPhNo: userDict["caretakerPhNo"],
                                    type: userDict["type"],
                                    imageURL: userDict["imageURL"]
                )
                completion? (true)
            }
            else {
                completion? (false)
            }
        })
    }
    
    // Load all contacts for the user. Get all the attributes that are present in the Contact Structure.
    func LoadContacts(completion: ((Bool) -> Void)?){
        let userID = Auth.auth().currentUser?.uid
        contactList.removeAll()
        
        let group = DispatchGroup()
        let dispatchQueue = DispatchQueue.global(qos: .userInitiated)
        
        FirebaseDatabase.sharedInstance.contactsRef.child(userID!).observeSingleEvent(of: .value, with: { (snapshot:  DataSnapshot) in
            //print(snapshot)
            dispatchQueue.async(group: group,
                                qos: .userInitiated,
                                flags: DispatchWorkItemFlags.assignCurrentContext,
                                execute: {
                                    
            for snap in snapshot.children{
                group.enter()
                if let firstLevel = (snap as! DataSnapshot).value as? [String:Any]{
                    let key = firstLevel["key"] as! String
                    let relation = firstLevel["relation"] as? String ?? "caretaker"
                    FirebaseDatabase.sharedInstance.usersRef.child(key).observeSingleEvent(of: .value, with: {(patientData: DataSnapshot) in
                        if let patientDict = patientData.value as? [String: Any] {
                    
                            var newContact = ContactPerson(fullName: patientDict["name"] as? String,
                                                           emailAddress: patientDict["email"] as? String,
                                                       relation: relation)
                            newContact.phoneNum = patientDict["phNo"] as? String
                            newContact.address = patientDict["address"] as? String
                            newContact.identifier = key
                            let downloadURL = patientDict["imageURL"] as? String
                            let url = URL.init(string: downloadURL!)
                            if downloadURL?.isEmpty != true {
                                    let data = try! Data(contentsOf: url!)
                                    let image = UIImage(data: data as Data)
                                newContact.picture = image
                            }
                            self.contactList.append(newContact)
                            //print(newContact)
                        }
                        group.leave()
                    })
            }
            }
                                    
            })
            group.notify(queue: .main) {
                //Group has finished
                completion? (true)
            }
        })
    }
    
    // Return self as a user object.
    func getUserData() -> User {
        return self.userObj
    }
    
    // Check if the selected Patient is valid
    func isSelectedPatientValid() -> Bool{
        return (contactList.count != 0 && selectedContacts < contactList.count)
    }
    
    // Returns selected patient's information.
    func getSelectedPatientID() -> String {
        if isSelectedPatientValid(){
            print(contactList[selectedContacts].identifier)
            return contactList[selectedContacts].identifier
        }
        print("None selected")
        return ""
    }
}
