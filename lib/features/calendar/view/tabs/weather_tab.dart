import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../model/weather_model.dart';
import '../../state/app_state.dart';
import '../../viewmodel/app_view_model.dart';
import '../app_colors_ext.dart';
import 'package:intl/intl.dart';

class WeatherTab extends ConsumerStatefulWidget {
  const WeatherTab({super.key, required this.theme});
  final LvTheme theme;

  @override
  ConsumerState<WeatherTab> createState() => _WeatherTabState();
}

class _WeatherTabState extends ConsumerState<WeatherTab> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appViewModelProvider);
    final vm = ref.read(appViewModelProvider.notifier);
    final t = widget.theme;
    final wx = state.wx;
    final cur = wx?.current;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search bar
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 38,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: t.surface,
                    borderRadius: BorderRadius.circular(LvColors.radiusMd),
                    border: Border.all(color: t.divider),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.search, color: t.dim, size: 15),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _ctrl,
                          onChanged: vm.setCityDraft,
                          onSubmitted: (_) => vm.submitCity(),
                          decoration: InputDecoration(
                            hintText: 'Tìm thành phố…',
                            hintStyle: TextStyle(color: t.muted, fontSize: 14),
                            border: InputBorder.none,
                            isDense: true,
                          ),
                          style: TextStyle(color: t.text, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: vm.useGeo,
                child: Container(
                  width: 38, height: 38,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(LvColors.radiusMd),
                    border: Border.all(color: t.accent),
                  ),
                  child: Icon(Icons.my_location, color: t.accent, size: 17),
                ),
              ),
            ],
          ),

          if (state.wxErr.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(LvColors.radiusMd),
                border: Border.all(color: t.divider),
              ),
              child: Text(state.wxErr, style: const TextStyle(fontSize: 12.5, color: LvColors.accent300)),
            ),
          ],

          const SizedBox(height: 20),

          // Current weather
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(state.city?.displayName ?? '—',
                        style: TextStyle(fontWeight: FontWeight.w500, fontSize: 22, letterSpacing: -0.2, color: t.text)),
                    const SizedBox(height: 10),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          cur != null ? '${(cur['temperature_2m'] as num).round()}' : '--',
                          style: TextStyle(fontWeight: FontWeight.w400, fontSize: 68, height: 0.95, letterSpacing: -2, color: t.text),
                        ),
                        Text('°', style: TextStyle(fontSize: 24, color: t.muted)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (cur != null) ...[
                      Text(_wmo(cur['weather_code'] as int).desc, style: TextStyle(fontSize: 14.5, color: t.text)),
                      const SizedBox(height: 3),
                      Text(_rangeText(wx), style: TextStyle(fontSize: 12.5, color: t.muted)),
                    ],
                  ],
                ),
              ),
              if (cur != null)
                Icon(_wmoIcon(cur['weather_code'] as int), color: LvColors.accent400, size: 56),
            ],
          ),

          // Stats grid
          if (cur != null) ...[
            const SizedBox(height: 24),
            Row(
              children: [
                _StatCard(label: 'Cảm giác', value: '${(cur['apparent_temperature'] as num).round()}°', theme: t),
                const SizedBox(width: 8),
                _StatCard(label: 'Độ ẩm', value: '${cur['relative_humidity_2m']}%', theme: t),
                const SizedBox(width: 8),
                _StatCard(label: 'Gió', value: '${(cur['wind_speed_10m'] as num).round()} km/h', theme: t),
              ],
            ),
          ],

          // Hourly
          if (wx?.hourly != null) ...[
            const SizedBox(height: 24),
            Text('THEO GIỜ', style: TextStyle(fontSize: 11, letterSpacing: 1.2, color: t.muted)),
            const SizedBox(height: 12),
            _HourlyRow(wx: wx!, theme: t),
          ],

          // Daily
          if (wx?.daily != null) ...[
            const SizedBox(height: 24),
            Text('7 NGÀY TỚI', style: TextStyle(fontSize: 11, letterSpacing: 1.2, color: t.muted)),
            const SizedBox(height: 8),
            ..._buildDays(wx!.daily!, t),
          ],

          // Footer
          const SizedBox(height: 16),
          Text(_footer(state), style: TextStyle(fontSize: 11.5, color: t.dim)),
        ],
      ),
    );
  }

  String _rangeText(WeatherData? wx) {
    final daily = wx?.daily;
    if (daily == null) return '';
    final maxList = daily['temperature_2m_max'] as List?;
    final minList = daily['temperature_2m_min'] as List?;
    if (maxList == null || minList == null || maxList.isEmpty) return '';
    return 'Cao ${(maxList[0] as num).round()}° · Thấp ${(minList[0] as num).round()}°';
  }

  List<Widget> _buildDays(Map<String, dynamic> daily, LvTheme t) {
    final times = daily['time'] as List? ?? [];
    final codes = daily['weather_code'] as List? ?? [];
    final maxes = daily['temperature_2m_max'] as List? ?? [];
    final mins = daily['temperature_2m_min'] as List? ?? [];
    final days = <Widget>[];
    const viDays = ['Th 2', 'Th 3', 'Th 4', 'Th 5', 'Th 6', 'Th 7', 'CN'];
    for (int i = 0; i < times.length; i++) {
      final dt = DateTime.parse('${times[i]}T00:00:00');
      final label = i == 0 ? 'Hôm nay' : viDays[dt.weekday - 1];
      final wi = _wmo(codes[i] as int);
      days.add(Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            SizedBox(width: 62, child: Text(label, style: TextStyle(fontSize: 13.5, color: t.text))),
            Icon(_wmoIcon(codes[i] as int), color: LvColors.accent400, size: 17),
            const SizedBox(width: 8),
            Expanded(
              child: Text(wi.desc,
                  style: TextStyle(fontSize: 12, color: t.muted),
                  overflow: TextOverflow.ellipsis),
            ),
            Text('${(mins[i] as num).round()}°', style: TextStyle(fontSize: 13.5, color: t.muted)),
            const SizedBox(width: 8),
            SizedBox(
              width: 34,
              child: Text('${(maxes[i] as num).round()}°',
                  textAlign: TextAlign.right,
                  style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14.5, color: t.text)),
            ),
          ],
        ),
      ));
      days.add(Divider(color: t.divider, height: 1));
    }
    return days;
  }

  String _footer(AppState state) {
    if (state.wxAt == null) return 'Chưa có dữ liệu · Open-Meteo';
    final dt = DateTime.fromMillisecondsSinceEpoch(state.wxAt!);
    final time = DateFormat('HH:mm').format(dt);
    return 'Cập nhật $time · Open-Meteo${state.wxCached ? ' · bản cache offline' : ''}';
  }

  WeatherDescIcon _wmo(int code) => WeatherDescIcon.fromCode(code);

  IconData _wmoIcon(int code) {
    final icon = _wmo(code).icon;
    return _phosphorToMaterial(icon);
  }
}

