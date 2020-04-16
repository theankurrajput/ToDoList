//
//  ToDoListViewController.swift
//  ToDoList
//

import UIKit
import RealmSwift

protocol ToDoListDelegate: class {
    func update()
}

class ToDoListViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    var toDoItems: Results<Task>? {
        get {
            guard let realm = LocalDatabaseManager.realm else {
                return nil
            }
            return realm.objects(Task.self)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableFooterView = UIView()
        title = "To Do List"
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addButtonTapped))
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .edit, target: self, action: #selector(editButtonTapped))
        NotificationCenter.default.addObserver(self, selector: #selector(addNewTask(_:)), name: NSNotification.Name.init("com.todolistapp.addtask"), object: nil)
    }
    
    @objc func addNewTask(_ notification: NSNotification) {
        
        tableView.reloadData()
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        tableView.setEditing(false, animated: false)
    }
    
    @objc func addButtonTapped() {
        performSegue(withIdentifier: "AddTaskSegue", sender: nil)
    }
    
    @objc func editButtonTapped() {
        tableView.setEditing(!tableView.isEditing, animated: true)
        if tableView.isEditing {
            navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(editButtonTapped))
        } else {
            navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .edit, target: self, action: #selector(editButtonTapped))
        }
        
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let delete = UITableViewRowAction(style: .destructive, title: "Delete") { (action, indexPath) in
           // self.toDoItems.remove(at: indexPath.row)
            guard let realm = LocalDatabaseManager.realm else {
                return
            }
            do {
                try realm.write {
                    realm.delete(self.toDoItems![indexPath.row])
                }
            } catch let error as NSError {
                print(error.localizedDescription)
                return
            }
            self.tableView.deleteRows(at: [indexPath], with: UITableView.RowAnimation.automatic)
        }
        return [delete]
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return toDoItems?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let toDoItem = toDoItems![indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "ToDoItem")!
        cell.textLabel?.text = toDoItem.name
        cell.detailTextLabel?.text = toDoItem.isComplete ? "Complete" : "Incomplete"
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let toDoTuple = (toDoItems![indexPath.row], indexPath.row)
        performSegue(withIdentifier: "TaskDetailsSegue", sender: toDoTuple)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "TaskDetailsSegue" {
            guard let destinationVC = segue.destination as? ToDoDetailsViewController else { return }
            guard let toDoTuple = sender as? (Task, Int) else { return }
            destinationVC.toDoItem = toDoTuple.0
            destinationVC.toDoIndex = toDoTuple.1
            destinationVC.delegate = self
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.init("com.todolistapp.addtask"), object: nil)
    }
}

extension ToDoListViewController: ToDoListDelegate {
    func update() {
        tableView.reloadData()
    }
}
