package com.myspace.ai.myspace_ai

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import androidx.core.content.ContextCompat

class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Intent.ACTION_BOOT_COMPLETED) {
            // Restart foreground service after device reboot
            val serviceIntent = Intent(context, TriggerForegroundService::class.java)
            ContextCompat.startForegroundService(context, serviceIntent)
        }
    }
}
