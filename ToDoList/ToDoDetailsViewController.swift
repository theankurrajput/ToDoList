//
//  ToDoDetailsViewController.swift
//  ToDoList
//

import UIKit

class ToDoDetailsViewController: UIViewController {
    
    @IBOutlet weak var taskTitleLabel: UILabel!
    
    @IBOutlet weak var taskDetailsTextView: UITextView!
    
    @IBOutlet weak var taskCompletionButton: UIButton!
    
    @IBOutlet weak var taskCompletionDate: UILabel!
    
    var toDoItem: Task!
    var toDoIndex: Int!
    weak var delegate: ToDoListDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()

        taskTitleLabel.text = toDoItem.name
        taskDetailsTextView.text = toDoItem.details
        if toDoItem.isComplete {
            disableButton()
        }
        let stringFormatter = DateFormatter()
        stringFormatter.dateFormat = "MMM dd, yyy hh:mm"
        let taskDate = stringFormatter.string(from: toDoItem.completionDate as Date)
        taskCompletionDate.text = taskDate
        
    }
    
    func disableButton() {
        taskCompletionButton.backgroundColor = UIColor.gray
        taskCompletionButton.isEnabled = true
    }
    
   
    
    @IBAction func taskDidComplete(_ sender: Any) {
        //toDoItem.isComplete = true
        guard let realm = LocalDatabaseManager.realm else {
                 return
             }
             do {
                 try realm.write {
                     toDoItem.isComplete = true
                 }
             } catch let error as NSError {
                 print(error.localizedDescription)
                 return
             }
        delegate?.update()
        disableButton()
    }
    

}
