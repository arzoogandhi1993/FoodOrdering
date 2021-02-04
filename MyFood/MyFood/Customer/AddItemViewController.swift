//
//  AddItemViewController.swift
//  MyFood
//
//  Created by animesh seth on 12/11/20.
//

import UIKit

class AddItemViewController: UIViewController {
    var menuItem : MenuItem?
    var quantity : Int64?
    var tableNo : Int64?
    @IBOutlet weak var img: UIImageView!

    @IBOutlet weak var name: UITextView!
    @IBOutlet weak var quant: UITextField!
    @IBOutlet weak var detail: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupHideKeyboardOnTap()
        // Do any additional setup after loading the view.
        name.text = menuItem?.name
        quant.text = "1"
        detail.text = menuItem?.detail
        if(menuItem?.imgUrl != nil)
        {
            let imageUrl = menuItem?.imgUrl
            let documentDirectory = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first
            let localPath = documentDirectory?.appending((imageUrl!))
            let newUrl = URL(fileURLWithPath: localPath!)
            let imageData = try! Data(contentsOf: newUrl)
            img.image = UIImage(data: imageData)
        }
    }
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        
        let quantField : String = getTextField(textField: quant)
        
        if(quantField.count == 0)
        {
            self.addAlert(title: "Error", msg: "quantity cannot be empty")
            return false
        }
        
        let tempQuant = Int64(quantField)
        if(tempQuant == nil)
        {
            self.addAlert(title: "Error", msg: "Invalid quantity value")
            return false
        }
        
        if(tempQuant! < 1 || tempQuant! > 20)
        {
            self.addAlert(title: "Error", msg: "Quantity should be in the range of 1 to 20")
            return false
        }
        
        self.quantity = tempQuant!
        
        self.addItemToCart()
        
        return true
    }
    
    func addItemToCart()
    {
        let currentDate = Date()
        let since1970 = currentDate.timeIntervalSince1970
        let msSecs = String(since1970 * 1000)
        let json: [String: Any] =
            [
                "imgUrl": menuItem?.imgUrl as Any,
                "name" : menuItem?.name as Any,
                "price" : menuItem?.price as Any,
                "quantity" : self.quantity as Any,
                "subOrderid" : UUID().uuidString,
                "sendTime" : msSecs
            ]

        ApiRepository.shared.addItem(from : self.tableNo!, from : json) {
            [self] resultArray, error in
                if (error != nil)
                {
                    return
                }
                
                if(resultArray == nil)
                {
                    return
                }
        }
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

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
