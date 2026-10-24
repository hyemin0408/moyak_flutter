package com.example.moyak_flutter

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val journal = getSharedPreferences("moyak_order_recovery", MODE_PRIVATE)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "moyak/order_recovery")
            .setMethodCallHandler { call, result ->
                val key = call.argument<String>("key")
                if (key.isNullOrEmpty()) {
                    result.error("invalid_key", "Missing recovery namespace", null)
                } else {
                    when (call.method) {
                        "read" -> result.success(journal.getString(key, null))
                        "write" -> {
                            val value = call.argument<String>("value")
                            val editor = journal.edit()
                            if (value == null) editor.remove(key) else editor.putString(key, value)
                            result.success(editor.commit())
                        }
                        else -> result.notImplemented()
                    }
                }
            }
    }
}
