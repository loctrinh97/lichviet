import 'dart:io';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../model/event_model.dart';
import 'lunar_calendar.dart';

const _androidWidgetClass = 'com.gpdigital.lichviet.LichVietWidgetProvider';

class WidgetService {
  static const _channel = MethodChannel('com.gpdigital.lichviet/widget');

  static Future<void> updateWidget({List<EventModel> events = const []}) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final al  = LunarCalendar.solar2lunar(now.day, now.month, now.year);
    final cc  = LunarCalendar.canChi(al);
    final tot = LunarCalendar.ngayTot(al.month, cc.chiDay);
    final le  = LunarCalendar.holidays(now, al);

    final prefs = await SharedPreferences.getInstance();
    final storedTheme = prefs.getString('app_theme') ?? 'dark';

    // Find nearest upcoming item in next 30 days: holiday > mùng1/rằm > user event
    final upcomingLabel = _findUpcoming(today, events);

    if (Platform.isAndroid) {
      try {
        await _channel.invokeMethod('updateWidget', {
          'providerClass':  _androidWidgetClass,
          'solar_day':      '${now.day}',
          'solar_weekday':  _weekday(now.weekday),
          'lunar_day':      '${al.day}',
          'lunar_month':    '${al.month}',
          'can_chi_day':    cc.day,
          'is_auspicious':  tot ? '1' : '0',
          'holiday':        le.isNotEmpty ? le.first.name : '',
          'widget_theme':   storedTheme,
          'upcoming':       upcomingLabel,
        });
      } catch (_) {}
    }
  }

  /// Returns "Label · X ngày nữa" for nearest upcoming item within 30 days, or empty string.
  static String _findUpcoming(DateTime today, List<EventModel> events) {
    for (int i = 0; i < 30; i++) {
      final d  = today.add(Duration(days: i));
      final al = LunarCalendar.solar2lunar(d.day, d.month, d.year);
      final countdown = i == 0 ? 'Hôm nay' : i == 1 ? 'Ngày mai' : '$i ngày nữa';

      final key = EventModel.dateKey(d);
      final ev = events.where((e) => !e.deleted && e.date == key).firstOrNull;
      if (ev != null) return '${ev.title} · $countdown';

      final holidays = LunarCalendar.holidays(d, al);
      if (holidays.isNotEmpty) return '${holidays.first.name} · $countdown';

      if (al.day == 1) return 'Mùng 1 âm lịch · $countdown';
      if (al.day == 15) return 'Ngày Rằm · $countdown';
    }
    return '';
  }

  static String _weekday(int wd) {
    const days = [
      'Thứ Hai', 'Thứ Ba', 'Thứ Tư',
      'Thứ Năm', 'Thứ Sáu', 'Thứ Bảy', 'Chủ Nhật',
    ];
    return days[(wd - 1).clamp(0, 6)];
  }
}
