//
//  AddSongsTableViewController.swift
//  TKParty
//
//  Created by GuoGongbin on 1/21/17.
//  Copyright © 2017 GuoGongbin. All rights reserved.
//

import UIKit

class AddSongsTableViewController: UITableViewController {

    let CellIdentifier = "SongCell"
    var alreadySelectedSongs: [Song]?
    var selectedSongs = [Song]()
    var songList = [Song]()
    var partyEvent: PartyEvent!
    var mpcManager: MPCManager!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        songList = songsArray
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        mpcManager = appDelegate.mpcManager
        
    }

    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let songListViewController = segue.destination as? SongListViewController {
            if alreadySelectedSongs == nil {
                alreadySelectedSongs = []
            }
            print("partyevent.songlist.count original: \(partyEvent.songList.count)")
            //selectedSongs could be empty. so update operation is not done here. It's done in SongListViewController.
            songListViewController.partyEvent.songList = alreadySelectedSongs! + selectedSongs
            print("partyevent.songlist.count after: \(partyEvent.songList.count)")
            //update other members' songList
            //send the updated songList to other members
            //            let songListUpdatedValues = partyEvent.songList.map { $0.voteValue }
            
            let addedSongs = selectedSongs.map { $0.name! }
            let dataDictionary = [MessageType.AddedSongs: addedSongs]
            if mpcManager.sendData(dictionaryWithData: dataDictionary, toPeers: mpcManager.session.connectedPeers) {
                print("data sent successfully, songListUpdatedValues: \(addedSongs)")
            }
            
        }
    }
    @IBAction func cancel(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return songList.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: CellIdentifier, for: indexPath)
        let song = songList[indexPath.row]
        
        cell.textLabel?.text = song.name
        cell.detailTextLabel?.text = song.artist
        //        cell.imageView?.image = mediaItem.artwork?.image(at: (cell.imageView?.bounds.size)!)
        
        
        let hasThis = selectedSongs.contains(where: { item in
            if item.name == song.name {
                return true
            }else{
                return false
            }
        })
        if hasThis {
            cell.accessoryType = .checkmark
        }else{
            cell.accessoryType = .none
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath)
        let song = songList[indexPath.row]
        
        //does not deal with the repetition of the same song
        selectedSongs.append(song)
        cell?.accessoryType = .checkmark
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
