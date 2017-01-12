//
//  PowerDatabase.swift
//  DatabaseInSwift3
//
//  Created by Power  on 26/12/16.
//  Copyright © 2016 Power . All rights reserved.
//
import UIKit
class PowerDatabase: NSObject {
    
   let SQLITE_DATE = SQLITE_NULL + 1
   static var dbPath : String?
   static var  sqliteDatabase      : OpaquePointer? = nil
   var resultData : NSMutableArray = NSMutableArray()

    override init() {
        super.init()
        PowerDatabase.dbPath = Constant.strdbpath
    }
    //MARK:- Insert Dictionary Into Database
    func insertDictionaryIntoTable(tableName:String,tableData:NSDictionary)-> Bool{
        let arrayData:NSArray = [tableData]
        if self.insertArrayIntoTable(tableName: tableName, tableData: arrayData) {
            return true
        }else{
            return false
        }
    }
    //MARK:- Update Dictionary Into Database
    func updateTableWithDictionary(tableName:String,tableData:NSDictionary,whereClause:String?)-> Bool{
        let arrayData:NSArray = [tableData]
        if self.updateTableWithArray(tableName: tableName, tableData: arrayData, whereClause: whereClause) {
            return true
        }else{
            return false
        }
    }
    func updateTableWithDictionary(tableName:String,tableData:NSDictionary)-> Bool{
        if self.updateTableWithDictionary(tableName: tableName, tableData: tableData, whereClause: nil) {
            return true
        }else{
            return false
        }
    }
    //MARK:- Insert Array Into Database
    func insertArrayIntoTable(tableName:String,tableData:NSArray)-> Bool{
        if self.insertIntoDatabase(tableName: tableName, tableData: tableData) {
            return true
        }else{
            return false
        }
    }
    //MARK:- Update Array Into Database
    func updateTableWithArray(tableName:String,tableData:NSArray,whereClause:String?)-> Bool{
        if self.updateTableData(tableName: tableName, tableData: tableData, whereClause: whereClause) {
            return true
        }else{
            return false
        }
    }
    func updateTableWithArray(tableName:String,tableData:NSArray)-> Bool
    {
        if self.updateTableWithArray(tableName: tableName, tableData: tableData, whereClause: nil) {
            return true
        }else{
            return false
        }
    }
    //MARK:- Execute Query Into Database
    func insertUpdateDeleteOperation(query: String) -> Bool{
        var ans = false
        let databasePath = PowerDatabase.dbPath?.cString(using: String.Encoding.utf8)
        if sqlite3_open(databasePath!,&PowerDatabase.sqliteDatabase) == SQLITE_OK {
            var statement:OpaquePointer? = nil
            if sqlite3_prepare_v2(PowerDatabase.sqliteDatabase!, query.cString(using: String.Encoding.utf8), -1, &statement, nil) == SQLITE_OK {
                sqlite3_step(statement)
                ans = true
            }
            else{
                if let error = sqlite3_errmsg(PowerDatabase.sqliteDatabase!){
                    let msg = "SQLiteDB - failed to prepare SQL: \(PowerDatabase.sqliteDatabase!), Error: \(error)"
                    print(msg)
                }
            }
            sqlite3_finalize(statement)
            sqlite3_close(PowerDatabase.sqliteDatabase)
        }
        return ans
    }
    
