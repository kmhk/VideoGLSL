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
    
    let transtions : [String] = ["angular", "circle", "colorphase", "displacement", "glitchmemories", "linearblur", "wind", "windowblinds"]
    @IBOutlet weak var transitionPicker: UIPickerView!
    @IBOutlet weak var mergeVideos: UIButton!
    @IBOutlet weak var statusLabel: UILabel!
    
    var selected_transition = "angular"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        transitionPicker.dataSource = self
        transitionPicker.delegate = self
        
        statusLabel.text = "Transtion: 1/" + String(transtions.count)
        
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
        
        let videoMerger = VideoMerger(url1: url1, url2: url2, export: exportURL, vc: self)
        
        videoMerger.transtion_function = "transition_" + selected_transition
        mergeVideos.isEnabled = false
        
        videoMerger.startRendering()
        
    }
    
    func openPreviewScreen(_ videoURL:URL) -> Void {
        DispatchQueue.main.async {
            self.mergeVideos.isEnabled = true
            
            let player = AVPlayer(url: videoURL)
            let playerController = AVPlayerViewController()
            playerController.player = player
            
            self.present(playerController, animated: true, completion: {
                player.play()
            })
        }
        
    }
}

extension ViewController : UIPickerViewDelegate {
    
}

extension ViewController : UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        selected_transition = transtions[row]
        statusLabel.text = "Transtion: " + String(row + 1) + "/" + String(transtions.count)
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return transtions.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return transtions[row]
    }
}
