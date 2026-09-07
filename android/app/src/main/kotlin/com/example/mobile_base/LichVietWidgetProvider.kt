package com.example.mobile_base

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.SharedPreferences
import android.view.View
import android.widget.RemoteViews

class LichVietWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (id in appWidgetIds) {
            updateWidget(context, appWidgetManager, id)
        }
    }

    companion object {
        private const val PREFS = "FlutterSharedPreferences"

        fun updateWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            widgetId: Int
        ) {
            val prefs: SharedPreferences =
                context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

            // home_widget stores values as "flutter.<key>"
            val solarDay   = prefs.getString("flutter.solar_day",     "--") ?: "--"
            val weekday    = prefs.getString("flutter.solar_weekday", "---") ?: "---"
            val lunarDay   = prefs.getString("flutter.lunar_day",     "--") ?: "--"
            val lunarMonth = prefs.getString("flutter.lunar_month",   "--") ?: "--"
            val canChiDay  = prefs.getString("flutter.can_chi_day",   "") ?: ""
            val isAusp     = prefs.getString("flutter.is_auspicious", "0") == "1"
            val holiday    = prefs.getString("flutter.holiday",       "") ?: ""

            val views = RemoteViews(context.packageName, R.layout.lich_viet_widget)

            views.setTextViewText(R.id.widget_weekday,   weekday.uppercase())
            views.setTextViewText(R.id.widget_solar_day, solarDay)
            views.setTextViewText(R.id.widget_lunar,
                "Âm $lunarDay/$lunarMonth · $canChiDay")
            views.setTextViewText(R.id.widget_auspicious,
                if (isAusp) "Hoàng đạo" else "Hắc đạo")
            views.setTextColor(R.id.widget_auspicious,
                if (isAusp) 0xFF9184D9.toInt() else 0xFF796CBF.toInt())

            if (holiday.isNotBlank()) {
                views.setTextViewText(R.id.widget_holiday, holiday)
                views.setViewVisibility(R.id.widget_holiday, View.VISIBLE)
            } else {
                views.setViewVisibility(R.id.widget_holiday, View.GONE)
            }

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
