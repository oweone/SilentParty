//
//  ChannelListViewController.swift
//  SilentParty
//
//  Created by GuoGongbin on 2/12/17.
//  Copyright © 2017 GuoGongbin. All rights reserved.
//

import UIKit
import MultipeerConnectivity

class ChannelListViewController: UITableViewController {
    
    var mpcChatManager: MPCChatManager!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        mpcChatManager = appDelegate.mpcChatManager
        mpcChatManager.delegate = self
        
        mpcChatManager.advertiser.startAdvertisingPeer()
        mpcChatManager.browser.startBrowsingForPeers()
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return mpcChatManager.foundPeers.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellIdentifier = "PeerCell"
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath)

        cell.textLabel?.text = mpcChatManager.foundPeers[indexPath.row].displayName

        return cell
    }
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedPeer = mpcChatManager.foundPeers[indexPath.row]
        mpcChatManager.browser.invitePeer(selectedPeer, to: mpcChatManager.session, withContext: nil, timeout: 20)
        print("something happened here: appDelegate.mpcManager.browser.invitePeer:\(mpcChatManager.session.myPeerID.displayName)")
    }
    
    
}
extension ChannelListViewController: MPCChatManagerDelegate {
    func foundPeer() {
        tableView.reloadData()
    }
    func lostPeer() {
        tableView.reloadData()
    }
    func invitationWasReceived(fromPeer: String) {
        
        print("invitationWasReceived:\(mpcChatManager.session.myPeerID.displayName)")
        
        let alert = UIAlertController(title: nil, message: "\(fromPeer) wants to chat with you", preferredStyle: .alert)
        
        let accept = UIAlertAction(title: "Accept", style: .default, handler: { action in
            //this method is called on invitee's device, so the self.appDelegate.mpcManager.session is from invitee's device
            self.mpcChatManager.invitationHandler(true, self.mpcChatManager.session)
            
        })
        let decline = UIAlertAction(title: "Decline", style: .default, handler: { action in
            self.mpcChatManager.invitationHandler(false, nil)
        })
        alert.addAction(accept)
        alert.addAction(decline)
        
        OperationQueue.main.addOperation { () -> Void in
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    func connectedWithPeer(peerID: MCPeerID) {
        OperationQueue.main.addOperation({
            self.performSegue(withIdentifier: "idSegueChat", sender: self)
        })
    }

}
