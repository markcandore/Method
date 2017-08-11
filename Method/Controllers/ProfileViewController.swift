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
        let transition = CATransition()
        transition.duration = 0.2
        transition.type = kCATransitionPush
        transition.subtype = kCATransitionFromRight
        view.window!.layer.add(transition, forKey: kCATransition)
        
        dismiss(animated: false, completion: nil)
    }
    @IBAction func logoutButtonTapped(_ sender: Any) {
        
        let firebaseAuth = Auth.auth()
        
        do {
            try firebaseAuth.signOut()
            print("signout")
            self.dismiss(animated: true, completion: nil)
            let initialViewController = UIStoryboard.initialViewController(for: .login)
            let window = UIApplication.shared.keyWindow
            window?.rootViewController = initialViewController
            
        } catch let signOutError as NSError {
            print ("Error signing out: %@", signOutError)
        }
        /*
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
 */

    }
 
}
