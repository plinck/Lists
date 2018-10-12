//
//  ListViewController.swift
//  Lists
//
//  Created by Paul Linck on 10/12/18.
//  Copyright © 2018 Paul Linck. All rights reserved.
//

import UIKit
import CloudKit

class ListViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        fetchUserRecordID()
    }

    private func fetchUserRecordID () {
        // Fetch Default Container
        let defaultContainer = CKContainer.default()
        
        // Fetch User Record
        defaultContainer.fetchUserRecordID {
            (recordID, error) -> Void in
            if let responseError = error {
                // error isnt nil so we had a problem
                print(responseError);
            } else if let userRecordID = recordID {
                // valid recordID so send to main queue
                DispatchQueue.main.sync {
                    self.fetchUserRecord(recordID: userRecordID)
                }  // queue
            } // else if
        } // fetchUSerRecordID
    } // func fetchUserRecordID

    private func fetchUserRecord(recordID: CKRecord.ID) {
        // Fetch Default Container
        let defaultContainer = CKContainer.default()
        
        // Fetch Private Database
        let privateDatabase = defaultContainer.privateCloudDatabase
        
        // Fetch User Record
        privateDatabase.fetch(withRecordID: recordID) {  //Note trailing closure syntax
            (record, error) -> Void in
            if let responseError = error {
                print(responseError)
            } else if let userRecord = record {
                print(userRecord)
            }
            
        }
        
    }
    
} // class

