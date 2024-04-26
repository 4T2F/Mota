//
//  VideoEditorView.swift
//  MoTa
//
//  Created by 최동호 on 4/26/24.
//

import SnapKit

import AVKit
import AVFoundation
import Foundation
import UIKit

class VideoPlayerView: UIView {
    private let playerLayer: AVPlayerLayer
    
    init(player: AVPlayer) {
        self.playerLayer = AVPlayerLayer(player: player)
        super.init(frame: .zero)
        configurePlayerLayer()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func configurePlayerLayer() {
        playerLayer.videoGravity = .resizeAspectFill
        layer.addSublayer(playerLayer)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer.frame = bounds
    }
}

// View 프로토콜 정의
protocol VideoEditingView {
    func displayVideoPlayer(with player: AVPlayer) // 비디오 플레이어를 화면에 표시하는 메서드
}

// View 구현 클래스
class VideoEditingViewController: UIViewController, VideoEditingView {
    var presenter: VideoEditingPresenter? // 프레젠터 객체
    var videoPlayerView: VideoPlayerView?

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .systemBlue
        presenter?.viewDidLoad() // 뷰가 로드될 때 프레젠터에게 이벤트 전달
    }
    
    // 비디오 플레이어를 화면에 표시하는 메서드
    func displayVideoPlayer(with player: AVPlayer) {
        videoPlayerView = VideoPlayerView(player: player)
        
        if let videoPlayerView = videoPlayerView {
            view.addSubview(videoPlayerView)
            videoPlayerView.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
        }
    }
}

// Presenter 프로토콜 정의
protocol VideoEditingPresenter {
    func viewDidLoad() // 뷰가 로드될 때 호출되는 메서드
    func presentVideoPlayer(with player: AVPlayer)
}

// Presenter 구현 클래스
class VideoEditingPresenterImpl: VideoEditingPresenter {
    var view: VideoEditingView?// 뷰 객체
    var interactor: VideoEditingInteractor? // 인터렉터 객체

    
    func viewDidLoad() {
        print("dongho")
        interactor?.startVideoEditing() // 비디오 편집 시작 이벤트 전달
    }
    
    // 비디오 플레이어를 화면에 표시하는 메서드
    func presentVideoPlayer(with player: AVPlayer) {
        print("jooyoung")
        view?.displayVideoPlayer(with: player) // 뷰에 비디오 플레이어 전달
    }
}

// Interactor 프로토콜 정의
protocol VideoEditingInteractor {
    func startVideoEditing() // 비디오 편집 시작 메서드
}

// Interactor 구현 클래스
class VideoEditingInteractorImpl: VideoEditingInteractor {
    var presenter: VideoEditingPresenter? // 프레젠터 객체
    
    func startVideoEditing() {
        // 비디오 자르기 로직 수행
        print("hello")
        let videoURL = URL(fileURLWithPath: Bundle.main.path(forResource: "sample_video", ofType: "mp4")!) // 비디오 파일 경로
        let startTime = CMTime(seconds: 10, preferredTimescale: 600) // 시작 시간
        let endTime = CMTime(seconds: 20, preferredTimescale: 600) // 종료 시간
        let timeRange = CMTimeRange(start: startTime, end: endTime) // 시간 범위 설정
        let asset = AVAsset(url: videoURL) // 비디오 asset
        
        let composition = AVMutableComposition() // 비디오 합성 객체 생성
        let videoTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid) // 비디오 트랙
        
        do {
            try videoTrack?.insertTimeRange(timeRange, of: asset.tracks(withMediaType: .video)[0], at: .zero) // 비디오 자르기
        } catch {
            print("Error: \(error.localizedDescription)")
            return
        }
        
        let playerItem = AVPlayerItem(asset: composition) // 플레이어 아이템 생성
        let player = AVPlayer(playerItem: playerItem) // 플레이어 생성
        
        presenter?.presentVideoPlayer(with: player) // 비디오 플레이어 프레젠트
    }
}
