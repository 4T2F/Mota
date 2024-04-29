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
    private lazy var videoBackgroundView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemGray4
        self.addSubview(view)
        return view
    }()
    
    var videoTop: Constraint?
    var videobottom: Constraint?
    
    var playerLayer: AVPlayerLayer
    
    init(player: AVPlayer) {
        self.playerLayer = AVPlayerLayer(player: player)
        super.init(frame: .zero)
        
        self.videoBackgroundView.snp.makeConstraints { make in
            make.leading.trailing.top.bottom.equalToSuperview()
        }
        
        self.playerLayer.frame = self.videoBackgroundView.bounds
        self.playerLayer.videoGravity = .resizeAspectFill
        
        self.videoBackgroundView.layer.addSublayer(self.playerLayer)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.playerLayer.frame = self.videoBackgroundView.bounds
    }
}

// View 프로토콜 정의
protocol VideoEditingView {
    var presenter: VideoEditingPresenter? { get set }
    
    func displayVideoPlayer(with player: AVPlayer, time: TimeInterval?) // 비디오 플레이어를 화면에 표시하는 메서드
}

// View 구현 클래스
class VideoEditingViewController: UIViewController, VideoEditingView {
    var presenter: VideoEditingPresenter? // 프레젠터 객체
    var videoPlayerView: VideoPlayerView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .systemBackground
        
        presenter?.viewDidLoad() // 뷰가 로드될 때 프레젠터에게 이벤트 전달
    }
    
    // 비디오 플레이어를 화면에 표시하는 메서드
    func displayVideoPlayer(with player: AVPlayer, time: TimeInterval?) {
        self.videoPlayerView = VideoPlayerView(player: player)
        self.videoPlayerView?.layer.cornerRadius = 20
        
        if let videoPlayerView = self.videoPlayerView {
            self.view.addSubview(videoPlayerView)
            videoPlayerView.snp.makeConstraints { make in
                make.leading.trailing.equalToSuperview()
                self.videoPlayerView!.videoTop = make.top.equalTo(self.view.snp.top).constraint
                self.videoPlayerView!.videobottom = make.bottom.equalTo(self.view.snp.bottom).constraint
            }
            videoPlayerView.playerLayer.player?.play() // 비디오 재생

            DispatchQueue.main.async {
                // 첫 번째 동영상의 길이를 가져옵니다.
                guard let asset1Duration = player.currentItem?.duration.seconds else {
                    print("Error: Failed to get the duration of the first video.")
                    return
                }
                
                print(asset1Duration)
                DispatchQueue.main.asyncAfter(deadline: .now() + asset1Duration) {
                    print("First video ended")
                    
                    self.videoPlayerView!.videoTop?.update(offset: 300)
                    self.videoPlayerView!.videobottom?.update(offset: -300)
                }
            }
        }
    }
}

// Presenter 프로토콜 정의
protocol VideoEditingPresenter {
    var router: VideoRouter? { get set }
    var interactor: VideoEditingInteractor? { get set }
    var view: VideoEditingView? { get set }
    
    func viewDidLoad() // 뷰가 로드될 때 호출되는 메서드
    func presentVideoPlayer(with player: AVPlayer, time: TimeInterval?)
}

// Presenter 구현 클래스
class VideoEditingPresenterImpl: VideoEditingPresenter {
    var router: VideoRouter?
    
    var view: VideoEditingView?// 뷰 객체
    var interactor: VideoEditingInteractor? // 인터렉터 객체
    
    func viewDidLoad() {
        interactor?.startVideoEditing() // 비디오 편집 시작 이벤트 전달
    }
    
    // 비디오 플레이어를 화면에 표시하는 메서드
    func presentVideoPlayer(with player: AVPlayer, time: TimeInterval?) {
        view?.displayVideoPlayer(with: player, time: time) // 뷰에 비디오 플레이어 전달
    }
}

// Interactor 프로토콜 정의
protocol VideoEditingInteractor {
    var presenter: VideoEditingPresenter? { get set }
    
    func startVideoEditing() // 비디오 편집 시작 메서드
}

// Interactor 구현 클래스
class VideoEditingInteractorImpl: VideoEditingInteractor {
    var presenter: VideoEditingPresenter? // 프레젠터 객체
    
