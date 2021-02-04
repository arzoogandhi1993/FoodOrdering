//
//  AllChatsTableViewController.swift
//  MyFoodManager
//
//  Created by animesh seth on 12/15/20.
//

import UIKit
import CoreData

class AllChatsTableViewCell: UITableViewCell {

    @IBOutlet weak var tableNoField: UILabel!
    @IBOutlet weak var newMessageField: UILabel!
}

class AllChatsTableViewController: UITableViewController {
    
    var listVisible : Bool = false
    var isRunning : Bool = false
    var allTableMessages : [Int64 : [Message]] = [Int64 : [Message]]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.loadMessages()
        self.downloadMessages()
        self.tableView.reloadData()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }
    
    override func viewDidAppear(_ animated: Bool) {
        listVisible = true
        self.tabBarItem.badgeValue = ""
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        listVisible = false 
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return allTableMessages.count
    }


    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "allChatCell", for: indexPath) as! AllChatsTableViewCell
        
        let tableNo: Int64 = Array(allTableMessages.keys)[indexPath.row]
        cell.tableNoField.text = String(tableNo)
        let messages = allTableMessages[tableNo]
        
        let unreadCount = messages?.filter {$0.read == false}.count
        if(unreadCount == 0)
        {
            cell.newMessageField.backgroundColor = .none
            cell.newMessageField.text = ""
        }
        else {
            //cell.newMessageField.backgroundColor = .green
            //cell.newMessageField.text = "New"
        }

        return cell
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let chatTableViewController = segue.destination as? ChatViewController {
            let sel = self.tableView.indexPathForSelectedRow?.row
            let tableNo: Int64 = Array(allTableMessages.keys)[sel!]
            chatTableViewController.messages = allTableMessages[tableNo]
            chatTableViewController.tableNo = tableNo
        }
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
            var messages = try managedContext.fetch(fetchRequest) as! [Message]
            messages = messages.sorted(by: { $0.sendTime! < $1.sendTime! })
            
            for (message) in messages {
                if let _ = allTableMessages[message.tableNo]
                {
                    allTableMessages[message.tableNo]?.append(message)
                }
                else
                {
                    allTableMessages[message.tableNo] = []
                    allTableMessages[message.tableNo]?.append(message)
                }
            }
            
            
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
        }
    }
    
    func saveMessages(newMessages: [String : Any])
    {
        DispatchQueue.main.async {
            
            guard let appDelegate =
                    UIApplication.shared.delegate as? AppDelegate else {
                return
            }
            
            let managedContext =
                appDelegate.persistentContainer.viewContext
            
            for (tableNoStr , anyMessages) in newMessages {
                let tableNo = Int64(tableNoStr)!
                
                let messages = anyMessages as! [[String : Any]]
                
                for (messageItem) in messages {
                    let sendTime = messageItem["sendTime"] as! String
                    let content = messageItem["content"] as! String
                    let isCustomer = messageItem["isCustomer"] as! Int
                    
                    var tableMessages : [Message] = [Message]()
                    if let _ = self.allTableMessages[tableNo] {
                        tableMessages = self.allTableMessages[tableNo]!
                    }
                    else
                    {
                        self.allTableMessages[tableNo] = tableMessages
                    }
                    
                    let total = tableMessages.filter {($0.sendTime?.elementsEqual(sendTime))! }.count
                    print("total : \(total), tableMessages : \(tableMessages.count) \(sendTime)")
                    
                    let existing = tableMessages.filter {$0.sendTime == sendTime }.first

                    if(existing == nil)
                    {
                        let newMessage = Message(context: managedContext)
                        newMessage.content = content
                        newMessage.isCustomer = isCustomer == 1 ? true : false
                        newMessage.sendTime = sendTime
                        newMessage.tableNo = tableNo
                        newMessage.read = false
                        tableMessages.append(newMessage)

                        do {
                            print("message Stored")
                            try managedContext.save()
                            self.allTableMessages[tableNo] = tableMessages
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
    
    func downloadMessages()
    {
        _ = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if(self.isRunning ==  true)
            {
                return
            }
            
            self.isRunning = true
            let workItem = DispatchWorkItem {
                    ApiRepository.shared.getMessages { [self] messagesArray, error in
                        if (error != nil)
                        {
                            return
                        }
                        
                        if(messagesArray == nil)
                        {
                            return
                        }
                        
                        var newMessages : [String : Any] = [String : Any]()
                        
                        for (tableNoStr, anyMessages) in messagesArray! {
                            
                            let tableNo = Int64(tableNoStr)!
                            
                            var tableMessages : [Message] = [Message]()
                            if let _ = allTableMessages[tableNo] {
                                tableMessages = allTableMessages[tableNo]!
                            }
                            else
                            {
                                allTableMessages[tableNo] = tableMessages
                            }
                            
                            let messages = anyMessages as! [[String : Any]]
                            var newTableMessages : [Any] = []
                            for (messageItem) in messages {
                                let sendTime = messageItem["sendTime"] as! String
                                
                                let existing = tableMessages.filter {$0.sendTime == sendTime }.first

                                if(existing == nil)
                                {
                                    if let _ = newMessages[tableNoStr]
                                    {
                                        newTableMessages = newMessages[tableNoStr] as! [Any]
                                    }
                                    else{
                                        newMessages[tableNoStr] = newTableMessages
                                    }
                                    
                                    newTableMessages.append(messageItem)
                                }
                            }
                            
                            if(newTableMessages.count > 0)
                            {
                                newMessages[tableNoStr] = newTableMessages
                            }
                        }
                        
                        if(newMessages.count > 0)
                        {
                            saveMessages(newMessages: newMessages)
                        }
                    }
            }
            
            DispatchQueue.global(qos: .utility).async {
                workItem.perform()
            }
            
            workItem.notify(queue: DispatchQueue.main, execute: {
                self.isRunning = false
                self.tableView.reloadData()
            })

        }
    }

}
