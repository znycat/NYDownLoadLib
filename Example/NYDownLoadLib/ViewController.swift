//
//  ViewController.swift
//  NYDownLoadLib
//
//  Created by znycat@163.com on 03/26/2018.
//  Copyright (c) 2018 znycat@163.com. All rights reserved.
//

import UIKit
import NYDownLoadLib
class ViewController: UIViewController {

    @IBOutlet weak var currentSizeLabel: UILabel!
    
    @IBOutlet weak var totalSizeLabel: UILabel!
    
    @IBOutlet weak var progress: UIProgressView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.totalSizeLabel.text = ""
        self.currentSizeLabel.text = ""
        self.progress.progress = 0
    }
    
    @IBOutlet weak var start: UIButton!
    @IBAction func start(_ sender: Any) {
        let url1 = URL(string: "http://gslb.miaopai.com/stream/1jKUPAXcKNBGVti0h9J1wub8RnD5JGfMttBs5w__.mp4?yx=&refer=weibo_app&Expires=1521804223&ssig=5qt8S2FX%2FO&KID=unistore,video")
        
        let _ = DownLoaderManager.manager.downLoad(url: url1!, downLoadInfoClosure: { (totalSize) in
            print("信息:\(totalSize)")
            self.totalSizeLabel.text = "总大小:\(totalSize)"
        }, progressClosure: { (progress,tmpSize,totalSize) in
            print("进度:\(progress),tmpSize:\(tmpSize)totalSize\(totalSize)")
            self.currentSizeLabel.text = "当前:\(tmpSize)"
            self.progress.progress = Float(progress)
            
        }, stateChangeClosure: { (state) in
            print("状态:\(state)")
        }, successClosure: { (filePath) in
            print("成功 路径 :\(filePath)")
            self.progress.progress = 1
        }) {failedInfo in
            print("下载失败: \(failedInfo)")
        }
        
    }
    @IBAction func pause(_ sender: Any) {
        DownLoaderManager.manager.pauseAll()
    }
    @IBAction func resume(_ sender: Any) {
        DownLoaderManager.manager.resumeAll()
    }
    @IBAction func cancel(_ sender: Any) {
        DownLoaderManager.manager.cancelAndClearCacheAll()
    }
    
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        
        
        // 功能包括
        /**
         1:多任务下载
         2:断点续传 (暂停后续,网络异常后重新开始,强制杀死app后继续)
         3:下载配置
            3.1:下载和临时缓存 所在文件夹配置
            3.2:下载进度返回最小间隔配置(默认最快每隔)0.1秒返回一次
            3.3:下载平均速度 通过属性DownTask获取
         
         */
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

