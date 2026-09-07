import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../state/app_state.dart';
import '../viewmodel/app_view_model.dart';
import 'app_colors_ext.dart';
import 'tabs/calendar_tab.dart';
import 'tabs/weather_tab.dart';
import 'tabs/astrology_tab.dart';
import 'tabs/profile_tab.dart';
import 'widgets/detail_sheet.dart';
import 'widgets/splash_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appViewModelProvider);
    final vm = ref.read(appViewModelProvider.notifier);
    final isDark = state.theme == 'dark';
    final t = LvColors.of(isDark);

    return Scaffold(
      backgroundColor: t.bg,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                Expanded(child: _buildTab(state, t, ref)),
                _TabBar(theme: t, state: state, vm: vm),
              ],
            ),
          ),

          if (state.selectedDateKey != null) ...[
            GestureDetector(
              onTap: vm.closeDetail,
              child: Container(color: Colors.black.withValues(alpha: 0.55)),
            ),
            Positioned(
              left: 0, right: 0, bottom: 0,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.82),
                child: DetailSheet(theme: t, dateKey: state.selectedDateKey!),
              ),
            ),
          ],

          if (state.splashVisible)
            Positioned.fill(
              child: SplashOverlay(theme: t, visible: state.splashVisible),
            ),
        ],
      ),
    );
  }

  Widget _buildTab(AppState state, LvTheme t, WidgetRef ref) {
    switch (state.tab) {
      case AppTab.calendar:
        return CalendarTab(theme: t);
      case AppTab.weather:
        return WeatherTab(theme: t);
      case AppTab.astrology:
        return AstrologyTab(theme: t);
      case AppTab.profile:
        return ProfileTab(theme: t);
    }
  }
}

class _TabBar extends StatelessWidget {
  const _TabBar({required this.theme, required this.state, required this.vm});
  final LvTheme theme;
  final AppState state;
  final AppViewModel vm;

  static const _tabs = [
    (AppTab.calendar, 'Lịch', Icons.calendar_month, Icons.calendar_month_outlined),
    (AppTab.weather, 'Thời tiết', Icons.wb_cloudy, Icons.cloud_outlined),
    (AppTab.astrology, 'Tử vi', Icons.stars, Icons.star_border),
    (AppTab.profile, 'Cá nhân', Icons.person, Icons.person_outline),
  ];

  @override
  Widget build(BuildContext context) {
    final t = theme;
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 20),
      decoration: BoxDecoration(
        color: t.surface,
        border: Border(top: BorderSide(color: t.divider)),
      ),
      child: Row(
        children: _tabs.map((tab) {
          final on = state.tab == tab.$1;
          return Expanded(
            child: GestureDetector(
              onTap: () => vm.setTab(tab.$1),
              behavior: HitTestBehavior.opaque,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(on ? tab.$3 : tab.$4,
                      color: on ? t.accent : t.dim, size: 23),
                  const SizedBox(height: 4),
                  Text(tab.$2,
                      style: TextStyle(
                          fontSize: 10.5,
                          letterSpacing: 0.1,
                          fontWeight: FontWeight.w500,
                          color: on ? t.accent : t.dim)),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
