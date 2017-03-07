//
//  MusicPlayerSingleton.swift
//  TKParty
//
//  Created by GuoGongbin on 1/11/17.
//  Copyright © 2017 GuoGongbin. All rights reserved.
//

import Foundation
import MultipeerConnectivity
import AVFoundation

class MusicPlayerSingleton {
    
    static let shared = MusicPlayerSingleton()
    
    var mediaPlayer = AVAudioPlayer()
    // the party event that this userOfThisDevice is in, could be nil
    var partyEvent: PartyEvent?
    var partyPeer = MCPeerID(displayName: UIDevice.current.name)
//    var nowPlayingSongIndex: Int?
    var userOfThisDevice = Person(name: UIDevice.current.name, partyEventKey: nil)
    var isInPartyEvent = false
    var isPartyOrganizer = false
    
    var nowPlayingSong: Song?
}
