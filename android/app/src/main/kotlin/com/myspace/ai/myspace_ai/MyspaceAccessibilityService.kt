package com.myspace.ai.myspace_ai

import android.accessibilityservice.AccessibilityService
import android.accessibilityservice.AccessibilityServiceInfo
import android.view.KeyEvent
import android.view.accessibility.AccessibilityEvent
import io.flutter.plugin.common.EventChannel

class MyspaceAccessibilityService : AccessibilityService() {

    companion object {
        // Shared with NativeChannelHandler via EventSink
        @Volatile
        var eventSink: EventChannel.EventSink? = null

        private const val LONG_PRESS_THRESHOLD_MS = 600L
        private const val VOLUME_COMBO_WINDOW_MS = 400L
    }

    private var powerDownTime = 0L
    private var volumeDownTime = 0L
    private var isVolumeDownHeld = false

    override fun onServiceConnected() {
        val info = AccessibilityServiceInfo().apply {
            flags = AccessibilityServiceInfo.FLAG_REQUEST_FILTER_KEY_EVENTS or
                    AccessibilityServiceInfo.DEFAULT
            eventTypes = AccessibilityEvent.TYPES_ALL_MASK
            feedbackType = AccessibilityServiceInfo.FEEDBACK_GENERIC
            notificationTimeout = 100
        }
        serviceInfo = info
    }

    override fun onKeyEvent(event: KeyEvent): Boolean {
        val now = System.currentTimeMillis()
        val sink = eventSink ?: return false

        when (event.keyCode) {
            KeyEvent.KEYCODE_VOLUME_DOWN -> {
                when (event.action) {
                    KeyEvent.ACTION_DOWN -> {
                        volumeDownTime = now
                        isVolumeDownHeld = true
                    }
                    KeyEvent.ACTION_UP -> {
                        isVolumeDownHeld = false
                    }
                }
                // Do not consume volume keys — let system handle screenshot shortcut
                return false
            }

            KeyEvent.KEYCODE_POWER -> {
                when (event.action) {
                    KeyEvent.ACTION_DOWN -> {
                        powerDownTime = now
                        // Check for volume+power combo (system screenshot trigger)
                        if (isVolumeDownHeld &&
                            (now - volumeDownTime) < VOLUME_COMBO_WINDOW_MS
                        ) {
                            // Let system take the screenshot, our FileObserver will detect it
                            return false
                        }
                    }
                    KeyEvent.ACTION_UP -> {
                        val holdDuration = now - powerDownTime
                        if (holdDuration >= LONG_PRESS_THRESHOLD_MS) {
                            // Long press on power → voice trigger
                            try {
                                sink.success("VOICE_TRIGGER")
                            } catch (e: Exception) {
                                // Sink might be closed
                            }
                            return true // Consume to prevent default power menu
                        }
                    }
                }
                return false
            }
        }
        return false
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent) {
        // Not needed for key event detection
    }

    override fun onInterrupt() {
        // Service interrupted (e.g., another accessibility service took focus)
    }
}
