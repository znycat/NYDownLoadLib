//
//  DownLoader.swift
//  下载
//
//  Created by 翟乃玉 on 2017/11/27.
//  Copyright © 2017年 翟乃玉. All rights reserved.
//

import UIKit
public typealias DownLoadInfoClosure = (_ totalSize: Int64)->()
public typealias SuccessClosure = (_ filePath: String)->()
public typealias FailedClosure = (_ failedInfo: String)->()
public typealias ProgressClosure = (_ progress: Double,_ tmpSize: Int64,_ totalSize: Int64)->()
public typealias StateChangeClosure = (_ state: DownLoaderState)->()
@objc public enum DownLoaderState: Int {
    /** 最开始 无状态 */
    case none = 0
    /** 下载暂停 */
    case pause
    /** 正在下载 */
    case downLoading
    /** 下载成功 */
    case success
    /** 下载成功,文件已经存在 */
    case fileExists
    /** 下载失败 */
    case failed
}
public struct DownLoaderConfig{
    /// 缓存文件夹名
    var cacheFolderName: String = "NYDownLoaderCache"
    /// 下载进度最快 0.1秒 提示一次
    var progressMinReturn :Double = 0.1
    
}
public struct DownTask{
    /// 一次计算读取的总数据
    var totalRead: Int64 = 0
    /// 速度
    var speed: Double = 0
    /// 上一次计算的时间
    var lastDate: Date = Date()
    
}

public class DownLoader: NSObject {
    deinit {
        NYLog("deinit----- XXXXXXXXXXXXXXxxXXXXXXXXXXx")
    }
    public init(url: URL,
                config: DownLoaderConfig?,
                downLoadInfoClosure: @escaping DownLoadInfoClosure,
                progressClosure: @escaping ProgressClosure,
                stateChangeClosure: @escaping StateChangeClosure,
                successClosure: @escaping SuccessClosure,
                failedClosure: @escaping FailedClosure) {
        self.downLoadInfoClosure = downLoadInfoClosure
        self.progressClosure = progressClosure
        self.successClosure = successClosure
        self.failedClosure = failedClosure
        self.stateChangeClosure = stateChangeClosure
        self.url = url
        self.cacheTotalSizeKey = "NYDownLoaderCacheTotalSizeKey\(url.absoluteString)"
        
        //获取文件名称, 指明路径
        let fileName = url.lastPathComponent
        if config != nil {
            downLoaderConfig = config!
        }else{
            downLoaderConfig = DownLoaderConfig()
        }
        let kTmpPath = NSTemporaryDirectory()
        let _ = kTmpPath
        
        let kCachePath = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first! + "/"
        
        let tmpFolder = "\(kCachePath)\(downLoaderConfig.cacheFolderName)/tmp"
        let cacheFolder = "\(kCachePath)\(downLoaderConfig.cacheFolderName)/cache"
        if !FileTool.isFileExists(filePath: tmpFolder) {
            try? FileManager.default.createDirectory(atPath: tmpFolder, withIntermediateDirectories: true, attributes: nil)
        }
        if !FileTool.isFileExists(filePath: cacheFolder) {
            try? FileManager.default.createDirectory(atPath: cacheFolder, withIntermediateDirectories: true, attributes: nil)
        }
        
        tmpFilePath = "\(tmpFolder)/\(fileName.nyMd5())"
        cacheFilePath = "\(cacheFolder)/\(fileName)"
        
        self.state = .none
        self.downTask = DownTask()
        super.init()
        
        // 2.开始下载
        self.downLoad()
    }
    public let url : URL
    fileprivate var failedInfo: String = ""
    fileprivate let cacheTotalSizeKey: String
    public let downLoaderConfig: DownLoaderConfig
    // 当前文件的下载状态
    public var state: DownLoaderState = .success {
        didSet{
            // 数据过滤
            if oldValue == state {
                return
            }
            stateChangeClosure(state)
            switch state {
            case .success:
                self.successClosure(cacheFilePath)
                self.progressClosure(self.progress,tmpSize,totalSize)
                UserDefaults.standard.removeObject(forKey: cacheTotalSizeKey)
                
                
            case .failed:
                self.failedClosure(failedInfo)
                UserDefaults.standard.removeObject(forKey: cacheTotalSizeKey)
            default: break
//                NYLog(state)
            }
            
        }
    }
    // 当前文件的下载进度
    public var progress: Double = 0
    /** 文件下载信息的闭包 */
    public var downLoadInfoClosure: DownLoadInfoClosure
    /** 状态改变的闭包 */
    public var stateChangeClosure: StateChangeClosure
    /** 进度改变的闭包 */
    public var progressClosure: ProgressClosure
    /** 下载成功的闭包 */
    public var successClosure: SuccessClosure
    /** 下载失败的闭包 */
    public var failedClosure: FailedClosure
    /// 临时下载文件的大小
    fileprivate var tmpSize: Int64 = 0
    /// 文件下载的总大小
    fileprivate var totalSize: Int64 = 0
    /// 文件的缓存路径
    fileprivate var cacheFilePath: String!
    /// 文件的临时缓存路径
    fileprivate var tmpFilePath: String
    
