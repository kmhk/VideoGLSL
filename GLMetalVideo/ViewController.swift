//
//  ViewController.swift
//  GLMetalVideo
//
//  Created by com on 7/5/19.
//  Copyright © 2019 KMHK. All rights reserved.
//

import UIKit
import AVFoundation
import AVKit

class ViewController: UIViewController {
    
    @IBOutlet weak var mergeVideos: UIButton!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    @IBAction func mergeVideos(_ sender: Any) {
        guard let url1 = Bundle.main.url(forResource: "movie1", withExtension: "mov") else {
            print("Impossible to find the video.")
            return
        }
        
        guard let url2 = Bundle.main.url(forResource: "movie2", withExtension: "mov") else {
            print("Impossible to find the video.")
            return
        }
        
        // Export to file
        let dirPaths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        
        let docsURL = dirPaths[0]
        
        let path = docsURL.path.appending("/mergedVideo.mp4")
        let exportURL = URL.init(fileURLWithPath: path)
        
        var videoMerger = VideoMerger(url1: url1, url2: url2, export: exportURL, vc: self)
        
        videoMerger.startRendering()
        
    }
    
    func openPreviewScreen(_ videoURL:URL) -> Void {
        let player = AVPlayer(url: videoURL)
        let playerController = AVPlayerViewController()
        playerController.player = player
        
        present(playerController, animated: true, completion: {
            player.play()
        })
    }
}
