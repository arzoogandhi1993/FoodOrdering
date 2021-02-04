//
//  CreateOrderViewController.swift
//  MyFood
//
//  Created by animesh seth on 12/10/20.
//

import UIKit

class CreateOrderViewController: UIViewController {

    @IBOutlet weak var tableNumber: UITextField!
    @IBOutlet weak var submit: UIButton!
    var tableNo : Int64 = 0
    var orderId : String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupHideKeyboardOnTap()

        // Do any additional setup after loading the view.
    }
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        
        return isValidTableNo()
    }
    
    func isValidTableNo() -> Bool{
            
            let table : String = getTextField(textField: tableNumber)
            
            if(table.count == 0)
            {
                self.addAlert(title: "Error", msg: "Table number cannot be empty")
                return false
            }
            
            let tableNum = Int64(table)
            if(tableNum == nil)
            {
                self.addAlert(title: "Error", msg: "Invalid table number")
                return false
            }
            
            if(tableNum! < 1 || tableNum! > 100)
            {
                self.addAlert(title: "Error", msg: "Table number should be in the range of 1 to 100")
                return false
            }
            
            self.tableNo = tableNum!
            
            return true
    }
    
    func createOrder(tableNum : Int64) -> Bool{
        
        var result = false
        ApiRepository.shared.createOrder(from: tableNum){ [self] resultArray, error in
            if (error != nil)
            {
                result = false
                return
            }
            
            if(resultArray == nil)
            {
                result = false
                return
            }
            
            let status = resultArray!["status"] as! String
            self.orderId = resultArray!["orderId"] as! String
            if(status == "Success")
            {
                result = true


            }
        }
        
        return result
    }
    
    
    func addAlert(title : String, msg : String) {
        let alertController = UIAlertController(title: title, message: msg, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "Ok", style: .default, handler: nil)
        alertController.addAction(okAction)
        self.present(alertController, animated: true, completion: nil)
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
    
    @IBAction func submitAction(_ sender: Any) {
        if(!isValidTableNo())
        {
            return
        }
        
        ApiRepository.shared.createOrder(from: self.tableNo) {
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
                let tempOrderId = responseJson!["orderId"] as! String
                DispatchQueue.main.async {
                    /*
                    let alert = UIAlertController(title: "Success", message: "Menu Item Updated", preferredStyle: .alert)
                    let OKAction = UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: {
                             (_)in
                        _ = navigationController?.popViewController(animated: true)
                         })
                     
                         alert.addAction(OKAction)
                         self.present(alert, animated: true, completion: nil)
                     */
                    self.orderId = tempOrderId
                    self.performSegue(withIdentifier: "onUnwindMyOrder", sender: self)

                }
            } else {
                DispatchQueue.main.async {

                    let alert = UIAlertController(title: "Failure", message: "Table Booked at the moment. Please select another table", preferredStyle: .alert)
                    let OKAction = UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil)
                         alert.addAction(OKAction)
                         self.present(alert, animated: true, completion: nil)
                }
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let myOrderTableViewController = segue.destination as? MyOrderTableViewController {
            myOrderTableViewController.order = nil
            myOrderTableViewController.isRunning = false
            myOrderTableViewController.orderId = self.orderId

            //myOrderTableViewController.table = table
        }
    }
}
