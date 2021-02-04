//
//  MenuTableViewController.swift
//  MyFoodManager
//
//  Created by animesh seth on 12/15/20.
//

import UIKit
import CoreData

class MyMenuTableViewCell: UITableViewCell {
    @IBOutlet weak var menuItemImage: UIImageView!
    @IBOutlet weak var menuItemName: UILabel!
    @IBOutlet weak var menuItemPrice: UILabel!
}

class MenuTableViewController: UITableViewController {

    var menuItems : [MenuItem] = [MenuItem]()
    var isRunning : Bool = false
    override func viewDidLoad() {
        super.viewDidLoad()
        self.loadMenu()
        self.downloadMenu()
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
        return menuItems.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "myMenuCell", for: indexPath) as! MyMenuTableViewCell
        
        let menuItem = menuItems[indexPath.row]
        cell.menuItemName?.text = menuItem.name
        cell.menuItemPrice?.text = String(format: "%.2f",  menuItem.price)
        let img = menuItem.imgUrl
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
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == UITableViewCell.EditingStyle.delete {
            let menuItem = menuItems[indexPath.row]
            ApiRepository.shared.deleteMenu(from: menuItem.id!){
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
                        
                        let managedContext = menuItem.managedObjectContext
//                            appDelegate.persistentContainer.viewContext
                        managedContext!.delete(menuItem)
                        do {
                            try managedContext!.save()
                            self.menuItems = menuItems.filter {$0.id != menuItem.id}
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
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let menuDetailsController = segue.destination as? MenuDetailsViewController {
            let sel = self.tableView.indexPathForSelectedRow?.row
            if(sel != nil)
            {
                menuDetailsController.menuItem = menuItems[sel!]
            }
        }
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
                    managedContext.delete(existing!)
                }
                
                do {
                    try managedContext.save()
                    self.menuItems = self.menuItems.filter {$0.id != deleteId}
                    //menuItems.append(newProduct)
                    
                } catch {
                    let nserror = error as NSError
                    fatalError("Unresolved Error \(nserror), \(nserror.userInfo)")
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
            
            self.tableView.reloadData()
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
    
    @IBAction func addMenu(_ sender: Any) {
        self.performSegue(withIdentifier: "menuDetailSegue", sender: self)
    }
    
    @IBAction func unwindToMenuTable(unwindSegue: UIStoryboardSegue) {
    }
}
