import ActivityKit
import Foundation

@available(iOS 16.2, *)
struct TimerActivityAttributes: ActivityAttributes {
    public typealias TimerStatus = ContentState

    public struct ContentState: Codable, Hashable {
        var elapsedSeconds: Int
        var isRunning: Bool
    }

    var planName: String
}
