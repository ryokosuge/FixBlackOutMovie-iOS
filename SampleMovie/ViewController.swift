//
//  ViewController.swift
//  SampleMovie
//
//  Created by RyoKosuge on 2018/12/10.
//  Copyright © 2018年 Ryo Kosuge. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var playerView: PlayerView?

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.

        let center = NotificationCenter.default
        center.addObserver(self, selector: #selector(applicationDidBecomeActiveNotification(_:)), name: UIApplication.didBecomeActiveNotification, object: nil)
        center.addObserver(self, selector: #selector(applicationWillResignActiveNotification(_:)), name: UIApplication.willResignActiveNotification, object: nil)

        guard let url = Bundle.main.url(forResource: "waterfall-free-video1", withExtension: "mp4") else { return }
        self.playerView?.loadVideoURL(url)
    }

    @objc private func applicationDidBecomeActiveNotification(_ notification: Notification) {
        if let playerView = self.playerView, !playerView.isComplete {
            self.playerView?.play()
        }
    }

    @objc private func applicationWillResignActiveNotification(_ notification: Notification) {
        self.playerView?.pause()
    }

}

