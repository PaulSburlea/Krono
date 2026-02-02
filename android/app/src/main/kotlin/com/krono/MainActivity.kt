package com.krono.app

import android.view.KeyEvent
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {
    // Must match the MethodChannel name used in Dart
    private val CHANNEL = "com.yourapp.volume"
    private var methodChannel: MethodChannel? = null
    private var isCameraActive = false

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)

        methodChannel?.setMethodCallHandler { call, result ->
            if (call.method == "setCameraActive") {
                isCameraActive = call.arguments as Boolean
                result.success(null)
            } else {
                result.notImplemented()
            }
        }
    }

    override fun onKeyDown(keyCode: Int, event: KeyEvent?): Boolean {
        if (keyCode == KeyEvent.KEYCODE_VOLUME_UP || keyCode == KeyEvent.KEYCODE_VOLUME_DOWN) {
            if (isCameraActive) {
                try {
                    methodChannel?.invokeMethod("volume", keyCode)
                } catch (e: Exception) {
                    // ignore
                }
                return true
            }
        }
        return super.onKeyDown(keyCode, event)
    }
}
