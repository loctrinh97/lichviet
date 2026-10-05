package com.gpdigital.lichviet

import android.app.AlarmManager
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.app.PendingIntent
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.util.Log
import android.view.View
import android.widget.RemoteViews
import java.util.Calendar
import java.util.concurrent.TimeUnit

class LichVietWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (id in appWidgetIds) {
            updateWidget(context, appWidgetManager, id)
        }
        scheduleNextMidnight(context)
    }

    override fun onEnabled(context: Context) {
        scheduleNextMidnight(context)
    }

    override fun onDisabled(context: Context) {
        val am = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        am.cancel(refreshPendingIntent(context))
    }

    // The midnight alarm, reboot and clock/timezone changes all arrive here with no widget ids,
    // which AppWidgetProvider.onReceive ignores — so refresh every placed widget ourselves.
    override fun onReceive(context: Context, intent: Intent) {
        when (intent.action) {
            ACTION_REFRESH,
            Intent.ACTION_BOOT_COMPLETED,
            Intent.ACTION_MY_PACKAGE_REPLACED,
            Intent.ACTION_DATE_CHANGED,
            Intent.ACTION_TIME_CHANGED,
            Intent.ACTION_TIMEZONE_CHANGED -> {
                val manager = AppWidgetManager.getInstance(context)
                val ids = manager.getAppWidgetIds(ComponentName(context, LichVietWidgetProvider::class.java))
                if (ids.isNotEmpty()) onUpdate(context, manager, ids)
            }
            else -> super.onReceive(context, intent)
        }
    }

    companion object {
        private const val PREFS = "LichVietWidget"
        private const val ACTION_REFRESH = "com.gpdigital.lichviet.WIDGET_REFRESH"

        private fun refreshPendingIntent(context: Context): PendingIntent =
            PendingIntent.getBroadcast(
                context, 0,
                Intent(context, LichVietWidgetProvider::class.java).setAction(ACTION_REFRESH),
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )

        /** Arms a one-shot alarm for the next 00:01; every refresh re-arms it. */
        fun scheduleNextMidnight(context: Context) {
            val am = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            val next = Calendar.getInstance().apply {
                add(Calendar.DAY_OF_YEAR, 1)
                set(Calendar.HOUR_OF_DAY, 0); set(Calendar.MINUTE, 1)
                set(Calendar.SECOND, 0);      set(Calendar.MILLISECOND, 0)
            }.timeInMillis
            val pending = refreshPendingIntent(context)
            try {
                if (android.os.Build.VERSION.SDK_INT < android.os.Build.VERSION_CODES.S || am.canScheduleExactAlarms()) {
                    am.setExactAndAllowWhileIdle(AlarmManager.RTC, next, pending)
                } else {
                    am.setAndAllowWhileIdle(AlarmManager.RTC, next, pending)
                }
            } catch (e: SecurityException) {
                am.setAndAllowWhileIdle(AlarmManager.RTC, next, pending)
            }
        }

        /** Next holiday / mùng 1 / rằm within 30 days from [from] (user events live only in the app). */
        private fun findUpcoming(from: Calendar): Pair<String, Calendar>? {
            for (i in 0 until 30) {
                val d = (from.clone() as Calendar).apply { add(Calendar.DAY_OF_YEAR, i) }
                val dd = d.get(Calendar.DAY_OF_MONTH)
                val mm = d.get(Calendar.MONTH) + 1
                val al = LunarCalendar.solar2lunar(dd, mm, d.get(Calendar.YEAR))
                LunarCalendar.holiday(dd, mm, al.day, al.month, al.isLeap)?.let { return it to d }
                if (al.day == 1) return "Mùng 1 âm lịch" to d
                if (al.day == 15) return "Ngày Rằm" to d
            }
            return null
        }

        fun updateWidget(context: Context, appWidgetManager: AppWidgetManager, widgetId: Int) {
            Log.d("LichVietWidget", "updateWidget called for id=$widgetId")
            val cal   = Calendar.getInstance()
            val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

            fun get(key: String, fallback: String) = prefs.getString(key, fallback) ?: fallback

            // Always compute from system clock — stays correct after midnight without opening app
            val dd = cal.get(Calendar.DAY_OF_MONTH)
            val mm = cal.get(Calendar.MONTH) + 1
            val yy = cal.get(Calendar.YEAR)
            val lunar     = LunarCalendar.solar2lunar(dd, mm, yy)
            val solarDay  = "$dd"
            val weekday   = systemWeekday(cal)
            val lunarDay  = "${lunar.day}"
            val lunarMonth= "${lunar.month}"
            val canChiDay = LunarCalendar.canChiDay(lunar.jd)
            val chiNgay   = LunarCalendar.chiDay(lunar.jd)
            val isAusp    = LunarCalendar.ngayTot(lunar.month, chiNgay)
            val holiday   = LunarCalendar.holiday(dd, mm, lunar.day, lunar.month, lunar.isLeap) ?: ""
            val isLight    = get("widget_theme",  "dark") == "light"

            // Recompute countdown from stored upcoming_date using today's system date
            var upcomingLabel = get("upcoming_label", "")
            var upcomingDate  = get("upcoming_date",  "")

            // Stored event already passed (app not opened for days) → recompute natively.
            val storedParts = upcomingDate.split("-").mapNotNull { it.toIntOrNull() }
            val stale = storedParts.size != 3 || Calendar.getInstance().apply {
                set(storedParts[0], storedParts[1] - 1, storedParts[2], 23, 59, 59)
            }.before(cal)
            if (stale) {
                findUpcoming(cal)?.let { (label, d) ->
                    upcomingLabel = label
                    upcomingDate  = "${d.get(Calendar.YEAR)}-${d.get(Calendar.MONTH) + 1}-${d.get(Calendar.DAY_OF_MONTH)}"
                }
            }
            val upcomingText  = if (upcomingLabel.isNotBlank() && upcomingDate.isNotBlank()) {
                val parts = upcomingDate.split("-").mapNotNull { it.toIntOrNull() }
                if (parts.size == 3) {
                    val target = Calendar.getInstance().apply {
                        set(parts[0], parts[1] - 1, parts[2], 0, 0, 0)
                        set(Calendar.MILLISECOND, 0)
                    }
                    val today = Calendar.getInstance().apply {
                        set(Calendar.HOUR_OF_DAY, 0); set(Calendar.MINUTE, 0)
                        set(Calendar.SECOND, 0);      set(Calendar.MILLISECOND, 0)
                    }
                    val diffMs   = target.timeInMillis - today.timeInMillis
                    val diffDays = TimeUnit.MILLISECONDS.toDays(diffMs).toInt()
                    val countdown = when {
                        diffDays <= 0 -> "Hôm nay"
                        diffDays == 1 -> "Ngày mai"
                        else          -> "$diffDays ngày nữa"
                    }
                    "$upcomingLabel · $countdown"
                } else upcomingLabel
            } else upcomingLabel

            val layout = if (isLight) R.layout.lich_viet_widget_light else R.layout.lich_viet_widget
            val views  = RemoteViews(context.packageName, layout)

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

            if (upcomingText.isNotBlank()) {
                views.setTextViewText(R.id.widget_upcoming_event, upcomingText)
                views.setViewVisibility(R.id.widget_upcoming_event, View.VISIBLE)
            } else {
                views.setViewVisibility(R.id.widget_upcoming_event, View.GONE)
            }

            applyUserConfig(views, prefs)

            val launchIntent = context.packageManager.getLaunchIntentForPackage(context.packageName)?.apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_RESET_TASK_IF_NEEDED)
            }
            if (launchIntent != null) {
                val pending = PendingIntent.getActivity(
                    context, 0, launchIntent,
                    PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
                )
                views.setOnClickPendingIntent(R.id.widget_root, pending)
            }

            Log.d("LichVietWidget", "Applying: solarDay=$solarDay weekday=$weekday upcoming=$upcomingText")
            try {
                appWidgetManager.updateAppWidget(widgetId, views)
                Log.d("LichVietWidget", "updateAppWidget SUCCESS for id=$widgetId")
            } catch (e: Exception) {
                Log.e("LichVietWidget", "updateAppWidget FAILED: ${e.message}", e)
            }
        }

        /** User customisation from the app's widget settings screen: hidden rows and text size. */
        private fun applyUserConfig(views: RemoteViews, prefs: android.content.SharedPreferences) {
            fun show(key: String) = prefs.getBoolean(key, true)
            if (!show("show_weekday"))    views.setViewVisibility(R.id.widget_weekday, View.GONE)
            if (!show("show_lunar"))      views.setViewVisibility(R.id.widget_lunar, View.GONE)
            if (!show("show_auspicious")) views.setViewVisibility(R.id.widget_auspicious, View.GONE)
            if (!show("show_events")) {
                views.setViewVisibility(R.id.widget_holiday, View.GONE)
                views.setViewVisibility(R.id.widget_upcoming_event, View.GONE)
            }

            val k = when (prefs.getString("text_scale", "medium")) {
                "small" -> 0.85f
                "large" -> 1.25f
                else    -> 1f
            }
            val sizes = mapOf(
                R.id.widget_weekday to 11f, R.id.widget_solar_day to 28f, R.id.widget_lunar to 11f,
                R.id.widget_auspicious to 11f, R.id.widget_holiday to 10f, R.id.widget_upcoming_event to 10f,
            )
            for ((id, base) in sizes) views.setTextViewTextSize(id, android.util.TypedValue.COMPLEX_UNIT_SP, base * k)
        }

        private fun systemWeekday(cal: Calendar): String {
            val days = arrayOf("Chủ Nhật", "Thứ Hai", "Thứ Ba", "Thứ Tư", "Thứ Năm", "Thứ Sáu", "Thứ Bảy")
            return days[cal.get(Calendar.DAY_OF_WEEK) - 1]
        }
    }
}
