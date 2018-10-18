//
//  AddListViewController.swift
//  Lists
//
//  Created by Paul Linck on 10/15/18.
//  Copyright © 2018 Paul Linck. All rights reserved.
//

import UIKit
import CloudKit
import SVProgressHUD

// for communicaing to the list view controller to add/update
// remember, the protocal defines the methods that the delegate must adhere to
// this class defines the protocol abd calls the delegate method,
// the list class implements the delegate method to update its view based on changes made here
// It is kinda/sorta similar to the message publish subscrive stuff in c#,
// But, in swift it is a one to one relationshiop where in c# many can subscribe to it
protocol AddListViewControllerDelegate {
    func controller(controller: AddListViewController, didAddList list: CKRecord)
    func controller(controller: AddListViewController, didUpdateList list: CKRecord)
}

class AddListViewController: UIViewController {
    
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var saveButton: UIBarButtonItem!
    
    var delegate: AddListViewControllerDelegate?                // Delegate to notify List View Controller
    var newList: Bool = true
    
    var list: CKRecord?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupView()

        // Update Helper
        self.newList = self.list == nil         // if list is empty, set new to true
        
        // TODO: - This code did not work so I switched to using outlet, not sure hwo to fix this way
        // Add Observer
        // This is used to enable and disable the save button
        // Any time the nameTextField change, this observer gets called
        // This is the way it shows how to do it in the tutorial
//        let notificationCenter = NotificationCenter.default
//        notificationCenter.addObserver(self, selector: #selector(AddListViewController.textFieldTextDidChange(notification:)), name: NSNotification.Name.UITextFieldTextDidChange, object: nameTextField)

        // MARK: - This is an alternate way of doing it in swift 4.2.
        nameTextField.addTarget(self, action: #selector(AddListViewController.textFieldTextDidChange(_:)), for: UIControl.Event.editingChanged)
    }
    
    // first responder to show keyboard
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        nameTextField.becomeFirstResponder()
    }
    
    @IBAction func cancel(sender: AnyObject) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func save(sender: AnyObject) {
        
        // Helpers
        let name = self.nameTextField.text! as NSString
        
        // Fetch Private Database
        let privateDatabase = CKContainer.default().privateCloudDatabase
        
        // If no list yet, create it
        if list == nil {
            list = CKRecord(recordType: "Lists")
        }
        
        // Configure Record - put the name into the name field of the record
        // I beleive you can also use
        // list?["name"] = name
        list?.setObject(name, forKey: "name")
        
        // Show Progress
        SVProgressHUD.show()
        
        // Save the record to the DB
        privateDatabase.save(list!) {                       // Again, trailing closure syntax
            (record, error) -> Void in
                DispatchQueue.main.sync {
                    // Dismiss Progress
                    SVProgressHUD.dismiss()
                    
                    // Process Response from Cloudkit DB save command
                    self.processResponse(record: record, error: error)
                }
            }
    }
    
    // MARK: -
    // helper to process the save
    private func processResponse(record: CKRecord?, error: Error?) {
        var message = ""
        
        if let error = error {
            // Error is not nil so print
            print(error)
            message = "Unable to save your list"
        } else if record == nil {
            message = "record is nil, unable to save your list"
        }
        
        // Alert
        if !message.isEmpty {
            //Init alert controller
            let alertController = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
            present(alertController, animated: true, completion: nil)
        } else {
            // Notify list controller of the changes made since no errors ocurred (i.e. list is empty)
            if newList {
                delegate?.controller(controller: self, didAddList: list!)
            } else {
                delegate?.controller(controller: self, didUpdateList: list!)
            }
            
            // pop this view controller to go back to list
            self.dismiss(animated: true, completion: nil)
        }
}
    
    // MARK: - A Mark statement lives here
    // This is helper function to setup the view
    private func setupView() {
        updateNameTextField()
        updateSaveButton()
    }
    
    // TODO: - A Todo Comment Lives here
    // populate the text field if list is not nil. In other words, if we're editing an existing record, then we
    // populate the text field with the name of that record.
    private func updateNameTextField() {
        if let name = list?.object(forKey: "name") as? String {
            nameTextField.text = name
        }
    }
    
    // FIXME: - A Fix me comment lives here (the - gives me the gray line separator)
    // This is in charge of enabling and disabling the bar button item in the top right.
    // We only enable the save button if the name of the shopping list is not an empty string.
    private func updateSaveButton() {
        let text = nameTextField.text
        
        if let name = text {
            saveButton.isEnabled = !name.isEmpty
        } else {
            saveButton.isEnabled = false
        }
    }

    // MARK: - This is what I had to do to get notification working
    // I could not get the manual / coded notifcation to work
    // This should get called anytime the text field changes.
    @IBAction func nameTextField(_ sender: UITextField) {
        updateSaveButton()
    }
    // MARK: -  THIS DID NOT WORK SO I SWITCHED TO ABOVE
//    @objc func textFieldTextDidChange(notification: NSNotification) {
//        updateSaveButton()
//    }
    // MARK: -  THIS worked for swift 4.2
    @objc func textFieldTextDidChange(_ textField: UITextField) {
        updateSaveButton()
    }
}
