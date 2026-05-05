package com.example.frontend

import android.app.*
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.*
import androidx.core.app.NotificationCompat
import io.flutter.plugin.common.EventChannel

class TimerForegroundService : Service() {
    private val handler = Handler(Looper.getMainLooper())
    private var startTimeMs: Long = 0L
    private var accumulatedMs: Long = 0L
    private var planName: String = ""

    companion object {
        const val CHANNEL_ID = "timer_channel"
        const val NOTIFICATION_ID = 1001
        const val ACTION_START = "com.example.frontend.START_TIMER"
        const val ACTION_PAUSE = "com.example.frontend.PAUSE_TIMER"
        const val ACTION_STOP = "com.example.frontend.STOP_TIMER"
        const val EXTRA_PLAN_NAME = "plan_name"
        const val EXTRA_ELAPSED_MS = "elapsed_ms"

        @Volatile
        var eventSink: EventChannel.EventSink? = null
        val mainHandler = Handler(Looper.getMainLooper())
    }

    private val updateRunnable = object : Runnable {
        override fun run() {
            updateNotification()
            handler.postDelayed(this, 1000)
        }
    }

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_START -> {
                planName = intent.getStringExtra(EXTRA_PLAN_NAME) ?: ""
                accumulatedMs = intent.getLongExtra(EXTRA_ELAPSED_MS, 0L)
                startTimeMs = System.currentTimeMillis()
                val notification = buildNotification(getCurrentElapsedMs())
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
                    startForeground(NOTIFICATION_ID, notification, ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE)
                } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                    startForeground(NOTIFICATION_ID, notification, 0)
                } else {
                    startForeground(NOTIFICATION_ID, notification)
                }
                handler.removeCallbacks(updateRunnable)
                handler.post(updateRunnable)
            }
            ACTION_PAUSE -> {
                handler.removeCallbacks(updateRunnable)
                @Suppress("DEPRECATION")
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                    stopForeground(STOP_FOREGROUND_REMOVE)
                } else {
                    stopForeground(true)
                }
                stopSelf()
                mainHandler.post { eventSink?.success("timerPaused") }
            }
            ACTION_STOP -> {
                handler.removeCallbacks(updateRunnable)
                @Suppress("DEPRECATION")
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                    stopForeground(STOP_FOREGROUND_REMOVE)
                } else {
                    stopForeground(true)
                }
                stopSelf()
            }
        }
        return START_NOT_STICKY
    }

    private fun getCurrentElapsedMs(): Long =
        accumulatedMs + (System.currentTimeMillis() - startTimeMs)

    private fun updateNotification() {
        val nm = getSystemService(NOTIFICATION_SERVICE) as NotificationManager
        nm.notify(NOTIFICATION_ID, buildNotification(getCurrentElapsedMs()))
    }

    private fun buildNotification(elapsedMs: Long): Notification {
        val totalSeconds = elapsedMs / 1000
        val hours = totalSeconds / 3600
        val minutes = (totalSeconds % 3600) / 60
        val seconds = totalSeconds % 60
        val timeStr = if (hours > 0) {
            String.format("%d:%02d:%02d", hours, minutes, seconds)
        } else {
            String.format("%02d:%02d", minutes, seconds)
        }

        val mainIntent = packageManager.getLaunchIntentForPackage(packageName)?.apply {
            flags = Intent.FLAG_ACTIVITY_SINGLE_TOP
        }
        val pendingMain = PendingIntent.getActivity(
            this, 0, mainIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val pauseIntent = Intent(this, TimerForegroundService::class.java).apply {
            action = ACTION_PAUSE
        }
        val pendingPause = PendingIntent.getService(
            this, 1, pauseIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle(planName)
            .setContentText("⏱ $timeStr 진행 중")
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setSilent(true)
            .setContentIntent(pendingMain)
            .addAction(android.R.drawable.ic_media_pause, "일시정지", pendingPause)
            .build()
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "타이머 알림",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                setShowBadge(false)
                enableLights(false)
                enableVibration(false)
            }
            (getSystemService(NOTIFICATION_SERVICE) as NotificationManager)
                .createNotificationChannel(channel)
        }
    }

    override fun onDestroy() {
        handler.removeCallbacks(updateRunnable)
        super.onDestroy()
    }

    override fun onBind(intent: Intent?) = null
}
