//
//  MenuDetailsViewController.swift
//  MyFoodManager
//
//  Created by animesh seth on 12/17/20.
//

import UIKit

class MenuDetailsViewController: UIViewController {

    @IBOutlet weak var nameField: UITextField!
    @IBOutlet weak var urlField: UITextField!
    @IBOutlet weak var typeField: UITextField!
    @IBOutlet weak var priceField: UITextField!
    @IBOutlet weak var detailsFeild: UITextView!
    
    var menuItem : MenuItem?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupHideKeyboardOnTap()
        if(menuItem != nil)
        {
            self.nameField.text = menuItem?.name
            self.urlField.text = menuItem?.completeUrl
            self.typeField.text = menuItem?.type
            self.priceField.text = String(format: "%.2f",  menuItem?.price as! CVarArg)
            self.detailsFeild.text = menuItem?.detail
        }
        
        // Do any additional setup after loading the view.
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
    
    func getTextField(textField : UITextView) -> String
    {
        var fieldValue : String = ""
        //Get One By One with Tag
        if((textField.text) != nil)
        {
            fieldValue = textField.text!
        }
        
        return fieldValue
    }
    
    @IBAction func saveAction(_ sender: Any) {
        
        let name : String = getTextField(textField: self.nameField)
        let priceStr : String = getTextField(textField: priceField)
        let url : String = getTextField(textField: urlField)
        let type : String = getTextField(textField: typeField)
        let details : String = getTextField(textField: detailsFeild)
        
        if(name.count == 0) {
            self.addAlert(title: "Error", msg: "Name cannot be empty")
            return
        }
        
        if(url.count == 0) {
            self.addAlert(title: "Error", msg: "URL Cannot be Empty")
            return
        } else if NSURL(string: url) != nil {

        } else {
            self.addAlert(title: "Error", msg: "URL is not valid")
            return
        }
        
        if(type.count == 0) {
            self.addAlert(title: "Error", msg: "Type is not valid")
            return
        }
        
        if(priceStr.count == 0)
        {
            self.addAlert(title: "Error", msg: "Price cannot be empty")
            return
        } else if Double(priceStr) != nil {
            
        } else {
            self.addAlert(title: "Error", msg: "Price is invalid")
            return
        }
        
        if(details.count == 0)
        {
            self.addAlert(title: "Error", msg: "Details cannot be empty")
            return
        }
        
        var jsonBody : [String : Any] = [:]
        jsonBody["name"] = self.nameField.text
        jsonBody["imgUrl"] = self.urlField.text
        jsonBody["price"] = Double(self.priceField.text!)
        jsonBody["description"] = self.detailsFeild.text
        jsonBody["type"] = self.typeField.text

        if(self.menuItem == nil) {
            jsonBody["Id"] = UUID().uuidString
            ApiRepository.shared.createMenu(from: jsonBody){
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
                            let alert = UIAlertController(title: "Success", message: "Menu Item Added", preferredStyle: .alert)
                            let OKAction = UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: {
                                     (_)in
                                _ = navigationController?.popViewController(animated: true)
                                 })
                             
                                 alert.addAction(OKAction)
                                 self.present(alert, animated: true, completion: nil)

                        }
                    }
            }
        }
        else{
            jsonBody["Id"] = self.menuItem?.id
            ApiRepository.shared.updateMenu(from: (self.menuItem?.id)!, from: jsonBody){
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
                            let alert = UIAlertController(title: "Success", message: "Menu Item Updated", preferredStyle: .alert)
                            let OKAction = UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: {
                                     (_)in
                                _ = navigationController?.popViewController(animated: true)
                                 })
                             
                                 alert.addAction(OKAction)
                                 self.present(alert, animated: true, completion: nil)

                        }
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
