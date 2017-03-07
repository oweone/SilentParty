//
//  PartyEventsTableViewController.swift
//  TKParty
//
//  Created by GuoGongbin on 1/7/17.
//  Copyright © 2017 GuoGongbin. All rights reserved.
//

import UIKit
import MultipeerConnectivity

class PartyEventsTableViewController: UITableViewController {
    
    var mpcManager: MPCManager!
//    var partyPeers = [MCPeerID]()
    var filteredPartyPeers: [MCPeerID]!
    

    let CellIdentifier = "PartyEventCell"
    let ShowPartyIdentifier = "ShowParty"
    var searchController: UISearchController!
//    var partyEvents = [PartyEvent]()
//    var filteredPartyEvents: [PartyEvent]!

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        mpcManager = appDelegate.mpcManager
        mpcManager.delegate = self
        
        //get party peers nearby
        loadPartyPeers()
        
        // only used for test reasons
//        MusicPlayerSingleton.shared.partyPeer = mpcManager.peer
        
        //configure the leftBarButton
        configureLeftBarButton()

        
        searchController = UISearchController(searchResultsController: nil)
        searchController.searchResultsUpdater = self
        
        searchController.dimsBackgroundDuringPresentation = false
        definesPresentationContext = true
        
        tableView.tableHeaderView = searchController.searchBar
        refreshControl = UIRefreshControl()
        refreshControl?.addTarget(self, action: #selector(PartyEventsTableViewController.updateDataSource(refreshControle:)), for: .valueChanged)
        
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
    }
    
    //MARK: initial configuration
    func configureLeftBarButton() {
        let image = UIImage(named: "player")
        let button = UIButton(type: .custom)
        button.setImage(image, for: .normal)
        button.frame = CGRect(x: 0, y: 0, width: 40, height: 40)
        button.addTarget(self, action: #selector(PartyEventsTableViewController.leftBarButtonTapped), for: .touchUpInside)
        let barButton = UIBarButtonItem(customView: button)
        self.navigationItem.leftBarButtonItem = barButton
    }
    
    
    func loadPartyPeers() {
        mpcManager.browser.startBrowsingForPeers()
        
    }
    
    func updateDataSource(refreshControle: UIRefreshControl) {
//        partyEvents = temporaryPartyEvents
        tableView.reloadData()
        refreshControl?.endRefreshing()
    }
    func leftBarButtonTapped() {
        let partyEvent = MusicPlayerSingleton.shared.partyEvent
        if partyEvent == nil {
            let promptView = PromptView.promptView(width: self.view.frame.width, height: self.view.frame.height, text: "Please join a party event first!")
            self.view.addSubview(promptView)
            promptView.alpha = 0
            
            let animation = CABasicAnimation(keyPath: "opacity")
            animation.fromValue = 0
            animation.toValue = 1
            animation.duration = 2.5
            animation.autoreverses = true
            animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionDefault)
            promptView.layer.add(animation, forKey: "opacity")
        }else{
            // to be implemented
            performSegue(withIdentifier: ShowPartyIdentifier, sender: nil)
            
        }  
    }
    
     // MARK: - Navigation

    // to be completed
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == ShowPartyIdentifier, let showPartyViewController = segue.destination as? ShowPartyViewController {
            // could be nil, it's checked in WhowPartyViewController
            showPartyViewController.partyEvent = MusicPlayerSingleton.shared.partyEvent
            
//            if let indexPath = tableView.indexPathForSelectedRow {
//                var partyPeer: MCPeerID
//                if searchController.isActive && searchController.searchBar.text != "" {
//                    partyPeer = filteredPartyPeers[indexPath.row]
//                }else{
//                    partyPeer = mpcManager.foundPeers[indexPath.row]
//                }
//                showPartyViewController.partyEvent = MusicPlayerSingleton.shared.partyEvent
//            }else{
////                showPartyViewController.partyEvent = MusicPlayerSingleton.shared.partyEvent
//            }
        }
     }
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if searchController.isActive && searchController.searchBar.text != "" {
            return filteredPartyPeers.count
        }
        return mpcManager.foundPeers.count
//        return partyPeers.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: CellIdentifier, for: indexPath)
        var partyPeer: MCPeerID
        if searchController.isActive && searchController.searchBar.text != "" {
            partyPeer = filteredPartyPeers[indexPath.row]
        }else{
            partyPeer = mpcManager.foundPeers[indexPath.row]
        }
        
        cell.textLabel?.text = partyPeer.displayName
//        cell.detailTextLabel?.text = partyEvent.description
        
        return cell
    }
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedPeer = mpcManager.foundPeers[indexPath.row]
        mpcManager.browser.invitePeer(selectedPeer, to: mpcManager.session, withContext: nil, timeout: 20)
    }

    func filter(searchText: String) {
        filteredPartyPeers = mpcManager.foundPeers.filter { partyPeer in
            return partyPeer.displayName.lowercased().contains(searchText.lowercased())
        }
        tableView.reloadData()
    }
}
extension PartyEventsTableViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        filter(searchText: searchController.searchBar.text!)
    }
}
extension PartyEventsTableViewController: MPCManagerDelegate {
    func foundPeer() {
        tableView.reloadData()
    }
    func lostPeer() {
        tableView.reloadData()
    }
    func connectedWithPeer(peerID: MCPeerID) {
        OperationQueue.main.addOperation({
            let ShowPartyIdentifier = "ShowParty"
            if MusicPlayerSingleton.shared.isInPartyEvent == false {
                self.performSegue(withIdentifier: ShowPartyIdentifier, sender: self)
                MusicPlayerSingleton.shared.isInPartyEvent = true
            }
        })
        
    }
}
