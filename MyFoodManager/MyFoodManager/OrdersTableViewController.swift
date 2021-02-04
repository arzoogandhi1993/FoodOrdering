//
//  OrdersTableViewController.swift
//  MyFoodManager
//
//  Created by animesh seth on 12/15/20.
//

import UIKit
import CoreData

class OrderCell :UITableViewCell{
    
    @IBOutlet weak var tableField: UILabel!
    @IBOutlet weak var countField: UILabel!
    @IBOutlet weak var statusField: UILabel!
}

class OrdersTableViewController: UITableViewController {

    fileprivate let globalBackgroundSyncronizeDataQueue = DispatchQueue.init(label: "globalBackgroundSyncronizeSharedData")
    var orders : [Order]?
    //Variable accessor that can be accessed from anywhere (multithread-protected).

    var concurrentOrders : [Order]? {
        set(newValue){
            globalBackgroundSyncronizeDataQueue.sync(){

                self.orders = newValue

            }
        }

        get{
            return globalBackgroundSyncronizeDataQueue.sync{
                self.orders
            }
        }
    }
    
    var isRunning : Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.downloadMenu()
        loadOrders()
        downloadOrders()
        
        self.tableView.reloadData()
    }
    

    
    override func viewWillAppear(_ animated: Bool) {
        self.tableView.reloadData()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        self.tabBarItem.badgeValue = ""
    }
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return orders?.count ?? 0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "orderCell", for: indexPath) as! OrderCell

        let order = orders![indexPath.row]
        
        cell.tableField?.text = "Table No: \(order.tableNo)"
        cell.countField?.text = "Items:\(order.orderItems?.count ?? 0)"
        if(order.isComplete)
        {
            if(order.isPaid)
            {
                cell.statusField.text = "Paid"
                cell.statusField.backgroundColor = .green
            } else {
                cell.statusField.text = "Complete"
                cell.statusField.backgroundColor = .yellow

            }
        }
        else {
            cell.statusField.text = "In-Progress"
            cell.statusField.backgroundColor = .blue
        }

       return cell
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let orderDetailsController = segue.destination as? OrderDetailsTableViewController {
            let sel = self.tableView.indexPathForSelectedRow?.row
            orderDetailsController.modalPresentationStyle = .fullScreen
            orderDetailsController.orderId = orders![sel!].orderId
        }
    }
    
    func loadOrders()
    {
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
                self.orders = allOrders
            }
            else
            {
                self.orders = []
            }
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
        }
    }
    
    func saveOrder(newOrders : [String : Any])
    {
        DispatchQueue.main.async {
            guard let appDelegate =
                    UIApplication.shared.delegate as? AppDelegate else {
                return
            }
            
            let managedContext =
                appDelegate.persistentContainer.viewContext
            
            for(orderId , anyOrder) in newOrders {
                let orderDetails = anyOrder as! [String : Any]
                let isComplete = orderDetails["isComplete"] as! Bool
                let subOrders = orderDetails["orderItems"] as! [[String : Any]]
                let creationTime = orderDetails["creationTime"] as! String
                let tableNo = Int64(orderDetails["tableNo"] as! String)
                let isPaid = orderDetails["isPaid"] as! Bool
                
                let existing = self.concurrentOrders?.filter {$0.orderId == orderId}.first
                
                if(existing == nil)
                {
                    let newOrder = Order(context: managedContext)
                    newOrder.orderId = orderId
                    newOrder.creationTime = creationTime
                    newOrder.isComplete = isComplete
                    newOrder.tableNo = tableNo!
                    newOrder.isPaid = isPaid
                    for (orderItem) in subOrders{
                        let subOrderId = orderItem["subOrderid"] as! String
                        let imgUrl = orderItem["imgUrl"] as! String
                        let name = orderItem["name"] as! String
                        let price = orderItem["price"] as! Double
                        let quantity = orderItem["quantity"] as! Int64
                        let createTime = orderItem["sendTime"] as! String
                        let subOrder = OItem(context: managedContext)
                        subOrder.subOrderId = subOrderId
                        subOrder.imgUrl = imgUrl
                        subOrder.name = name
                        subOrder.price = price
                        subOrder.quantity = quantity
                        subOrder.createTime = createTime
                        newOrder.addToOrderItems(subOrder)
                    }
                    
                    do {
                        print("New Order Stored")
                        try managedContext.save()
                        var tempOrders = self.concurrentOrders
                        tempOrders?.append(newOrder)
                        tempOrders = tempOrders?.sorted(by: { $0.creationTime! > $1.creationTime! })
                        self.orders = tempOrders
                        self.tableView.reloadData()
                    } catch {
                        let nserror = error as NSError
                        fatalError("Unresolved Error \(nserror), \(nserror.userInfo)")
                    }
                } else {
                    existing?.isComplete = isComplete
                    existing?.isPaid = isPaid
                    for (orderItem) in subOrders{
                        let subOrderId = orderItem["subOrderid"] as! String
                        let imgUrl = orderItem["imgUrl"] as! String
                        let name = orderItem["name"] as! String
                        let price = orderItem["price"] as! Double
                        let quantity = orderItem["quantity"] as! Int64
                        let createTime = orderItem["sendTime"] as! String
                        
                        let existingSubOrders = existing?.orderItems?.allObjects as! [OItem]
                        let existingSubOrder = existingSubOrders.filter {$0.subOrderId == subOrderId}.first
                        if(existingSubOrder == nil)
                        {
                            let subOrder = OItem(context: (existing?.managedObjectContext)!)
                            subOrder.subOrderId = subOrderId
                            subOrder.imgUrl = imgUrl
                            subOrder.name = name
                            subOrder.price = price
                            subOrder.quantity = quantity
                            subOrder.createTime = createTime
                            
                            existing?.addToOrderItems(subOrder)
                            
                            do {
                                print("New Order Stored")
                                try existing?.managedObjectContext!.save()
                                self.orders = self.concurrentOrders?.sorted(by: { $0.creationTime! > $1.creationTime! })
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
    }
    
    func downloadOrders()
    {
        _ = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
            if(self.isRunning ==  true)
            {
                return
            }
            
            self.isRunning = true
            let workItem = DispatchWorkItem {
                ApiRepository.shared.getOrders { [self] orderJson, error in
                    if (error != nil)
                    {
                        return
                    }
                    
                    if(orderJson == nil)
                    {
                        return
                    }
                    
                    var newOrders : [String : Any] = [String : Any]()
                    
                    for(tableNoStr, anyOrder) in orderJson! {
                        let orderDetails = anyOrder as! [String : Any]
                        let orderId = orderDetails["orderId"] as! String
                        let isComplete = orderDetails["isComplete"] as! Bool
                        let subOrders = orderDetails["orderItems"] as! [[String : Any]]
                        let isPaid = orderDetails["isPaid"] as! Bool
                        
                        let existing = self.concurrentOrders?.filter {$0.orderId == orderId}.first
                        if(existing == nil || existing?.isComplete != isComplete || existing?.orderItems?.count != subOrders.count
                            || existing?.isPaid != isPaid)
                        {
                            newOrders[tableNoStr] = anyOrder
                        }
                    }

                    if(newOrders.count != 0)
                    {
                        self.saveOrder(newOrders: newOrders)
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
    
    func downloadMenu()
    {
        let workItem = DispatchWorkItem {
            ApiRepository.shared.getMenu { [self] menusJson, error in
                if (error != nil)
                {
                    return
                }
                
                if(menusJson == nil)
                {
                    return
                }
                
                for(menuJson) in menusJson! {
                    let imageUrl = menuJson["imgUrl"] as! String
                    
                    DispatchQueue.global(qos: .background).async {
                        self.downloadImage(from: URL(string: imageUrl)!)
                    }
                }
            }
        }
        
        DispatchQueue.main.async {
            workItem.perform()
        }
    }
    
    func downloadImage(from url: URL) {
        print("Download Started")
        ApiRepository.shared.getData(from: url) { data, response, error in
            guard let data = data, error == nil else { return }
            print(response?.suggestedFilename ?? url.lastPathComponent)
            let imgName = url.lastPathComponent
            let documentDirectory = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first
            let localPath = documentDirectory?.appending(imgName)
            let image = UIImage(data: data)
            let imgData = image!.pngData()! as NSData
            imgData.write(toFile: localPath!, atomically: true)
            
            print("Download Finished")
        }
    }

}
