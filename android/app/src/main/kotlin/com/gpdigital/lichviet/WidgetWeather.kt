package com.gpdigital.lichviet

import android.content.Context
import android.util.Log
import org.json.JSONObject
import java.net.HttpURLConnection
import java.net.URL

/** Current weather for the home-screen widget: fetched natively from Open-Meteo and cached in the widget prefs. */
object WidgetWeather {
    private const val PREFS = "LichVietWidget"
    private const val MAX_AGE_MS = 30 * 60 * 1000L

    data class Snapshot(val tempC: Int, val code: Int, val city: String, val fetchedAt: Long)

    fun cached(context: Context): Snapshot? {
        val p = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        if (!p.contains("weather_temp")) return null
        return Snapshot(
            p.getInt("weather_temp", 0), p.getInt("weather_code", -1),
            p.getString("weather_city", "") ?: "", p.getLong("weather_at", 0L)
        )
    }

    /** Fetches when the cache is missing/older than 30 min. Returns true if new data was stored. Blocking — call off the main thread. */
    fun refreshIfStale(context: Context): Boolean {
        val p = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        val lat = p.getString("weather_lat", null)?.toDoubleOrNull() ?: return false
        val lon = p.getString("weather_lon", null)?.toDoubleOrNull() ?: return false
        if (System.currentTimeMillis() - p.getLong("weather_at", 0L) < MAX_AGE_MS) return false
        return try {
            val conn = URL("https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon" +
                "&current=temperature_2m,weather_code&timezone=auto").openConnection() as HttpURLConnection
            conn.connectTimeout = 8000
            conn.readTimeout = 8000
            try {
                if (conn.responseCode != 200) return false
                val cur = JSONObject(conn.inputStream.bufferedReader().readText()).getJSONObject("current")
                p.edit()
                    .putInt("weather_temp", Math.round(cur.getDouble("temperature_2m")).toInt())
                    .putInt("weather_code", cur.getInt("weather_code"))
                    .putLong("weather_at", System.currentTimeMillis())
                    .apply()
                true
            } finally {
                conn.disconnect()
            }
        } catch (e: Exception) {
            Log.w("LichVietWidget", "weather fetch failed: ${e.message}")
            false
        }
    }

    /** WMO weather code → (emoji, Vietnamese description); same wording as the app's WeatherDescIcon. */
    fun describe(code: Int): Pair<String, String> = when (code) {
        0 -> "☀️" to "Trời quang"
        1 -> "🌤️" to "Ít mây"
        2 -> "⛅" to "Có mây"
        3 -> "☁️" to "Nhiều mây"
        45, 48 -> "🌫️" to "Sương mù"
        51, 53, 55 -> "🌦️" to "Mưa phùn"
        61, 63, 65, 66, 67 -> "🌧️" to "Mưa"
        80, 81, 82 -> "🌧️" to "Mưa rào"
        71, 73, 75, 77, 85, 86 -> "❄️" to "Tuyết"
        95, 96, 99 -> "⛈️" to "Dông"
        else -> "☁️" to "—"
    }
}
