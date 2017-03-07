//
//  SettingsViewController.swift
//  TKParty
//
//  Created by GuoGongbin on 1/19/17.
//  Copyright © 2017 GuoGongbin. All rights reserved.
//

import UIKit

class SettingsViewController: UIViewController {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var downloadedImageView: UIImageView!
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
//    @IBAction func download(_ sender: UIButton) {
//        let name = MusicPlayerSingleton.shared.userOfThisDevice.name
//        let childImageRef = Settings.ImageStorageReference.child(name)
//        
//        let directories = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
//        let documentDirectory = directories[0]
//        let fileUrl = documentDirectory.appendingPathComponent("\(name).jpg")
//        
//        childImageRef.write(toFile: fileUrl, completion: { (url, error) in
//            if let error = error {
//                print("download error:\(error)")
//            }else{
//                print("download success")
//                self.downloadedImageView.image = UIImage(contentsOfFile: fileUrl.path)
//            }
//        })
//        
//    }
    @IBAction func imageViewTapped(_ sender: UITapGestureRecognizer) {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            let cameraAction = UIAlertAction(title: "Camera", style: .default, handler: { action in
                let imagePicker = UIImagePickerController()
                imagePicker.sourceType = .camera
                imagePicker.delegate = self
                self.present(imagePicker, animated: true, completion: nil)
            })
            alert.addAction(cameraAction)
        }
        
        let photoAction = UIAlertAction(title: "from photos", style: .default, handler: { action in
            let imagePicker = UIImagePickerController()
            imagePicker.sourceType = .photoLibrary
            imagePicker.delegate = self
            self.present(imagePicker, animated: true, completion: nil)
        })
        alert.addAction(photoAction)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alert.addAction(cancelAction)
        present(alert, animated: true, completion: nil)
    }

}
extension SettingsViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
//    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
//        let selectedPhoto = info[UIImagePickerControllerOriginalImage] as! UIImage
//        imageView.image = selectedPhoto
//        let imageName = MusicPlayerSingleton.shared.userOfThisDevice.name
//        let childImageRef = Settings.ImageStorageReference.child(imageName)
//        let imageData = UIImageJPEGRepresentation(selectedPhoto, 1.0)
//        let metaData = FIRStorageMetadata()
//        metaData.contentType = "image/jpeg"
//        childImageRef.put(imageData!, metadata: metaData, completion: { (metadata, error) in
//            if let error = error {
//                print("uploading user image error: \(error)")
//            }else{
//                print("uploading user image success")
////                childPersonRef.setValue(personAny)
//                self.dismiss(animated: true, completion: nil)
//            }
//        })
//    }
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
}
