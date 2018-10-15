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

// for coimmunicaing from list to add/update
protocol AddListViewControllerDelegate {
    func controller(controller: AddListViewController, didAddList list: CKRecord)
    func controller(controller: AddListViewController, didUpdateList list: CKRecord)
}

class AddListViewController: UIViewController {
    
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var saveButton: UIBarButtonItem!

    var delegate: AddListViewControllerDelegate?
    var newList: Bool = true
    
    var list: CKRecord?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupView()

        // Update Helper
        self.newList = self.list == nil         // if list is empty, set new to true
        
        // Add Observer
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(AddListViewController.textFieldTextDidChange(notification:)), name: NSNotification.Name.UITextFieldTextDidChange, object: nameTextField)
    }
    
    // first responder to show keyboard
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        nameTextField.becomeFirstResponder()
    }
    
    private func setupView() {
        updateNameTextField()
        updateSaveButton()
    }
    
    // MARK: -
    // populate the text field if list is not nil. In other words, if we're editing an existing record, then we
    // populate the text field with the name of that record.
    private func updateNameTextField() {
        if let name = list?.object(forKey: "name") as? String {
            nameTextField.text = name
        }
    }
    
    // MARK: -
    // in charge of enabling and disabling the bar button item in the top right.
    // We only enable the save button if the name of the shopping list is not an empty string.
    private func updateSaveButton() {
        let text = nameTextField.text
        
        if let name = text {
            saveButton.isEnabled = !name.isEmpty
        } else {
            saveButton.isEnabled = false
        }
    }

    @IBAction func cancel(sender: AnyObject) {
        
    }
    
    @IBAction func save(sender: AnyObject) {
        
    }
}
