import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import '../model/event_model.dart';
import 'lunar_calendar.dart';

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static const _channel = AndroidNotificationChannel(
    'lichviet_daily',
    'Nhắc nhở Lịch Việt',
    description: 'Thông báo sự kiện, ngày lễ và âm lịch',
    importance: Importance.defaultImportance,
  );

  static Future<void> init() async {
    if (_initialized) return;
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Ho_Chi_Minh'));

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );

    final androidImpl = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidImpl?.createNotificationChannel(_channel);
    await androidImpl?.requestNotificationsPermission();
    _initialized = true;
  }

  /// Schedule notifications for the next 30 days.
  static Future<void> scheduleUpcoming(List<EventModel> events) async {
    await init();
    await _plugin.cancelAll();

    final now = DateTime.now();
    int id = 0;

    for (int i = 0; i < 30; i++) {
      final d = DateTime(now.year, now.month, now.day + i);
      final al = LunarCalendar.solar2lunar(d.day, d.month, d.year);
      final holidays = LunarCalendar.holidays(d, al);
      final userEvents = events.where((e) => !e.deleted && e.date == EventModel.dateKey(d)).toList();
      final isFirst15 = al.day == 1 || al.day == 15;

      final parts = <String>[];
      if (holidays.isNotEmpty) parts.add(holidays.first.name);
      if (userEvents.isNotEmpty) parts.addAll(userEvents.map((e) => e.title));
      if (isFirst15 && holidays.isEmpty) {
        parts.add(al.day == 1 ? 'Mùng 1 âm lịch' : 'Ngày Rằm âm lịch');
      }

      if (parts.isEmpty) continue;

      // Schedule at 7:30 AM that day (or immediately if today and past 7:30)
      var scheduleTime = DateTime(d.year, d.month, d.day, 7, 30);
      if (scheduleTime.isBefore(now)) {
        if (i == 0) continue; // today already passed, skip
        continue;
      }

      final tzTime = tz.TZDateTime.from(scheduleTime, tz.local);
      final title = i == 0 ? 'Hôm nay' : _dayLabel(d);
      final body = parts.join(' · ');

      await _plugin.zonedSchedule(
        id++,
        title,
        body,
        tzTime,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channel.id,
            _channel.name,
            channelDescription: _channel.description,
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    }
  }

  static String _dayLabel(DateTime d) {
    const days = ['Thứ Hai', 'Thứ Ba', 'Thứ Tư', 'Thứ Năm', 'Thứ Sáu', 'Thứ Bảy', 'Chủ Nhật'];
    return '${days[d.weekday - 1]}, ${d.day}/${d.month}';
  }

  static Future<void> cancelAll() => _plugin.cancelAll();
}
