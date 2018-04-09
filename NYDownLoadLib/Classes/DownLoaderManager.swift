//
//  DownLoaderManager.swift
//  下载
//
//  Created by 翟乃玉 on 2017/11/27.
//  Copyright © 2017年 翟乃玉. All rights reserved.
//

import UIKit

open class DownLoaderManager: NSObject {
    public static let manager = DownLoaderManager()
    private override init() {}
    fileprivate lazy var downLoadInfo: [String : DownLoader] = {
        return [String : DownLoader]();
    }()
    
    public func getDownLoader(url: URL) -> DownLoader? {
        let md5Name = url.absoluteString.nyMd5()
        return downLoadInfo[md5Name];
    }
    public func getDownLoaderKey(url: URL) -> String {
        return url.absoluteString.nyMd5()
    }
    
    public func downLoad(url: URL,
                         downLoadInfoClosure: @escaping DownLoadInfoClosure,
                         progressClosure: @escaping ProgressClosure,
                         stateChangeClosure: @escaping StateChangeClosure,
                         successClosure: @escaping SuccessClosure,
                         failedClosure: @escaping FailedClosure) -> DownLoader {
        var downloader: DownLoader
        if let downloaderTemp = getDownLoader(url: url) {
            // 有 直接执行
            downloaderTemp.downLoad()
            downloader = downloaderTemp
        }else{
            // 木有 新建
            var config = DownLoaderConfig()
//            config.progressMinReturn = 3
            downloader = DownLoader(url: url, config: config , downLoadInfoClosure: { (totalSize) in
                downLoadInfoClosure(totalSize)
            }, progressClosure: { (progress,tmpSize, totalSize) in
                progressClosure(progress,tmpSize, totalSize)
            }, stateChangeClosure: { (state) in
                
                stateChangeClosure(state)
            }, successClosure: { (filePath) in
                
                successClosure(filePath)
                // 从info中删除
                self.downLoadInfo.removeValue(forKey: self.getDownLoaderKey(url: url))
                
            }, failedClosure: { (failedInfo) in
                
                failedClosure(failedInfo)
                // 从info中删除
                self.downLoadInfo.removeValue(forKey: self.getDownLoaderKey(url: url))
            })
            //放入downLoadInfo
            downLoadInfo[getDownLoaderKey(url: url)] = downloader
        }
        return downloader;
    }
    
    /// 暂停
    public func pause(url: URL){
        let downLoader = self.downLoadInfo[getDownLoaderKey(url: url)]
        downLoader?.pauseCurrentTask()
    }
    /// 继续
    public func resume(url: URL){
        let downLoader = self.downLoadInfo[getDownLoaderKey(url: url)]
        downLoader?.resumeCurrentTask()
    }
    /// 取消
    public func cancel(url: URL){
        let downLoader = self.downLoadInfo[getDownLoaderKey(url: url)]
        downLoader?.cancelCurrentTask()
    }
    /// 取消并且清空缓存
    public func cancelAndClearCache(url: URL){
        let downLoader = self.downLoadInfo[getDownLoaderKey(url: url)]
        downLoader?.cancelAndCleanCache()
    }
    
    /// 暂停全部
    public func pauseAll(){
        for downLoader in self.downLoadInfo.values {
            downLoader.pauseCurrentTask()
        }
    }
    /// 继续全部
    public func resumeAll(){
        for downLoader in self.downLoadInfo.values {
            downLoader.resumeCurrentTask()
        }
    }
    /// 取消全部
    public func cancelAll(){
        for downLoader in self.downLoadInfo.values {
            downLoader.cancelCurrentTask()
        }
    }
    /// 取消并且清空缓存全部
    public func cancelAndClearCacheAll(){
        for downLoader in self.downLoadInfo.values {
            downLoader.cancelAndCleanCache()
        }
    }
}
