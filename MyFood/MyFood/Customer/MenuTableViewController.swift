//
//  MenuTableViewController.swift
//  MyFood
//
//  Created by animesh seth on 12/11/20.
//

import UIKit
import CoreData

class MyMenuTableViewCell: UITableViewCell {
    @IBOutlet weak var menuItemName: UILabel!
    @IBOutlet weak var menuItemImage: UIImageView!
    @IBOutlet weak var menuItemPrice: UILabel!
}

class MenuTableViewController: UITableViewController, UISearchBarDelegate {

    var allData : [String : [MenuItem]] = [String : [MenuItem]]()
    var filtered : [String : [MenuItem]] = [String : [MenuItem]]()
    var tableNo : Int64?
    var menuItems : [MenuItem] = [MenuItem]()
    var netWorkMonitor = NetworkMonitor()
    var isRunning : Bool = false

    @IBOutlet weak var searchBar: UISearchBar!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.netWorkMonitor.startMonitoring()
        searchBar.delegate = self
        self.loadMenu()
        self.downloadMenu()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        filtered = allData
        super.viewWillAppear(animated)
        self.tableView.reloadData()
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
            self.searchBar.showsCancelButton = true
    }
    
    // This method updates filteredData based on the text in the Search Box
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        // When there is no text, filteredData is the same as the original data
        // When user has entered text into the search box
        // Use the filter method to iterate over all items in the data array
        // For each item, return true if the item should be included and false if the
        // item should NOT be included
        
        if(searchText.isEmpty)
        {
            self.filtered = allData
        }
        else{
            var temp = [String : [MenuItem]]()
            
            for(menuType, menuItems) in allData {
                temp[menuType] = menuItems.filter{
                    $0.name!.localizedCaseInsensitiveContains(searchText) ||
                    $0.detail!.localizedCaseInsensitiveContains(searchText)
                }
            }
            
            
            for(type , items) in temp {
                filtered[type] = items.sorted(by: { $0.name! < $1.name! })
            }

            let sortedKeys = temp.keys.sorted()

            for key in sortedKeys {
                // Ordered iteration over the dictionary
                let val = temp[key]
                temp[key] = val
            }
            
            self.filtered = temp
        }
        
        self.tableView.reloadData()
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
            searchBar.showsCancelButton = false
            searchBar.text = ""
            searchBar.resignFirstResponder()
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return filtered.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        let intIndex = section // where intIndex < myDictionary.count
        let index = filtered.index(filtered.startIndex, offsetBy: intIndex)
        return filtered[filtered.keys[index]]!.count
    }


    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "myMenuCell", for: indexPath) as! MyMenuTableViewCell
        
        let index = filtered.index(filtered.startIndex, offsetBy: indexPath.section)
        cell.menuItemName?.text = filtered[filtered.keys[index]]![indexPath.row].name
        cell.menuItemPrice?.text = String(filtered[filtered.keys[index]]![indexPath.row].price)
        let img = filtered[filtered.keys[index]]![indexPath.row].imgUrl
        if(img !=  nil && img!.count > 0)
        {
            
            let documentDirectory = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first
            let localPath = documentDirectory?.appending(img!)
            let imgUrl = URL(fileURLWithPath: localPath!)
            let imageData = try! Data(contentsOf: imgUrl)
            cell.menuItemImage?.image = UIImage(data: imageData)
        }

        return cell
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let index = filtered.index(filtered.startIndex, offsetBy: section)
        return filtered.keys[index]
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if let addItemViewController = segue.destination as? AddItemViewController{
            let intIndex = self.tableView.indexPathForSelectedRow?.section // where intIndex < myDictionary.count
            let index = filtered.index(filtered.startIndex, offsetBy: intIndex!)
            let tempMenuItem = filtered[filtered.keys[index]]![self.tableView.indexPathForSelectedRow!.row]
            addItemViewController.menuItem = tempMenuItem
            addItemViewController.tableNo = tableNo
        }
    }
    
    func addAlert(title : String, msg : String) {
        let alertController = UIAlertController(title: title, message: msg, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "Ok", style: .default, handler: nil)
        alertController.addAction(okAction)
        self.present(alertController, animated: true, completion: nil)
    }
        
    func loadMenu()
    {
        guard let appDelegate =
                UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        
        let managedContext =
            appDelegate.persistentContainer.viewContext
        
        let fetchRequest =
            NSFetchRequest<NSManagedObject>(entityName: "MenuItem")

        do {
            self.menuItems = try managedContext.fetch(fetchRequest) as! [MenuItem]
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
        }
        self.triggerMenu()
        self.tableView.reloadData()
    }
    
    func saveMenu(addJson : [[String : Any]], deleteIds : [String], updateJson : [[String : Any]])
    {
        DispatchQueue.main.async {
            guard let appDelegate =
                    UIApplication.shared.delegate as? AppDelegate else {
                return
            }
            
            let managedContext =
                appDelegate.persistentContainer.viewContext
            
            for(addMenu) in addJson {
                let id = addMenu["Id"] as! String
                let existing = self.menuItems.filter {$0.id == id}.first
                if(existing == nil)
                {
                    let name = addMenu["name"] as! String
                    let imgUrl = addMenu["imgUrl"] as! String
                    let price = addMenu["price"] as! Double
                    let description = addMenu["description"] as! String
                    let type = addMenu["type"] as! String
                    
                    let menuItem = MenuItem(context: managedContext)
                    menuItem.id = id
                    menuItem.detail = description
                    menuItem.completeUrl = imgUrl
                    menuItem.imgUrl = ""
                    menuItem.price = price
                    menuItem.type = type
                    menuItem.name = name
                    
                    do {
                        try managedContext.save()
                        self.menuItems.append(menuItem)
                        
                    } catch {
                        let nserror = error as NSError
                        fatalError("Unresolved Error \(nserror), \(nserror.userInfo)")
                    }

                    DispatchQueue.global(qos: .background).async {
                        self.downloadImage(from: URL(string: imgUrl)!, menuItem: menuItem)
                    }
                }
            }
            
            for(deleteId) in deleteIds {
                let existing = self.menuItems.filter {$0.id == deleteId}.first
                
                if(existing != nil)
                {
                    do {
                        let temp = self.menuItems.filter {$0.id != deleteId}
                        managedContext.delete(existing!)
                        try managedContext.save()
                        self.menuItems = temp
                        
                    } catch {
                        let nserror = error as NSError
                        fatalError("Unresolved Error \(nserror), \(nserror.userInfo)")
                    }

                }
                
                
            }
            
            for (menuJson) in updateJson {
                let id = menuJson["Id"] as! String
                let existing  = self.menuItems.filter {$0.id == id}.first
                if(existing != nil)
                {
                    existing?.name = (menuJson["name"] as! String)
                    existing?.completeUrl = (menuJson["imgUrl"] as! String)
                    existing?.price = menuJson["price"] as! Double
                    existing?.detail = (menuJson["description"] as! String)
                    existing?.type = (menuJson["type"] as! String)
                    
                    do {
                        try existing?.managedObjectContext!.save()
                        //menuItems.append(newProduct)
                        
                    } catch {
                        let nserror = error as NSError
                        fatalError("Unresolved Error \(nserror), \(nserror.userInfo)")
                    }

                    DispatchQueue.global(qos: .background).async {
                        self.downloadImage(from: URL(string: (existing?.completeUrl)!)!, menuItem: existing!)
                    }
                }
            }
            self.triggerMenu()
            
            self.tableView.reloadData()
        }
    }
    
    func triggerMenu()
    {
        var result : [String : [MenuItem]] = [:]
        for (menuItem) in self.menuItems {
            if let _ = result[menuItem.type!] {
                result[menuItem.type!]?.append(menuItem)
            }
            else
            {
                result[menuItem.type!] = []
                result[menuItem.type!]?.append(menuItem)
            }
        }

        self.allData = result
        
        if(self.searchBar.searchTextField.text == nil || self.searchBar.searchTextField.text?.count == 0)
        {
            filtered = allData
        }
        else{
            var temp = [String : [MenuItem]]()
            let searchText = self.searchBar.searchTextField.text!
            
            for(menuType, menuItems) in allData {
                temp[menuType] = menuItems.filter{
                    $0.name!.localizedCaseInsensitiveContains(searchText) ||
                    $0.detail!.localizedCaseInsensitiveContains(searchText)
                }
            }
            
            filtered = temp

        }
        
    }
    
    func downloadMenu()
    {
        _ = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if(self.isRunning ==  true )
            {
                return
            }
            
            self.isRunning = true
            let workItem = DispatchWorkItem {
                ApiRepository.shared.getMenu { [self] menusJson, error in
                    if (error != nil)
                    {
                        return
                    }
                    
                    var addJson : [[String : Any]] = []
                    var deleteId : [String] = []
                    var updateJson : [[String : Any]] = []
                    var idList : [String] = []
                    
                    
                    if(menusJson == nil)
                    {
                        return
                    }
                    
                    for(menuJson) in menusJson! {
                        let id = menuJson["Id"] as! String
                        idList.append(id)
                        let existing = self.menuItems.filter {$0.id == id}.first
                        
                        if(existing == nil)
                        {
                            addJson.append(menuJson)
                        } else {
                            let name = menuJson["name"] as! String
                            let imgUrl = menuJson["imgUrl"] as! String
                            let price = menuJson["price"] as! Double
                            let description = menuJson["description"] as! String
                            let type = menuJson["type"] as! String
                            
                            if(existing?.name != name
                                || existing?.completeUrl != imgUrl
                                || String(format: "%.20f", existing?.price as! CVarArg) != String(format: "%.20f", price)
                                || existing?.detail != description
                                || existing?.type != type){
                                //print(existing?.name != name)
                                //print(existing?.completeUrl != imgUrl)
                                //print(String(format: "%.20f", existing?.price as! CVarArg) != String(format: "%.20f", price))
                                print(existing?.detail != description)
                                
                                //print(existing?.type != type)
                                updateJson.append(menuJson)
                            }
                        }
                    }
                    
                    for (menuItem) in menuItems {
                        let existing = idList.filter { $0 == menuItem.id }.first
                        if(existing == nil)
                        {
                            deleteId.append(menuItem.id!)
                        }
                    }
                    
                    if(addJson.count > 0 || deleteId.count > 0 || updateJson.count > 0)
                    {
                        saveMenu(addJson: addJson, deleteIds: deleteId, updateJson: updateJson)
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
    
    func downloadImage(from url: URL, menuItem : MenuItem) {
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
            menuItem.imgUrl = imgName
            
            DispatchQueue.main.async { [self] in
                do {
                    try menuItem.managedObjectContext!.save()
                } catch {
                    let nserror = error as NSError
                    fatalError("Unresolved Error \(nserror), \(nserror.userInfo)")
                }
                
                self.tableView.reloadData()
            }
            print("Download Finished")
        }
    }

}
