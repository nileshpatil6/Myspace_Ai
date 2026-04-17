package com.myspace.ai.myspace_ai

import android.content.Context
import android.graphics.Color
import android.graphics.drawable.GradientDrawable
import android.os.Build
import android.provider.Settings
import android.view.Gravity
import android.view.MotionEvent
import android.view.View
import android.view.WindowManager
import io.flutter.plugin.common.EventChannel

object FloatingButtonOverlay {

    @Volatile
    var eventSink: EventChannel.EventSink? = null

    private var floatingView: View? = null
    private var windowManager: WindowManager? = null

    fun show(context: Context) {
        if (!canDraw(context) || floatingView != null) return

        val wm = context.getSystemService(Context.WINDOW_SERVICE) as WindowManager
        windowManager = wm

        val view = createButtonView(context)
        floatingView = view

        val params = WindowManager.LayoutParams(
            dpToPx(context, 52),
            dpToPx(context, 52),
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O)
                WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
            else
                @Suppress("DEPRECATION")
                WindowManager.LayoutParams.TYPE_PHONE,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                    WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN,
            android.graphics.PixelFormat.TRANSLUCENT
        ).apply {
            gravity = Gravity.END or Gravity.CENTER_VERTICAL
            x = dpToPx(context, 8)
            y = 0
        }

        wm.addView(view, params)
    }

    fun hide(context: Context) {
        floatingView?.let {
            try {
                val wm = context.getSystemService(Context.WINDOW_SERVICE) as WindowManager
                wm.removeView(it)
            } catch (e: Exception) {
                // View already removed
            }
            floatingView = null
        }
        windowManager = null
    }

    private fun createButtonView(context: Context): View {
        val view = View(context)

        // Orange circle background
        val drawable = GradientDrawable().apply {
            shape = GradientDrawable.OVAL
            colors = intArrayOf(Color.parseColor("#FF8C54"), Color.parseColor("#FF5A1A"))
            gradientType = GradientDrawable.LINEAR_GRADIENT
        }
        view.background = drawable
        view.elevation = dpToPx(context, 8).toFloat()
        view.alpha = 0.92f

        var lastX = 0f
        var lastY = 0f
        var moved = false

        view.setOnTouchListener { v, event ->
            when (event.action) {
                MotionEvent.ACTION_DOWN -> {
                    lastX = event.rawX
                    lastY = event.rawY
                    moved = false
                    true
                }
                MotionEvent.ACTION_MOVE -> {
                    val dx = event.rawX - lastX
                    val dy = event.rawY - lastY
                    if (Math.abs(dx) > 5 || Math.abs(dy) > 5) {
                        moved = true
                        val params = v.layoutParams as? WindowManager.LayoutParams
                        params?.let {
                            it.x = (it.x - dx).toInt()
                            it.y = (it.y + dy).toInt()
                            lastX = event.rawX
                            lastY = event.rawY
                            windowManager?.updateViewLayout(v, it)
                        }
                    }
                    true
                }
                MotionEvent.ACTION_UP -> {
                    if (!moved) {
                        // Tap → trigger voice mode
                        try {
                            eventSink?.success("VOICE_TRIGGER")
                        } catch (e: Exception) {
                            // Sink closed
                        }
                        // Pulse animation
                        v.animate().scaleX(0.85f).scaleY(0.85f).setDuration(100)
                            .withEndAction {
                                v.animate().scaleX(1f).scaleY(1f).setDuration(150).start()
                            }.start()
                    }
                    true
                }
                else -> false
            }
        }

        return view
    }

    private fun canDraw(context: Context): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            Settings.canDrawOverlays(context)
        } else {
            true
        }
    }

    private fun dpToPx(context: Context, dp: Int): Int {
        return (dp * context.resources.displayMetrics.density).toInt()
    }
}
