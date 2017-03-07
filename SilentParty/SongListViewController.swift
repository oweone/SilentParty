//
//  SongListViewController.swift
//  TKParty
//
//  Created by GuoGongbin on 1/10/17.
//  Copyright © 2017 GuoGongbin. All rights reserved.
//

import UIKit
import CoreMotion

class SongListViewController: UIViewController {

    // MARK: properties
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var danceValueLabel: UILabel!
    @IBOutlet weak var startStopButton: UIButton!
    @IBOutlet weak var pickerView: UIPickerView!
    @IBOutlet weak var submitButton: UIButton!
    @IBOutlet weak var assignCommitButton: UIButton!
    
    let SegueIdentifier = "AddSongsFromParty"
    var partyEvent: PartyEvent!
    let CellIdentifier = "SongCell"
    let manager = CMMotionManager()
    var buttonTitleIsStart = true
//    var votingValues: [Double]!
    var danceValue: Int = 0
    
    var mpcManager: MPCManager!
    var voteValues = [Int]()
    
    //
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.dataSource = self
        tableView.delegate = self
        tableView.allowsMultipleSelection = false
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        mpcManager = appDelegate.mpcManager
        
        buttonTitleIsStart = true
        configureStartStopButton()
        configureAssignCommitButton()
        
        danceValueLabel.text = "\(danceValue)"
        //when a song is finished, the table view is updated automatically
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(SongListViewController.handleSongListChangeNotification(notification:)), name: Notification.Name("PartyEventSongListChange"),
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(SongListViewController.handleSongListVoteValuesChange(notification:)), name: Notification.Name("SongListVoteValuesChange"),
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(SongListViewController.handleSongListVoteValuesChange(notification:)), name: Notification.Name("SongListUpdatedValuesChange"),
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(SongListViewController.handleSongListChange(notification:)),
                                               name: Notification.Name("SongListChange"),
                                               object: nil)
        
        //picker view
        pickerView.dataSource = self
        pickerView.delegate = self
        
        // test
        pickerView.selectRow(5, inComponent: 0, animated: true)
        
        voteValues = Array(repeating: 0, count: partyEvent.songList.count)
        
    }
    // MARK: handle SongList Change Notification
    func handleSongListChangeNotification(notification: Notification) {
        let from = IndexPath(row: 0, section: 0)
        let to = IndexPath(row: partyEvent.songList.count - 1, section: 0)
        tableView.moveRow(at: from, to: to)
        tableView.reloadData()
    }
    func handleSongListVoteValuesChange(notification: Notification){
        OperationQueue.main.addOperation {
            self.tableView.reloadData()
        }
    }
    func handleSongListChange(notification: Notification) {
        OperationQueue.main.addOperation {
            self.tableView.reloadData()
        }
    }

    // MARK: IBAction methods
    
    @IBAction func commitButtonTapped(_ sender: UIButton) {
        
        var hasChanged = false
        for value in voteValues {
            if value != 0 {
                hasChanged = true
                break
            }
        }
        
        if !hasChanged {
            //                tableView.isUserInteractionEnabled = false
            // no value can be used for voting, show the prompt message
            let promptView = PromptView.promptView(width: self.view.frame.width, height: self.view.frame.height, text: "You haven't changed the vote values!")
            self.view.addSubview(promptView)
            promptView.alpha = 0
            
            let animation = CABasicAnimation(keyPath: "opacity")
            animation.fromValue = 0
            animation.toValue = 1
            animation.duration = 2.5
            animation.autoreverses = true
            animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionDefault)
            promptView.layer.add(animation, forKey: "opacity")
            return
        }
        
        //commit the values to the organizer
        print("values: \(voteValues)")
        
        for (index, value) in voteValues.enumerated() {
            partyEvent.songList[index].voteValue = partyEvent.songList[index].voteValue + value
        }
        //sort the songList according to the voteValue
        sortSongList()
        tableView.reloadData()
        //send the updated songList to other members
        //            let songListUpdatedValues = partyEvent.songList.map { $0.voteValue }
        let dataDictionary = [MessageType.VoteValues: voteValues]
        if mpcManager.sendData(dictionaryWithData: dataDictionary, toPeers: mpcManager.session.connectedPeers) {
            print("data sent successfully, songListUpdatedValues: \(voteValues)")
        }
        
