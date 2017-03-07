//
//  Person.swift
//  TKParty
//
//  Created by GuoGongbin on 1/6/17.
//  Copyright © 2017 GuoGongbin. All rights reserved.
//

import Foundation
import UIKit
import MultipeerConnectivity

class Person: NSObject {
    //this person's name
    var name: String
    // this person's image profile
    var image: UIImage?
    // the party event this user is in
    var partyEventKey: String?
    
    var peer: MCPeerID?
    
    init(name: String, partyEventKey: String?, image: UIImage = UIImage(named: "profile1")!) {
        self.name = name
        self.image = image
        self.partyEventKey = partyEventKey
//        self.peer = peer
    }
    
}
