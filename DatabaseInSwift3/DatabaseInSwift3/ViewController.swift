//
//  ViewController.swift
//  DatabaseInSwift3
//
//  Created by Power  on 26/12/16.
//  Copyright © 2016 Power . All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        // insert  with query
        
        let str = String(format: "INSERT OR REPLACE INTO swifttable(name,surname,roll) VALUES ('%@','%@','%@')", "ajay","sharma","2")
        
        
        let che = Constant.detabaseobj.insertUpdateDeleteOperation(query: str)
        if che == true {
            print("success")
        }
        
        // Update
        
        /*
//        let dic = ["name":"auj","surname":"dalwadi","roll":"1"]
//        
//      let che1 =  Constant.detabaseobj.updateTableWithDictionary(tableName: "swifttable", tableData: dic , whereClause: "where roll = 2")
//        
//        if che1 == true {
//            print("che1 success")
//        }
        
        */
        // Update whole dictionary
        
        /*
        let di2 = ["name":"Mahavir","surname":"Naman","roll":"8"]
        
        let che3 =  Constant.detabaseobj.insertDictionaryIntoTable(tableName: "swifttable", tableData: di2 as NSDictionary)
        
        if che3 == true {
            print("che3 success")
        }
           */
 
        // Delete with query
        /*
        let strdelete = String(format: "DELETE FROM swifttable where roll = 8")
        let che4 = Constant.detabaseobj.insertUpdateDeleteOperation(query: strdelete)
        if che4 == true {
            print("che4 success")
        }
        */
        
        // fetch Data From Database
        
        /*
        let che5 = Constant.detabaseobj.fetchDataFromDatabase(query: "select * from swifttable where roll = 1")
        if che5 == true {
            print("che5 success")
            
          let array = Constant.detabaseobj.resultData
            
            print(array)
        }
      */
        
         // insert  Whole Array
    
        let dic10 = ["name":"Kri","surname":"shah","roll":"80"]
        let dic11 = ["name":"Jag","surname":"Patel","roll":"84"]
        let dic12 = ["name":"hfi","surname":"Patel","roll":"79"]
       
        
        let array = [dic10,dic11,dic12]
        let che6 = Constant.detabaseobj.insertArrayIntoTable(tableName: "swifttable", tableData: array as NSArray)
        if che6 == true {
            print("che6 success")
        }
     
        
        // Count Row
        /*
        let che7 = Constant.detabaseobj.fetchCountWhere(whereClause: "roll = 22", tablename: "swifttable")
        
        if che7.0 == true {
            
            print("che7 success")
            
            print(che7.1)
        }
      */
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