    var downTask: DownTask
    /// 当前下载任务
    fileprivate weak var dataTask: URLSessionDataTask?
    /// 下载会话
    fileprivate lazy var session: URLSession = {
        let session = URLSession(configuration: URLSessionConfiguration.default, delegate: self, delegateQueue: OperationQueue.main)
        return session
    }()
    /// 文件输出流
    fileprivate lazy var outputStream: OutputStream = {
        let outputStream = OutputStream(toFileAtPath: self.tmpFilePath, append: true)
        return outputStream!
    }()
    
    /// 为控制进度条提示而记录的上一次时间
    fileprivate var progressLastDate: Date = Date()
}
// MARK: - 下载
extension DownLoader {
    ///检测,临时文件是否存在
    fileprivate func existsTmpFileAndDownLoad() {
        //检测,临时文件是否存在
        if FileTool.isFileExists(filePath: tmpFilePath) {
            // 存在 看位置 然后续传
            tmpSize = FileTool.fileSize(filePath: tmpFilePath)
            self.downLoad(url: url, offset: tmpSize)
        }else{
            //不存在 从0开始下载
            self.downLoad(url: url, offset: 0)
        }
    }
    
    private func downLoad(url: URL, offset: Int64){
        var request = URLRequest(url: url, cachePolicy:URLRequest.CachePolicy.reloadIgnoringLocalCacheData, timeoutInterval: 0)
        request.setValue(String(format: "bytes=%lld-", offset), forHTTPHeaderField: "Range")
        self.dataTask = self.session.dataTask(with: request)
        self.dataTask?.resume()
    }
}
// MARK: - 提供给外界的接口
public extension DownLoader {
    /// 根据链接进行下载
    public func downLoad(){
        if let cacheTotalSize = UserDefaults.standard.object(forKey: cacheTotalSizeKey) as? Int64 {
            totalSize = cacheTotalSize
        }
        
        if FileTool.isFileExists(filePath: cacheFilePath) {
            //缓存文件存在 下载成功
            let fileSize = FileTool.fileSize(filePath: cacheFilePath)
            self.downLoadInfoClosure(fileSize)
            state = .fileExists
            successClosure(cacheFilePath)
            return
        }
        
        if dataTask == nil {//下载任务 不存在
            //检测,临时文件是否存在
            self.existsTmpFileAndDownLoad()
            return
        }
        // 下载任务 存在
        // 如果正在下载, 则返回
        if state == .downLoading {
            return
        }
        // 暂停, 那么让继续
        if state == .pause {
            self.resumeCurrentTask()
            return
        }
        
        self.existsTmpFileAndDownLoad()
        
    }
    /// 暂停任务
    public func pauseCurrentTask(){
        if self.state == .downLoading {
            self.state = .pause
            dataTask?.suspend()
        }
    }
    /// 继续任务
    public func resumeCurrentTask(){
        if (self.dataTask != nil && self.state == .pause) {
            self.dataTask!.resume()
            self.state = .downLoading
        }
    }
    
    /// 取消任务
    public func cancelCurrentTask(){
        self.state = .pause
        self.session.invalidateAndCancel()
    }
    
    /// 取消任务, 并清理资源
    public func cancelAndCleanCache(){
        self.cancelCurrentTask()
        FileTool.removeFile(filePath: tmpFilePath)
        UserDefaults.standard.removeObject(forKey: cacheTotalSizeKey)
    }
}
// MARK: - URLSessionDataDelegate
extension DownLoader: URLSessionDataDelegate{
    
    /// 第一次接受到相应的时候调用(响应头, 并没有具体的资源内容)
    /// 通过这个方法里面系统提供的回调代码块(completionHandler) 可以控制:是继续请求, 还是取消本次请求
    /// - Parameters:
    ///   - session: 会话
    ///   - dataTask: 任务
    ///   - response: 响应头信息
    ///   - completionHandler: 系统回调代码块, 通过它可以控制是否继续接收数据
    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        
        if totalSize == 0 {
            setupTotalSize(response: response)
        }
        
        // 传递给外界 : 总大小 & 本地存储的文件路径
        self.downLoadInfoClosure(totalSize)
        
