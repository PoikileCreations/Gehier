//  Copyright © 2020 Poikile Creations. All rights reserved.

import Foundation

/// A snapshot of the audio volume at a specific point in time.
public struct AudioVolume {

    /// The absolute decibel level, with `0.0` is the *maximum* volume that
    /// the microphone can handle. Refer to the audio input characteristics to
    /// determine the minimum value.
    public var decibels: Double

    /// The percentage of the decibel reading in the total range.
    public var level: Float

    /// The time at which the volume was captured.
    public var time = Date()

}
