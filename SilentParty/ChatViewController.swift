//
//  ChatViewController.swift
//  SilentParty
//
//  Created by GuoGongbin on 2/12/17.
//  Copyright © 2017 GuoGongbin. All rights reserved.
//

import UIKit
import MultipeerConnectivity
import JSQMessagesViewController

class ChatViewController: JSQMessagesViewController {
    
    var mpcChatManager: MPCChatManager!
    
    lazy var outgoingBubbleImageView: JSQMessagesBubbleImage = self.setupOutgoingBubble()
    lazy var incomingBubbleImageView: JSQMessagesBubbleImage = self.setupIncomingBubble()

    var messages = [JSQMessage]()

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        mpcChatManager = appDelegate.mpcChatManager
        
        self.senderId = MusicPlayerSingleton.shared.userOfThisDevice.name
        self.senderDisplayName = MusicPlayerSingleton.shared.userOfThisDevice.name
     
        NotificationCenter.default.addObserver(self, selector: #selector(self.handleMPCReceivedChatDataWithNotification(notification:)), name: NSNotification.Name("receivedMPCChatDataNotification"), object: nil)
    }
    // MARK: quit the chat
    @IBAction func cancel(_ sender: UIBarButtonItem) {
        let messageDictionary: [String: String] = ["senderId": senderId!,
                                                   "senderName": senderDisplayName!,
                                                   "text": "_end_chat_"]
        if mpcChatManager.sendData(dictionaryWithData: messageDictionary, toPeer: mpcChatManager.session.connectedPeers[0] as MCPeerID){
            self.dismiss(animated: true, completion: { () -> Void in
                self.mpcChatManager.session.disconnect()
            })
        }
    }
    // MARK: send and receive data method
    override func didPressSend(_ button: UIButton!, withMessageText text: String!, senderId: String!, senderDisplayName: String!, date: Date!) {
        let messageItem = [
            "senderId": senderId!,
            "senderName": senderDisplayName!,
            "text": text!
            ]
        
        if mpcChatManager.sendData(dictionaryWithData: messageItem, toPeer: mpcChatManager.session.connectedPeers[0]) {
//            let dictionary = ["sender": "self", "message": textField.text!]
//            messagesArray.append(dictionary)
            print("messageItem sent successfully: \(messageItem)")
            self.addMessage(withId: senderId, name: senderDisplayName, text: text)
            
//            self.updateTableView()
        }else{
            print("Could not send data")
        }
        
        
        JSQSystemSoundPlayer.jsq_playMessageSentSound() // 4
        
        finishSendingMessage() // 5
    }
    func handleMPCReceivedChatDataWithNotification(notification: Notification) {
        let receivedDictionary = notification.object as! [String: Any]
        let data = receivedDictionary["data"] as! Data
        let fromPeer = receivedDictionary["fromPeer"] as! MCPeerID
        
        let dataDictionary = NSKeyedUnarchiver.unarchiveObject(with: data) as! [String: Any]
        
        print("dataDictionary: \(dataDictionary)")
        
        if let id = dataDictionary["senderId"] as? String, let name = dataDictionary["senderName"] as? String, let text = dataDictionary["text"] as? String, text.characters.count > 0 {
            if text == "_end_chat_" {
                let alert = UIAlertController(title: "", message: "\(fromPeer.displayName) ended this chat.", preferredStyle: .alert)
                
                let doneAction: UIAlertAction = UIAlertAction(title: "Okay", style: .default) { (alertAction) -> Void in
                    self.mpcChatManager.session.disconnect()
                    self.dismiss(animated: true, completion: nil)
                }
                
                alert.addAction(doneAction)
                
                OperationQueue.main.addOperation{
                    self.present(alert, animated: true, completion: nil)
                }
            }else{
                print("received data ")

                OperationQueue.main.addOperation {
                    self.addMessage(withId: id, name: name, text: text)
                }
                
                self.finishReceivingMessage()
                OperationQueue.main.addOperation {
                    self.collectionView.reloadData()
                }
            }
            
        }else{
            print("Error! Could not decode message data")
        }
    }
    func updateTableView() {
        self.collectionView.reloadData()
    }
    
    
//    func observeMessages() {
//        
//        let newMessageRefHandle = messagesRef.queryLimited(toLast: 25)
//        newMessageRefHandle.observe(.childAdded, with: { snapshot in
//            let messageData = snapshot.value as! Dictionary<String, String>
//            if let id = messageData["senderId"] as String!, let name = messageData["senderName"] as String!, let text = messageData["text"] as String!, text.characters.count > 0 {
//                self.addMessage(withId: id, name: name, text: text)
//                print("self.addMessage: \(id), \(name), \(text)")
//                self.finishReceivingMessage()
//            }else {
//                print("Error! Could not decode message data")
//            }
//        })
//    }
    private func addMessage(withId id: String, name: String, text: String) {
        if let message = JSQMessage(senderId: id, displayName: name, text: text) {
            messages.append(message)
        }
    }
    
    // MARK: Collection view data source (and related) methods
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = super.collectionView(collectionView, cellForItemAt: indexPath) as! JSQMessagesCollectionViewCell
        let message = messages[indexPath.item]
        
        if message.senderId == senderId {
            cell.textView?.textColor = UIColor.white
        } else {
            cell.textView?.textColor = UIColor.black
        }
        return cell
    }
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, messageDataForItemAt indexPath: IndexPath!) -> JSQMessageData! {
        return messages[indexPath.item]
    }
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return messages.count
    }
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, messageBubbleImageDataForItemAt indexPath: IndexPath!) -> JSQMessageBubbleImageDataSource! {
        let message = messages[indexPath.item]
        if senderId == message.senderId {
            return outgoingBubbleImageView
        }else{
            return incomingBubbleImageView
        }
    }
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, avatarImageDataForItemAt indexPath: IndexPath!) -> JSQMessageAvatarImageDataSource! {
        return nil
    }
    
    // MARK: UI and User Interaction
    func setupOutgoingBubble() -> JSQMessagesBubbleImage {
        let bubbleImageFactory = JSQMessagesBubbleImageFactory()
        return bubbleImageFactory!.outgoingMessagesBubbleImage(with: UIColor.jsq_messageBubbleBlue())
    }
    private func setupIncomingBubble() -> JSQMessagesBubbleImage {
        let bubbleImageFactory = JSQMessagesBubbleImageFactory()
        return bubbleImageFactory!.incomingMessagesBubbleImage(with: UIColor.jsq_messageBubbleLightGray())
    }
}
