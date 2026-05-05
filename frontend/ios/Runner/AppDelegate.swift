import Flutter
import UIKit
import ActivityKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
    private var updateTimer: Timer?
    private var activityStartTime: Date?
    private var accumulatedSeconds: Int = 0

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
        GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
        guard let messenger = engineBridge.pluginRegistry
            .registrar(forPlugin: "TimerPlugin")?.messenger() else { return }
        setupTimerChannel(messenger: messenger)
    }

    private func setupTimerChannel(messenger: FlutterBinaryMessenger) {
        let channel = FlutterMethodChannel(
            name: "com.example.frontend/timer_notification",
            binaryMessenger: messenger
        )
        channel.setMethodCallHandler { [weak self] call, result in
            guard let self else { return }
            switch call.method {
            case "startTimer":
                guard let args = call.arguments as? [String: Any],
                      let planName = args["planName"] as? String,
                      let elapsedMinutes = args["elapsedMinutes"] as? Double
                else {
                    result(FlutterError(code: "INVALID_ARGS", message: nil, details: nil))
                    return
                }
                self.startLiveActivity(planName: planName, elapsedMinutes: elapsedMinutes)
                result(nil)
            case "stopTimer":
                self.stopLiveActivity()
                result(nil)
            default:
                result(FlutterMethodNotImplemented)
            }
        }
    }

    private func startLiveActivity(planName: String, elapsedMinutes: Double) {
        guard #available(iOS 16.2, *) else { return }
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }

        stopLiveActivity()

        accumulatedSeconds = Int(elapsedMinutes * 60)
        activityStartTime = Date()

        let attributes = TimerActivityAttributes(planName: planName)
        let state = TimerActivityAttributes.ContentState(
            elapsedSeconds: accumulatedSeconds,
            isRunning: true
        )
        let content = ActivityContent(state: state, staleDate: nil)

        do {
            let activity = try Activity<TimerActivityAttributes>.request(
                attributes: attributes,
                content: content,
                pushType: nil
            )
            startUpdateLoop(activity: activity)
        } catch {
            print("[TimerActivity] request failed: \(error)")
        }
    }

    @available(iOS 16.2, *)
    private func startUpdateLoop(activity: Activity<TimerActivityAttributes>) {
        updateTimer?.invalidate()
        updateTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self, weak activity] _ in
            guard let self, let activity, let start = self.activityStartTime else { return }
            let elapsed = self.accumulatedSeconds + Int(Date().timeIntervalSince(start))
            let state = TimerActivityAttributes.ContentState(
                elapsedSeconds: elapsed,
                isRunning: true
            )
            let content = ActivityContent(state: state, staleDate: nil)
            Task { await activity.update(content) }
        }
    }

    private func stopLiveActivity() {
        updateTimer?.invalidate()
        updateTimer = nil
        activityStartTime = nil

        guard #available(iOS 16.2, *) else { return }
        Task {
            for activity in Activity<TimerActivityAttributes>.activities {
                await activity.end(nil, dismissalPolicy: .immediate)
            }
        }
    }
}