    //MARK:- Row Count With Where Clause
    func fetchCountWhere(whereClause:NSString, tablename:NSString)-> (Bool,Int){
        let sqlQuery : NSString = NSString.init(format: "SELECT COUNT(*) FROM %@ WHERE %@", tablename, whereClause)
        return self.fetchMaxOrCount(sqlQuery: sqlQuery)
    }
    //MARK:- lookupMax With Where Clause
    func fetchMax(whereClause:NSString, tablename:NSString, key: NSString)-> (Bool,Int){
         let sqlQuery : NSString = NSString.init(format: "SELECT MAX(%@) FROM %@ WHERE %@",key, tablename, whereClause)
        return self.fetchMaxOrCount(sqlQuery: sqlQuery)
    }
    //MARK:- Delete Method
    func deleteWhere(whereClause:NSString, tablename:NSString)-> Bool {
        let sqlQuery : NSString = NSString.init(format: "DELETE FROM %@ WHERE %@", tablename, whereClause)
        if insertUpdateDeleteOperation(query: sqlQuery as String) {
            print("Successfully deleted Data into \(tablename)")
            return  true
        }else{
            print("Could not deleted data into \(tablename)")
             return  false
        }
    }
    //Delete All Rows
    func deleteAllRowsForTable(tablename:NSString)-> Bool{
        let sqlQuery : NSString = NSString.init(format: "DELETE FROM %@", tablename)
        if insertUpdateDeleteOperation(query: sqlQuery as String) {
            print("Successfully deleted Data into \(tablename)")
            return  true
        }else{
            print("Could not deleted data into \(tablename)")
            return  false
        }
    }
    //MARK:- Private Method
    // Get column type
    private func getColumnType(index:CInt, stmt:OpaquePointer)->CInt {
        var type:CInt = 0
        // Column types - http://www.sqlite.org/datatype3.html (section 2.2 table column 1)
        let blobTypes = ["BINARY", "BLOB", "VARBINARY"]
        let charTypes = ["CHAR", "CHARACTER", "CLOB", "NATIONAL VARYING CHARACTER", "NATIVE CHARACTER", "NCHAR", "NVARCHAR", "TEXT", "VARCHAR", "VARIANT", "VARYING CHARACTER"]
        let dateTypes = ["DATE", "DATETIME", "TIME", "TIMESTAMP"]
        let intTypes  = ["BIGINT", "BIT", "BOOL", "BOOLEAN", "INT", "INT2", "INT8", "INTEGER", "MEDIUMINT", "SMALLINT", "TINYINT"]
        let nullTypes = ["NULL"]
        let realTypes = ["DECIMAL", "DOUBLE", "DOUBLE PRECISION", "FLOAT", "NUMERIC", "REAL"]
        // Determine type of column - http://www.sqlite.org/c3ref/c_blob.html
        let buf = sqlite3_column_decltype(stmt, index)
        //		NSLog("SQLiteDB - Got column type: \(buf)")
        if buf != nil {
            var tmp = String(validatingUTF8:buf!)!.uppercased()
            // Remove brackets
            let pos = tmp.positionOf(sub:"(")
            if pos > 0 {
                tmp = tmp.subString(start:0, length:pos)
            }
            // Remove unsigned?
            // Remove spaces
            // Is the data type in any of the pre-set values?
            //			NSLog("SQLiteDB - Cleaned up column type: \(tmp)")
            if intTypes.contains(tmp) {
                return SQLITE_INTEGER
            }
            if realTypes.contains(tmp) {
                return SQLITE_FLOAT
            }
            if charTypes.contains(tmp) {
                return SQLITE_TEXT
            }
            if blobTypes.contains(tmp) {
                return SQLITE_BLOB
            }
            if nullTypes.contains(tmp) {
                return SQLITE_NULL
            }
            if dateTypes.contains(tmp) {
                return SQLITE_DATE
            }
            return SQLITE_TEXT
        } else {
            // For expressions and sub-queries
            type = sqlite3_column_type(stmt, index)
        }
        return type
    }
    
