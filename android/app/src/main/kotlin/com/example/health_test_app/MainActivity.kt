package com.example.copd_ai_health_app

import android.content.Intent
import android.content.IntentFilter
import android.os.BatteryManager
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
                    "getBatteryTemperature" -> result.success(readBatteryTemperature())
                    else -> result.notImplemented()
                }
            }
    }

    /// Battery temperature in °C, read from the sticky battery broadcast. A good,
    /// always-available proxy for device thermal state. Returns NaN if absent.
    private fun readBatteryTemperature(): Double {
        val batteryStatus = registerReceiver(
            null,
            IntentFilter(Intent.ACTION_BATTERY_CHANGED),
        )
        val tenthsCelsius =
            batteryStatus?.getIntExtra(BatteryManager.EXTRA_TEMPERATURE, Int.MIN_VALUE)
                ?: Int.MIN_VALUE
        return if (tenthsCelsius == Int.MIN_VALUE) Double.NaN else tenthsCelsius / 10.0
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
