package com.myspace.ai.myspace_ai

import android.app.Service
import android.content.Intent
import android.os.Environment
import android.os.FileObserver
import android.os.IBinder
import android.util.Log
import io.flutter.plugin.common.EventChannel
import java.io.File

class ScreenshotObserverService : Service() {

    companion object {
        private const val TAG = "ScreenshotObserver"

        @Volatile
        var screenshotEventSink: EventChannel.EventSink? = null
    }

    private var fileObserver: FileObserver? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        startObserving()
        return START_STICKY
    }

    private fun startObserving() {
        val screenshotDirs = listOf(
            File(
                Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_PICTURES),
                "Screenshots"
            ),
            File(
                Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DCIM),
                "Screenshots"
            ),
        ).filter { it.exists() || it.mkdirs() }

        val dir = screenshotDirs.firstOrNull() ?: return

        fileObserver = if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.Q) {
            object : FileObserver(dir, CREATE or MOVED_TO) {
                override fun onEvent(event: Int, path: String?) {
                    path?.let { handleNewFile(dir.absolutePath, it) }
                }
            }
        } else {
            @Suppress("DEPRECATION")
            object : FileObserver(dir.absolutePath, CREATE or MOVED_TO) {
                override fun onEvent(event: Int, path: String?) {
                    path?.let { handleNewFile(dir.absolutePath, it) }
                }
            }
        }

        fileObserver?.startWatching()
        Log.d(TAG, "Watching: ${dir.absolutePath}")
    }

    private fun handleNewFile(dirPath: String, filename: String) {
        val lowerName = filename.lowercase()
        if (!lowerName.endsWith(".jpg") &&
            !lowerName.endsWith(".jpeg") &&
            !lowerName.endsWith(".png")
        ) return

        val fullPath = "$dirPath/$filename"
        Log.d(TAG, "New screenshot detected: $fullPath")

        // Small delay to ensure file is fully written before Flutter reads it
        Thread.sleep(500)

        try {
            screenshotEventSink?.success(fullPath)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to emit screenshot event: ${e.message}")
        }
    }

    override fun onDestroy() {
        fileObserver?.stopWatching()
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null
}
