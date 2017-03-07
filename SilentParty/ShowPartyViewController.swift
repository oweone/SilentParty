//
//  ShowPartyViewController.swift
//  TKParty
//
//  Created by GuoGongbin on 1/10/17.
//  Copyright © 2017 GuoGongbin. All rights reserved.
//
import UIKit
import MediaPlayer
import MultipeerConnectivity

class ShowPartyViewController: UIViewController {

    // MARK: properties
    @IBOutlet weak var elapsedTime: UILabel!
    @IBOutlet weak var duration: UILabel!
    @IBOutlet weak var progress: UISlider!
    @IBOutlet weak var songName: UILabel!
    @IBOutlet weak var albumArtist: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var songList: UIButton!
    @IBOutlet weak var previousButton: UIButton!
    @IBOutlet weak var playPausebutton: UIButton!
    @IBOutlet weak var nextButton: UIButton!
    
    var mediaPlayer: AVAudioPlayer!
    var partyEvent: PartyEvent!
    let SongListIdentifier = "ShowSongList"
    let MembersIdentifier = "ShowPartyEventDetail"
    let songListString = "songListString"
//    var nowPlayingSongIndex: Int?
    var mpcManager: MPCManager!
    var nowPlayingSong: Song?
    
    var timer: Timer!
    
    // MARK: initialization of party event
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        mpcManager = appDelegate.mpcManager
        mpcManager.partyEventDelegate = self

        if MusicPlayerSingleton.shared.isPartyOrganizer == true {
            mpcManager.advertiser.startAdvertisingPeer()
            enableButtons()
        }else{
            disableButtons()
        }
        
        progress.isContinuous = false
        
        partyEvent = MusicPlayerSingleton.shared.partyEvent
        mediaPlayer = MusicPlayerSingleton.shared.mediaPlayer
        nowPlayingSong = MusicPlayerSingleton.shared.nowPlayingSong
        
