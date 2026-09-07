import 'dart:io';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'lunar_calendar.dart';

// Android widget provider class name
const _androidWidgetClass =
    'com.gpdigital.lichviet.LichVietWidgetProvider';

class WidgetService {
  static const _channel =
      MethodChannel('com.gpdigital.lichviet/widget');

  static Future<void> updateWidget() async {
    final now = DateTime.now();
    final al = LunarCalendar.solar2lunar(now.day, now.month, now.year);
    final cc = LunarCalendar.canChi(al);
    final tot = LunarCalendar.ngayTot(al.month, cc.chiDay);
    final le = LunarCalendar.holidays(now, al);

    // Write data to FlutterSharedPreferences — same store the
    // Android AppWidgetProvider reads via "flutter.<key>" prefix.
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('solar_day',     '${now.day}');
    await prefs.setString('solar_weekday', _weekday(now.weekday));
    await prefs.setString('lunar_day',     '${al.day}');
    await prefs.setString('lunar_month',   '${al.month}');
    await prefs.setString('can_chi_day',   cc.day);
    await prefs.setString('can_chi_year',  cc.year);
    await prefs.setString('is_auspicious', tot ? '1' : '0');
    await prefs.setString('holiday',       le.isNotEmpty ? le.first.name : '');

    // Broadcast the APPWIDGET_UPDATE intent so Android refreshes the widget.
    if (Platform.isAndroid) {
      try {
        await _channel.invokeMethod('updateWidget',
            {'providerClass': _androidWidgetClass});
      } catch (_) {
        // Widget not installed or device doesn't support widgets — ignore.
      }
    }
  }

  static String _weekday(int wd) {
    const days = ['Thứ Hai', 'Thứ Ba', 'Thứ Tư', 'Thứ Năm', 'Thứ Sáu', 'Thứ Bảy', 'Chủ Nhật'];
    return days[(wd - 1).clamp(0, 6)];
  }
}
