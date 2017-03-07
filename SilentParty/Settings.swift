//
//  Settings.swift
//  TKParty
//
//  Created by GuoGongbin on 1/8/17.
//  Copyright © 2017 GuoGongbin. All rights reserved.
//
import Foundation
import MediaPlayer
import MultipeerConnectivity

//var person = Person(name: "anonymous")
//let person1 = Person(name: "person1")
//let person2 = Person(name: "person2")
//let person3 = Person(name: "person3")
//let person4 = Person(name: "person4")
//let person5 = Person(name: "person5")
//
let songName1 = "No Heart"
let songName2 = "X"
let songName3 = "Water Under the Bridge"
let songName4 = "Scars To Your Beautiful"
let songName5 = "Broccoli"
let songName6 = "Hide Away"
let songName7 = "Sit Still, Look Pretty"
let songName8 = "i hate u i love u"
let songName9 = "All Time Low"
let songName10 = "Better Man"
let songName11 = "Unsteady"
let songName12 = "Ooouuu"

let songNamesArray = [songName1, songName2, songName3, songName4, songName5, songName6, songName7, songName8, songName9, songName10, songName11, songName12]

let path = Bundle.main.path(forResource: songName12, ofType: ".mp3")
let songPathsArray = songNamesArray.map { return Bundle.main.path(forResource: $0, ofType: ".mp3")! }
let songURLsArray = songPathsArray.map { return URL(fileURLWithPath: $0) }
let songsArray = songURLsArray.map { return Song(localUrl: $0) }

//MusicPlayerSingleton.shared.partyPeer = peer
