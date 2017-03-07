//
//  SongsTableViewController.swift
//  SilentParty
//
//  Created by GuoGongbin on 1/25/17.
//  Copyright © 2017 GuoGongbin. All rights reserved.
//

import UIKit

class SongsTableViewController: UITableViewController {
    
    let CellIdentifier = "SongCell"
    var alreadySelectedSongs: [Song]?
    var selectedSongs = [Song]()
    var songList = [Song]()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        songList = songsArray
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if let createPartyViewController = segue.destination as? CreatePartyViewController {
            if alreadySelectedSongs == nil {
                alreadySelectedSongs = []
            }
            createPartyViewController.selectedSongs = alreadySelectedSongs! + selectedSongs
        }
    }

    @IBAction func cancel(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
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
        cell.imageView?.image = song.image
        
        
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
 

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
