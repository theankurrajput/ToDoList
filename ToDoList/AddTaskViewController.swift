//
//  AddTaskViewController.swift
//  ToDoList
//

import UIKit

class AddTaskViewController: UIViewController {
    
    @IBOutlet weak var navigationBar: UINavigationBar!
    
    @IBOutlet weak var taskNameTextField: UITextField!
    
    @IBOutlet weak var taskDetailsTextView: UITextView!
    
    @IBOutlet weak var taskCompletionDatePicker: UIDatePicker!
    
    @IBOutlet weak var scrollView: UIScrollView!

    lazy var touchView: UIView = {
        let _touchView = UIView()
        _touchView.backgroundColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0)
        let touchViewTapped = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        _touchView.addGestureRecognizer(touchViewTapped)
        _touchView.isUserInteractionEnabled = true
        _touchView.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height)
        return _touchView
    }()
    let toolBar = UIToolbar.init()
    var activeTextField: UITextField?
    var activeTextView: UITextView?
    var keyboardNotification: NSNotification?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        let navigationItem = UINavigationItem(title: "Add Task")
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelButtonTapped))
        navigationBar.items = [navigationItem]
        
        taskDetailsTextView.layer.borderColor = UIColor.lightGray.cgColor
        taskDetailsTextView.layer.borderWidth = CGFloat(1)
        taskDetailsTextView.layer.cornerRadius = CGFloat(3)
        
        toolBar.sizeToFit()
        toolBar.barTintColor = UIColor.red
        toolBar.isTranslucent = true
        
        let flexSpace = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.flexibleSpace, target: self, action: nil)
        let btnDone = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(doneButtonTapped))
        btnDone.setTitleTextAttributes([NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 17),
                                        NSAttributedString.Key.foregroundColor: UIColor.white], for: .normal)
        toolBar.items = [flexSpace, flexSpace, btnDone]
        taskNameTextField.inputAccessoryView = toolBar
        taskDetailsTextView.inputAccessoryView = toolBar
        
        taskNameTextField.delegate = self
        taskDetailsTextView.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        registerForKeyboardNotification()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        deregisterFromKeyboardNotification()
    }
    
    func registerForKeyboardNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWasShown(notification:)), name: UIWindow.keyboardDidShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWasHidden(notification:)), name: UIWindow.keyboardWillHideNotification, object: nil)
    }
    
    @objc func keyboardWasShown(notification: NSNotification) {
        view.addSubview(touchView)
        let info: NSDictionary = notification.userInfo! as NSDictionary
        let keyboardSize = (info[UIResponder.keyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue.size
        let contentInsets: UIEdgeInsets = UIEdgeInsets(top: 0.0, left: 0.0, bottom: (keyboardSize!.height +
            toolBar.frame.size.height + 10.0), right: 0.0)
        self.scrollView.contentInset = contentInsets
        self.scrollView.scrollIndicatorInsets = contentInsets
        var aRect: CGRect = UIScreen.main.bounds
        aRect.size.height = aRect.size.height - keyboardSize!.height
        if activeTextField != nil {
            if(!aRect.contains(activeTextField!.frame.origin)) {
                self.scrollView.scrollRectToVisible(activeTextField!.frame, animated: true)
            }
        } else if activeTextView != nil {
            let textViewPoint: CGPoint = CGPoint(x: activeTextView!.frame.origin.x, y: activeTextView!.frame.size.height + activeTextView!.frame.size.height)
            if (aRect.contains(textViewPoint)) {
                self.scrollView.scrollRectToVisible(activeTextView!.frame, animated: true)
            }
            
        }
    }
    
    @objc func keyboardWasHidden(notification: NSNotification) {
        touchView.removeFromSuperview()
        let contentInsets: UIEdgeInsets = UIEdgeInsets.zero
        self.scrollView.contentInset = contentInsets
        self.scrollView.scrollIndicatorInsets = contentInsets
        self.view.endEditing(true)
    }
    
    func deregisterFromKeyboardNotification() {
        NotificationCenter.default.removeObserver(self, name: UIWindow.keyboardDidShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIWindow.keyboardWillHideNotification, object: nil)
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
    @objc func doneButtonTapped() {
        view.endEditing(true)
    }
    
    @objc func cancelButtonTapped() {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func addTaskDidTouch(_ sender: Any) {
        guard let taskName = taskNameTextField.text, !taskName.isEmpty else {
            reportError(title: "Invalid Name", message: "Task Name can not be blank")
            return
        }
        if taskDetailsTextView.text.isEmpty {
            reportError(title: "Invalid Details", message: "Task Details can not be blank")
            return
        }
        let taskDetails: String = taskDetailsTextView.text
        let completionDate: Date = taskCompletionDatePicker.date
        if completionDate < Date() {
            reportError(title: "Invalid Date", message: "Date must be in future")
            return
        }
        guard let realm = LocalDatabaseManager.realm else {
            reportError(title: "Error", message: "A new task can not be created")
            return
        }
        let newTaskId = (realm.objects(Task.self).max(ofProperty: "id") as Int? ?? 0) + 1
        let newTask = Task()
        newTask.id = newTaskId
        newTask.name = taskName
        newTask.details = taskDetails
        newTask.completionDate = completionDate as NSDate
        newTask.isComplete = false
        do {
            try realm.write {
                realm.add(newTask)
            }
        } catch let error as NSError {
            print(error.localizedDescription)
            reportError(title: "Error", message: "A new task can not be created")
            return
        }
        
        //let toDoItem = ToDoItemModel(name: taskName, details: taskDetails, completionDate: completionDate)
        NotificationCenter.default.post(name: NSNotification.Name.init("com.todolistapp.addtask"), object: nil)
        dismiss(animated: true, completion: nil)
    }
    
    func reportError(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default) { (action) in
            alert.dismiss(animated: true, completion: nil)
        }
        alert.addAction(okAction)
        present(alert, animated: true, completion: nil)
    }
    
}

extension AddTaskViewController: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        activeTextField = textField
    }
    func textFieldDidEndEditing(_ textField: UITextField) {
        activeTextField = nil
    }
}

extension AddTaskViewController: UITextViewDelegate {
    func textViewDidBeginEditing(_ textView: UITextView) {
        activeTextView = textView
    }
    func textViewDidEndEditing(_ textView: UITextView) {
        activeTextView = nil
    }
}
