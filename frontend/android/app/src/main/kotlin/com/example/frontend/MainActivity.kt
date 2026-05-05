package com.example.frontend

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val METHOD_CHANNEL = "com.example.frontend/timer_notification"
    private val EVENT_CHANNEL = "com.example.frontend/timer_events"
    private val NOTIF_PERMISSION_CODE = 1001

    override fun onStart() {
        super.onStart()
        requestNotificationPermissionIfNeeded()
    }

    private fun requestNotificationPermissionIfNeeded() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            if (ContextCompat.checkSelfPermission(this, Manifest.permission.POST_NOTIFICATIONS)
                != PackageManager.PERMISSION_GRANTED
            ) {
                ActivityCompat.requestPermissions(
                    this,
                    arrayOf(Manifest.permission.POST_NOTIFICATIONS),
                    NOTIF_PERMISSION_CODE
                )
            }
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, METHOD_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "startTimer" -> {
                        val planName = call.argument<String>("planName") ?: ""
                        val elapsedMinutes = call.argument<Double>("elapsedMinutes") ?: 0.0
                        startTimerService(planName, (elapsedMinutes * 60_000).toLong())
                        result.success(null)
                    }
                    "stopTimer" -> {
                        sendServiceIntent(TimerForegroundService.ACTION_STOP)
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    TimerForegroundService.eventSink = events
                }
                override fun onCancel(arguments: Any?) {
                    TimerForegroundService.eventSink = null
                }
            })
    }

    private fun startTimerService(planName: String, elapsedMs: Long) {
        val intent = Intent(this, TimerForegroundService::class.java).apply {
            action = TimerForegroundService.ACTION_START
            putExtra(TimerForegroundService.EXTRA_PLAN_NAME, planName)
            putExtra(TimerForegroundService.EXTRA_ELAPSED_MS, elapsedMs)
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startForegroundService(intent)
        } else {
            startService(intent)
        }
    }

    private fun sendServiceIntent(action: String) {
        startService(Intent(this, TimerForegroundService::class.java).apply {
            this.action = action
        })
    }
}