    func startVideoEditing() {
        // 비디오 파일 경로
        let videoURL1 = URL(fileURLWithPath: Bundle.main.path(forResource: "sample_video", ofType: "mp4")!)
        let asset1 = AVAsset(url: videoURL1)
        
        let startTime1 = CMTime(seconds: 0, preferredTimescale: 600) // 시작 시간
        let endTime1 = CMTime(seconds: .infinity, preferredTimescale: 600) // 종료 시간
        let timeRange1 = CMTimeRange(start: startTime1, end: endTime1) // 시간 범위 설정
        
        // 비디오 파일 경로
        let videoURL2 = URL(fileURLWithPath: Bundle.main.path(forResource: "hi", ofType: "mp4")!)
        let asset2 = AVAsset(url: videoURL2)
        
        // 비디오 합성 객체 생성
        let composition = AVMutableComposition()
        
        // 첫 번째 비디오 트랙과 오디오 트랙 추가
        let videoTrackComposition = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)
        let audioTrackComposition = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)
        
        do {
            // 첫 번째 비디오와 오디오 자르기
            try videoTrackComposition?.insertTimeRange(timeRange1, of: asset1.tracks(withMediaType: .video)[0], at: .zero)
            
            if let audioTrack = asset1.tracks(withMediaType: .audio).first {
                try audioTrackComposition?.insertTimeRange(timeRange1, of: audioTrack, at: .zero)
            } else {
                audioTrackComposition?.insertEmptyTimeRange(CMTimeRangeMake(start: .zero, duration: asset1.duration))
            }
            
            // 두 번째 비디오와 오디오 자르기
            try videoTrackComposition?.insertTimeRange(CMTimeRangeMake(start: .zero, duration: asset2.duration), of: asset2.tracks(withMediaType: .video)[0], at: .zero)
            
            if let audioTrack = asset2.tracks(withMediaType: .audio).first {
                try audioTrackComposition?.insertTimeRange(CMTimeRangeMake(start: .zero, duration: asset2.duration), of: audioTrack, at: .zero)
            } else {
                audioTrackComposition?.insertEmptyTimeRange(CMTimeRangeMake(start: .zero, duration: asset2.duration))
            }
        } catch {
            print("Error: \(error.localizedDescription)")
            return
        }
        
        /*
         // 영상 합성 설정
         let mainVideoInstruction = AVMutableVideoCompositionInstruction()
         mainVideoInstruction.timeRange = CMTimeRangeMake(start: .zero, duration: CMTimeAdd(asset1.duration, asset2.duration))
         
         // 첫 번째 비디오 트랙 지시 사항 설정
         let firstInstruction = self.videoCompositionInstruction(
         videoTrackComposition1!,
         asset: asset1
         )
         firstInstruction.setOpacity(1.0, at: .zero) // 첫 번째 동영상은 시작부터 투명하지 않도록 설정
         firstInstruction.setOpacity(0.0, at: asset1.duration)
         
         
         // 두 번째 비디오 트랙 지시 사항 설정
         let secondInstruction = self.videoCompositionInstruction(
         videoTrackComposition2!,
         asset: asset2
         )
         secondInstruction.setOpacity(0.0, at: .zero) // 두 번째 동영상은 시작부터 투명하도록 설정
         secondInstruction.setOpacity(1.0, at: asset1.duration) // 첫 번째 동영상이 끝난 시점부터 두 번째 동영상이 나오도록 설정
         
         
         // 지시 사항 추가
         mainVideoInstruction.layerInstructions = [firstInstruction, secondInstruction]
         let mainComposition = AVMutableVideoComposition()
         mainComposition.instructions = [mainVideoInstruction]
         mainComposition.renderSize = UIScreen.main.bounds.size
         mainComposition.frameDuration = CMTimeMake(value: 1, timescale: 30)
         */
        // 플레이어 아이템 생성
        let playerItem = AVPlayerItem(asset: composition)
        //playerItem.videoComposition = mainComposition
        // 플레이어 생성
        let player = AVPlayer(playerItem: playerItem)
        
        print(playerItem.asset.tracks)
        
        presenter?.presentVideoPlayer(with: player, time: CMTimeGetSeconds(timeRange1.duration)) // 비디오 플레이어 프레젠트
    }
}