    // Get column value
    private func getColumnValue(index:CInt, type:CInt, stmt:OpaquePointer)->Any? {
        // Integer
        if type == SQLITE_INTEGER {
            let val = sqlite3_column_int(stmt, index)
            return Int(val)
        }
        // Float
        if type == SQLITE_FLOAT {
            let val = sqlite3_column_double(stmt, index)
            return Double(val)
        }
        // Text - handled by default handler at end
        // Blob
        if type == SQLITE_BLOB {
            let data = sqlite3_column_blob(stmt, index)
            let size = sqlite3_column_bytes(stmt, index)
            let val = NSData(bytes:data, length:Int(size))
            return val
        }
        // Null
        if type == SQLITE_NULL {
            return nil
        }
        // Date
        if type == SQLITE_DATE {
            // Is this a text date
            if let ptr = UnsafeRawPointer.init(sqlite3_column_text(stmt, index)) {
                let uptr = ptr.bindMemory(to:CChar.self, capacity:0)
                let txt = String(validatingUTF8:uptr)!
                let set = CharacterSet(charactersIn:"-:")
                if txt.rangeOfCharacter(from:set) != nil {
                    // Convert to time
                    var time:tm = tm(tm_sec: 0, tm_min: 0, tm_hour: 0, tm_mday: 0, tm_mon: 0, tm_year: 0, tm_wday: 0, tm_yday: 0, tm_isdst: 0, tm_gmtoff: 0, tm_zone:nil)
                    strptime(txt, "%Y-%m-%d %H:%M:%S", &time)
                    time.tm_isdst = -1
                    let diff = NSTimeZone.local.secondsFromGMT()
                    let t = mktime(&time) + diff
                    let ti = TimeInterval(t)
                    let val = NSDate(timeIntervalSince1970:ti)
                    return val
                }
            }
            // If not a text date, then it's a time interval
            let val = sqlite3_column_double(stmt, index)
            let dt = NSDate(timeIntervalSince1970: val)
            return dt
        }
        // If nothing works, return a string representation
        if let ptr = UnsafeRawPointer.init(sqlite3_column_text(stmt, index)) {
            let uptr = ptr.bindMemory(to:CChar.self, capacity:0)
            let txt = String(validatingUTF8:uptr)
            return txt
        }
        return nil
    }

    // fetchMaxOrCount
    private func fetchMaxOrCount(sqlQuery: NSString)-> (Bool,Int){
        var ans: Bool = false
        var countData: Int = 0
        
        let databasePath = PowerDatabase.dbPath?.cString(using: String.Encoding.utf8)
        if sqlite3_open(databasePath!,&PowerDatabase.sqliteDatabase) == SQLITE_OK {
            var statement:OpaquePointer? = nil
            let result = sqlite3_prepare_v2(PowerDatabase.sqliteDatabase, sqlQuery.cString(using: String.Encoding.utf8.rawValue), -1, &statement, nil)
            
            if result == SQLITE_OK {
                if (sqlite3_step(statement) == SQLITE_ROW) {
                    countData = Int(sqlite3_column_int(statement,0))
                }
            }
            sqlite3_finalize(statement)
            ans = true
        }
        else{
            if let error = sqlite3_errmsg(PowerDatabase.sqliteDatabase){
                let msg = "SQLiteDB - failed to prepare SQL: \(PowerDatabase.sqliteDatabase), Error: \(error)"
                print(msg)
            }
            ans = false
        }
        sqlite3_close(PowerDatabase.sqliteDatabase)
        return (ans,countData)
    }
    
    // insertIntoDatabase For Array
    private func insertIntoDatabase(tableName:String,tableData:NSArray)-> Bool {
        var ans: Bool = false
        var querry : String = ""
       
       // var countQuery: Int = 0
        
        for dicArray in tableData {
            let dicData : NSDictionary = dicArray as! NSDictionary
            let index = tableData.index(of: dicArray)
            
            var keys : String = "("
            var values : String = "("
            var countRow : Int = 0
            
            var strValue : String = ""
            
            for (key, value) in dicData {
                //'
                strValue = Constant.Remove_Null_From_String(str: value as? NSString) as String
                strValue = strValue.replacingOccurrences(of: "'", with: "''")
                
                if countRow < (dicData.count - 1) {
                    keys += "\(key),"
                    values += "'\(strValue)',"
                }else{
                    keys += "\(key)"
                    values += "'\(strValue)'"
                }
                countRow += 1;
            }
            
            keys += ")"
            values += ")"
            querry += "INSERT OR REPLACE INTO \(tableName) \(keys) values\(values)"
            print(querry)
            
            if tableData.count > 1 && index < tableData.count - 1 {
                querry = querry.appendingFormat("; ")
            }
            
            if insertUpdateDeleteOperation(query: querry) {
                print("Successfully INSERT Data into \(tableName)")
                ans = true
               // countQuery += 1
            }else{
                print("Could not INSERT data into \(tableName)")
                ans = false
            }
        }
    
        /*
        if countQuery == tableData.count {
            ans = true
        }
        else{
             ans = false
        }
       */
        
        return ans
    }
    
