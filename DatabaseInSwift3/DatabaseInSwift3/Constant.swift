//
//  Constant.swift
//  DatabaseInSwift3
//
//  Created by Power  on 26/12/16.
//  Copyright © 2016 Power . All rights reserved.
//

import UIKit

class Constant: NSObject {

   static var strdbpath : String  = String()
   static var strDbName : String  = "swiftDemo.db"
   static let detabaseobj : PowerDatabase = PowerDatabase() 
    
    
    static func copypasteDB()
    {
        var arrpath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let pathdir = arrpath[0]
        print("\(pathdir)")
        strdbpath = (pathdir as NSString).appendingPathComponent(Constant.strDbName)
        print("\(strdbpath)")
        if !FileManager.default.fileExists(atPath: strdbpath) {
            let localdir = Bundle.main.path(forResource: "swiftDemo", ofType: "db")!
            print("\(localdir)")
            do {
                try FileManager.default.copyItem(atPath: localdir, toPath: strdbpath)
                 print("copy success")
            }
            catch {
                print("not copy")
            }
        }
    }
    static func Remove_Null_From_String(str: NSString?)-> NSString{
        var strResult: NSString? = nil

        guard let strString = str else {
            return ""
        }
        
        if strString.length < 0 ||  strString == "(null)" || strString == "<null>"{
            strResult = ""
        }
        else{
            strResult = str
        }
        return strResult!
    }
}
