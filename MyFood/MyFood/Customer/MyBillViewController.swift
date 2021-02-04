//
//  MyBillViewController.swift
//  MyFood
//
//  Created by animesh seth on 12/11/20.
//

import UIKit
import CoreData

class MyBillViewController: UIViewController {

    var order : Order?
    var isRunning : Bool = false
    var orderId : String?
    @IBOutlet weak var billField: UILabel!
    @IBOutlet weak var payButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupHideKeyboardOnTap()
        self.payButton.isEnabled = false
        self.loadOrder()
        self.orderId = self.order?.orderId
        self.billField.text = "0.0"
        // Do any additional setup after loading the view.
    }
    
    func trigger()
    {
        if(self.order?.isComplete == false) {
            self.payButton.isEnabled = false
            self.payButton.backgroundColor = .gray
            
            var total : Double = 0.0

            let orderItems = self.order?.orderItems?.allObjects as? [OItem]
            for(orderItem) in orderItems! {
                total += (orderItem.price) * Double(orderItem.quantity)
            }

            self.billField.text =  String(format: "%.2f", total)

        } else {
            self.payButton.isEnabled = true
            self.payButton.backgroundColor = .blue
            
            if(self.order?.isPaid == true)
            {
            } else {
                var total : Double = 0.0

                let orderItems = self.order?.orderItems?.allObjects as? [OItem]
                for(orderItem) in orderItems! {
                    total += orderItem.price * Double(orderItem.quantity)
                }
                
                self.billField.text =  String(format: "%.2f", total)
            }
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
                    if(tempOrders.count == 0)
                    {
                        return
                    }
                    
                    let tempOrder = tempOrders.first!
                    self.order = tempOrder
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
        
        if(self.order?.orderItems?.allObjects.count != order.orderItems?.allObjects.count)
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
    
    @IBAction func payAction(_ sender: Any) {
        ApiRepository.shared.markPaid(from: (self.order?.orderId!)!) {
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
                    let OKAction = UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: {
                             (_)in
                        _ = navigationController?.popViewController(animated: true)
                         })
                     
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
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
