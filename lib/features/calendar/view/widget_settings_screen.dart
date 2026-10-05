import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../model/widget_config.dart';
import '../viewmodel/app_view_model.dart';
import 'app_colors_ext.dart';
import 'widgets/widget_preview.dart';

class WidgetSettingsScreen extends ConsumerWidget {
  const WidgetSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appViewModelProvider);
    final vm = ref.read(appViewModelProvider.notifier);
    final config = state.widgetConfig;
    final t = LvColors.of(state.theme == 'dark');

    Widget label(String s) => Padding(
          padding: const EdgeInsets.only(top: 24, bottom: 8),
          child: Text(s, style: TextStyle(fontSize: 11, letterSpacing: 1.2, color: t.muted)),
        );

    Widget toggle(String title, bool value, WidgetConfig Function(bool) apply) => SwitchListTile(
          contentPadding: EdgeInsets.zero,
          dense: true,
          title: Text(title, style: TextStyle(fontSize: 14, color: t.text)),
          value: value,
          activeThumbColor: t.accent,
          onChanged: (v) => vm.setWidgetConfig(apply(v)),
        );

    Widget segmented<T>(List<T> values, T selected, String Function(T) text, ValueChanged<T> onSelect) =>
        SegmentedButton<T>(
          showSelectedIcon: false,
          segments: [for (final v in values) ButtonSegment(value: v, label: Text(text(v)))],
          selected: {selected},
          onSelectionChanged: (s) => onSelect(s.first),
        );

    return Scaffold(
      backgroundColor: t.bg,
      appBar: AppBar(
        backgroundColor: t.bg,
        foregroundColor: t.text,
        elevation: 0,
        title: const Text('Tuỳ chỉnh widget', style: TextStyle(fontSize: 16)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 24),
              width: double.infinity,
              decoration: BoxDecoration(
                color: t.surface,
                borderRadius: BorderRadius.circular(LvColors.radiusLg),
                border: Border.all(color: t.divider),
              ),
              child: Center(child: WidgetPreview(config: config, appTheme: state.theme)),
            ),
          ),
          label('THÔNG TIN HIỂN THỊ'),
          toggle('Thứ trong tuần', config.showWeekday, (v) => config.copyWith(showWeekday: v)),
          toggle('Ngày âm lịch · can chi', config.showLunar, (v) => config.copyWith(showLunar: v)),
          toggle('Hoàng đạo / Hắc đạo', config.showAuspicious, (v) => config.copyWith(showAuspicious: v)),
          toggle('Ngày lễ / Sự kiện', config.showEvents, (v) => config.copyWith(showEvents: v)),
          label('CỠ CHỮ'),
          segmented(WidgetTextScale.values, config.textScale, (s) => s.label,
              (s) => vm.setWidgetConfig(config.copyWith(textScale: s))),
          label('GIAO DIỆN WIDGET'),
          segmented(WidgetThemeMode.values, config.themeMode, (m) => m.label,
              (m) => vm.setWidgetConfig(config.copyWith(themeMode: m))),
          const SizedBox(height: 16),
          Text(
            'Bạn có thể kéo giãn ô widget bằng cách nhấn giữ widget trên màn hình chính.',
            style: TextStyle(fontSize: 12, height: 1.5, color: t.dim),
          ),
        ],
      ),
    );
  }
}
