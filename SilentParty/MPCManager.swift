//
//  MPCManager.swift
//  SilentParty
//
//  Created by GuoGongbin on 1/30/17.
//  Copyright © 2017 GuoGongbin. All rights reserved.
//

import UIKit
import MultipeerConnectivity

protocol MPCManagerDelegate {
    func foundPeer()
    
    func lostPeer()
    
    func connectedWithPeer(peerID: MCPeerID)
}
protocol MPCManagerPartyEventDelegate {
    func invitationWasReceived(fromPeer: String)
    func partyEventOrganizerLeft()
}


class MPCManager: NSObject {
    var session: MCSession!
    var peer: MCPeerID!
    var browser: MCNearbyServiceBrowser!
    var advertiser: MCNearbyServiceAdvertiser!
    
    var foundPeers = [MCPeerID]()
    var invitationHandler: ((Bool, MCSession?)->Void)!
    var delegate: MPCManagerDelegate?
    var partyEventDelegate: MPCManagerPartyEventDelegate?
    
    override init() {
        super.init()
        
        peer = MCPeerID(displayName: UIDevice.current.name)
        
        session = MCSession(peer: peer, securityIdentity: nil, encryptionPreference: .none)
        session.delegate = self
        
        browser = MCNearbyServiceBrowser(peer: peer, serviceType: "silent-party")
        browser.delegate = self
        
        advertiser = MCNearbyServiceAdvertiser(peer: peer, discoveryInfo: nil, serviceType: "silent-party")
        advertiser.delegate = self
    }
    
    func sendData(dictionaryWithData dictionary: [String: Any], toPeers targetPeers: [MCPeerID]) -> Bool {
        let dataToSend = NSKeyedArchiver.archivedData(withRootObject: dictionary)
        let peersArray = targetPeers
        
        do {
            try session.send(dataToSend, toPeers: peersArray, with: .reliable)
        }catch let error as NSError {
            print("send data error: \(error.localizedDescription)")
            return false
        }
        return true
    }

}

extension MPCManager: MCSessionDelegate{
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        switch state {
        case .connected:
            print("connected to session:\(peerID.displayName)")
            delegate?.connectedWithPeer(peerID: peerID)
            if MusicPlayerSingleton.shared.isPartyOrganizer {
                if let partyEvent = MusicPlayerSingleton.shared.partyEvent {
                    let existence = partyEvent.members.contains { person -> Bool in
                        if person.name == peerID.displayName {
                            return true
                        }else{
                            return false
                        }
                    }
                    if !existence {
                        partyEvent.members.append(Person(name: peerID.displayName, partyEventKey: nil))
//                        let members = session.connectedPeers.map { $0.displayName }
//                        let dataDictionary = [MessageType.Members: members]
//                        if sendData(dictionaryWithData: dataDictionary, toPeers: session.connectedPeers) {
//                            print("send members list successfully")
//                        }
                    }
                }
            }
            
            
        case .connecting:
            print("Connecting to session: \(peerID.displayName)")
        case .notConnected:
            if let partyEvent = MusicPlayerSingleton.shared.partyEvent {
                if partyEvent.organizer.name == peerID.displayName {
                    // the party organizer has left the party
                    partyEventDelegate?.partyEventOrganizerLeft()
                    break
                }
                for (index, peer) in partyEvent.members.enumerated() {
                    if peer.name == peerID.displayName {
                        partyEvent.members.remove(at: index)
                        break
                    }
                }
            }
            
            print("Did not connect to session: \(peerID.displayName)")
        }
    }
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        let dictionary = ["data": data, "fromPeer": peerID] as [String : Any]
        NotificationCenter.default.post(name: NSNotification.Name("receivedMPCDataNotification"), object: dictionary)
    }
    
    
    
    //
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        
    }
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        
    }
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL, withError error: Error?) {
        
    }
}

extension MPCManager: MCNearbyServiceBrowserDelegate {
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

extension MPCManager: MCNearbyServiceAdvertiserDelegate {
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        
        print("MCNearbyServiceAdvertiserDelegate called: \(UIDevice.current.name) ")
        
        self.invitationHandler = invitationHandler
        partyEventDelegate?.invitationWasReceived(fromPeer: peerID.displayName)
        
    }
}


