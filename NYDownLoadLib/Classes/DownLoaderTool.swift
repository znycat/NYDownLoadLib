//
//  DownLoaderTool.swift
//  下载
//
//  Created by 翟乃玉 on 2017/11/27.
//  Copyright © 2017年 翟乃玉. All rights reserved.
//

import UIKit
import CryptoSwift
extension String {
    func nyMd5() -> String {
//        let str = self.cString(using: String.Encoding.utf8)
//        let strLen = CUnsignedInt(self.lengthOfBytes(using: String.Encoding.utf8))
//        let digestLen = Int(CC_MD5_DIGEST_LENGTH)
//        let result = UnsafeMutablePointer<CUnsignedChar>.allocate(capacity: digestLen)
//        CC_MD5(str!, strLen, result)
//        let hash = NSMutableString()
//        for i in 0 ..< digestLen {
//            hash.appendFormat("%02x", result[i])
//        }
//        result.deinitialize()
//        return String(format: hash as String)
        return self.md5()
    }
}

struct FileTool  {
    /// 文件是否存在
    ///
    /// - Parameter filePath: 文件路径
    /// - Returns: 是否存在
    static func isFileExists(filePath: String?)-> Bool{
        guard let filePath = filePath else{
            print("filePath nil")
            return false
        }
        if filePath.isEmpty {
            print("filePath isEmpty")
            return false
        }
        var isDir: ObjCBool = false
        let isFileExists = FileManager.default.fileExists(atPath: filePath, isDirectory: &isDir)
        return isFileExists
    }
    
    /// 文件大小
    ///
    /// - Parameter filePath: 文件路径
    /// - Returns: 文件大小
    static func fileSize(filePath: String?)-> Int64{
        guard self.isFileExists(filePath: filePath) else{
            return 0
        }
        do {
            /*神坑, 有两个方法
             FileManager.default.attributesOfFileSystem(forPath: )
             
             */
            let fileInfo = try FileManager.default.attributesOfItem(atPath: filePath!)
            if let size: NSNumber = fileInfo[FileAttributeKey.size] as? NSNumber {
                return size.int64Value
            }
        } catch {
            print(error)
        }
        return 0
    }

    
    /// 移动一个文件,到另外一个文件路径中
    ///
    /// - Parameters:
    ///   - fromPAthena: 从哪个文件
    ///   - toPath: 目标文件位置
    static func moveFile(fromPath: String?, toPath: String?) -> Bool {
        guard let fromPath = fromPath else {
            print("no fromPath")
            return false }
        guard let toPath = toPath else {
            print("no toPath")
            return false }
        if self.fileSize(filePath: fromPath) == 0 {
            print("fileSize nil")
            return false
        }
        do {
            try FileManager.default.moveItem(atPath: fromPath, toPath: toPath)
            return true
        } catch {
            print(error)
            return false
        }
    }
    
    /// 删除某个文件
    ///
    /// - Parameter filePath: 文件路径
    static func removeFile(filePath: String?){
        guard let filePath = filePath else { return }
        
        try? FileManager.default.removeItem(atPath: filePath)
    }
}

func NYLog<T>(_ messsage : T, file : String = #file, funcName : String = #function, lineNum : Int = #line) {
    
    #if DEBUG
        
        let fileName = (file as NSString).lastPathComponent
        
        print("\(fileName)-\(funcName):[line-\(lineNum))]:\(messsage)")
        
    #endif
}
