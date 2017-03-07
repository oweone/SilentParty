//
//  CreatePartyViewController.swift
//  SilentParty
//
//  Created by GuoGongbin on 1/25/17.
//  Copyright © 2017 GuoGongbin. All rights reserved.
//

import UIKit

class CreatePartyViewController: UIViewController {

    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var descriptionTextField: UITextField!
    @IBOutlet weak var tableView: UITableView!
    
    var selectedSongs: [Song]?
    let CellIdentifier = "SongCell"
    let SegueIdentifier = "AddSongs"
    let ShowPartyIdentifier = "ShowParty"
    var mpcManager: MPCManager!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        mpcManager = appDelegate.mpcManager

        // Do any additional setup after loading the view.
    }

    @IBAction func done(_ sender: UIBarButtonItem) {
        
//        let partyName = titleTextField.text == "" ? "untitled" : titleTextField.text
//        let description = descriptionTextField.text == "" ? "no description" : descriptionTextField.text
        
        if selectedSongs == nil {
            
            let promptView = PromptView.promptView(width: self.view.frame.width, height: self.view.frame.height, text: "No Songs Added")
            view.addSubview(promptView)
            promptView.alpha = 0
            
            let animation = CABasicAnimation(keyPath: "opacity")
            animation.fromValue = 0
            animation.toValue = 1
            animation.duration = 2.5
            animation.autoreverses = true
            animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionDefault)
            promptView.layer.add(animation, forKey: "opacity")
            
            return
        }
        let partyName = MusicPlayerSingleton.shared.partyPeer.displayName
        let partyEvent = PartyEvent(name: partyName, organizer: MusicPlayerSingleton.shared.userOfThisDevice, songList: self.selectedSongs!)
        MusicPlayerSingleton.shared.isInPartyEvent = true
        MusicPlayerSingleton.shared.isPartyOrganizer = true
        MusicPlayerSingleton.shared.partyEvent = partyEvent
        print("party event is created here:\(partyEvent.name)")
        
//        mpcManager.advertiser.startAdvertisingPeer()
        
        dismiss(animated: true, completion: nil)
}
    
    @IBAction func cancel(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
    @IBAction func comeBackFromSongsTableViewController(segue: UIStoryboardSegue) {
        self.tableView.reloadData()
        self.tableView.setEditing(true, animated: true)
    }
    

    
    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == SegueIdentifier, let navigationController = segue.destination as? UINavigationController {
            
            let songsTableViewController = navigationController.topViewController as! SongsTableViewController
            songsTableViewController.alreadySelectedSongs = selectedSongs
        }
    }
 

}
extension CreatePartyViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if selectedSongs != nil {
            return selectedSongs!.count
        }else{
            return 0
        }
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: CellIdentifier, for: indexPath)
        let song = selectedSongs![indexPath.row]
        cell.textLabel?.text = song.name
        cell.detailTextLabel?.text = song.artist
        return cell
    }
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
        return .delete
    }
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if selectedSongs != nil {
            selectedSongs?.remove(at: indexPath.row)
        }
        if editingStyle == .delete {
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
    }
}
