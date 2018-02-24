//
//  ImagesListView.swift
//  S3Sample
//
//  Created by Kalyan Parise on 19/02/18.
//  Copyright © 2018 kalyan. All rights reserved.
//

import Foundation
import UIKit
import AWSS3


class ImagesListView: UITableViewController

{
    
    var imagesArray = [AnyObject]()
    var s3Url = "https://s3.amazonaws.com/<BUCKET NAME>/"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let editButton = UIBarButtonItem(title: "Edit", style: .plain, target: self, action: #selector(enableEdit))
        self.navigationItem.rightBarButtonItem = editButton
        self.title = "Images List"
        
        listS3Objects()

        tableView.dataSource = self
        tableView.delegate = self
    
        
    }
    
    @objc func enableEdit(){
        
        if(self.tableView.isEditing == true)
        {
            self.tableView.isEditing = false
            self.navigationItem.rightBarButtonItem?.title = "Edit"
        }
        else
        {
            self.tableView.isEditing = true
            self.navigationItem.rightBarButtonItem?.title = "Done"
        }
    }
    
    func listS3Objects(){
        let credentialProvider = AWSCognitoCredentialsProvider(regionType: "<REGION>", identityPoolId: "POOL ID From awsconfiguration.json file")
        let configuration = AWSServiceConfiguration(region: "<REGION>", credentialsProvider: credentialProvider)
        AWSServiceManager.default().defaultServiceConfiguration = configuration
        
        AWSS3.register(with: configuration!, forKey: "defaultKey")
        let s3 = AWSS3.s3(forKey: "defaultKey")
        
        let listRequest: AWSS3ListObjectsRequest = AWSS3ListObjectsRequest()
        listRequest.bucket = "<BUCKET NAME>"
        
        s3.listObjects(listRequest).continueWith { (task) -> AnyObject? in
            print("Object result = \(task.result)")
            
            print("Object contents = \(task.result?.contents)")
            for object in (task.result?.contents)! {
                
                print("Object key = \(object.key!)")
                self.imagesArray.append(object)
            }
            
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
            return nil
            
        }
        
    }
    
    
    func deleteS3Object(imageKey : String){
        
        let credentialProvider = AWSCognitoCredentialsProvider(regionType: "<REGION>", identityPoolId: "POOL ID From awsconfiguration.json file")
        let configuration = AWSServiceConfiguration(region: "<REGION>", credentialsProvider: credentialProvider)
        AWSServiceManager.default().defaultServiceConfiguration = configuration
        
        AWSS3.register(with: configuration!, forKey: "defaultKey")
        let s3 = AWSS3.s3(forKey: "defaultKey")
        let deleteObjectRequest = AWSS3DeleteObjectRequest()
        deleteObjectRequest?.bucket = "<BUCKET NAME>" // bucket name
        deleteObjectRequest?.key = imageKey // File name
        s3.deleteObject(deleteObjectRequest!).continueWith { (task:AWSTask) -> AnyObject? in
            if let error = task.error {
                print("Error occurred: \(error)")
                return nil
            }
            print("Bucket deleted successfully.")
            return nil
        }
        
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.imagesArray.count
        
    }
    
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "imgcell", for: indexPath)
        let s3ImageObj = self.imagesArray[indexPath.row]
        
        let finalUrl = self.s3Url + s3ImageObj.key // here the s3url has to be hardcoded which will be available in the s3 bucket.
        print("the final url is \(finalUrl)")
        
        let imageV = cell.viewWithTag(1000) as! UIImageView
        
        imageV.loadImageUsingCache(withUrl: finalUrl)
        return cell
    }
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            let s3ImageObj = self.imagesArray[indexPath.row]
            self.deleteS3Object(imageKey: s3ImageObj.key)
            self.imagesArray.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }
    }

    
    
    
}

let imageCache = NSCache<NSString, AnyObject>()

extension UIImageView {
    func loadImageUsingCache(withUrl urlString : String) {
        let url = URL(string: urlString)
        //self.image = nil
        
        // check cached image
        if let cachedImage = imageCache.object(forKey: urlString as NSString) as? UIImage {
            self.image = cachedImage
            return
        }
        
        // if not, download image from url
        URLSession.shared.dataTask(with: url!, completionHandler: { (data, response, error) in
            if error != nil {
                print(error!)
                return
            }
            
            DispatchQueue.main.async {
                if let image = UIImage(data: data!) {
                    self.image = image

                    imageCache.setObject(image, forKey: urlString as NSString)
                }
            }
            
        }).resume()
    }
}
