package com.example.copd_ai_health_app

import android.os.Build
import android.os.PowerManager
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {
    private val thermalChannel = "com.alentoai/thermal"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, thermalChannel)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getThermalHeadroom" -> result.success(readThermalHeadroom())
                    "getThermalStatus" -> result.success(readThermalStatus())
                    else -> result.notImplemented()
                }
            }
    }

    /// Continuous throttling forecast: 0.0 == cool, 1.0 == at the throttling
    /// threshold. Returns NaN when the API is unavailable (API < 30) or the OS
    /// has no reading yet, so the Dart side can fall back to thermal status.
    private fun readThermalHeadroom(): Double {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.R) return Double.NaN
        val powerManager = getSystemService(POWER_SERVICE) as PowerManager
        return try {
            powerManager.getThermalHeadroom(0).toDouble() // 0s forecast == now
        } catch (e: Exception) {
            Double.NaN
        }
    }

    /// Coarse 5-bucket thermal status (PowerManager.THERMAL_STATUS_*), or -1 when
    /// unavailable (API < 29).
    private fun readThermalStatus(): Int {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) return -1
        val powerManager = getSystemService(POWER_SERVICE) as PowerManager
        return powerManager.currentThermalStatus
    }
}