//        if MusicPlayerSingleton.shared.isPartyOrganizer {
//            // deal with this votingValues here, no need to send to other members, but after committing the values, need to send to other members to update other members songList
//            
//        }else{
//            // send this array to the organizer
//            let dataDictionary = [MessageType.VoteValues: voteValues]
//            if mpcManager.sendData(dictionaryWithData: dataDictionary, toPeers: mpcManager.session.connectedPeers) {
//                print("data sent successfully, votingValues: \(voteValues)")
//            }
//        }
    }

    // when the button's title is start dancing
    @IBAction func startStopButtonTapped(_ sender: UIButton) {
        buttonTitleIsStart = !buttonTitleIsStart
        configureStartStopButton()
        if !buttonTitleIsStart {
            
            var s = 0
            
            if manager.isAccelerometerAvailable {
                manager.accelerometerUpdateInterval = 1
                manager.startAccelerometerUpdates(to: OperationQueue.main, withHandler: {(data, error) in
                    if let error = error {
                        print("accelerometer error: \(error)")
                    }else{
                        let x: Double = abs(data!.acceleration.x)
                        let y: Double = abs(data!.acceleration.y)
                        let z: Double = abs(data!.acceleration.z)
                        s += Int(1 + 5 * (x + y + z)) - 6
                        self.danceValueLabel.text = "dance value: \(s)"
                        if s >= 100 {
                            s = 0
                            self.danceValueLabel.text = "dance value: 100"
                            let selectedRow = self.pickerView.selectedRow(inComponent: 0)
                            self.pickerView.selectRow(selectedRow + 1, inComponent: 0, animated: true)
//                            self.tableView.isUserInteractionEnabled = true
                        }
                    }
                })
            }
        }else{
            manager.stopAccelerometerUpdates()
        }
    }
    // MARK: Segues
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == SegueIdentifier, let naviController = segue.destination as? UINavigationController  {
            let addSongsTableViewController = naviController.topViewController as! AddSongsTableViewController
            addSongsTableViewController.alreadySelectedSongs = partyEvent.songList
            addSongsTableViewController.partyEvent = partyEvent
        }
    }
    
    @IBAction func goToSongLstViewController(segue: UIStoryboardSegue) {
        // added songs are download in showPartyViewController.
        self.tableView.reloadData()
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

    // MARK: configure the two buttons
    func configureStartStopButton() {
        startStopButton.setTitleColor(UIColor.black, for: .normal)
        startStopButton.layer.cornerRadius = 5
        startStopButton.clipsToBounds = true
        if buttonTitleIsStart {
            startStopButton.backgroundColor = UIColor.green
            startStopButton.setTitle("Start Dancing", for: .normal)
            buttonTitleIsStart = true
        }else{
            startStopButton.backgroundColor = UIColor.red
            startStopButton.setTitle("Stop Dancing", for: .normal)
            buttonTitleIsStart = false
        }
    }
    func configureAssignCommitButton() {
        assignCommitButton.setTitleColor(UIColor.black, for: .normal)
        assignCommitButton.layer.cornerRadius = 5
        assignCommitButton.clipsToBounds = true
        assignCommitButton.backgroundColor = UIColor.green
    }
}

extension SongListViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return partyEvent.songList.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: CellIdentifier, for: indexPath) as! SongTableViewCell
        let song = partyEvent.songList[indexPath.row]
        cell.songNameLabel.text = song.name
        cell.artistLabel.text = song.artist
        cell.artwork.image = song.image
        cell.value.text = "\(song.voteValue)"
        
        if indexPath.row == 0 {
            cell.value.isHidden = true
        }else{
            cell.value.isHidden = false
        }
        
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedRow = pickerView.selectedRow(inComponent: 0)
        if selectedRow != 0 {
            if indexPath.row != 0 {
                voteValues[indexPath.row] = voteValues[indexPath.row] + 1
                if let cell = tableView.cellForRow(at: indexPath) as? SongTableViewCell {
                    cell.value.text = "\(partyEvent.songList[indexPath.row].voteValue + voteValues[indexPath.row])"
                }
                
                pickerView.selectRow(selectedRow - 1, inComponent: 0, animated: true)
            }
        }else{
            // no value can be used for voting, show the prompt message
            let promptView = PromptView.promptView(width: self.view.frame.width, height: self.view.frame.height, text: "Please dance to get vote values")
            self.view.addSubview(promptView)
            promptView.alpha = 0
            
            let animation = CABasicAnimation(keyPath: "opacity")
            animation.fromValue = 0
            animation.toValue = 1
            animation.duration = 2.5
            animation.autoreverses = true
            animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionDefault)
            promptView.layer.add(animation, forKey: "opacity")
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
}
extension SongListViewController: UIPickerViewDelegate, UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return 50
    }
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return "\(row)"
    }
}
