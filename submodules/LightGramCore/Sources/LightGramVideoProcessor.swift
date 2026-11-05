import Foundation
import UIKit
import AVFoundation

public final class LightGramVideoProcessor {
    public static func convertVideoToCircle(
        sourceURL: URL,
        completion: @escaping (URL?, Double, String?) -> Void
    ) {
        let asset = AVURLAsset(url: sourceURL)
        let duration = CMTimeGetSeconds(asset.duration)
        guard duration > 0 else {
            completion(nil, 0, "Invalid video duration")
            return
        }
        
        let trimDuration = min(duration, 60.0)
        let timeRange = CMTimeRange(start: .zero, duration: CMTime(seconds: trimDuration, preferredTimescale: 600))
        
        guard let videoTrack = asset.tracks(withMediaType: .video).first else {
            completion(nil, 0, "No video track found")
            return
        }
        
        let naturalSize = videoTrack.naturalSize
        let cropSide = min(abs(naturalSize.width), abs(naturalSize.height))
        let targetSize = CGSize(width: cropSide, height: cropSide)
        
        let composition = AVMutableComposition()
        guard let compTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid) else {
            completion(nil, 0, "Failed to create video composition track")
            return
        }
        
        try? compTrack.insertTimeRange(timeRange, of: videoTrack, at: .zero)
        
        if let audioTrack = asset.tracks(withMediaType: .audio).first,
           let compAudio = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid) {
            try? compAudio.insertTimeRange(timeRange, of: audioTrack, at: .zero)
        }
        
        let videoComposition = AVMutableVideoComposition()
        videoComposition.renderSize = targetSize
        videoComposition.frameDuration = CMTime(value: 1, timescale: 30)
        
        let instruction = AVMutableVideoCompositionInstruction()
        instruction.timeRange = timeRange
        
        let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: compTrack)
        let tx = (cropSide - abs(naturalSize.width)) / 2.0
        let ty = (cropSide - abs(naturalSize.height)) / 2.0
        let transform = videoTrack.preferredTransform.concatenating(CGAffineTransform(translationX: tx, y: ty))
        layerInstruction.setTransform(transform, at: .zero)
        
        instruction.layerInstructions = [layerInstruction]
        videoComposition.instructions = [instruction]
        
        let tempExportURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("circle_\(UUID().uuidString).mp4")
        try? FileManager.default.removeItem(at: tempExportURL)
        
        guard let exportSession = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetHighestQuality) else {
            completion(nil, 0, "Failed to initialize AVAssetExportSession")
            return
        }
        
        exportSession.outputURL = tempExportURL
        exportSession.outputFileType = .mp4
        exportSession.videoComposition = videoComposition
        exportSession.timeRange = timeRange
        
        exportSession.exportAsynchronously {
            DispatchQueue.main.async {
                if exportSession.status == .completed {
                    completion(tempExportURL, trimDuration, nil)
                } else {
                    completion(nil, 0, exportSession.error?.localizedDescription ?? "Crop failed")
                }
            }
        }
    }
}
