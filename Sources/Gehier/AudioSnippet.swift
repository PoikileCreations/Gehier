//  Copyright © 2020 Poikile Creations. All rights reserved.

import AVFoundation
import Combine

/// An `AVAudioBuffer` and the time at which it was captured. These types
/// must match the parameters of `AVAudioInputNode.installTap()`'s completion
/// block.
public struct AudioSnippet {

    /// The audio data that was captured by the `AVAudioEngine`.
    public var buffer: AVAudioPCMBuffer

    /// The time at which the sample was captured.
    public var time: AVAudioTime

}
