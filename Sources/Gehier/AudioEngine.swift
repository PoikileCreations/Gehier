//  Copyright © 2020 Poikile Creations. All rights reserved.

import AVFoundation
import Combine
import Foundation

/// An `AVAudioEngine` subclass that has an `Observable` `AudioSnippet`
/// object.
public final class AudioEngine: AVAudioEngine, ObservableObject {

    // MARK: - Defaults

    private struct Defaults {
        static let bus: AVAudioNodeBus = 0
        static let bufferSize: AVAudioFrameCount = 1024
    }

    // MARK: - ObservableObject

    @Published var audioSnippet = AudioSnippet(buffer: .init(), time: .init())

    // MARK: - Properties

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
        audioSnippet = AudioSnippet(buffer: buffer, time: time)
    }

}
