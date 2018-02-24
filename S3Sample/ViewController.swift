//
//  ViewController.swift
//  S3Sample
//
//  Created by Kalyan Parise on 17/02/18.
//  Copyright © 2018 kalyan. All rights reserved.
//

import UIKit
import AWSS3


class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    @IBOutlet weak var selectedImageView: UIImageView!
    override func viewDidLoad() {
        super.viewDidLoad()
       
        
        self.title = "S3Upload"
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    func getCurrentMillis()->Int64 {
        return Int64(Date().timeIntervalSince1970 * 1000)
    }
    
    
    func uploadData(image: UIImage) {
      //  let img = UIImage(named: "bob.jpg") // to upload the image from the project folder
        let data:Data = UIImagePNGRepresentation(image)!
        // let data: Data = Data() // Data to be uploaded
        
        let expression = AWSS3TransferUtilityUploadExpression()
        expression.progressBlock = {(task, progress) in
            DispatchQueue.main.async(execute: {
                // Do something e.g. Update a progress bar.
                
                print("upload in process \(progress)")
                
            })
        }
        
        var completionHandler: AWSS3TransferUtilityUploadCompletionHandlerBlock?
        completionHandler = { (task, error) -> Void in
            DispatchQueue.main.async(execute: {
                // Do something e.g. Alert a user for transfer completion.
                // On failed uploads, `error` contains the error object.
                
                print("upload completed1 \(task.bucket)")
                print("upload completed2 \(String(describing: task.response))")
                print("upload completed3 \(task.key)")
                
                
                
            })
        }
        
        let transferUtility = AWSS3TransferUtility.default()
        let currentTime = getCurrentMillis()
        var imageKey = String(format: "%ld", currentTime)
        imageKey = imageKey + ".jpg"
        

        transferUtility.uploadData(data,
                                   bucket: "BUCKET NAME",
                                   key: imageKey,
                                   contentType: "image/jpeg",
                                   expression: expression,
                                   completionHandler: completionHandler).continueWith {
                                    (task) -> AnyObject! in
                                    if let error = task.error {
                                        print("Error: \(error.localizedDescription)")
                                    }
                                    
                                    if let _ = task.result {
                                        // Do something with uploadTask.
                                        
                                        print("something upload completed \(String(describing: task.result.debugDescription))")
                                        
                                    }
                                    return nil;
        }
    }
    
    
    @IBAction func selectImageFromGallery(_ sender: UIButton) {
        
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.allowsEditing = false
        imagePicker.sourceType = .photoLibrary
        present(imagePicker, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let pickedImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
            selectedImageView.contentMode = .scaleAspectFit
            selectedImageView.image = pickedImage
        }
        
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func uploadImageToS3(_ sender: UIButton) {
        
        uploadData(image: selectedImageView.image!)
    }
}



