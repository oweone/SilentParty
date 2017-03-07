//
//  Song.swift
//  TKParty
//
//  Created by GuoGongbin on 1/7/17.
//  Copyright © 2017 GuoGongbin. All rights reserved.
//
import UIKit
import AVFoundation

class Song {
    var name: String?
    var artist: String?
    var image: UIImage?
    var localUrl: URL?
    var voteValue: Int = 0
    
    init(localUrl: URL?) {
        
        self.localUrl = localUrl
        
        let asset = AVAsset(url: localUrl!)
        for metadataItem in asset.commonMetadata {
            if metadataItem.commonKey == "artwork" {
                self.image = UIImage(data: metadataItem.value as! Data)
            }
            if metadataItem.commonKey == "title" {
                self.name = metadataItem.value as! String?
            }
            if metadataItem.commonKey == "artist" {
                self.artist = metadataItem.value as! String?
            }
        }
    }
    
    func toAny() -> Any {
        return [
            "name": name,
            "artist": artist
        ]
    }
    
//    func setMusicArtwork(url: URL) {
//        let asset = AVAsset(url: url)
//        for metadataItem in asset.commonMetadata {
//            if metadataItem.commonKey == "artwork" {
//                imageView.image = UIImage(data: metadataItem.value as! Data)
//                return
//            }
//        }
//        imageView.image = UIImage(named: "default")
//    }
    
}
