//
//  ViewController.swift
//  CoreDataCRUDOperation
//
//  Created by Jenish Mistry on 07/04/20.
//  Copyright © 2020 Jenish Mistry. All rights reserved.
//

import UIKit
import CoreData
import Toast_Swift

class ViewController: UIViewController {
    
    // MARK: - Attributes -
    @IBOutlet weak var tblView: UITableView!
    var arrPeople: [NSManagedObject] = []
    let tableCellIdentifier = "cell"
    let entityKey = "User"
    let attributeNameKey = "name"
    
    // MARK: - Life cycle -
    override func viewDidLoad() {
        super.viewDidLoad()
        fetchRecord()
        setUpView()
    }
    
    // MARK: - Button Action -
    @IBAction func btnAddTapepd(_ sender: Any) {
        self.insertRecord()
    }
    
    // MARK: - Helper Method -
    func setUpView() {
        self.tblView.dataSource = self
        self.tblView.delegate = self
        tblView.register(UITableViewCell.self, forCellReuseIdentifier: tableCellIdentifier)
    }
    func showToast(message: String) {
        DispatchQueue.main.async {
            self.view.makeToast(message, duration: 2.0, position: .bottom)
        }
    }
}

// MARK: - UITableview Data Source  -
extension ViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return arrPeople.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let user = arrPeople[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: tableCellIdentifier, for: indexPath)
        cell.textLabel?.text = user.value(forKey: attributeNameKey) as? String
        return cell
    }
    
}

// MARK: - UITableview Delegate  -
extension ViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.updateRecord(indexPathRow: indexPath.row)
    }
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            self.deleteRecord(indexpath: indexPath)
        }
    }
}

