//
//  MyOrderTableViewController.swift
//  MyFood
//
//  Created by animesh seth on 12/11/20.
//

import UIKit
import CoreData

class MyOrderTableViewCell: UITableViewCell {
    @IBOutlet weak var itemImage: UIImageView!
    @IBOutlet weak var itemName: UILabel!
    @IBOutlet weak var itemQuantity: UILabel!
    
}

class MyOrderTableViewController: UITableViewController {

    var orderId : String?
    var order : Order?
    @IBOutlet weak var menuButton: UIBarButtonItem!
    @IBOutlet weak var billButton: UINavigationItem!
    var message : String?
    var isRunning : Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupHideKeyboardOnTap()
        self.downloadOrder()
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if(self.orderId == nil)
        {
            tryLoadOrder()
            if(self.orderId == nil)
            {
                loadLoginScreen()
            }
        }
        else if (message != nil) {
            self.addAlert(title: "", msg: message!)
            message = nil
        }
        
        self.tableView.reloadData()
    }

    override func viewWillAppear(_ animated: Bool) {
        self.tableView.reloadData()
    }
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return self.order?.orderItems?.count ?? 0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "orderItemCell", for: indexPath) as! MyOrderTableViewCell

        var orderItems = order?.orderItems?.allObjects as! [OItem]
        orderItems = orderItems.sorted(by: { $0.createTime! < $1.createTime! })
        cell.itemName?.text = orderItems[indexPath.row].name
        let total = (orderItems[indexPath.row].price) * Double(orderItems[indexPath.row].quantity)
        cell.itemQuantity?.text = String(orderItems[indexPath.row].quantity) + " X " + String(orderItems[indexPath.row].price) + " = " +  String(format: "%.2f", total)
        if(orderItems[indexPath.row].imgUrl != nil && (orderItems[indexPath.row].imgUrl!.count) > 0)
        {
            let imageUrl = orderItems[indexPath.row].imgUrl
            let documentDirectory = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first
            let localPath = documentDirectory?.appending((imageUrl!))
            let newUrl = URL(fileURLWithPath: localPath!)
            let imageData = try! Data(contentsOf: newUrl)
            cell.itemImage?.image = UIImage(data: imageData)
            
        }
       return cell        
    }
    
    @IBAction func onUnwind(unwindSegue : UIStoryboardSegue) {
        if let createOrderViewController = unwindSegue.source as? CreateOrderViewController {
            let tableNo = createOrderViewController.tableNo
            let orderId = createOrderViewController.orderId
            
            guard let appDelegate =
                    UIApplication.shared.delegate as? AppDelegate else {
                return
            }
            
            // 1
            let managedContext =
                appDelegate.persistentContainer.viewContext
            
            order = Order(context : managedContext)
            order?.tableNo = tableNo
            order?.orderId = orderId
            do {
                try managedContext.save()
                message = "Please start adding Items from Menu to place your order"
            } catch let error as NSError {
                print("Could not save. \(error), \(error.userInfo)")
            }
        } else if let addItemViewontroller = unwindSegue.source as? AddItemViewController {
            let menuItem = addItemViewontroller.menuItem
            
            message = "\(menuItem!.name as! String) Ordered"
        } else {
            return
        }
        
        tableView.reloadData()
    }
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        if(identifier == "menuListSegue")
        {
            if(self.order!.isComplete || self.order!.isPaid)
            {
                addAlert(title: "Failure", msg: "Your order is now completed. Please pay in order to start your new order")
                return false
            }
        }
        
        return true
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let menuTableViewController = segue.destination as? MenuTableViewController {
            menuTableViewController.tableNo = order?.tableNo
        } else if let chatTableViewController = segue.destination as? ChatViewController {
            chatTableViewController.tableNo = order?.tableNo
        } else if let billTableViewController = segue.destination as? MyBillViewController {
            billTableViewController.order = self.order
        }
    }
    
    func loadLoginScreen(){
        let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let createOrderViewController = storyBoard.instantiateViewController(withIdentifier: "CreateOrderViewController") as! CreateOrderViewController
        createOrderViewController.modalPresentationStyle = .fullScreen
        self.present(createOrderViewController, animated: true, completion: nil)
     }
    
    func tryLoadOrder() {
        guard let appDelegate =
                UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        
        let managedContext =
            appDelegate.persistentContainer.viewContext
        
        let fetchRequest =
            NSFetchRequest<NSManagedObject>(entityName: "Order")
        
        do {
            let allOrders = try managedContext.fetch(fetchRequest) as! [Order]
            if(allOrders.count > 0)
            {
                self.order = allOrders.first!
                self.orderId = allOrders.first!.orderId!
            }
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
        }
    }
    
    func downloadOrder()
    {
        _ = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if(self.isRunning ==  true || self.order == nil)
            {
                return
            }
            
            self.isRunning = true
            if(self.order == nil || self.order == nil || self.order?.orderId == nil)
            {
                return
            }
            
            let workItem = DispatchWorkItem {
                ApiRepository.shared.getOrder(from : (self.order?.orderId!)!) { [self] orderJson, error in
                    if (error != nil)
                    {
                        return
                    }
                    
                    if(orderJson == nil)
                    {
                        return
                    }
                
                    let isComplete = orderJson!["isComplete"] as! Bool
                    let orderItems = orderJson!["orderItems"] as! [[String : Any]]
                    let isPaid = orderJson!["isPaid"] as! Bool
                    
                    if(isComplete != order?.isComplete)
                    {
                        DispatchQueue.main.async {
                            if(self.order?.isComplete != true)
                            {
                                self.order?.isComplete = true
                                guard let appDelegate =
                                        UIApplication.shared.delegate as? AppDelegate else {
                                    return
                                }
                                
                                let managedContext =
                                    appDelegate.persistentContainer.viewContext

                                do {
                                    try managedContext.save()
                                    self.tableView.reloadData()
                                } catch {
                                    let nserror = error as NSError
                                    fatalError("Unresolved Error \(nserror), \(nserror.userInfo)")
                                }

                                self.addAlert(title: "Notice", msg: "Your order is now complete")
                            }
                        }
                    }
                    
                    if(isPaid != order?.isPaid)
                    {
                        DispatchQueue.main.async {
                            if(self.order?.isPaid != true)
                            {
                                do {
                                    self.order?.isPaid = true
                                    guard let appDelegate =
                                            UIApplication.shared.delegate as? AppDelegate else {
                                        return
                                    }
                                    
                                    let managedContext =
                                        appDelegate.persistentContainer.viewContext
                                    managedContext.delete(self.order!)
                                    try managedContext.save()
                                    
                                    let fetchRequest =
                                        NSFetchRequest<NSManagedObject>(entityName: "Message")

                                    do {
                                        let messages = try managedContext.fetch(fetchRequest) as? [Message]
                                        
                                        for(message) in messages!{
                                            managedContext.delete(message)
                                        }
                                        
                                        try! managedContext.save()
                                        
                                    } catch let error as NSError {
                                        print("Could not fetch. \(error), \(error.userInfo)")
                                    }
                                    
                                    self.orderId = nil
                                    loadLoginScreen()
                                    
                                } catch {
                                    let nserror = error as NSError
                                    fatalError("Unresolved Error \(nserror), \(nserror.userInfo)")
                                }
                            }
                        }
                    }

                    
                    for(orderItem) in orderItems {
                        let subOrderId = orderItem["subOrderid"] as! String
                        let imgUrl = orderItem["imgUrl"] as! String
                        let name = orderItem["name"] as! String
                        let price = orderItem["price"] as! Double
                        let quantity = orderItem["quantity"] as! Int64
                        let createTime = orderItem["sendTime"] as! String
                        
                        let subOrders = order?.orderItems?.allObjects as? [OItem]
                        if(subOrders == nil)
                        {
                            return
                        }
                        
                        let existing = subOrders!.filter {subOrderId == $0.subOrderId}.first
                        if(existing == nil)
                        {
                            DispatchQueue.main.async {
                                let subOrdersTemp = order?.orderItems?.allObjects as! [OItem]
                                if(subOrdersTemp.filter {$0.subOrderId == subOrderId }.first != nil)
                                {
                                    return
                                }
                                
                                guard let appDelegate =
                                        UIApplication.shared.delegate as? AppDelegate else {
                                    return
                                }
                                
                                let managedContext =
                                    appDelegate.persistentContainer.viewContext
                                
                                let newSubOrder = OItem(context: managedContext)
                                newSubOrder.subOrderId = subOrderId
                                newSubOrder.imgUrl = imgUrl
                                newSubOrder.name = name
                                newSubOrder.price = price
                                newSubOrder.quantity = quantity
                                newSubOrder.createTime = createTime
                                order?.addToOrderItems(newSubOrder)

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
            })
        }
    }
    
    func addAlert(title : String, msg : String) {
        let alertController = UIAlertController(title: title, message: msg, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "Ok", style: .default, handler: nil)
        alertController.addAction(okAction)
        self.present(alertController, animated: true, completion: nil)
    }
}
