package com.gpdigital.lichviet

import android.app.AlarmManager
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.Calendar

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
                    scheduleMidnightRefresh()
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

    // Schedule a daily alarm at 00:01 so widget refreshes date/countdown without opening app.
    private fun scheduleMidnightRefresh() {
        val alarmManager = getSystemService(ALARM_SERVICE) as AlarmManager
        val intent = Intent(this, LichVietWidgetProvider::class.java).apply {
            action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
        }
        val pending = PendingIntent.getBroadcast(
            this, 0, intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        val nextMidnight = Calendar.getInstance().apply {
            add(Calendar.DAY_OF_YEAR, 1)
            set(Calendar.HOUR_OF_DAY, 0)
            set(Calendar.MINUTE, 1)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
        }
        alarmManager.setRepeating(
            AlarmManager.RTC,
            nextMidnight.timeInMillis,
            AlarmManager.INTERVAL_DAY,
            pending
        )
    }
}