IconData _phosphorToMaterial(String name) {
  switch (name) {
    case 'ph-sun': return Icons.wb_sunny;
    case 'ph-cloud-sun': return Icons.wb_cloudy;
    case 'ph-cloud': return Icons.cloud;
    case 'ph-cloud-fog': return Icons.foggy;
    case 'ph-cloud-rain': return Icons.grain;
    case 'ph-snowflake': return Icons.ac_unit;
    case 'ph-cloud-lightning': return Icons.flash_on;
    default: return Icons.cloud;
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value, required this.theme});
  final String label, value;
  final LvTheme theme;

  @override
  Widget build(BuildContext context) {
    final t = theme;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(LvColors.radiusMd),
          border: Border.all(color: t.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label.toUpperCase(), style: TextStyle(fontSize: 10.5, letterSpacing: 0.8, color: t.muted)),
            const SizedBox(height: 5),
            Text(value, style: TextStyle(fontWeight: FontWeight.w500, fontSize: 19, color: t.text)),
          ],
        ),
      ),
    );
  }
}

class _HourlyRow extends StatelessWidget {
  const _HourlyRow({required this.wx, required this.theme});
  final WeatherData wx;
  final LvTheme theme;

  @override
  Widget build(BuildContext context) {
    final t = theme;
    final hourly = wx.hourly!;
    final cur = wx.current;
    final times = hourly['time'] as List? ?? [];
    final temps = hourly['temperature_2m'] as List? ?? [];
    final codes = hourly['weather_code'] as List? ?? [];
    final precip = hourly['precipitation_probability'] as List?;

    String? nowTime = cur?['time'] as String?;
    int start = 0;
    if (nowTime != null) {
      start = times.indexWhere((t2) => (t2 as String).compareTo(nowTime) >= 0);
      if (start < 0) start = 0;
    }

    final items = <Widget>[];
    for (int i = start; i < (start + 24).clamp(0, times.length); i++) {
      final isNow = i == start;
      final label = isNow ? 'Bây giờ' : (times[i] as String).substring(11, 16);
      final temp = (temps[i] as num).round();
      final icon = _phosphorToMaterial(WeatherDescIcon.fromCode(codes[i] as int).icon);
      final rain = precip != null && i < precip.length ? '${precip[i]}%' : '';

      items.add(Container(
        width: 62,
        padding: const EdgeInsets.symmetric(vertical: 12),
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(LvColors.radiusMd),
          border: Border.all(color: isNow ? t.accent : t.divider),
          color: isNow ? t.accent.withOpacity(0.10) : Colors.transparent,
        ),
        child: Column(
          children: [
            Text(label, style: TextStyle(fontSize: 11.5, color: t.muted)),
            const SizedBox(height: 9),
            Icon(icon, color: LvColors.accent400, size: 20),
            const SizedBox(height: 9),
            Text('$temp°', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 15, color: t.text)),
            const SizedBox(height: 3),
            Text(rain, style: TextStyle(fontSize: 10.5, color: t.dim)),
          ],
        ),
      ));
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(children: items),
    );
  }
}
