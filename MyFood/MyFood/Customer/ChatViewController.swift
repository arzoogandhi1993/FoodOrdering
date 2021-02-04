//
//  ChatViewController.swift
//  MyFood
//
//  Created by animesh seth on 12/11/20.
//

import UIKit
import CoreData


class MyChatTableViewCell: UITableViewCell {
    
    @IBOutlet weak var managerLabel: UILabel!
    @IBOutlet weak var receivedLabel: UILabel!
    @IBOutlet weak var meLabel: UILabel!
    @IBOutlet weak var sendLabel: UILabel!
}

class ChatViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextViewDelegate {

    @IBOutlet weak var input: UITextView!
    @IBOutlet weak var inputMessage: UITextField!
    @IBOutlet weak var dockView: UIView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var sendButton: UIButton!
    var tableNo : Int64?
    var messages :[Message] = [Message]()
    var isRunning : Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupHideKeyboardOnTap()
        self.loadMessages()
        self.downloadMessages()

        //self.tableView.delegate = self
        self.tableView.dataSource = self
        //self.input.delegate = self
        
        self.tableView.reloadData()

    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.tableView.reloadData()
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        self.view.layoutIfNeeded()
    }
    override func viewDidAppear(_ animated: Bool) {
        self.scrollToBottom()
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        self.view.layoutIfNeeded()
    }
        
    @IBAction func sendMessage(_ sender: Any) {
        self.inputMessage.endEditing(true)
        let msg = getTextField(textField: inputMessage)
        if(msg == nil || msg.count == 0)
        {
            return
        }
        
        let workItem = DispatchWorkItem {
            ApiRepository.shared.sendMessage(from: msg, from: self.tableNo!){ [self] error in
                    if (error != nil)
                    {
                        return
                    }
                }
        }
        
        DispatchQueue.global(qos: .utility).async {
            workItem.perform()
        }
        
        workItem.notify(queue: DispatchQueue.main, execute: {
            self.inputMessage.text = ""
            self.tableView.reloadData()
            self.scrollToBottom()
        })
    }
    
    func getTextField(textField : UITextField) -> String
    {
        var fieldValue : String = ""
        //Get One By One with Tag
        if((textField.text) != nil)
        {
            fieldValue = textField.text!
        }
        
        return fieldValue
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "myChatCell", for: indexPath) as! MyChatTableViewCell
        
        let message = messages[indexPath.row]
        if(message.isCustomer == true)
        {
            cell.managerLabel.text = ""
            cell.receivedLabel.text = ""
            cell.meLabel.text = "Me"
            cell.sendLabel.text = message.content
        }
        else
        {
            cell.managerLabel.text = "Manager"
            cell.receivedLabel.text = message.content
            cell.meLabel.text = ""
            cell.sendLabel.text = ""
        }
        
        return cell
    }
    
    func loadMessages()
    {
        guard let appDelegate =
                UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        
        let managedContext =
            appDelegate.persistentContainer.viewContext
        
        let fetchRequest =
            NSFetchRequest<NSManagedObject>(entityName: "Message")

        do {
            messages = try managedContext.fetch(fetchRequest) as! [Message]
            messages = messages.sorted(by: { $0.sendTime! < $1.sendTime! })
            
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
        }
    }
    
    func downloadMessages()
    {
        _ = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if(self.isRunning ==  true)
            {
                return
            }
            
            self.isRunning = true
            let workItem = DispatchWorkItem {
                    ApiRepository.shared.getMessage (from : self.tableNo!){ [self] messagesArray, error in
                        if (error != nil)
                        {
                            return
                        }
                        
                        if(messagesArray == nil)
                        {
                            return
                        }
                        
                        for messageItem in messagesArray! {
                            let sendTime = messageItem["sendTime"] as! String
                            let content = messageItem["content"] as! String
                            let isCustomer = messageItem["isCustomer"] as! Int
                            
                            let existing = messages.filter {$0.sendTime == sendTime }.first
                            
                            if(existing == nil)
                            {
                                DispatchQueue.main.async {
                                    if(messages.filter {$0.sendTime == sendTime }.first != nil)
                                    {
                                        return
                                    }
                                    
                                    guard let appDelegate =
                                            UIApplication.shared.delegate as? AppDelegate else {
                                        return
                                    }
                                    
                                    let managedContext =
                                        appDelegate.persistentContainer.viewContext
                                    
                                    let newMessage = Message(context: managedContext)
                                    newMessage.content = content
                                    newMessage.isCustomer = isCustomer == 1 ? true : false
                                    newMessage.sendTime = sendTime
                                    messages.append(newMessage)

                                    do {
                                        try managedContext.save()
                                        self.tableView.reloadData()
                                    } catch {
                                        let nserror = error as NSError
                                        fatalError("Unresolved Error \(nserror), \(nserror.userInfo)")
                                    }
                                }
                            }
                        }
                    }
            }
            
            DispatchQueue.global(qos: .utility).async {
                workItem.perform()
            }
            
            workItem.notify(queue: DispatchQueue.main, execute: {
                self.isRunning = false
                self.tableView.reloadData()
                self.scrollToBottom()
            })

        }
    }
    
    func scrollToBottom(){
        DispatchQueue.main.async { [self] in
            let indexPath = IndexPath(
                row: self.tableView.numberOfRows(inSection:  self.tableView.numberOfSections-1) - 1,
                section: self.tableView.numberOfSections - 1)
            if hasRowAtIndexPath(indexPath : indexPath) {
                self.tableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
            }
        }
    }
    
    func hasRowAtIndexPath(indexPath: IndexPath) -> Bool {
        return indexPath.section < self.tableView.numberOfSections && indexPath.row >= 0 && indexPath.row < self.tableView.numberOfRows(inSection: indexPath.section)
    }
}
