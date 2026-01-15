package com.krono.com.krono

import android.view.KeyEvent
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {
    // Must match the MethodChannel name used in Dart
    private val CHANNEL = "com.yourapp.volume"
    private var methodChannel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
    }

    override fun onKeyDown(keyCode: Int, event: KeyEvent?): Boolean {
        if (keyCode == KeyEvent.KEYCODE_VOLUME_UP || keyCode == KeyEvent.KEYCODE_VOLUME_DOWN) {
            try {
                // send an event to Flutter — Dart handler will trigger the shutter
                methodChannel?.invokeMethod("volume", keyCode)
            } catch (e: Exception) {
                // ignore
            }
            // return true -> prevent default system volume change.
            // If you prefer to also change system volume, replace "return true" with:
            // return super.onKeyDown(keyCode, event)
            return true
        }
        return super.onKeyDown(keyCode, event)
    }
}
