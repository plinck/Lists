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

// TODO: - finish comments to explain everything
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
        fetchLists()
    }
    
    // MARK: -
    // Get a list of all the shopping list names from cloudkit
    private func fetchLists() {
        // Private Database in the _defaultZone
        // TODO: - Add error handling to ensure user is logged into iCloud
        let privateDatabase = CKContainer.default().privateCloudDatabase
        
        // TODO: - Why do we need NSPredicate of true - i.e. what does true mean in this context
        // Initialize Query - just sets up which record type (table) you want to access
        let query = CKQuery(recordType: "Lists", predicate: NSPredicate(value: true))
        
        // Configure Query sorting.  sortDesciptors is collection (array) of fields to sort by
        query.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
        
        // perform Query
        privateDatabase.perform(query, inZoneWith: nil) { // trailing completion handler syntax
            (records, error) in
                guard error == nil else {                       // if error not nil, print and stop
                    print(error?.localizedDescription as Any)
                    return
                }
            
                // Remember.  Cloudkit completions are done on background task so must dispatch
                // UI things to the main thread
                records?.forEach( { (record) in
                    print(record.value(forKey: "name") ?? "")
                    self.lists.append(record)
                    DispatchQueue.main.sync {
                        self.tableView.reloadData()
                        self.messageLabel.text = ""
                        self.updateView()
                    }
                })  // forEach record in
        }
        self.updateView()
    }
    
    // Prepare the user interface for fetching the list of records in the database
    // Hide all and spin the activity indicator
    private func setupView() {
        tableView.isHidden = true
        messageLabel.isHidden = true
        messageLabel.text = "No Records Found"
        activityIndicatorView.startAnimating()
    }
    
    // update the user interface based on the contents of the lists property
    // The tutorial forgot to hide activity indicator
    // TODO: - Why did they use activityIndicator vs SVProgressHUD?
    private func updateView() {
        let hasRecords = self.lists.count > 0
        
        self.tableView.isHidden = !hasRecords           // if no records dont show table view
        messageLabel.isHidden = hasRecords              // if any records, hide message but show tableView
        activityIndicatorView.stopAnimating()           // stop spinenr
        activityIndicatorView.isHidden = true
    }
    
    // TODO: - Complete the signature comments
    // This method gets the recordID for the current iCloud user
    // passes that to another methoid to get the full record for user
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


// TODO: - Ask why these methods are an extenstion vs part of the main class
// In BNR bootcamps, we put these in the class, but our own custom delegates in extensions
// Put delegate methods in class extension
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

