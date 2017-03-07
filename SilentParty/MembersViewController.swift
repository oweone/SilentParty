//
//  MembersViewController.swift
//  TKParty
//
//  Created by GuoGongbin on 1/19/17.
//  Copyright © 2017 GuoGongbin. All rights reserved.
//

import UIKit
import Firebase
import MediaPlayer
import MultipeerConnectivity

class MembersViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var leaveButton: UIButton!
    @IBOutlet weak var spinningIndicator: UIActivityIndicatorView!
    
    let MemberCellIdentifier = "MemberCell"
    var partyEvent: PartyEvent!
    var mpcManager: MPCManager!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        mpcManager = appDelegate.mpcManager
        
        spinningIndicator.isHidden = true
        
        configureleaveButton()
        
        NotificationCenter.default.addObserver(self, selector: #selector(MembersViewController.handleMemberLeaveNotification(notification:)), name: Notification.Name("PartyEventMemberLeave"), object: nil)
        
//        let directories = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
//        let documentDirectory = directories[0]
        
    }
    // the userOfThisDevice is a member of this party, the button is red(leave), otherwise green(join)
    @IBAction func leaveButtonTapped(_ sender: UIButton) {
        if MusicPlayerSingleton.shared.isPartyOrganizer {
            deletePartyEvent()
        }else{
            // one member wants to leave this partyEvent, to be implemented
            deletePerson()
        }
    }
    
    func handleMemberLeaveNotification(notification: Notification) {
        tableView.reloadData()
    }
    
    func configureleaveButton() {
        leaveButton.setTitleColor(UIColor.white, for: .normal)
        leaveButton.layer.cornerRadius = 5
        leaveButton.clipsToBounds = true
        leaveButton.backgroundColor = UIColor.red
        leaveButton.setTitle("Leave", for: .normal)
    }
    
    func deletePartyEvent() {
        mpcManager.advertiser.stopAdvertisingPeer()
        disconnectFromPartyEvent()
    }
    
    func deletePerson() {
        disconnectFromPartyEvent()
    }
    
    func disconnectFromPartyEvent() {
        
        _ = self.navigationController?.popToRootViewController(animated: true)
        
        mpcManager.session.disconnect()
        
        MusicPlayerSingleton.shared.mediaPlayer.stop()
        MusicPlayerSingleton.shared.mediaPlayer = AVAudioPlayer()
//        MusicPlayerSingleton.shared.nowPlayingSongIndex = nil
        MusicPlayerSingleton.shared.nowPlayingSong = nil
        MusicPlayerSingleton.shared.partyEvent = nil
        MusicPlayerSingleton.shared.isPartyOrganizer = false
        MusicPlayerSingleton.shared.isInPartyEvent = false
        
    }
    //MARK: segue
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let segueIdentifier = "ShowChatFromMembers"
        if segue.identifier == segueIdentifier, let chatViewController = segue.destination as? ChatViewController {
            chatViewController.senderDisplayName = MusicPlayerSingleton.shared.userOfThisDevice.name
            
        }
    }
    
}
extension MembersViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return partyEvent.members.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: MemberCellIdentifier, for: indexPath)
        let member = partyEvent.members[indexPath.row]
        cell.textLabel?.text = member.name
        cell.detailTextLabel?.text = nil
        cell.imageView?.image = member.image
        
        return cell
    }
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Members List"
    }
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        if MusicPlayerSingleton.shared.isPartyOrganizer {
            return true
        }else{
            return false
        }
    }
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
        return .delete
    }
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        let member = partyEvent.members[indexPath.row]
        
        if partyEvent.organizer.name == member.name {
            deletePartyEvent()
        }else{
            let dataDictionary = [MessageType.MemberLeave: member.name]
            if mpcManager.sendData(dictionaryWithData: dataDictionary, toPeers: mpcManager.session.connectedPeers) {
              partyEvent.members.remove(at: indexPath.row)
                if editingStyle == .delete {
                    tableView.deleteRows(at: [indexPath], with: .fade)
                }
            }
        }
    }

}
