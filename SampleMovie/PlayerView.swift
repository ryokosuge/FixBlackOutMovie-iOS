//
//  PlayerView.swift
//  SampleMovie
//
//  Created by RyoKosuge on 2018/12/10.
//  Copyright © 2018年 Ryo Kosuge. All rights reserved.
//

import UIKit
import AVFoundation

class PlayerView: UIView {

    override static var layerClass: AnyClass {
        return AVPlayerLayer.self
    }

    private var playerLayer: AVPlayerLayer {
        return self.layer as! AVPlayerLayer
    }

    private var playerItem: AVPlayerItem?
    private var player: AVPlayer?
    private var periodicTimeObserver: Any?
    private var currentTime: Double = 0.0

    private(set) var isComplete: Bool = false

    init() {
        super.init(frame: .zero)
        setup()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }

    func loadVideoURL(_ url: URL) {
        let urlAsset = AVURLAsset(url: url)
        let playerItem = AVPlayerItem(asset: urlAsset)
        self.playerItem = playerItem
        playerItem.addObserver(self, forKeyPath: "status", options: [.new, .old], context: nil)
        let player = AVPlayer(playerItem: playerItem)
        self.player = player
        self.playerLayer.player = player

    }

    func play() {
        self.player?.play()

        if let observer = self.periodicTimeObserver {
            self.player?.removeTimeObserver(observer)
            self.periodicTimeObserver = nil
        }

        let time = CMTimeMakeWithSeconds(0.1, preferredTimescale: Int32(NSEC_PER_SEC))
        self.periodicTimeObserver = self.player?.addPeriodicTimeObserver(forInterval: time, queue: .main, using: {[weak self] (time) in
            self?.currentTime = CMTimeGetSeconds(time)
        })
    }

    func pause() {
        self.player?.pause()

        if let observer = self.periodicTimeObserver {
            self.player?.removeTimeObserver(observer)
            self.periodicTimeObserver = nil
        }

        if let currentTime = self.player?.currentTime() {
            self.currentTime = CMTimeGetSeconds(currentTime)
        }
    }

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard let keyPath = keyPath, keyPath == "status" else { return }
        guard
            let old = change?[NSKeyValueChangeKey.oldKey] as? Int,
            let oldValue = AVPlayerItem.Status(rawValue: old),
            let new = change?[NSKeyValueChangeKey.newKey] as? Int,
            let newValue = AVPlayerItem.Status(rawValue: new) else {
            return
        }

        guard oldValue != newValue else {
            return
        }

        self.playerItem?.removeObserver(self, forKeyPath: "status")

        guard case AVPlayerItem.Status.readyToPlay = newValue else {
            return
        }
        
        DispatchQueue.main.async {[weak self] in
            self?.player?.play()
        }

    }

    @objc private func playerItemDidPlayToEndTimeNotification(_ notification: Notification) {
        self.isComplete = true
    }

    @objc private func applicationWillEnterForegroundNotification(_ notification: Notification) {
        if (self.isComplete) {
            let time = CMTimeMakeWithSeconds(floor(self.currentTime), preferredTimescale: Int32(NSEC_PER_SEC))
            self.player?.seek(to: time, toleranceBefore: CMTime.zero, toleranceAfter: CMTime.zero)
        }
    }

    private func setup() {
        self.playerLayer.videoGravity = .resizeAspect
        
        let center = NotificationCenter.default
        center.addObserver(self, selector: #selector(applicationWillEnterForegroundNotification(_:)), name: UIApplication.willEnterForegroundNotification, object: nil)
        center.addObserver(self, selector: #selector(playerItemDidPlayToEndTimeNotification(_:)), name: .AVPlayerItemDidPlayToEndTime, object: playerItem)
    }

}
