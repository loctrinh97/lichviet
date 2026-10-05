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
                    if (args != null) saveWidgetData(args)
                    broadcastWidgetUpdate()
                    LichVietWidgetProvider.scheduleNextMidnight(this)
                    result.success(null)
                } else {
                    result.notImplemented()
                }
            }
    }

    private fun saveWidgetData(args: Map<*, *>) {
        val prefs = getSharedPreferences("LichVietWidget", Context.MODE_PRIVATE)
        prefs.edit().apply {
            putString("widget_theme",   args["widget_theme"]?.toString()   ?: "dark")
            putString("upcoming_label", args["upcoming_label"]?.toString() ?: "")
            putString("upcoming_date",  args["upcoming_date"]?.toString()  ?: "")
            putBoolean("show_weekday",    args["show_weekday"]    as? Boolean ?: true)
            putBoolean("show_lunar",      args["show_lunar"]      as? Boolean ?: true)
            putBoolean("show_auspicious", args["show_auspicious"] as? Boolean ?: true)
            putBoolean("show_events",     args["show_events"]     as? Boolean ?: true)
            putString("text_scale",     args["text_scale"]?.toString() ?: "medium")
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
