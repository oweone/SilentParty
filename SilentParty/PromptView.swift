//
//  PromptView.swift
//  TKParty
//
//  Created by GuoGongbin on 1/10/17.
//  Copyright © 2017 GuoGongbin. All rights reserved.
//

import UIKit

class PromptView: UIView {

    class func promptView(width: CGFloat, height: CGFloat, text: String) -> UIView {
        let promptHeight: CGFloat = 100
        let rect = CGRect(x: 0.25 * width, y: 0.5 * (height - promptHeight), width: 0.5 * width, height: promptHeight)
        let promptView = UIView(frame: rect)
        promptView.backgroundColor = UIColor.gray
        promptView.layer.cornerRadius = 5
        
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: 0.5 * width, height: promptHeight))
        label.text = text
        label.textColor = UIColor.white
        label.numberOfLines = 0
        
        label.textAlignment = .center
        promptView.addSubview(label)
        
        return promptView
    }
}