    private func updateTableData(tableName:String,tableData:NSArray,whereClause:String?)-> Bool{
        var ans: Bool = false
        var querry      : String = ""
        for dicArray in tableData {
            let dicData : NSDictionary = dicArray as! NSDictionary
            var countRow    : Int = 0
            var updateValue : String = ""
            
            for (key, value) in dicData {
                let  strValue = Constant.Remove_Null_From_String(str: value as? NSString) as String
                if countRow < (dicData.count - 1) {
                    if strValue == "" {
                        updateValue += "\(key) = '', "
                    }else{
                        updateValue += "\(key) = '\(strValue)', "
                    }
                }else{
                    if strValue == "" {
                        updateValue += "\(key) = '' "
                    }else{
                        updateValue += "\(key) = '\(strValue)' "
                    }
                }
                countRow += 1;
            }
            
            if whereClause != nil {
                querry += "UPDATE \(tableName) SET \(updateValue) \(whereClause)"
            }
            else{
                querry += "UPDATE \(tableName) SET \(updateValue)"
            }
            
            let index = tableData.index(of: dicArray)
            
            if tableData.count > 1 && index < tableData.count - 1 {
                querry = querry.appendingFormat("; ")
            }
        }
        print(querry)
        if insertUpdateDeleteOperation(query: querry) {
            print("Successfully UPDATE Data into \(tableName)")
            ans = true
        }else{
            print("Could not UPDATE data into \(tableName)")
            ans = false
        }
        return ans
    }
    //MARK:- ExecuteQuery
    func fetchDataFromDatabase(query:String) -> Bool{
        var ans = false
        let databasePath = PowerDatabase.dbPath?.cString(using: String.Encoding.utf8)
        if sqlite3_open(databasePath!,&PowerDatabase.sqliteDatabase) == SQLITE_OK {
            var statement:OpaquePointer? = nil
            var result = sqlite3_prepare_v2(PowerDatabase.sqliteDatabase, query.cString(using: String.Encoding.utf8), -1, &statement, nil)
            
            if result == SQLITE_OK {
                // var rows = [SQLRow]()
                var columnCount:CInt = 0
                var columnNames = [String]()
                var columnTypes = [CInt]()
                var fetchColumnInfo = true
                
                resultData.removeAllObjects()
                result = sqlite3_step(statement)
                while result == SQLITE_ROW {
                    
                    // Should we get column info?
                    if fetchColumnInfo {
                        columnCount = sqlite3_column_count(statement)
                        for index in 0..<columnCount {
                            // Get column name
                            let name = sqlite3_column_name(statement, index)
                            columnNames.append(String(validatingUTF8:name!)!)
                            
                            // Get column type
                            columnTypes.append(self.getColumnType(index: index, stmt:statement!))
                    }
                        fetchColumnInfo = false
                    }
                    // Get row data for each column
                    //let row = SQLRow()
                    let tableInfo : NSMutableDictionary = NSMutableDictionary()
                    for index in 0..<columnCount {
                        let key = columnNames[Int(index)]
                        let type = columnTypes[Int(index)]
                        if let val:AnyObject = self.getColumnValue(index: index, type:type, stmt:statement!) as AnyObject? {
                            //print("Column type:\(type) - key :\(key) value:\(val)")
                            //let col = SQLColumn(value: val, type: type)
                            //row[key] = col
                            tableInfo.setValue(val, forKey: key)
                        }
                    }
                    if tableInfo.count != 0{
                        resultData.add(tableInfo)
                    }
                    //resultData.addObject(tableInfo)
                    //resultData.append(tableInfo)
                    // rows.append(row)
                    // Next row
                    result = sqlite3_step(statement)
                }
                //NSLog("%@", tableData)
                sqlite3_finalize(statement)
                ans = true
            }
            else{
                if let error = sqlite3_errmsg(PowerDatabase.sqliteDatabase){
                    let msg = "SQLiteDB - failed to prepare SQL: \(PowerDatabase.sqliteDatabase), Error: \(error)"
                    print(msg)
                }
                ans = false
            }
            sqlite3_close(PowerDatabase.sqliteDatabase)
        }
        return ans
    }
    //MARK:- Convert_String_From_Response
    func Convert_String_From_Response(data:NSDictionary) -> String{
        if data.count > 0 {
            do {
                let jsonData  = try JSONSerialization.data(withJSONObject: data, options: [])
                //print(jsonData)
                //Convert_Response_From_String(String.init(data: jsonData, encoding: NSUTF8StringEncoding)!)
                return  String.init(data: jsonData, encoding: String.Encoding.utf8)!
            } catch {
                print(error)
                return ""
            }
        }
        return ""
    }
    //MARK:- Convert_Response_From_String
    func Convert_Response_From_String(strData:String) -> NSDictionary{
        let data : NSData = strData.data(using: String.Encoding.utf8)! as NSData
        do {
          if let responseDictionary = try JSONSerialization.jsonObject(with: data as Data, options: []) as? NSDictionary {
            return responseDictionary
            }
        } catch {
            print(error)
        }
        return NSDictionary()
    }
}
extension String {
    func positionOf(sub:String)->Int {
        var pos = -1
        if let range = range(of:sub) {
            if !range.isEmpty {
                pos = characters.distance(from:startIndex, to:range.lowerBound)
            }
        }
        return pos
    }
    
