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
    private var kioskEnabled = false

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
        enableImmersiveMode()
    }

    override fun onBackPressed() {
        if (kioskEnabled) {
            // block back button in kiosk mode
        } else {
            super.onBackPressed()
        }
    }

    override fun onWindowFocusChanged(hasFocus: Boolean) {
        super.onWindowFocusChanged(hasFocus)
        // Only hide system UI when kiosk is active
        if (hasFocus && kioskEnabled) hideSystemUI()
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
                    "launchApp" -> {
                        val appPackage = call.argument<String>("package")
                        if (appPackage != null) {
                            val intent = packageManager.getLaunchIntentForPackage(appPackage)
                            if (intent != null) {
                                startActivity(intent)
                                result.success(null)
                            } else {
                                result.error("NOT_FOUND", "App not found: $appPackage", null)
                            }
                        } else {
                            result.error("INVALID", "No package provided", null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun startKiosk() {
        kioskEnabled = true
        val dpm = getSystemService(Context.DEVICE_POLICY_SERVICE) as DevicePolicyManager
        val componentName = ComponentName(this, MyDeviceAdminReceiver::class.java)

        if (dpm.isDeviceOwnerApp(packageName)) {
            dpm.setLockTaskPackages(componentName, arrayOf(packageName, "com.termux"))
            dpm.setLockTaskFeatures(componentName, DevicePolicyManager.LOCK_TASK_FEATURE_NONE)
            startLockTask()
        }
        hideSystemUI()
    }

    private fun stopKiosk() {
        kioskEnabled = false
        val dpm = getSystemService(Context.DEVICE_POLICY_SERVICE) as DevicePolicyManager
        val componentName = ComponentName(this, MyDeviceAdminReceiver::class.java)

        if (dpm.isDeviceOwnerApp(packageName)) {
            dpm.setLockTaskFeatures(
                componentName,
                DevicePolicyManager.LOCK_TASK_FEATURE_SYSTEM_INFO or
                DevicePolicyManager.LOCK_TASK_FEATURE_NOTIFICATIONS or
                DevicePolicyManager.LOCK_TASK_FEATURE_HOME or
                0x00000010
            )
        }
        stopLockTask()
        showSystemUI() // restore nav bar and status bar
    }

    private fun hideSystemUI() {
        window.decorView.systemUiVisibility = (
            android.view.View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY
            or android.view.View.SYSTEM_UI_FLAG_LAYOUT_STABLE
            or android.view.View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION
            or android.view.View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN
            or android.view.View.SYSTEM_UI_FLAG_HIDE_NAVIGATION
            or android.view.View.SYSTEM_UI_FLAG_FULLSCREEN
        )
    }

    private fun showSystemUI() {
        window.decorView.systemUiVisibility = (
            android.view.View.SYSTEM_UI_FLAG_LAYOUT_STABLE
            or android.view.View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION
            or android.view.View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN
        )
        window.insetsController?.show(WindowInsets.Type.systemBars())
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
