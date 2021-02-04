//
//  ApiRepostary.swift
//  Assignement8
//
//  Created by animesh seth on 11/27/20.
//

import Foundation

class ApiRepository {
    
    private init() {}
    static let shared = ApiRepository()
    
    private let urlSession = URLSession.shared
    
    //func getProducts() {
    func getMenu(completion: @escaping(_ productsDict: [[String: Any]]?, _ error: Error?) -> ()) {
        let baseURL = URL(string: "http://localhost:3000")
        let tempUrl = baseURL?.appendingPathComponent("/api/menuItems")
        urlSession.dataTask(with: tempUrl!) { (data, response, error) in
            if let error = error {
                completion(nil, error)
                return
            }
            
            do {
                let jsonObject = try JSONSerialization.jsonObject(with: data!, options: [])
                let jsonDictionary = jsonObject as? [[String: Any]]

                completion(jsonDictionary, nil)
            } catch {
                completion(nil, error)
            }
        }.resume()
    }
    
    func getData(from url: URL, completion: @escaping (Data?, URLResponse?, Error?) -> ()) {
        urlSession.dataTask(with: url, completionHandler: completion).resume()
    }
    
    func createOrder(from tableNo : Int64, completion: @escaping(_ productsDict: [String: Any]?, _ error: Error?) -> ()) {
        let baseURL = URL(string: "http://localhost:3000")
        let tempUrl = baseURL?.appendingPathComponent("/api/table/" + String(tableNo))
        var request = URLRequest(url : tempUrl!)
        
        print(tempUrl?.absoluteURL)
        print(tempUrl?.relativeString)
        
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                completion(nil, error)
                print(error?.localizedDescription ?? "No data")
                return
            }
            let responseJSON = try? JSONSerialization.jsonObject(with: data, options: [])
            if let mydata = responseJSON as? [String: Any] {
                completion(mydata, nil)
                print(responseJSON)
            }
        }

        task.resume()
    }
    
    func addItem(from tableNo : Int64, from json : [String : Any], completion: @escaping(_ productsDict: [String: Any]?, _ error: Error?) -> ()) {

        let jsonData = try? JSONSerialization.data(withJSONObject: json)

        // create post request
        let baseURL = URL(string: "http://localhost:3000")
        let tempUrl = baseURL?.appendingPathComponent("/api/table/" + String(tableNo) + "/add")
        print(tempUrl?.absoluteURL)
        var request = URLRequest(url: tempUrl!)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")


        // insert json data to the request
        request.httpBody = jsonData

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                completion(nil, error)
                print(error?.localizedDescription ?? "No data")
                return
            }
            let responseJSON = try? JSONSerialization.jsonObject(with: data, options: [])
            if let responseJSON = responseJSON as? [String: Any] {
                completion(responseJSON, nil)
                print(responseJSON)
            }
        }

        task.resume()
        
    }
    
    func sendMessage(from msg : String, from tableNo : Int64, completion : @escaping(_ error : Error?) -> () ){
        
        let currentDate = Date()
        let since1970 = currentDate.timeIntervalSince1970
        let msSecs = String(since1970 * 1000)
        let json: [String: Any] =
            [
                "content": msg,
                "isCustomer" : 1,
                "sendTime" : msSecs
            ]

        let jsonData = try? JSONSerialization.data(withJSONObject: json)

        // create post request
        let baseURL = URL(string: "http://localhost:3000")
        let tempUrl = baseURL?.appendingPathComponent("/api/messages/" + String(tableNo))
        var request = URLRequest(url: tempUrl!)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")


        // insert json data to the request
        request.httpBody = jsonData

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                completion(error)
                print(error?.localizedDescription ?? "No data")
                return
            }
            let responseJSON = try? JSONSerialization.jsonObject(with: data, options: [])
            if let responseJSON = responseJSON as? [String: Any] {
                completion(nil)
                print(responseJSON)
            }
        }

        task.resume()
    }
    

    func getOrder(from orderId : String , completion: @escaping(_ productsDict: [String: Any]?, _ error: Error?) -> ()) {
        let baseURL = URL(string: "http://localhost:3000")
        let tempUrl = baseURL?.appendingPathComponent("/api/order/" + orderId)
        urlSession.dataTask(with: tempUrl!) { (data, response, error) in
            if let error = error {
                completion(nil, error)
                return
            }
            
            do {
                let jsonObject = try JSONSerialization.jsonObject(with: data!, options: [])
                let jsonDictionary = jsonObject as? [String: Any]

                completion(jsonDictionary, nil)
            } catch {
                completion(nil, error)
            }
        }.resume()
    }

    
    func getMessage(from table : Int64 , completion: @escaping(_ productsDict: [[String: Any]]?, _ error: Error?) -> ()) {
        let baseURL = URL(string: "http://localhost:3000")
        let tempUrl = baseURL?.appendingPathComponent("/api/messages/" + String(table))
        urlSession.dataTask(with: tempUrl!) { (data, response, error) in
            if let error = error {
                completion(nil, error)
                return
            }
            
            do {
                let jsonObject = try JSONSerialization.jsonObject(with: data!, options: [])
                let jsonDictionary = jsonObject as? [[String: Any]]

                completion(jsonDictionary, nil)
            } catch {
                completion(nil, error)
            }
        }.resume()
    }
    
    func markPaid(from orderId : String, completion : @escaping(_ result: [String: Any]?, _ error : Error?) -> () ){
        let baseURL = URL(string: "http://localhost:3000")
        let tempUrl = baseURL?.appendingPathComponent("/api/order/" + orderId + "/pay")
        var request = URLRequest(url: tempUrl!)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                completion(nil, error)
                print(error?.localizedDescription ?? "No data")
                return
            }
            let responseJSON = try? JSONSerialization.jsonObject(with: data, options: [])
            let responseData = responseJSON as! [String : Any]
            completion(responseData, nil)
        }

        task.resume()
    }
}
