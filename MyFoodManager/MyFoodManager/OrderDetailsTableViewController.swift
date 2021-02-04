//
//  OrderDetailsTableViewController.swift
//  MyFoodManager
//
//  Created by animesh seth on 12/16/20.
//

import UIKit
import CoreData

class MyOrderTableViewCell: UITableViewCell {
    @IBOutlet weak var itemImage: UIImageView!
    @IBOutlet weak var itemName: UILabel!
    @IBOutlet weak var itemQuantity: UILabel!
}

class OrderDetailsTableViewController: UITableViewController {
    var order : Order?
    var orderId : String?
    var orderItems : [OItem] = [OItem]()
    var isRunning : Bool = false
    
    @IBOutlet weak var done: UIBarButtonItem!
    @IBOutlet weak var paid: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.loadOrder()
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return orderItems.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "orderItemCell", for: indexPath) as! MyOrderTableViewCell
        
        orderItems = orderItems.sorted(by: {$0.createTime! < $1.createTime!})
        var items = orderItems[indexPath.row]
        cell.itemName?.text = orderItems[indexPath.row].name
        cell.itemQuantity?.text = String(orderItems[indexPath.row].quantity)
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
    
    func trigger()
    {
        if(self.order != nil && self.order?.isComplete == false) {
            self.done.isEnabled = true
            self.paid.isEnabled = false

        } else {
            self.done.isEnabled = false
            if(self.order != nil && self.order?.isPaid == false) {
                self.paid.isEnabled = true

            } else {
                self.paid.isEnabled = false
            }
        }
        
        self.tableView.reloadData()
    }
        
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let chatTableViewController = segue.destination as? ChatViewController {
            chatTableViewController.messages = []
            chatTableViewController.tableNo = self.order?.tableNo
        }
    }
    
    func loadOrder()
    {
        _ = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [self] _ in
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
                    NSFetchRequest<NSManagedObject>(entityName: "Order")
                fetchRequest.predicate = NSPredicate(format: "orderId == %@", argumentArray: [self.orderId!])

                do {
                    let tempOrders = try managedContext.fetch(fetchRequest) as! [Order]
                    let tempOrder = tempOrders.first!
                    self.order = tempOrder
                    self.orderItems = tempOrder.orderItems?.allObjects as! [OItem]
                    self.trigger()
                } catch let error as NSError {
                    print("Could not fetch. \(error), \(error.userInfo)")
                }
            
                self.isRunning = false
            }

    }
    
    func areOrderDiff(order : Order) -> Bool{
        if(self.order == nil)
        {
            return true
        }
        
        if(self.orderItems.count != order.orderItems?.allObjects.count)
        {
            return true
        }
        
        if(self.order?.isComplete != order.isComplete)
        {
            return true
        }
        
        if(self.order?.isPaid != order.isPaid)
        {
            return true
        }
        
        return false
    }
    
    @IBAction func markDone(_ sender: Any) {
        ApiRepository.shared.markComplete(from: self.orderId!) {
            [self] responseJson, error in
                if (error != nil)
                {
                    return
                }
            
                if(responseJson == nil)
                {
                    return
                }
            
            let result = responseJson!["status"] as! String
            if(result == "Success")
            {
                DispatchQueue.main.async {
                    let alert = UIAlertController(title: "Success", message: "Order Marked as Complete", preferredStyle: .alert)
                    let OKAction = UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil)
                         alert.addAction(OKAction)
                         self.present(alert, animated: true, completion: nil)
                }
            } else {
                DispatchQueue.main.async {

                    let alert = UIAlertController(title: "Failure", message: "Error occured when trying to complete the order", preferredStyle: .alert)
                    let OKAction = UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil)
                         alert.addAction(OKAction)
                         self.present(alert, animated: true, completion: nil)
                }
            }
        }
    }
    
    @IBAction func markPaid(_ sender: Any) {
        ApiRepository.shared.markPaid(from: self.orderId!) {
            [self] responseJson, error in
                if (error != nil)
                {
                    return
                }
            
                if(responseJson == nil)
                {
                    return
                }
            
            let result = responseJson!["status"] as! String
            if(result == "Success")
            {
                DispatchQueue.main.async {
                    let alert = UIAlertController(title: "Success", message: "Order Marked as Paid", preferredStyle: .alert)
                    let OKAction = UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil)
                         alert.addAction(OKAction)
                         self.present(alert, animated: true, completion: nil)
                }
            } else {
                DispatchQueue.main.async {

                    let alert = UIAlertController(title: "Failure", message: "Error occured when trying to mark the order as paid", preferredStyle: .alert)
                    let OKAction = UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil)
                         alert.addAction(OKAction)
                         self.present(alert, animated: true, completion: nil)
                }
            }
        }
    }
}
    
