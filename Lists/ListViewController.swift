//
//  ListViewController.swift
//  Lists
//
//  Created by Paul Linck on 10/12/18.
//  Copyright © 2018 Paul Linck. All rights reserved.
//

import UIKit
import CloudKit
import SVProgressHUD

class ListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    static let ListCell = "ListCell"
    
    @IBOutlet weak var tableView: UITableView!              // Explain weak again?
    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!
    @IBOutlet weak var messageLabel: UILabel!

    var lists = [CKRecord]()                // Array to hold tableView items
    // var alists: Array<CKRecord> = Array()   // Alternate method to initialize array

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // fetchUserRecordID()                  // This was in the intro not needed now
        setupView()
    }

    // Prepare the user interface for fetching the list of records in the database
    // Hide all and spin the activity indicator
    private func setupView() {
        tableView.isHidden = true
        messageLabel.isHidden = true
        activityIndicatorView.startAnimating()
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


// Put delegate methods in class extension
// Ask why this is an extenstion vs part of the class
extension ListViewController
{
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return lists.count
    }
    
    // Puts the listName in the correct row of the tableView
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // DeQueue Reusable Cell
        let cell = tableView.dequeueReusableCell(withIdentifier: ListViewController.ListCell, for: indexPath)
        
        // Configure Cell
        cell.accessoryType = .detailDisclosureButton
        
        // Fetch Record
        let list = lists[indexPath.row]
        
        // put the name field of the record into the cell - this is shopping list name
        if let listName = list.object(forKey: "name") as? String {
            cell.textLabel?.text = listName
        } else {
            cell.textLabel?.text = "_"
        }
        
        return cell
    }
}

