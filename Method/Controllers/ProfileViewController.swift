//
//  ProfileViewController.swift
//  Method
//
//  Created by Mark Wang on 7/28/17.
//  Copyright © 2017 MarkWang. All rights reserved.
//

import Foundation
import UIKit
import FirebaseAuth

class ProfileViewController: UIViewController{
    
    @IBOutlet weak var fullNameLabel: UILabel!
    
    @IBOutlet weak var userNameLabel: UILabel!
    
    override func viewDidLoad(){
        super.viewDidLoad()
        //fullNameLabel.text = User.current.uid
        userNameLabel.text = User.current.username
    }
    
    @IBAction func backButtonTapped(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }
    @IBAction func logoutButtonTapped(_ sender: Any) {
        
        let firebaseAuth = Auth.auth()
        UserService.removeObserver(for: User.current, completion:{ (word) in
            do {
                
                try firebaseAuth.signOut()
                print("signout")
                //self.goHome()
                let initialViewController = UIStoryboard.initialViewController(for: .login)
                self.view.window?.rootViewController = initialViewController
                self.view.window?.makeKeyAndVisible()

            } catch let signOutError as NSError {
                print ("Error signing out: %@", signOutError)
            }

        })
    }
 
}
