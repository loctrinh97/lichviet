package com.gpdigital.lichviet

import kotlin.math.PI
import kotlin.math.floor
import kotlin.math.sin

/** Kotlin port of lib/features/calendar/services/lunar_calendar.dart (used by the home-screen widget). */
data class LunarDate(val day: Int, val month: Int, val year: Int, val isLeap: Boolean, val jd: Int)

object LunarCalendar {
    private const val TZ = 7
    private val can = arrayOf("Giáp", "Ất", "Bính", "Đinh", "Mậu", "Kỷ", "Canh", "Tân", "Nhâm", "Quý")
    private val chi = arrayOf("Tý", "Sửu", "Dần", "Mão", "Thìn", "Tỵ", "Ngọ", "Mùi", "Thân", "Dậu", "Tuất", "Hợi")

    private val ngayHD: Map<Int, List<String>> = mapOf(
        1 to listOf("Tý", "Sửu", "Thìn", "Tỵ", "Mùi", "Tuất"),
        7 to listOf("Tý", "Sửu", "Thìn", "Tỵ", "Mùi", "Tuất"),
        2 to listOf("Dần", "Mão", "Ngọ", "Mùi", "Dậu", "Tý"),
        8 to listOf("Dần", "Mão", "Ngọ", "Mùi", "Dậu", "Tý"),
        3 to listOf("Thìn", "Tỵ", "Thân", "Dậu", "Hợi", "Dần"),
        9 to listOf("Thìn", "Tỵ", "Thân", "Dậu", "Hợi", "Dần"),
        4 to listOf("Ngọ", "Mùi", "Tuất", "Hợi", "Sửu", "Thìn"),
        10 to listOf("Ngọ", "Mùi", "Tuất", "Hợi", "Sửu", "Thìn"),
        5 to listOf("Thân", "Dậu", "Tý", "Sửu", "Mão", "Ngọ"),
        11 to listOf("Thân", "Dậu", "Tý", "Sửu", "Mão", "Ngọ"),
        6 to listOf("Tuất", "Hợi", "Dần", "Mão", "Tỵ", "Thân"),
        12 to listOf("Tuất", "Hợi", "Dần", "Mão", "Tỵ", "Thân"),
    )

    private val leDuong = mapOf(
        "1-1" to "Tết Dương lịch", "2-14" to "Valentine", "3-8" to "Quốc tế Phụ nữ",
        "4-30" to "Giải phóng miền Nam", "5-1" to "Quốc tế Lao động", "6-1" to "Quốc tế Thiếu nhi",
        "9-2" to "Quốc khánh", "10-20" to "Phụ nữ Việt Nam", "11-20" to "Nhà giáo Việt Nam",
        "11-24" to "Ngày Văn hóa Việt Nam",
        "12-24" to "Giáng sinh", "12-25" to "Giáng sinh",
    )

    private val leAm = mapOf(
        "1-1" to "Tết Nguyên Đán", "1-2" to "Mùng 2 Tết", "1-3" to "Mùng 3 Tết",
        "1-15" to "Tết Nguyên Tiêu", "3-3" to "Tết Hàn thực", "3-10" to "Giỗ tổ Hùng Vương",
        "5-5" to "Tết Đoan Ngọ", "7-15" to "Lễ Vu Lan", "8-15" to "Tết Trung Thu",
        "9-9" to "Tết Trùng Cửu", "12-23" to "Ông Công Ông Táo",
    )

    private fun jdFromDate(dd: Int, mm: Int, yy: Int): Int {
        val a = (14 - mm) / 12
        val y = yy + 4800 - a
        val m = mm + 12 * a - 3
        var jd = dd + (153 * m + 2) / 5 + 365 * y + y / 4 - y / 100 + y / 400 - 32045
        if (jd < 2299161) {
            jd = dd + (153 * m + 2) / 5 + 365 * y + y / 4 - 32083
        }
        return jd
    }

