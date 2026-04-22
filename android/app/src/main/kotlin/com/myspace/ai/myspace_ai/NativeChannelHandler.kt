package com.myspace.ai.myspace_ai

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import androidx.core.content.ContextCompat
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class NativeChannelHandler(
    private val context: Context,
    private val flutterEngine: FlutterEngine
) {
    companion object {
        const val TRIGGER_CHANNEL = "com.myspace.ai/trigger"
        const val POWER_EVENT_CHANNEL = "com.myspace.ai/power_events"
        const val SCREENSHOT_EVENT_CHANNEL = "com.myspace.ai/screenshot_events"
    }

    private val triggerMethodChannel = MethodChannel(
        flutterEngine.dartExecutor.binaryMessenger,
        TRIGGER_CHANNEL
    )
    private val powerEventChannel = EventChannel(
        flutterEngine.dartExecutor.binaryMessenger,
        POWER_EVENT_CHANNEL
    )
    private val screenshotEventChannel = EventChannel(
        flutterEngine.dartExecutor.binaryMessenger,
        SCREENSHOT_EVENT_CHANNEL
    )

    fun register() {
        triggerMethodChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "startService" -> {
                    startForegroundService()
                    result.success(null)
                }
                "stopService" -> {
                    stopForegroundService()
                    result.success(null)
                }
                "isServiceRunning" -> {
                    result.success(TriggerForegroundService.isRunning)
                }
                "openAccessibilitySettings" -> {
                    openAccessibilitySettings()
                    result.success(null)
                }
                "hasOverlayPermission" -> {
                    result.success(
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M)
                            Settings.canDrawOverlays(context)
                        else true
                    )
                }
                "requestOverlayPermission" -> {
                    requestOverlayPermission()
                    result.success(null)
                }
                "showFloatingButton" -> {
                    FloatingButtonOverlay.show(context)
                    result.success(null)
                }
                "hideFloatingButton" -> {
                    FloatingButtonOverlay.hide(context)
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }

        // Wire up EventChannel sinks to static companions
        powerEventChannel.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                MyspaceAccessibilityService.eventSink = events
                FloatingButtonOverlay.eventSink = events
            }
            override fun onCancel(arguments: Any?) {
                MyspaceAccessibilityService.eventSink = null
                FloatingButtonOverlay.eventSink = null
            }
        })

        screenshotEventChannel.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                ScreenshotObserverService.screenshotEventSink = events
            }
            override fun onCancel(arguments: Any?) {
                ScreenshotObserverService.screenshotEventSink = null
            }
        })
    }

    fun unregister() {
        triggerMethodChannel.setMethodCallHandler(null)
        powerEventChannel.setStreamHandler(null)
        screenshotEventChannel.setStreamHandler(null)
    }

    private fun startForegroundService() {
        val intent = Intent(context, TriggerForegroundService::class.java)
        ContextCompat.startForegroundService(context, intent)
    }

    private fun stopForegroundService() {
        context.stopService(Intent(context, TriggerForegroundService::class.java))
    }

    private fun openAccessibilitySettings() {
        val intent = Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS)
        intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
        context.startActivity(intent)
    }

    private fun requestOverlayPermission() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val intent = Intent(
                Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                Uri.parse("package:${context.packageName}")
            )
            intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
            context.startActivity(intent)
        }
    }
}
