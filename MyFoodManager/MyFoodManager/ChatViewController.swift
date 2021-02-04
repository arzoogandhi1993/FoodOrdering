//
//  ChatViewController.swift
//  MyFoodManager
//
//  Created by animesh seth on 12/16/20.
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


    @IBOutlet weak var inputMessage: UITextField!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var sendButton: UIButton!
    var tableNo : Int64?
    var messages :[Message]?
    var count = 0
    var isRunning : Bool = false
    @IBOutlet weak var uiView: UIView!
    var appDelegate : AppDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupHideKeyboardOnTap()
        self.downloadMessages()
        self.title = "Table No " + String(tableNo!)

        //self.tableView.delegate = self
        self.tableView.dataSource = self
        //self.input.delegate = self
        self.count = self.messages?.count ?? 0
        self.tableView.reloadData()

    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.tableView.reloadData()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        //self.tableView.frame = CGRect(x:0, y:0, width : self.view.frame.size.width, height : self.view.frame.size.height - 200)
        self.scrollToBottom()
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        self.view.layoutIfNeeded()
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        self.view.layoutIfNeeded()
    }
        
    @IBAction func sendMessage(_ sender: Any) {
        self.inputMessage.endEditing(true)
        let msg = getTextField(textField: inputMessage)
        if(msg.count == 0)
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
        return messages?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "myChatCell", for: indexPath) as! MyChatTableViewCell
        
        let message = messages![indexPath.row]
        if(message.isCustomer == true)
        {
            cell.managerLabel.text = "Customer"
            cell.receivedLabel.text = message.content
            cell.meLabel.text = ""
            cell.sendLabel.text = ""
        }
        else
        {
            cell.managerLabel.text = ""
            cell.receivedLabel.text = ""
            cell.meLabel.text = "me"
            cell.sendLabel.text = message.content
        }
        
        return cell
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
        print(indexPath.section)
        print(indexPath.row)
        return indexPath.section < self.tableView.numberOfSections && indexPath.row >= 0 && indexPath.row < self.tableView.numberOfRows(inSection: indexPath.section)
    }
    
    func downloadMessages()
    {
        _ = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if(self.isRunning ==  true)
            {
                return
            }
            
            self.isRunning = true
                guard let appDelegate =
                        UIApplication.shared.delegate as? AppDelegate else {
                    return
                }
                
                let managedContext =
                    appDelegate.persistentContainer.viewContext
                
                let fetchRequest =
                    NSFetchRequest<NSManagedObject>(entityName: "Message")
                fetchRequest.predicate = NSPredicate(format: "tableNo == %@", argumentArray: [self.tableNo!])

                do {
                    var tempMessages = try managedContext.fetch(fetchRequest) as! [Message]
                    tempMessages = tempMessages.sorted(by: { $0.sendTime! < $1.sendTime! })
                    
                    if(tempMessages.count > self.messages!.count)
                    {
                        for(tempMessage) in tempMessages {
                            tempMessage.read = true
                        }

                        self.messages = tempMessages
                        self.tableView.reloadData()
                        self.scrollToBottom()
                    }
                    
                } catch let error as NSError {
                    print("Could not fetch. \(error), \(error.userInfo)")
                }
            
                self.isRunning = false
            }

    }
}

