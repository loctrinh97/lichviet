import 'dart:io';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../model/event_model.dart';
import 'lunar_calendar.dart';

const _androidWidgetClass = 'com.gpdigital.lichviet.LichVietWidgetProvider';

class WidgetService {
  static const _channel = MethodChannel('com.gpdigital.lichviet/widget');

  static Future<void> updateWidget({List<EventModel> events = const []}) async {
    final now   = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final prefs = await SharedPreferences.getInstance();
    final storedTheme = prefs.getString('app_theme') ?? 'dark';

    final upcoming = _findUpcoming(today, events);

    if (Platform.isAndroid) {
      try {
        await _channel.invokeMethod('updateWidget', {
          'providerClass':  _androidWidgetClass,
          'widget_theme':   storedTheme,
          'upcoming_label': upcoming?.label ?? '',
          // "yyyy-M-d" — widget recomputes countdown from system clock each day
          'upcoming_date':  upcoming != null ? EventModel.dateKey(upcoming.date) : '',
        });
      } catch (_) {}
    }
  }

  static ({String label, DateTime date})? _findUpcoming(
      DateTime today, List<EventModel> events) {
    for (int i = 0; i < 30; i++) {
      final d  = today.add(Duration(days: i));
      final al = LunarCalendar.solar2lunar(d.day, d.month, d.year);

      final key = EventModel.dateKey(d);
      final ev  = events.where((e) => !e.deleted && e.date == key).firstOrNull;
      if (ev != null) return (label: ev.title, date: d);

      final holidays = LunarCalendar.holidays(d, al);
      if (holidays.isNotEmpty) return (label: holidays.first.name, date: d);

      if (al.day == 1)  return (label: 'Mùng 1 âm lịch', date: d);
      if (al.day == 15) return (label: 'Ngày Rằm', date: d);
    }
    return null;
  }

  static String _weekday(int wd) {
    const days = [
      'Thứ Hai', 'Thứ Ba', 'Thứ Tư',
      'Thứ Năm', 'Thứ Sáu', 'Thứ Bảy', 'Chủ Nhật',
    ];
    return days[(wd - 1).clamp(0, 6)];
  }
}