    private fun newMoon(k: Int): Double {
        val t = k / 1236.85
        val t2 = t * t
        val t3 = t2 * t
        val dr = PI / 180
        var jd1 = 2415020.75933 + 29.53058868 * k + 0.0001178 * t2 - 0.000000155 * t3
        jd1 += 0.00033 * sin((166.56 + 132.87 * t - 0.009173 * t2) * dr)
        val m = 359.2242 + 29.10535608 * k - 0.0000333 * t2 - 0.00000347 * t3
        val mpr = 306.0253 + 385.81691806 * k + 0.0107306 * t2 + 0.00001236 * t3
        val f = 21.2964 + 390.67050646 * k - 0.0016528 * t2 - 0.00000239 * t3
        var c1 = (0.1734 - 0.000393 * t) * sin(m * dr) + 0.0021 * sin(2 * dr * m)
        c1 = c1 - 0.4068 * sin(mpr * dr) + 0.0161 * sin(dr * 2 * mpr)
        c1 -= 0.0004 * sin(dr * 3 * mpr)
        c1 += 0.0104 * sin(dr * 2 * f) - 0.0051 * sin(dr * (m + mpr))
        c1 = c1 - 0.0074 * sin(dr * (m - mpr)) + 0.0004 * sin(dr * (2 * f + m))
        c1 -= 0.0004 * sin(dr * (2 * f - m)) + 0.0006 * sin(dr * (2 * f + mpr))
        c1 += 0.001 * sin(dr * (2 * f - mpr)) + 0.0005 * sin(dr * (2 * mpr + m))
        val deltat = if (t < -11) {
            0.001 + 0.000839 * t + 0.0002261 * t2 - 0.00000845 * t3 - 0.000000081 * t * t3
        } else {
            -0.000278 + 0.000265 * t + 0.000262 * t2
        }
        return jd1 + c1 - deltat
    }

    private fun sunLongitude(jdn: Double): Int {
        val t = (jdn - 2451545.5 - TZ / 24.0) / 36525
        val t2 = t * t
        val dr = PI / 180
        val m = 357.5291 + 35999.0503 * t - 0.0001559 * t2 - 0.00000048 * t * t2
        val l0 = 280.46645 + 36000.76983 * t + 0.0003032 * t2
        var dl = (1.9146 - 0.004817 * t - 0.000014 * t2) * sin(dr * m)
        dl += (0.019993 - 0.000101 * t) * sin(dr * 2 * m) + 0.00029 * sin(dr * 3 * m)
        var l = (l0 + dl) % 360
        if (l < 0) l += 360
        return floor(l / 30).toInt()
    }

    private fun getNewMoonDay(k: Int): Int = floor(newMoon(k) + 0.5 + TZ / 24.0).toInt()

    private fun lunarMonth11(yy: Int): Int {
        val off = jdFromDate(31, 12, yy) - 2415021
        val k = floor(off / 29.530588853).toInt()
        var nm = getNewMoonDay(k)
        if (sunLongitude(nm.toDouble()) >= 9) nm = getNewMoonDay(k - 1)
        return nm
    }

    private fun leapMonthOffset(a11: Int): Int {
        val k = floor((a11 - 2415021.076998695) / 29.530588853 + 0.5).toInt()
        var last: Int
        var i = 1
        var arc = sunLongitude(getNewMoonDay(k + i).toDouble())
        do {
            last = arc
            i++
            arc = sunLongitude(getNewMoonDay(k + i).toDouble())
        } while (arc != last && i < 14)
        return i - 1
    }

    fun solar2lunar(dd: Int, mm: Int, yy: Int): LunarDate {
        val dayNumber = jdFromDate(dd, mm, yy)
        val k = floor((dayNumber - 2415021.076998695) / 29.530588853).toInt()
        var monthStart = getNewMoonDay(k + 1)
        if (monthStart > dayNumber) monthStart = getNewMoonDay(k)
        var a11 = lunarMonth11(yy)
        var b11 = a11
        var lunarYear: Int
        if (a11 >= monthStart) {
            lunarYear = yy
            a11 = lunarMonth11(yy - 1)
        } else {
            lunarYear = yy + 1
            b11 = lunarMonth11(yy + 1)
        }
        val lunarDay = dayNumber - monthStart + 1
        val diff = (monthStart - a11) / 29
        var lunarLeap = 0
        var lunarMonth = diff + 11
        if (b11 - a11 > 365) {
            val lo = leapMonthOffset(a11)
            if (diff >= lo) {
                lunarMonth = diff + 10
                if (diff == lo) lunarLeap = 1
            }
        }
        if (lunarMonth > 12) lunarMonth -= 12
        if (lunarMonth >= 11 && diff < 4) lunarYear -= 1
        return LunarDate(lunarDay, lunarMonth, lunarYear, lunarLeap == 1, dayNumber)
    }

    fun canChiDay(jd: Int): String = "${can[(jd + 9) % 10]} ${chi[(jd + 1) % 12]}"

    fun chiDay(jd: Int): String = chi[(jd + 1) % 12]

    fun ngayTot(lunarMonth: Int, chiNgay: String): Boolean = ngayHD[lunarMonth]?.contains(chiNgay) == true

    /** First holiday of the day (solar before lunar), matching widget_service.dart. */
    fun holiday(dd: Int, mm: Int, lunarDay: Int, lunarMonth: Int, isLeap: Boolean): String? =
        leDuong["$mm-$dd"] ?: if (!isLeap) leAm["$lunarMonth-$lunarDay"] else null
}
