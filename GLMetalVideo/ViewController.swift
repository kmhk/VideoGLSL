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
    
    @IBOutlet weak var filterChoice: UISegmentedControl!
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
        
        switch filterChoice.selectedSegmentIndex {
        case 0:
            videoMerger.transtion_function = "transition_circle"
            break
        case 1:
            videoMerger.transtion_function = "transition_displacement"
            break
        case 2:
            videoMerger.transtion_function = "transition_linearblur"
            break
        case 3:
            videoMerger.transtion_function = "transition_glitchmemories"
            break
        default:
            videoMerger.transtion_function = "transition_colorphase"
            break
        }
        mergeVideos.isEnabled = false
        
        videoMerger.startRendering()
        
    }
    
    func openPreviewScreen(_ videoURL:URL) -> Void {
        DispatchQueue.main.async {
            self.mergeVideos.isEnabled = true
        }
        
        let player = AVPlayer(url: videoURL)
        let playerController = AVPlayerViewController()
        playerController.player = player
        
        present(playerController, animated: true, completion: {
            player.play()
        })
    }
}
