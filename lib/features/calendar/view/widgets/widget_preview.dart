import 'package:flutter/material.dart';
import '../../model/widget_config.dart';
import '../../services/lunar_calendar.dart';

/// Flutter mock of the native home-screen widget, driven by [WidgetConfig].
/// Colours and base sizes mirror LichVietWidgetProvider.kt / lich_viet_widget*.xml.
class WidgetPreview extends StatelessWidget {
  const WidgetPreview({super.key, required this.config, required this.appTheme});
  final WidgetConfig config;
  final String appTheme;

  @override
  Widget build(BuildContext context) {
    final isLight = config.resolveTheme(appTheme) == 'light';
    final k = config.textScale.factor;

    final now = DateTime.now();
    final al = LunarCalendar.solar2lunar(now.day, now.month, now.year);
    final cc = LunarCalendar.canChi(al);
    final isAusp = LunarCalendar.ngayTot(al.month, cc.chiDay);
    final holidays = LunarCalendar.holidays(now, al);
    final weekday = LunarCalendar.weekdays[now.weekday % 7];

    final cWeekday = isLight ? const Color(0xFF75798C) : const Color(0xFF9397AB);
    final cSolar = isLight ? const Color(0xFF1C1D26) : const Color(0xFFE9E9ED);
    final cAccent = isLight ? const Color(0xFF5D5294) : const Color(0xFF9184D9);
    final cHoliday = isLight ? const Color(0xFF796CBF) : const Color(0xFFB5ABFC);
    const cAuspNo = Color(0xFF796CBF);

    Text line(String s, double size, Color c, {bool bold = false, bool upper = false}) => Text(
          upper ? s.toUpperCase() : s,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
              fontSize: size * k, color: c, fontWeight: bold ? FontWeight.bold : FontWeight.normal, height: 1.25),
        );

    return Container(
      width: 220,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isLight ? const Color(0xE8F5F5FA) : const Color(0xCC161826),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (config.showWeekday) line(weekday, 11, cWeekday, upper: true),
          line('${now.day}', 28, cSolar, bold: true),
          if (config.showLunar) line('Âm ${al.day}/${al.month} · ${cc.day}', 11, cAccent),
          if (config.showAuspicious) line(isAusp ? 'Hoàng đạo' : 'Hắc đạo', 11, isAusp ? cAccent : cAuspNo),
          if (config.showEvents && holidays.isNotEmpty) line(holidays.first.name, 10, cHoliday),
          if (config.showEvents) line('Sự kiện sắp tới · 3 ngày nữa', 10, const Color(0xFF27AE82)),
        ],
      ),
    );
  }
}
