//
//  MPCManager.swift
//  SilentParty
//
//  Created by GuoGongbin on 1/30/17.
//  Copyright © 2017 GuoGongbin. All rights reserved.
//

import UIKit
import MultipeerConnectivity

protocol MPCChatManagerDelegate {
    func foundPeer()
    func lostPeer()
    func invitationWasReceived(fromPeer: String)
    func connectedWithPeer(peerID: MCPeerID)
}

class MPCChatManager: NSObject {
    var session: MCSession!
    var peer: MCPeerID!
    var browser: MCNearbyServiceBrowser!
    var advertiser: MCNearbyServiceAdvertiser!
    
    var foundPeers = [MCPeerID]()
    var invitationHandler: ((Bool, MCSession?)->Void)!
    var delegate: MPCChatManagerDelegate?
    
    override init() {
        super.init()
        
        peer = MCPeerID(displayName: UIDevice.current.name)
        
        session = MCSession(peer: peer, securityIdentity: nil, encryptionPreference: .none)
        session.delegate = self
        
        browser = MCNearbyServiceBrowser(peer: peer, serviceType: "chat")
        browser.delegate = self
        
        advertiser = MCNearbyServiceAdvertiser(peer: peer, discoveryInfo: nil, serviceType: "chat")
        advertiser.delegate = self
    }
    
    func sendData(dictionaryWithData dictionary: [String: Any], toPeer targetPeer: MCPeerID) -> Bool {
        let dataToSend = NSKeyedArchiver.archivedData(withRootObject: dictionary)
        let peersArray = NSArray(object: targetPeer)
        
        do {
            try session.send(dataToSend, toPeers: peersArray as! [MCPeerID], with: .reliable)
        }catch let error as NSError {
            print("send data error: \(error.localizedDescription)")
            return false
        }
        return true
    }
    
}

extension MPCChatManager: MCSessionDelegate{
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        switch state {
        case .connected:
            delegate?.connectedWithPeer(peerID: peerID)
            print("connected to session:\(session)")
        case .connecting:
            print("Connecting to session: \(session)")
        case .notConnected:
            print("Did not connect to session: \(session)")
        }
    }
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        let dictionary = ["data": data, "fromPeer": peerID] as [String : Any]
        NotificationCenter.default.post(name: NSNotification.Name("receivedMPCChatDataNotification"), object: dictionary)
    }
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        
    }
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        
    }
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL, withError error: Error?) {
        
    }
    
}

extension MPCChatManager: MCNearbyServiceBrowserDelegate {
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        foundPeers.append(peerID)
        delegate?.foundPeer()
    }
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        for (index, peer) in foundPeers.enumerated() {
            if peer == peerID {
                foundPeers.remove(at: index)
                break
            }
        }
        delegate?.lostPeer()
    }
    func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
        print("browser found peer error: \(error.localizedDescription)")
    }
}
extension MPCChatManager: MCNearbyServiceAdvertiserDelegate {
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        
        print("something happened here: didReceiveInvitationFromPeer: \(peerID.displayName)")
        
        self.invitationHandler = invitationHandler
        delegate?.invitationWasReceived(fromPeer: peer.displayName)
        
    }
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
        print("advertiser did not start error: \(error.localizedDescription)")
    }
}


