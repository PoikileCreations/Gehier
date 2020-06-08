//  Copyright © 2020 Poikile Creations. All rights reserved.

@testable import Gehier
import Foundation
import SwiftUI
import XCTest

class AudioVolumePublisherTests: XCTestCase {

    @State private var audioSnippet = AudioSnippet(buffer: .init(), time: .init())

    func testAudioVolumePublisherInitializer() {
        let snippet = $audioSnippet
        let volumePublisher = AudioVolumePublisher(audioSnippet: snippet)
        XCTAssertEqual(volumePublisher.minimumDecibels, -80.0, accuracy: 0.1)
    }

}