typealias VideoPoint = VideoEditingView & UIViewController

protocol VideoRouter {
    var entry: VideoPoint? { get }
    
    static func start() -> VideoRouter
}

class VDRouter: VideoRouter {
    var entry: VideoPoint?
    
    static func start() -> VideoRouter {
        let router = VDRouter()
        
        // Assign VIP
        var view: VideoEditingView = VideoEditingViewController()
        var presenter: VideoEditingPresenter = VideoEditingPresenterImpl()
        var interactor: VideoEditingInteractor = VideoEditingInteractorImpl()
        
        view.presenter = presenter
        
        interactor.presenter = presenter
        
        presenter.router = router
        presenter.view = view
        presenter.interactor = interactor
        
        router.entry = view as? VideoPoint
        
        return router
    }
}

//MARK: - 동영상 비율 맞추기
extension VideoEditingInteractorImpl {
    func orientationFromTransform(_ transform: CGAffineTransform) -> (orientation: UIImage.Orientation, isPortrait: Bool) {
        var assetOrientation = UIImage.Orientation.up
        var isPortrait = false
        let tfA = transform.a
        let tfB = transform.b
        let tfC = transform.c
        let tfD = transform.d
        
        if tfA == 0 && tfB == 1.0 && tfC == -1.0 && tfD == 0 {
            assetOrientation = .right
            isPortrait = true
        } else if tfA == 0 && tfB == -1.0 && tfC == 1.0 && tfD == 0 {
            assetOrientation = .left
            isPortrait = true
        } else if tfA == 1.0 && tfB == 0 && tfC == 0 && tfD == 1.0 {
            assetOrientation = .up
        } else if tfA == -1.0 && tfB == 0 && tfC == 0 && tfD == -1.0 {
            assetOrientation = .down
        }
        return (assetOrientation, isPortrait)
    }
    
    func videoCompositionInstruction(_ track: AVCompositionTrack, asset: AVAsset) -> AVMutableVideoCompositionLayerInstruction {
        // 1
        let instruction = AVMutableVideoCompositionLayerInstruction(assetTrack: track)
        
        // 2
        let assetTrack = asset.tracks(withMediaType: AVMediaType.video)[0]
        
        // 3
        let transform = assetTrack.preferredTransform
        let assetInfo = orientationFromTransform(transform)
        
        var scaleToFitRatio = UIScreen.main.bounds.width / assetTrack.naturalSize.width
        if assetInfo.isPortrait {
            // 4
            scaleToFitRatio = UIScreen.main.bounds.width / assetTrack.naturalSize.height
            let scaleFactor = CGAffineTransform(
                scaleX: scaleToFitRatio,
                y: scaleToFitRatio)
            instruction.setTransform(
                assetTrack.preferredTransform.concatenating(scaleFactor),
                at: .zero)
        } else {
            //
            let scaleFactor = CGAffineTransform(
                scaleX: scaleToFitRatio,
                y: scaleToFitRatio)
            
            let assetHalfHeight = assetTrack.naturalSize.height * UIScreen.main.bounds.size.width / assetTrack.naturalSize.width / 2
            
            var concat = assetTrack.preferredTransform.concatenating(scaleFactor)
                .concatenating(CGAffineTransform(
                    translationX: 0,
                    y: assetTrack.naturalSize.width >= assetTrack.naturalSize.height ? (UIScreen.main.bounds.height / 2) - assetHalfHeight : 0))
            if assetInfo.orientation == .down {
                let fixUpsideDown = CGAffineTransform(rotationAngle: CGFloat(Double.pi))
                let windowBounds = UIScreen.main.bounds
                let yFix = assetTrack.naturalSize.height + windowBounds.height
                let centerFix = CGAffineTransform(
                    translationX: assetTrack.naturalSize.width,
                    y: yFix)
                concat = fixUpsideDown.concatenating(centerFix).concatenating(scaleFactor)
            }
            instruction.setTransform(concat, at: .zero)
        }
        
        return instruction
    }
}