        if partyEvent != nil {
            OperationQueue.main.addOperation {
//                self.prepareAudio()
                self.checkPartyEvent()
            }
        }else{
            askForData()
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(ShowPartyViewController.handleMPCReceivedDataWithNotification(notification:)), name: Notification.Name("receivedMPCDataNotification"), object: nil)
        
    }
    
    func checkPartyEvent() {
        if MusicPlayerSingleton.shared.nowPlayingSong != nil {
            // the media player has been initialized.
            if mediaPlayer.isPlaying {
                print("playing: \(nowPlayingSong?.name), and the url is: \(mediaPlayer.url)")
                updateUI(song: nowPlayingSong!)
                updateElapsedTime(currentPlaybackTime: mediaPlayer.currentTime)
                setPlayPauseButtonWithPauseImage()
                startTimer()
            }
            if !mediaPlayer.isPlaying {
                print("paused:\(nowPlayingSong?.name)")
                print("meidaPlayer.currentPlaybackTime:\(mediaPlayer.currentTime)")
                updateUI(song: nowPlayingSong!)
                updateElapsedTime(currentPlaybackTime: mediaPlayer.currentTime)
                setPlayPauseButtonWithPlayImage()
            }
        }else{
            prepareAudio()
        }
    }
    
    
    func askForData() {
        let dataDictionary = [MessageType.askForSongList: MessageType.askForSongList]
        if mpcManager.sendData(dictionaryWithData: dataDictionary, toPeers: mpcManager.session.connectedPeers) {
            print("ask for data successfully")
        }
    }
    //task: need to deal members

    func handleMPCReceivedDataWithNotification(notification: NSNotification) {

        let receivedDictionary = notification.object as! [String: Any]
        let data = receivedDictionary["data"] as! Data
        let fromPeer = receivedDictionary["fromPeer"] as! MCPeerID
        let dataDictionary = NSKeyedUnarchiver.unarchiveObject(with: data) as! [String: Any]
        print("dataDictionary:\(dataDictionary)")
        
        // only the party organizer handle the reception of the message of requesting for song list
        if MusicPlayerSingleton.shared.isPartyOrganizer {
            if (dataDictionary[MessageType.askForSongList] as? String) != nil {
                let songNames = MusicPlayerSingleton.shared.partyEvent!.songList.map { $0.name! }
                let isPlaying = mediaPlayer.isPlaying ? 1 : 0
                let currentTime = mediaPlayer.currentTime
                let members = MusicPlayerSingleton.shared.partyEvent!.members.map { $0.name }
                let dataDictionary = [MessageType.returnedSongList: songNames, MessageType.isPlaying: isPlaying, MessageType.currentTime: currentTime, MessageType.Members: members] as [String : Any]
                // only send to the peer that has asked for song list
                if self.mpcManager.sendData(dictionaryWithData: dataDictionary, toPeers: mpcManager.session.connectedPeers) {
                    print("data sent successfully, dataDictionary: \(dataDictionary)")
                }
            }
        }
        
        if let songsArray = dataDictionary[MessageType.returnedSongList] as? [String] {
            // song list has been sent to this peer, need to initialize the partyEvent
            let partyname = fromPeer.displayName
            let organizer = Person(name: fromPeer.displayName, partyEventKey: nil)
            let songsPathArray = songsArray.map { Bundle.main.path(forResource: $0, ofType: ".mp3")! }
            let songsUrlArray = songsPathArray.map { URL(fileURLWithPath: $0) }
            let songList = songsUrlArray.map { Song(localUrl: $0) }
            partyEvent = PartyEvent(name: partyname, organizer: organizer, songList: songList)
            
//            var connectedPeers = mpcManager.session.connectedPeers.map { Person(name: $0.displayName, partyEventKey: nil) }
//            connectedPeers.append(MusicPlayerSingleton.shared.userOfThisDevice)
//            partyEvent.members = connectedPeers
            
            MusicPlayerSingleton.shared.partyEvent = partyEvent
            OperationQueue.main.addOperation {
                self.prepareAudio()
            }
        }
        if let addedSongs = dataDictionary[MessageType.AddedSongs] as? [String] {
            let songsPathArray = addedSongs.map { Bundle.main.path(forResource: $0, ofType: ".mp3")! }
            let songsUrlArray = songsPathArray.map { URL(fileURLWithPath: $0) }
            let songList = songsUrlArray.map { Song(localUrl: $0) }
            partyEvent.songList = partyEvent.songList + songList
            NotificationCenter.default.post(name: Notification.Name("SongListChange"), object: nil)
        }
        if let voteValues = dataDictionary[MessageType.VoteValues] as? [Int] {
            // update the partyEvent.songList voteValue
            for (index, value) in voteValues.enumerated() {
                partyEvent.songList[index].voteValue = partyEvent.songList[index].voteValue + value
            }
            sortSongList()
            //post notification
            NotificationCenter.default.post(name: Notification.Name("SongListVoteValuesChange"), object: nil)
            
//            if MusicPlayerSingleton.shared.isPartyOrganizer {
//                // send the updated values to other members
////                let songListUpdatedValues = partyEvent.songList.map { $0.voteValue }
//                let dataDictionary = [MessageType.VoteValues: voteValues]
//                if mpcManager.sendData(dictionaryWithData: dataDictionary, toPeers: mpcManager.session.connectedPeers) {
//                    print("data sent successfully from showPartyVeiwController, songListUpdatedValues: \(voteValues)")
//                }
//            }
        }
//        if let songListUpdatedValues = dataDictionary[MessageType.SongListUpdatedValues] as? [Int] {
//            // the songListUpdatedValues is from the organizer, so update the songList, and post a notification
//            for (index, value) in songListUpdatedValues.enumerated() {
//                partyEvent.songList[index].voteValue = value
//            }
//            NotificationCenter.default.post(name: Notification.Name("SongListUpdatedValuesChange"), object: nil)
//            
//        }
        
        if let members = dataDictionary[MessageType.Members] as? [String] {
            let partyMembers = members.map { Person(name: $0, partyEventKey: nil) }
            if partyEvent != nil {
                partyEvent.members = partyMembers
            }
        }
        
        if let isPlaying = dataDictionary[MessageType.isPlaying] as? Int{
            if isPlaying == 1 {
                OperationQueue.main.addOperation {
                    self.mediaPlayer.play()
                    self.setPlayPauseButtonWithPauseImage()
                    self.startTimer()
                }
            }else{
                OperationQueue.main.addOperation {
                    self.mediaPlayer.pause()
                    self.setPlayPauseButtonWithPlayImage()
                    self.stopTimer()
                }
            }
        }
        if let currentTime = dataDictionary[MessageType.currentTime] as? TimeInterval {
            OperationQueue.main.addOperation {
                self.updateElapsedTime(currentPlaybackTime: currentTime)
                // need to add adjustment to the currentTime due to network lag
                self.mediaPlayer.currentTime = currentTime + 1
                
            }
        }
        if let partyMemberName = dataDictionary[MessageType.MemberLeave] as? String {
            print("partyMember leave ")
            if partyMemberName == MusicPlayerSingleton.shared.userOfThisDevice.name {
                // this device is deleted, to be implemented
                disconnectFromPartyEvent()
                
            }
            if (partyEvent) != nil {
                for (index, member) in partyEvent.members.enumerated() {
                    if member.name == partyMemberName {
                        partyEvent.members.remove(at: index)
                        NotificationCenter.default.post(name: Notification.Name(rawValue: "PartyEventMemberLeave"), object: nil)
                        break
                    }
                }
            }
        }
        if let buttonTapped = dataDictionary[MessageType.ButtonTapped] as? String {
            switch buttonTapped {
            case MessageType.PlayPauseButton:
                playPausebutton.sendActions(for: .touchUpInside)
            case MessageType.NextButton:
                nextButton.sendActions(for: .touchUpInside)
            case MessageType.PreviousButton:
                previousButton.sendActions(for: .touchUpInside)
            default: break
            }
        }
    }
    
    func disconnectFromPartyEvent() {
        stopTimer()
        mediaPlayer.stop()
        mediaPlayer = AVAudioPlayer()
        
        OperationQueue.main.addOperation {
            _ = self.navigationController?.popToRootViewController(animated: true)
        }
        
        mpcManager.session.disconnect()
        
        MusicPlayerSingleton.shared.mediaPlayer.stop()
        MusicPlayerSingleton.shared.mediaPlayer = AVAudioPlayer()
//        MusicPlayerSingleton.shared.nowPlayingSongIndex = nil
        MusicPlayerSingleton.shared.nowPlayingSong = nil
        MusicPlayerSingleton.shared.partyEvent = nil
        MusicPlayerSingleton.shared.isPartyOrganizer = false
        MusicPlayerSingleton.shared.isInPartyEvent = false
    }

    // MARK: prepare the audio
    func prepareAudio() {
        if nowPlayingSong == nil {
            nowPlayingSong = partyEvent.songList[0]
        }
        
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
            try AVAudioSession.sharedInstance().setActive(true)
            if partyEvent == nil {
                print("party event is nil")
            }
            mediaPlayer = try AVAudioPlayer(contentsOf: nowPlayingSong!.localUrl!)
            
            
            mediaPlayer.delegate = self
            MusicPlayerSingleton.shared.mediaPlayer = mediaPlayer
            MusicPlayerSingleton.shared.nowPlayingSong = nowPlayingSong
        }catch let error as NSError {
            print(error.localizedDescription)
        }
        updateUI(song: nowPlayingSong!)
        updateElapsedTime(currentPlaybackTime: 0)
        print("prepareAudio method is called and the nowPlayingSongIndex is \(nowPlayingSong?.name)")
    }
    // MARK: update the UI
    // this method does not update the elapsedTime label, nor the progress.value
