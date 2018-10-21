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
// Notice the AddListViewControllerDelegate to get notifications from the add when the list changes
class ListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, AddListViewControllerDelegate {

    static let ListCell = "ListCell"
    
    @IBOutlet weak var tableView: UITableView!              // Explain weak again?
    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!
    @IBOutlet weak var messageLabel: UILabel!

    var lists = [CKRecord]()                // Array to hold tableView items
    // var alists: Array<CKRecord> = Array()   // Alternate method to initialize array
    
    var selection: Int?             // Holds which record in the lists that is selected

    // Main override that runs whenever view is loaded
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
    
    // MARK: -
    // Delete list from the set of lists
    private func deleteRecord(_ list: CKRecord) {
        let privateDatabase = CKContainer.default().privateCloudDatabase
        
        // SHow progress
        SVProgressHUD.show()
        
        // delete the list
        privateDatabase.delete(withRecordID: list.recordID) {
            (recordID, error) -> Void in
            DispatchQueue.main.sync {
                SVProgressHUD.dismiss()
                
                self.processResponseForDeleteRequest(list, recordID: recordID, error: error)
            }
        }
    }
    
    // MARK: -
    // process delete response by deleting from the list on this tableView
    private func processResponseForDeleteRequest(_ record: CKRecord, recordID: CKRecord.ID?, error: Error?) {
        var message = ""
        
        if let error = error {
            print(error)
            message = "We are unable to delete the list."
            
        } else if recordID == nil {
            message = "We are unable to delete the list."
        }
        
        if message.isEmpty {
            // Calculate Row Index
            let index = self.lists.index(of: record)
            
            if let index = index {
                // Update Data Source
                self.lists.remove(at: index)
                
                if lists.count > 0 {
                    // Update Table View
                    self.tableView.deleteRows(at: [NSIndexPath(row: index, section: 0) as IndexPath], with: .right)
                    
                } else {
                    // Update Message Label
                    messageLabel.text = "No Records Found"
                    
                    // Update View
                    updateView()
                }
            }
            
        } else {
            // Initialize Alert Controller
            let alertController = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
            
            // Present Alert Controller
            present(alertController, animated: true, completion: nil)
        }
    }
    
    // MARK: -
    // MARK: Seque Lifecycle
    // To edit a record, the user needs to tap the accessory button of a table view row.
    // This means that we need to implement the tableView(_:accessoryButtonTappedForRowWithIndexPath:)
    // method of the UITableViewDelegate protocol
    func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
        //
        tableView.deselectRow(at: indexPath, animated: true)
        
        // Set which one was selected
        selection = indexPath.row
        
        // perform Seque - the name of the Seque is ListDetail - propery on the Seque set in StoryBoard
        performSegue(withIdentifier: "ListDetail", sender: self)
    }
    
    // override the prepare to get seque ready with which one selected
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let identifier = segue.identifier else { return }

        switch identifier {
            
        case "ListDetail":
            // Fetch Destination View Controller
            let addListViewController = segue.destination as! AddListViewController
            
            // setup delegate
            addListViewController.delegate = self       // This class / object provides the delegate
            
            // only do this if one is selected
            if let selection = selection {
                // get specific selected list
                let list = lists[selection]
            
                // Set the view controller's list so it has it when invoked
                addListViewController.list = list
                
            }
            selection = nil         // to clear which one was selected so add can work
        default:
            break
        } // Switch
        
    }
    
    // We're almost there. When the segue with identifier ListDetail is performed,
    // we need to configure the AddListViewController instance that is pushed onto the navigation stack.
    // We do this in prepareForSegue(_:sender:).
    
    // The segue hands us a reference to the destination view controller,
    // the AddListViewController instance. We set the delegate property, and,
    // if a shopping list is updated, we set the view controller's list property to the selected record.
    

    
} // class


// TODO: - Ask why these methods are an extenstion vs part of the main class
// In BNR bootcamps, we put these in the class, but our own custom delegates in extensions
// Put delegate methods in class extension
extension ListViewController
{
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    // This one allows you to swipe left to delete an item
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    // This one selects the row and deletes it
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        // get the correct row
        let list = lists[indexPath.row]
        
        // delete it
        deleteRecord(list)
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

// MARK: -
// This is where the user defined delegates go.  The system delegates are in another extenstion
// in BNR I out the user defined ones in an extension but not the system ones
extension ListViewController
{
    // MARK: -
    // the delegate method for adding to the list
    // I honestly dont like the way he did this but more than one way to skin a cat
    // I would have create one delegate to handle add and update
    // He is doing this my just having diffetne function with slightly different signatures
    func controller(controller: AddListViewController, didAddList list: CKRecord) {
        // append the added one to the list
        lists.append(list)

        // sort
        sortLists()
        
        // reload the table view since items in list changed
        tableView.reloadData()
        
        // Update View
        updateView()
    }
    
    // MARK: -
    // the delegate method for updating the list
    func controller(controller: AddListViewController, didUpdateList list: CKRecord) {
        // no need to change the list since its done
        
        // sort
        sortLists()
        
        // reload the table view since items in list changed
        tableView.reloadData()
        
        // Because we're not adding a record, we only need to sort the array of records and reload the table view. There's no need to call updateView on the view controller since the array of records is, by definition, not empty
    }
    
    // Sort the list
    private func sortLists() {
        self.lists.sort {
            var result = false
            let name0 = $0["name"] as? String
            let name1 = $1["name"] as? String
            
            if let listName0 = name0, let listName1 = name1 {
                result = listName0.localizedCaseInsensitiveCompare(listName1) == .orderedAscending
            }
            
            return result
        }
    }
    
}

