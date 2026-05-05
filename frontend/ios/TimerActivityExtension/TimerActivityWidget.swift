import ActivityKit
import SwiftUI
import WidgetKit

@available(iOS 16.2, *)
struct TimerLiveActivityView: View {
    let context: ActivityViewContext<TimerActivityAttributes>

    private var timeString: String {
        let t = context.state.elapsedSeconds
        let h = t / 3600
        let m = (t % 3600) / 60
        let s = t % 60
        if h > 0 {
            return String(format: "%d:%02d:%02d", h, m, s)
        }
        return String(format: "%02d:%02d", m, s)
    }

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: context.state.isRunning ? "timer" : "pause.circle")
                .font(.title2)
                .foregroundStyle(.blue)
            VStack(alignment: .leading, spacing: 2) {
                Text(context.attributes.planName)
                    .font(.headline)
                    .lineLimit(1)
                Text(context.state.isRunning ? "진행 중" : "일시정지")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(timeString)
                .font(.title2.monospacedDigit().bold())
                .foregroundStyle(context.state.isRunning ? .blue : .gray)
        }
        .padding()
        .activityBackgroundTint(Color(.systemBackground))
    }
}

@available(iOS 16.2, *)
@main
struct TimerActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: TimerActivityAttributes.self) { context in
            TimerLiveActivityView(context: context)
        } dynamicIsland: { context in
            let timeString: String = {
                let t = context.state.elapsedSeconds
                let h = t / 3600
                let m = (t % 3600) / 60
                let s = t % 60
                if h > 0 { return String(format: "%d:%02d:%02d", h, m, s) }
                return String(format: "%02d:%02d", m, s)
            }()

            return DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Label(context.attributes.planName, systemImage: "timer")
                        .font(.headline)
                        .lineLimit(1)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(timeString)
                        .font(.title2.monospacedDigit().bold())
                        .foregroundStyle(.blue)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text(context.state.isRunning ? "진행 중" : "일시정지")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } compactLeading: {
                Image(systemName: "timer")
                    .foregroundStyle(.blue)
            } compactTrailing: {
                Text(timeString)
                    .font(.caption.monospacedDigit().bold())
                    .foregroundStyle(.blue)
            } minimal: {
                Image(systemName: "timer")
                    .foregroundStyle(.blue)
            }
        }
    }
}