        // 比对本地大小, 和 总大小
        if tmpSize == totalSize {
            NYLog("移动到下载完成文件夹 取消本次请求 修改状态")
            // 1. 移动到下载完成文件夹
            if FileTool.moveFile(fromPath: tmpFilePath, toPath: cacheFilePath) {
                // 2. 修改状态
                self.state = .success
            }else{
                // 2. 修改状态
                failedInfo = "文件移动失败"
                self.state = .failed
            }
            // 3. 取消本次请求
            completionHandler(.cancel)
            return;
        }
        self.state = .downLoading
        if tmpSize > totalSize {
            NYLog("删除临时缓存 取消请求 从0 开始下载")
            // 1. 删除临时缓存
            FileTool.removeFile(filePath: tmpFilePath)
            // 2. 取消请求
            completionHandler(.cancel);
            // 3. 从0 开始下载
            downLoad()
            return;
        }
        NYLog("继续接受数据 确定开始下载数据")
        outputStream.open()
        completionHandler(.allow)
    }
    
    /// 当用户确定, 继续接受数据的时候调用
    ///
    /// - Parameters:
    ///   - session: 会话
    ///   - dataTask: 任务
    ///   - data: 接收到的一段数据
    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        tmpSize += Int64(data.count)
        //计算一秒中的速度
        downTask.totalRead += Int64(data.count);
        let currentDate = Date()
        let time = currentDate.timeIntervalSince(downTask.lastDate)
        //当前时间和上一秒时间做对比，大于等于一秒就去计算
        if  time >= 1 {
            //计算速度
            let speed = Double(downTask.totalRead) / time
            
            //把速度转成KB或M
            downTask.speed = speed
            
            //维护变量，将计算过的清零
            downTask.totalRead = 0
            //维护变量，记录这次计算的时间
            downTask.lastDate = currentDate
            NYLog("------speed : \(speed)")
        }
        
        // 记录进度
        self.progress = 1.0 * Double(tmpSize) / Double(totalSize)
        // 每隔downLoaderConfig.progressMinReturn 秒 闭包返回一次进度
        if currentDate.timeIntervalSince(progressLastDate) > downLoaderConfig.progressMinReturn {
            self.progressClosure(self.progress,tmpSize,totalSize)
            progressLastDate = currentDate
        }
        
        // 往输出流中写入数据
        data.withUnsafeBytes({ (p: UnsafePointer<UInt8>) -> Void in
            outputStream.write(p, maxLength: data.count)
        })
    }
    
    /// 请求完成时候调用
    /// 请求完成的时候调用( != 请求成功/失败)
    /// - Parameters:
    ///   - session: 会话
    ///   - dataTask: 任务
    ///   - error: 错误
    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            self.failedInfo = "\(error)"
            self.state = .failed
        }else{
            let moveResult:Bool = FileTool.moveFile(fromPath: tmpFilePath, toPath: cacheFilePath)
            if moveResult {
                // 2. 修改状态
                self.state = .success
            }else{
                // 2. 修改状态
                failedInfo = "文件移动失败"
                self.state = .failed
            }
        }
        self.outputStream.close()
        self.session.invalidateAndCancel()
    }
}
// MARK: - Tool
extension DownLoader {
    /// 根据response 设置totalSize
    fileprivate func setupTotalSize(response: URLResponse){
        // 取资源总大小
        // 1. 从  Content-Length 取出来
        // 2. 如果 Content-Range 有, 应该从Content-Range里面获取
        guard let response = response as? HTTPURLResponse else{
            failedInfo = "response is not HTTPURLResponse";
            state = .failed
            return
        }
        //"Content-Length" = 21574062; 本次请求的总大小
        //"Content-Range" = "bytes 0-21574061/21574062"; 本次请求的区间 开始字节-结束字节 / 总字节
        //        guard let contentRangeStr = response.allHeaderFields["Content-Range"] as? String else{
        //            failedInfo = "Content-Range is not String";
        //            state = .failed
        //            return
        //        }
        //        totalSize = (contentLengthStr.components(separatedBy: "/").last! as NSString).longLongValue
        guard let contentLengthStr = response.allHeaderFields["Content-Length"] as? String else{
            failedInfo = "Content-Length is not String";
            state = .failed
            return
        }
        let contentLength = (contentLengthStr as NSString).longLongValue
        if contentLength > 0 {
            totalSize = contentLength
            //NYLog("totalSize: \(totalSize)")
            /// 根据URL缓存总大小
            UserDefaults.standard.set(totalSize, forKey: cacheTotalSizeKey)
        }else{
            failedInfo = "Content-Length 小于等于0 Content-Length: \(contentLengthStr)";
            state = .failed
            return
        }
    }
}
