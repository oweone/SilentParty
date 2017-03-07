//
//  MessageType.swift
//  SilentParty
//
//  Created by GuoGongbin on 2/3/17.
//  Copyright © 2017 GuoGongbin. All rights reserved.
//

import Foundation

struct MessageType {
    static let MemberLeave = "MemberLeave"
    static let DeleteParty = "DeleteParty"
    static let isPlaying = "isPlaying"
    static let currentTime = "currentTime"
    static let returnedSongList = "returnedSongList"
    static let askForSongList = "askForSongList"
    static let Members = "Members"
    static let ButtonTapped = "ButtonTapped"
    static let PlayPauseButton = "PlayPauseButton"
    static let NextButton = "NextButton"
    static let PreviousButton = "PreviousButton"
    static let VoteValues = "VoteValues"
    static let SongListUpdatedValues = "SongListUpdatedValues"
    static let AddedSongs = "AddedSongs"
}
