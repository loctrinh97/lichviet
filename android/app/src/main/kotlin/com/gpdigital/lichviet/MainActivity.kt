package com.gpdigital.lichviet

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channel = "com.gpdigital.lichviet/widget"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channel)
            .setMethodCallHandler { call, result ->
                if (call.method == "updateWidget") {
                    val args = call.arguments as? Map<*, *>
                    Log.d("LichVietWidget", "updateWidget called, args=$args")
                    if (args != null) {
                        saveWidgetData(args)
                    }
                    broadcastWidgetUpdate()
                    result.success(null)
                } else {
                    result.notImplemented()
                }
            }
    }

    private fun saveWidgetData(args: Map<*, *>) {
        val prefs = getSharedPreferences("LichVietWidget", Context.MODE_PRIVATE)
        prefs.edit().apply {
            putString("solar_day",     args["solar_day"]?.toString()     ?: "")
            putString("solar_weekday", args["solar_weekday"]?.toString() ?: "")
            putString("lunar_day",     args["lunar_day"]?.toString()     ?: "")
            putString("lunar_month",   args["lunar_month"]?.toString()   ?: "")
            putString("can_chi_day",   args["can_chi_day"]?.toString()   ?: "")
            putString("is_auspicious", args["is_auspicious"]?.toString() ?: "0")
            putString("holiday",       args["holiday"]?.toString()       ?: "")
            putString("widget_theme",    args["widget_theme"]?.toString()    ?: "dark")
            putString("upcoming",  args["upcoming"]?.toString()  ?: "")
            apply()
        }
    }

    private fun broadcastWidgetUpdate() {
        val manager = AppWidgetManager.getInstance(this)
        val ids = manager.getAppWidgetIds(ComponentName(this, LichVietWidgetProvider::class.java))
        Log.d("LichVietWidget", "broadcastWidgetUpdate: ids=${ids.toList()}")
        if (ids.isEmpty()) {
            Log.d("LichVietWidget", "No widgets placed on home screen")
            return
        }
        val intent = Intent(this, LichVietWidgetProvider::class.java).apply {
            action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
            putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, ids)
        }
        sendBroadcast(intent)
    }
}
