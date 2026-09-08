package com.gpdigital.lichviet

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

            val solarDay   = prefs.getString("flutter.solar_day",     "--") ?: "--"
            val weekday    = prefs.getString("flutter.solar_weekday", "---") ?: "---"
            val lunarDay   = prefs.getString("flutter.lunar_day",     "--") ?: "--"
            val lunarMonth = prefs.getString("flutter.lunar_month",   "--") ?: "--"
            val canChiDay  = prefs.getString("flutter.can_chi_day",   "") ?: ""
            val isAusp     = prefs.getString("flutter.is_auspicious", "0") == "1"
            val holiday    = prefs.getString("flutter.holiday",       "") ?: ""
            val theme      = prefs.getString("flutter.widget_theme",  "dark") ?: "dark"
            val isLight    = theme == "light"

            val views = RemoteViews(context.packageName, R.layout.lich_viet_widget)

            // Background
            views.setInt(
                R.id.widget_root, "setBackgroundResource",
                if (isLight) R.drawable.widget_background_light else R.drawable.widget_background
            )

            // Colors
            val colorWeekday  = if (isLight) 0xFF75798C.toInt() else 0xFF9397AB.toInt()
            val colorSolarDay = if (isLight) 0xFF1C1D26.toInt() else 0xFFE9E9ED.toInt()
            val colorAccent   = if (isLight) 0xFF5D5294.toInt() else 0xFF9184D9.toInt()
            val colorHoliday  = if (isLight) 0xFF796CBF.toInt() else 0xFFB5ABFC.toInt()
            val colorAuspYes  = if (isLight) 0xFF5D5294.toInt() else 0xFF9184D9.toInt()
            val colorAuspNo   = if (isLight) 0xFF796CBF.toInt() else 0xFF796CBF.toInt()

            views.setTextViewText(R.id.widget_weekday,   weekday.uppercase())
            views.setTextColor(R.id.widget_weekday,   colorWeekday)

            views.setTextViewText(R.id.widget_solar_day, solarDay)
            views.setTextColor(R.id.widget_solar_day, colorSolarDay)

            views.setTextViewText(R.id.widget_lunar, "Âm $lunarDay/$lunarMonth · $canChiDay")
            views.setTextColor(R.id.widget_lunar, colorAccent)

            views.setTextViewText(R.id.widget_auspicious, if (isAusp) "Hoàng đạo" else "Hắc đạo")
            views.setTextColor(R.id.widget_auspicious, if (isAusp) colorAuspYes else colorAuspNo)

            if (holiday.isNotBlank()) {
                views.setTextViewText(R.id.widget_holiday, holiday)
                views.setTextColor(R.id.widget_holiday, colorHoliday)
                views.setViewVisibility(R.id.widget_holiday, View.VISIBLE)
            } else {
                views.setViewVisibility(R.id.widget_holiday, View.GONE)
            }

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
