//
//  PartyEvent.swift
//  TKParty
//
//  Created by GuoGongbin on 1/6/17.
//  Copyright © 2017 GuoGongbin. All rights reserved.
//

import Foundation
import UIKit
import MediaPlayer

class PartyEvent {
    // the name of this party event
    var name: String
    //description of this party event
//    var description: String?
    // organizer of this party
    var organizer: Person
    // the members of this party event
    var members: [Person]
    //the songs
    var songList: [Song]
    // the key which identifies a party event
    var partyEventKey: String?
    
    init(name: String, organizer: Person, songList: [Song]) {
        self.name = name
//        self.description = description
        self.organizer = organizer
        self.members = [organizer]
        self.songList = songList
        
        //for test reason, now just simply the initialization of partyEventReference
//        partyEventReference = name
    }
}
