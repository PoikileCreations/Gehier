//  Copyright © 2020 Poikile Creations. All rights reserved.

import AVFoundation
import Combine
import Foundation
import SwiftUI

/// Publishes `AudioVolume` objects at intervals from an `AVAudioEngine`.
public class AudioVolumePublisher: NSObject, ObservableObject {

    /// The `AudioEngine` that supplies audio buffers for this class to
    /// publish to its own subscribers as audio level readings.
    @ObservedObject private var audioEngine: AudioEngine

    @Published public var audioVolume = AudioVolume(decibels: 0.0,
                                                    level: 0.0)

    /// The minimum value for decibel readings. This is used to calculate the
    /// `AudioVolume.level`. The default (as declared in the initializer) is
    /// `-80.0`.
    @Published public var minimumDecibels: Float = -80.0

    // MARK: - Initialization

    public init(audioEngine: AudioEngine) {
        self.audioEngine = audioEngine
        super.init()
    }

    // MARK: - Other Functions

    /// Publish a buffer's `AudioVolume` to subscribers.
    ///
    /// - parameter buffer: The audio buffer.
    /// - parameter time: The time at which the buffer was captured. **This is
    ///   not currently passed along to subscribers.**
    func publishAudioVolume(for buffer: AVAudioPCMBuffer,
                            at time: AVAudioTime) {
        // https://www.raywenderlich.com/5154-avaudioengine-tutorial-for-ios-getting-started#toc-anchor-005
        if let channelDataValue = buffer.floatChannelData?.pointee {
            let frameLength = buffer.frameLength
            let channelDataArray = stride(from: 0,
                                          to: Int(frameLength),
                                          by: buffer.stride).map {
                                            channelDataValue[$0]
            }
            let sumOfChannelSquares = channelDataArray.map { $0 * $0 }.reduce(0, +)
            let rootMeanSquare = sqrt(sumOfChannelSquares / Float(frameLength))
            let averageDb = 20 * log10(rootMeanSquare)
            let meterLevel = scaledDecibels(averageDb)

            audioVolume = AudioVolume(decibels: Double(averageDb),
                                      level: meterLevel)
        }
    }

    private func scaledDecibels(_ decibels: Float) -> Float {
        guard decibels.isFinite else { return 0.0 }

        if decibels < minimumDecibels {
            return 0.0
        } else if decibels >= 1.0 {
            return 1.0
        } else {
            return (abs(minimumDecibels) - abs(decibels)) / abs(minimumDecibels)
        }
    }

}
