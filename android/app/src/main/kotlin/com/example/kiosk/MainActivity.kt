package com.example.kiosk

import android.app.admin.DevicePolicyManager
import android.content.ComponentName
import android.content.Context
import android.os.Bundle
import android.view.WindowInsets
import android.view.WindowInsetsController
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val CHANNEL = "kiosk_channel"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Keep screen always ON
        window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)

        enableImmersiveMode()
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "enableKiosk" -> {
                        startKiosk()
                        result.success(null)
                    }
                    "disableKiosk" -> {
                        stopKiosk()
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun startKiosk() {
        val dpm = getSystemService(Context.DEVICE_POLICY_SERVICE) as DevicePolicyManager
        val componentName = ComponentName(this, MyDeviceAdminReceiver::class.java)

        if (dpm.isDeviceOwnerApp(packageName)) {
            dpm.setLockTaskPackages(componentName, arrayOf(packageName))
            startLockTask()
        }
    }

    private fun stopKiosk() {
        stopLockTask()
    }

    private fun enableImmersiveMode() {
        window.setDecorFitsSystemWindows(false)

        window.insetsController?.let { controller ->
            controller.hide(WindowInsets.Type.systemBars())
            controller.systemBarsBehavior =
                WindowInsetsController.BEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE
        }
    }
}