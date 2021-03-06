//
//  PatientTabBarViewController.swift
//  Remembral
//
//Team: Group 2
//  Created by Alwin Leong on 10/31/18.
//  Edited: Alwing Leong
//
//  Known bugs:
//
//


import UIKit

// Tab view for the patients screen: home, contacts and patients.
class PatientTabBarViewController: UITabBarController {

    // Is the screen loaded
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    // Is there memory warning
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
    //Instantiate a tab-bar
    override func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        let rootView = self.viewControllers![self.selectedIndex] as! UINavigationController
        rootView.popToRootViewController(animated: false)
    }

}
