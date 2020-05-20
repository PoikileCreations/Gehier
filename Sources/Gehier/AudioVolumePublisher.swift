//  Copyright © 2020 Poikile Creations. All rights reserved.

import AVFoundation
import Combine
import Foundation

/// Publishes `AudioVolume` objects at intervals from an `AVAudioEngine`.
public class AudioVolumePublisher: NSObject, Subject {

    // MARK: - Publisher Types

    public typealias Failure = Never

    public typealias Output = AudioVolume

    // MARK: - Properties

    /// The `AudioEngine` that supplies audio buffers for this class to
    /// publisdsh to its own subscribers as audio level readings.
    private var audioEngine: AudioEngine

    /// The subscription to the audio engine.
    private var audioEngineSubscription: AnyCancellable?

    /// The minimum value for decibel readings. This is used to calculate the
    /// `AudioVolume.level`. The default (as declared in the initializer) is
    /// `-80.0`.
    private var minimumDecibels: Float

    /// The passthrough publisher to which this `Publisher` delegates
    /// everything.
    private var publisher: PassthroughSubject<Output, Failure>

    // MARK: - Initialization

    /// Create the publisher with the audio engine to which it subscribes to
    /// receive audio buffer data.
    ///
    /// - parameter audioEngine: An `AVAudioEngine` that publishes
    ///   `AudioSnippet` values.
    /// - parameter minimumDecibels: The lowest decibel reading. This used to
    ///   calculate volume levels of the buffers sent by the audio engine.
    public init(audioEngine: AudioEngine,
                minimumDecibels: Float = -80.0) {
        self.minimumDecibels = minimumDecibels
        self.publisher = .init()
        self.audioEngine = audioEngine

        super.init()

        // Subscribe to the audioEngine's audio level readings. This has to be
        // done after super.init() because it uses `self` in the blocks.
        audioEngineSubscription = audioEngine.sink(
            receiveCompletion: { [weak self] (completion) in
                switch completion {
                case .finished:
                    self?.send(completion: .finished)
                case .failure:
                    // Our Failure type is Never, so don't pass the error along.
                    return
                }
            },
            receiveValue: { [weak self] (snippet) in
                self?.publishAudioVolume(for: snippet.buffer, at: snippet.time)
        })
    }

    // MARK: - Publisher Functions

    /// Connect a `Subscriber` that wants to receive `AudioVolume` readings.
    public func receive<S>(subscriber: S)
        where S: Subscriber,
        AudioVolumePublisher.Failure == S.Failure,
        AudioVolumePublisher.Output == S.Input {
            publisher.receive(subscriber: subscriber)
    }

    // MARK: - Subject Functions

    public func send(_ value: AudioVolume) {
        publisher.send(value)
    }

    public func send(completion: Subscribers.Completion<Failure>) {
        publisher.send(completion: completion)
    }

    public func send(subscription: Subscription) {
        publisher.send(subscription: subscription)
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

            DispatchQueue.main.async { [unowned self] in
                let volume = AudioVolume(decibels: Double(averageDb),
                                         level: meterLevel)
                self.publisher.send(volume)
            }
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
