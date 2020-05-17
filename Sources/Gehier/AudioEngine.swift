//  Copyright © 2020 Poikile Creations. All rights reserved.

import AVFoundation
import Combine
import Foundation

/// An `AVAudioEngine` subclass that publishes `AudioOutput` objects as they're
/// received. To receive buffers, callers should set up a `sink()` on the
/// engine.
public final class AudioEngine: AVAudioEngine, Publisher {

    // MARK: - struct AudioOutput

    /// An `AVAudioBuffer` and the time at which it was captured. These types
    /// match the parameters of `AVAudioInputNode.installTap()`'s completion
    /// block.
    public struct AudioOutput {

        /// The audio data that was captured by the `AVAudioEngine`.
        public var buffer: AVAudioPCMBuffer

        /// The time at which the sample was captured.
        public var time: AVAudioTime

    }

    // MARK: - Defaults

    private struct Defaults {
        static let bus: AVAudioNodeBus = 0
        static let bufferSize: AVAudioFrameCount = 1024
    }

    // MARK: - Publisher Types

    public typealias Output = AudioOutput

    public typealias Failure = Error

    // MARK: - Properties

    /// The `Publisher` that this class wraps and delegates all publishing
    /// calls to.
    private var publisher = PassthroughSubject<AudioOutput, Error>()

    // MARK: - AVAudioEngine Functions

    /// `start()` receiving audio on bus `0` with a buffer size of `0` and a
    /// frame buffer size of `1024`.
    ///
    /// - SeeAlso: `start(onBus:bufferSize:)`
    public override func start() throws {
        // The default bus number and buffer size come from Apple's sample
        // project. I don't know what they mean.
        try start(onBus: Defaults.bus, bufferSize: Defaults.bufferSize)
    }

    /// Stop the audio, then notify subscribers that we won't be sending any
    /// more buffers.
    public override func stop() {
        super.stop()
        publisher.send(completion: .finished)
    }

    // MARK: - Publisher Functions

    public func receive<S>(subscriber: S)
        where S: Subscriber,
        AudioEngine.Failure == S.Failure,
        AudioEngine.Output == S.Input {
            publisher.receive(subscriber: subscriber)
    }

    // MARK: - Other Functions

    /// Calls `start()` with a specified bus number and buffer size.
    ///
    /// - parameter bus: The number of the input node bus.
    /// - parameter bufferSize: The size of the audio buffer to capture.
    ///
    /// - throws: An exception if the audio data couldn't be captured for any
    ///           reason.
    public func start(onBus bus: AVAudioNodeBus,
                      bufferSize: AVAudioFrameCount) throws {
        // Only one tap can be on a given bus, so if there's already one on
        // our bus, remove it. What if there IS one already? Will there be any
        // negative consequences? Inquiring minds want to know.
        inputNode.removeTap(onBus: bus)

        let outputFormat = inputNode.outputFormat(forBus: bus)
        inputNode.installTap(onBus: bus,
                             bufferSize: bufferSize,
                             format: outputFormat,
                             block: self.handleInputTapBuffer(_:time:))

        try super.start()
    }

    /// Receive audio input data and send it to subscribers. This function's
    /// signature must match that of the `AVAudioInputNode.installTap()`'s
    /// completion block.
    ///
    /// - parameter buffer: The audio input buffer.
    /// - parameter time: The time at which the audio was captured.
    private func handleInputTapBuffer(_ buffer: AVAudioPCMBuffer,
                                      time: AVAudioTime) {
        let output = AudioOutput(buffer: buffer, time: time)
        publisher.send(output)
    }

}