    func subString(start:Int, length:Int = -1)->String {
        var len = length
        if len == -1 {
            len = characters.count - start
        }
        let st = characters.index(startIndex, offsetBy:start)
        let en = characters.index(st, offsetBy:len)
        let range = st ..< en
        return substring(with:range)
    }
}

/*
// insertIntoDatabase For Array
private func insertIntoDatabase(tableName:String,tableData:NSArray)-> Bool {
    var ans: Bool = false
    var querry : String = ""
    var keys : String = "("
    
    var strPass: String  = ""
    
    for dicArray in tableData {
        let dicData : NSDictionary = dicArray as! NSDictionary
        var index = tableData.index(of: dicArray)
        
        var values : String = "("
        
        // "INSERT OR REPLACE INTO swifttable (name,surname,roll) values(\'Kri\',\'shah\',\'80\'),),),"
        
        //  INSERT OR REPLACE INTO swifttable (name,surname,roll) values('Kri','shah','80'),('Jag','Patel','84'),('hfi','Patel','79')
        
        if index < 1 {
            var countRow : Int = 0
            var strValue : String = ""
            for (key, value) in dicData {
                
                strValue = Constant.Remove_Null_From_String(str: value as? NSString) as String
                strValue = strValue.replacingOccurrences(of: "'", with: "''")
                
                if countRow < (tableData.count - 1) {
                    keys += "\(key),"
                    values += "'\(strValue)',"
                }else{
                    keys += "\(key)"
                    values += "'\(strValue)'"
                }
                countRow += 1;
            }
            
            strPass = strPass.appendingFormat("%@",values)
        }
        else{
            var countRow : Int = 0
            var strValue : String = ""
            for (_, value) in dicData {
                strValue = Constant.Remove_Null_From_String(str: value as? NSString) as String
                strValue = strValue.replacingOccurrences(of: "'", with: "''")
                
                if countRow < (tableData.count - 1) {
                    values += "'\(strValue)',"
                }else{
                    values += "'\(strValue)'"
                }
                countRow += 1;
            }
            strPass = strPass.appendingFormat("%@",values)
        }
        
        
        if index < tableData.count - 1{
            strPass = strPass.appendingFormat("),")
        }
        else
        {
            strPass = strPass.appendingFormat(")")
        }
        
    }
    
    keys += ")"
    querry += "INSERT OR REPLACE INTO \(tableName) \(keys) values\(strPass)"
    
    if insertUpdateDeleteOperation(query: querry) {
        print("Successfully INSERT Data into \(tableName)")
        ans = true
    }else{
        print("Could not INSERT data into \(tableName)")
        ans = false
    }
    
    return ans
}
*/
