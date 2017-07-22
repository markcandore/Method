//
//  RecordsListViewController.swift
//  Method
//
//  Created by Mark Wang on 7/19/17.
//  Copyright © 2017 MarkWang. All rights reserved.
//

import Foundation
import UIKit
class RecordsListViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    var recordings = [Recording]()
    
    @IBOutlet weak var recordButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.dataSource = self
        
    }
    
    override func didReceiveMemoryWarning(){
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func recordButtonTapped(_ sender: Any) {
        let storyboard = UIStoryboard(name: "Main", bundle: .main)
        let recordPage = storyboard.instantiateViewController(withIdentifier: "recordingViewController") as? RecordingViewController
        //listPage?.event = Event(message: message)
        self.present(recordPage!, animated: true, completion: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let identifier = segue.identifier {
            if identifier == "showMedia" {
                print("Table view cell tapped")
                
                // 1
                let indexPath = tableView.indexPathForSelectedRow!
                // 2
                let record = recordings[indexPath.row]
                // 3
                let mediaPlayerViewController = segue.destination
                as! MediaPlayerViewController
                //let displayNoteViewController = segue.destination as! DisplayNoteViewController
                // 4
                //displayNoteViewController.note = note
                
            }
        }
    }
   
}

extension RecordsListViewController: UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return recordings.count
    }
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        //        // 3
        //        let cell = tableView.dequeueReusableCell(withIdentifier: "listNotesTableViewCell", for: indexPath)
        //
        //        // 4
        //        cell.textLabel?.text = "Yay - it's working!"
        //
        //        // 5
        //        return cell
        
        //        // 1
        //        let cell = tableView.dequeueReusableCell(withIdentifier: "listNotesTableViewCell", for: indexPath) as! ListNotesTableViewCell
        //
        //        // 2
        //        cell.noteTitleLabel.text = "note's title"
        //        cell.noteModificationTimeLabel.text = "note's modification time"
        //
        //        return cell
        //
        //let cell = tableView.dequeueReusableCell(withIdentifier: "listNotesTableViewCell", for: indexPath) as! ListNotesTableViewCell
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "audioTableViewCell", for: indexPath) as! RecordedAudioTableViewCell
        // 1
        let row = indexPath.row
        
        // 2
        let recording = recordings[row]
        
        // 3
        //cell.recordTitleLabel.text = record.title
        
        // 4
        //cell.noteModificationTimeLabel.text = note.modificationTime?.convertToString()
        
        return cell
    }
}
