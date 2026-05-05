import 'package:flutter/services.dart';

typedef TimerEventCallback = void Function();

class TimerNotificationService {
  static const _methodChannel =
      MethodChannel('com.example.frontend/timer_notification');
  static const _eventChannel =
      EventChannel('com.example.frontend/timer_events');

  static TimerEventCallback? _onTimerPausedFromNotification;

  static void init({required TimerEventCallback onTimerPaused}) {
    _onTimerPausedFromNotification = onTimerPaused;
    _eventChannel.receiveBroadcastStream().listen((event) {
      if (event == 'timerPaused') {
        _onTimerPausedFromNotification?.call();
      }
    });
  }

  static Future<void> startTimer({
    required String planName,
    required double elapsedMinutes,
  }) async {
    try {
      await _methodChannel.invokeMethod('startTimer', {
        'planName': planName,
        'elapsedMinutes': elapsedMinutes,
      });
    } catch (_) {}
  }

  static Future<void> stopTimer() async {
    try {
      await _methodChannel.invokeMethod('stopTimer');
    } catch (_) {}
  }
}
