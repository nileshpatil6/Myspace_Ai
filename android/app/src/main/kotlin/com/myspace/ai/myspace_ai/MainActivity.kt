package com.myspace.ai.myspace_ai

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    private lateinit var nativeChannelHandler: NativeChannelHandler

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        nativeChannelHandler = NativeChannelHandler(this, flutterEngine)
        nativeChannelHandler.register()
    }

    override fun onDestroy() {
        if (::nativeChannelHandler.isInitialized) {
            nativeChannelHandler.unregister()
        }
        super.onDestroy()
    }
}
