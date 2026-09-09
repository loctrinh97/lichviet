package com.gpdigital.lichviet

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.util.Log
import android.view.View
import android.widget.RemoteViews
import java.util.Calendar

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
        private const val PREFS = "LichVietWidget"

        fun updateWidget(context: Context, appWidgetManager: AppWidgetManager, widgetId: Int) {
            Log.d("LichVietWidget", "updateWidget called for id=$widgetId")
            val cal = Calendar.getInstance()
            val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            Log.d("LichVietWidget", "prefs keys=${prefs.all.keys}")

            fun get(key: String, fallback: String) = prefs.getString(key, fallback) ?: fallback

            val solarDay   = get("solar_day",     "${cal.get(Calendar.DAY_OF_MONTH)}")
            val weekday    = get("solar_weekday", systemWeekday(cal))
            val lunarDay   = get("lunar_day",     "--")
            val lunarMonth = get("lunar_month",   "--")
            val canChiDay  = get("can_chi_day",   "")
            val isAusp    = get("is_auspicious", "0") == "1"
            val holiday   = get("holiday",       "")
            val upcoming  = get("upcoming",      "")
            val isLight   = get("widget_theme",  "dark") == "light"

            val layout = if (isLight) R.layout.lich_viet_widget_light else R.layout.lich_viet_widget
            val views = RemoteViews(context.packageName, layout)

            val colorWeekday  = if (isLight) 0xFF75798C.toInt() else 0xFF9397AB.toInt()
            val colorSolarDay = if (isLight) 0xFF1C1D26.toInt() else 0xFFE9E9ED.toInt()
            val colorAccent   = if (isLight) 0xFF5D5294.toInt() else 0xFF9184D9.toInt()
            val colorHoliday  = if (isLight) 0xFF796CBF.toInt() else 0xFFB5ABFC.toInt()
            val colorAuspYes  = if (isLight) 0xFF5D5294.toInt() else 0xFF9184D9.toInt()
            val colorAuspNo   = 0xFF796CBF.toInt()

            views.setTextViewText(R.id.widget_weekday,   weekday.uppercase())
            views.setTextColor(R.id.widget_weekday,      colorWeekday)

            views.setTextViewText(R.id.widget_solar_day, solarDay)
            views.setTextColor(R.id.widget_solar_day,    colorSolarDay)

            val lunarText = if (lunarDay == "--") "Âm --/--"
                            else "Âm $lunarDay/$lunarMonth" + if (canChiDay.isNotBlank()) " · $canChiDay" else ""
            views.setTextViewText(R.id.widget_lunar,     lunarText)
            views.setTextColor(R.id.widget_lunar,        colorAccent)

            views.setTextViewText(R.id.widget_auspicious, if (isAusp) "Hoàng đạo" else "Hắc đạo")
            views.setTextColor(R.id.widget_auspicious,    if (isAusp) colorAuspYes else colorAuspNo)

            if (holiday.isNotBlank()) {
                views.setTextViewText(R.id.widget_holiday, holiday)
                views.setTextColor(R.id.widget_holiday,    colorHoliday)
                views.setViewVisibility(R.id.widget_holiday, View.VISIBLE)
            } else {
                views.setViewVisibility(R.id.widget_holiday, View.GONE)
            }

            if (upcoming.isNotBlank()) {
                views.setTextViewText(R.id.widget_upcoming_event, upcoming)
                views.setViewVisibility(R.id.widget_upcoming_event, View.VISIBLE)
            } else {
                views.setViewVisibility(R.id.widget_upcoming_event, View.GONE)
            }

            Log.d("LichVietWidget", "Applying: solarDay=$solarDay weekday=$weekday lunar=$lunarText isLight=$isLight")
            try {
                appWidgetManager.updateAppWidget(widgetId, views)
                Log.d("LichVietWidget", "updateAppWidget SUCCESS for id=$widgetId")
            } catch (e: Exception) {
                Log.e("LichVietWidget", "updateAppWidget FAILED: ${e.message}", e)
            }
        }

        private fun systemWeekday(cal: Calendar): String {
            val days = arrayOf("Chủ Nhật", "Thứ Hai", "Thứ Ba", "Thứ Tư", "Thứ Năm", "Thứ Sáu", "Thứ Bảy")
            return days[cal.get(Calendar.DAY_OF_WEEK) - 1]
        }
    }
}