//    func updateUI(index: Int){
//        navigationItem.title = partyEvent.name
////        imageView.image = mediaItem.artwork?.image(at: imageView.frame.size)
//        setMusicArtwork(url: partyEvent.songList[index].localUrl!)
//        
//        let min: Int = Int(mediaPlayer.duration) / 60
//        let sec: Int = Int(mediaPlayer.duration) % 60
//        let minString = String(format: "%.2d", min)
//        let secString = String(format: "%.2d", sec)
////        elapsedTime.text = "00:00"
//        duration.text = minString + ":" + secString
//        
//        songName.text = partyEvent.songList[index].name
//        albumArtist.text = partyEvent.songList[index].artist
//        
////        progress.value = 0
//        progress.minimumValue = 0
//        progress.maximumValue = Float(mediaPlayer.duration)
//    }
    func updateUI(song: Song) {
        navigationItem.title = partyEvent.name
        
        let min: Int = Int(mediaPlayer.duration) / 60
        let sec: Int = Int(mediaPlayer.duration) % 60
        let minString = String(format: "%.2d", min)
        let secString = String(format: "%.2d", sec)
        //        elapsedTime.text = "00:00"
        duration.text = minString + ":" + secString
        
        songName.text = song.name
        albumArtist.text = song.artist
        setMusicArtwork(url: song.localUrl!)
        
        progress.minimumValue = 0
        progress.maximumValue = Float(mediaPlayer.duration)
    }
    func setMusicArtwork(url: URL) {
        let asset = AVAsset(url: url)
        for metadataItem in asset.commonMetadata {
            if metadataItem.commonKey == "artwork" {
                imageView.image = UIImage(data: metadataItem.value as! Data)
                return
            }
        }
        imageView.image = UIImage(named: "default")
    }
    // this method updates the elapsed time of the audio
    func updateElapsedTime(currentPlaybackTime: TimeInterval) {
        let min: Int = Int(currentPlaybackTime) / 60
        let sec: Int = Int(currentPlaybackTime) % 60
        let minString = String(format: "%.2d", min)
        let secString = String(format: "%.2d", sec)
        elapsedTime.text = minString + ":" + secString
        progress.value = Float(currentPlaybackTime)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == SongListIdentifier, let songListViewController = segue.destination as? SongListViewController {
            songListViewController.partyEvent = partyEvent
        }
        if segue.identifier == MembersIdentifier, let membersViewController = segue.destination as? MembersViewController {
            membersViewController.partyEvent = partyEvent
        }
    }

    //MARK: Handle button actions
    @IBAction func progressChanged(_ sender: UISlider) {
        mediaPlayer.currentTime = TimeInterval(sender.value)
    }
    //store the current mediaPlayer isPlaying property, if media player is playing, then when the previous button is tapped, the media player should play the previous song, otherwise should not.
    @IBAction func previousButtonTapped(_ sender: UIButton) {
        // it's not implemented because the song list order is controlled by party members. the currently playing song is always the first song in the songList.
//        if MusicPlayerSingleton.shared.isPartyOrganizer {
//            let dataDictionary = [MessageType.ButtonTapped: MessageType.PreviousButton]
//            if mpcManager.sendData(dictionaryWithData: dataDictionary, toPeers: mpcManager.session.connectedPeers) {
//                print("previousButtonTapped")
//            }
//        }
//        
//        let isPlaying = mediaPlayer.isPlaying
//        mediaPlayer.stop()
//        if nowPlayingSongIndex == 0 {
//            nowPlayingSongIndex = partyEvent.songList.count - 1
//        }else{
//            nowPlayingSongIndex = nowPlayingSongIndex! - 1
//        }
//        
//        OperationQueue.main.addOperation {
//            self.prepareAudio()
//            self.mediaPlayer.prepareToPlay()
//            if isPlaying {
//                self.mediaPlayer.play()
//            }
//        }
    }
    @IBAction func playPauseButtonTapped(_ sender: UIButton) {
        print("mediaPlayer.nowPlayingItem before update:\(nowPlayingSong?.name)")
        if MusicPlayerSingleton.shared.isPartyOrganizer {
            let dataDictionary = [MessageType.ButtonTapped: MessageType.PlayPauseButton]
            if mpcManager.sendData(dictionaryWithData: dataDictionary, toPeers: mpcManager.session.connectedPeers) {
                print("playPauseButtonTapped")
            }
        }
        
        if mediaPlayer.isPlaying {
            mediaPlayer.pause()
            OperationQueue.main.addOperation {
                self.setPlayPauseButtonWithPlayImage()
                self.stopTimer()
            }
            
        }else{
            mediaPlayer.play()
            OperationQueue.main.addOperation {
                self.setPlayPauseButtonWithPauseImage()
                self.startTimer()
            }
        }
    }
    
    @IBAction func nextButtonTapped(_ sender: UIButton) {
        if MusicPlayerSingleton.shared.isPartyOrganizer {
            let dataDictionary = [MessageType.ButtonTapped: MessageType.NextButton]
            if mpcManager.sendData(dictionaryWithData: dataDictionary, toPeers: mpcManager.session.connectedPeers) {
                print("nextButtonTapped")
            }
        }
        
        nextSong()
    }
    func nextSong() {
        print("nextButtonTapped from nextSong method")
        let isPlaying = mediaPlayer.isPlaying
        mediaPlayer.stop()

        if partyEvent.songList.count > 1 {
            nowPlayingSong = partyEvent.songList[1]
            MusicPlayerSingleton.shared.nowPlayingSong = nowPlayingSong
            let removedSong = partyEvent.songList.removeFirst()
            partyEvent.songList.append(removedSong)
            partyEvent.songList.last?.voteValue = 0
            NotificationCenter.default.post(name: Notification.Name("PartyEventSongListChange"), object: nil)
        }
        
        OperationQueue.main.addOperation {
            self.prepareAudio()
            self.mediaPlayer.prepareToPlay()
            if isPlaying {
                self.mediaPlayer.play()
            }
        }
        
        print("mediaPlayer.nowPlayingItem from next:\(nowPlayingSong?.name)")
        print("number of channels: \(mediaPlayer.numberOfChannels)")
    }
    
    
    // MARK:  start and stop timer
    func startTimer() {
        if timer != nil {
            timer.invalidate()
        }
        timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(ShowPartyViewController.updateProgress(timer:)), userInfo: nil, repeats: true)
    }
    
    func stopTimer() {
        if timer != nil {
            timer.invalidate()
        }
    }
    
    func updateProgress(timer: Timer) {
        if nowPlayingSong != nil {
            let currentPlaybackTime = mediaPlayer.currentTime
            let min: Int = Int(currentPlaybackTime) / 60
            let sec: Int = Int(currentPlaybackTime) % 60
            let minString = String(format: "%.2d", min)
            let secString = String(format: "%.2d", sec)
            elapsedTime.text = minString + ":" + secString
            OperationQueue.main.addOperation {
                self.progress.value = Float(currentPlaybackTime)
            }
        }
    }
    // MARK: set button image
    func setPlayPauseButtonWithPauseImage() {
        playPausebutton.setBackgroundImage(UIImage(named:"pause"), for: .normal)
    }
    func setPlayPauseButtonWithPlayImage() {
        playPausebutton.setBackgroundImage(UIImage(named: "play"), for: .normal)
    }
    //MARK: enable or disable buttons
    func enableButtons() {
        previousButton.isEnabled = true
        playPausebutton.isEnabled = true
        nextButton.isEnabled = true
        progress.isEnabled = true
    }
    func disableButtons() {
        previousButton.isEnabled = false
        playPausebutton.isEnabled = false
        nextButton.isEnabled = false
        progress.isEnabled = false
    }
    
    // MARK: helper method
    func sortSongList() {
        // set the first song's voteValue to the Int.max, so that it is always on the top
        partyEvent.songList[0].voteValue = Int.max
        let sortedSongs = partyEvent.songList.sorted(by: { (song1, song2) -> Bool in
            if song1.voteValue > song2.voteValue {
                return true
            }else{
                return false
            }
        })
        partyEvent.songList = sortedSongs
    }
}
extension ShowPartyViewController: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        print("flag: \(flag)")
        if flag {
            // if partyEvent.songList.count == 1
            mediaPlayer.stop()
            if partyEvent.songList.count == 1 {
                nowPlayingSong = partyEvent.songList[0]
            }else{
                nowPlayingSong = partyEvent.songList[1]
                let removedSong = partyEvent.songList.removeFirst()
                partyEvent.songList.append(removedSong)
                partyEvent.songList.last?.voteValue = 0
                NotificationCenter.default.post(name: Notification.Name("PartyEventSongListChange"), object: nil)
            }
            MusicPlayerSingleton.shared.nowPlayingSong = nowPlayingSong
            
            OperationQueue.main.addOperation {
                self.prepareAudio()
                self.mediaPlayer.prepareToPlay()
                self.mediaPlayer.play()
            }
        }
    }
}
extension ShowPartyViewController: MPCManagerPartyEventDelegate {
    func invitationWasReceived(fromPeer: String) {
        print("invitationWasReceived:\(mpcManager.session.myPeerID.displayName)")
        
        let alert = UIAlertController(title: nil, message: "\(fromPeer) wants to join your party!", preferredStyle: .alert)
        
        let accept = UIAlertAction(title: "Accept", style: .default, handler: { action in
            //this method is called on invitee's device, so the self.appDelegate.mpcManager.session is from invitee's device
            self.mpcManager.invitationHandler(true, self.mpcManager.session)
            
        })
        let decline = UIAlertAction(title: "Decline", style: .default, handler: { action in
            self.mpcManager.invitationHandler(false, nil)
        })
        alert.addAction(accept)
        alert.addAction(decline)
        
        OperationQueue.main.addOperation { () -> Void in
            self.present(alert, animated: true, completion: nil)
        }
    }
    func partyEventOrganizerLeft() {
        disconnectFromPartyEvent()
    }
}