// MARK: - CRUD Operation Methods -
extension ViewController {
    // -----------------------------> Insert record into DB <--------------------------------------//
    // --------------------------------------------------------------------------------------------//
    func insertRecord() {
        let alert = UIAlertController(title: "Want to add name?", message: "Write a name to store in DB" , preferredStyle: .alert)
        let saveAction = UIAlertAction(title: "Save", style: .default) { [unowned self] action in
            guard let textField = alert.textFields?.first, let enteredName = textField.text else {
                return
            }
            if enteredName.trimmingCharacters(in: .whitespaces) != ""  {
                self.save(name: enteredName.trimmingCharacters(in: .whitespaces))
            } else {
                self.showToast(message: "Name cannot be blank.")
                return
            }
            self.tblView.reloadData()
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        
        alert.addTextField()
        alert.addAction(saveAction)
        alert.addAction(cancelAction)
        present(alert, animated: true)
    }
    // Saving record into DB -
    func save(name: String) {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        let managedContext = appDelegate.persistentContainer.viewContext
        let entity = NSEntityDescription.entity(forEntityName: self.entityKey, in: managedContext)!
        let people = NSManagedObject.init(entity: entity, insertInto: managedContext)
        people.setValue(name, forKey: self.attributeNameKey)
        
        do {
            try managedContext.save()
            self.arrPeople.append(people)
            print("Data saved in DB...!!")
            self.showToast(message: "Saved succesfully..!!")
        } catch let error as NSError {
            if error.domain == NSCocoaErrorDomain && (error.code == NSValidationStringTooShortError || error.code == NSValidationStringTooLongError) {
                self.showToast(message: "Name must be minimun 2 and maximum 30 character long.")
                return
            }
            print("Could not save in DB: \(error) , \(error.userInfo)")
            self.showToast(message: "Invalid name")
            managedContext.rollback()
        }
    }
    
    // -----------------------------> Update record into DB <--------------------------------------//
    // --------------------------------------------------------------------------------------------//
    func updateRecord(indexPathRow: Int) {
        let exitingName = arrPeople[indexPathRow].value(forKey: attributeNameKey) as! String
        let alert = UIAlertController(title: "Update", message: "Are you want to update this \(exitingName) name  with another name?" , preferredStyle: .alert)
        let okAction = UIAlertAction(title: "Ok", style: .default) { action in
            guard let textField = alert.textFields?.first, let updatedName = textField.text else {
                return
            }
            if updatedName.trimmingCharacters(in: .whitespaces) != "" {
                self.update(exitingName: exitingName, updatedName: updatedName.trimmingCharacters(in: .whitespaces))
            } else {
                self.showToast(message: "Name cannot be blank.")
            }
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        alert.addTextField()
        alert.addAction(okAction)
        alert.addAction(cancelAction)
        present(alert, animated: true)
    }
    // Update record into DB -
    func update(exitingName: String, updatedName: String) {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        let managedContext = appDelegate.persistentContainer.viewContext
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest.init(entityName: self.entityKey)
        fetchRequest.predicate = NSPredicate(format: "name = %@", exitingName)
        
        do {
            let test = try managedContext.fetch(fetchRequest)
            let updateObject = test[0] as! NSManagedObject
            updateObject.setValue(updatedName, forKey: self.attributeNameKey)
            do {
                try managedContext.save()
                DispatchQueue.main.async {
                    self.fetchRecord()
                    self.tblView.reloadData()
                    self.showToast(message: "Updated succesfully...!!")
                }
            } catch let error as NSError {
                if error.domain == NSCocoaErrorDomain && (error.code == NSValidationStringTooShortError || error.code == NSValidationStringTooLongError) {
                    self.showToast(message: "Name must be minimun 2 and maximum 30 character long.")
                    managedContext.rollback()
                    return
                }
                managedContext.rollback()
                print("Data updated... but could not saved in DB: \(error), \(error.userInfo)")
                self.showToast(message: "Invalid name")
            }
        } catch let error as NSError {
            print("Could not update data: \(error), \(error.userInfo)")
        }
    }
    
    // -----------------------------> Delete record from DB <--------------------------------------//
    // --------------------------------------------------------------------------------------------//
    func deleteRecord(indexpath: IndexPath) {
        let exitingName = arrPeople[indexpath.row].value(forKey: attributeNameKey) as! String
        let alert = UIAlertController(title: "Alert", message: "Are you sure want to delete this record?" , preferredStyle: .alert)
        let deleteAction = UIAlertAction(title: "Delete", style: .destructive) { action in
            self.delete(exitingName: exitingName, indexpath: indexpath)
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        alert.addAction(deleteAction)
        alert.addAction(cancelAction)
        present(alert, animated: true)
    }
    func delete(exitingName: String, indexpath: IndexPath) {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        let managedContext = appDelegate.persistentContainer.viewContext
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest.init(entityName: self.entityKey)
        fetchRequest.predicate = NSPredicate(format: "name = %@", exitingName)
        
        do {
            let result = try managedContext.fetch(fetchRequest)
            let objectToDelete = result[0] as! NSManagedObject
            managedContext.delete(objectToDelete)
            do{
                try managedContext.save()
                self.arrPeople.remove(at: indexpath.row)
                self.tblView.deleteRows(at: [indexpath], with: .left)
                self.showToast(message: "Deleted succesfully...!!")
            } catch let error as NSError{
                print("Data deleted... but could not saved in DB: \(error), \(error.userInfo)")
            }
        } catch let error as NSError{
            print("Could not delete data: \(error), \(error.userInfo)")
        }
    }
    
    // -----------------------------> Retrive record from DB <--------------------------------------//
    // --------------------------------------------------------------------------------------------//
    func fetchRecord() {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        
        let managedContext = appDelegate.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: entityKey)
        
        do {
            arrPeople = try managedContext.fetch(fetchRequest)
        } catch let error as NSError {
            self.showToast(message: "Could not fetch data. Try again.")
            print("Could not fetch Data: \(error) , \(error.userInfo)")
        }
    }
}
