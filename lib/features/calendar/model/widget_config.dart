import 'dart:convert';

enum WidgetTextScale {
  small('small', 'Nhỏ', 0.85),
  medium('medium', 'Vừa', 1.0),
  large('large', 'Lớn', 1.25);

  const WidgetTextScale(this.key, this.label, this.factor);
  final String key;
  final String label;
  final double factor;

  static WidgetTextScale fromKey(String? key) =>
      values.firstWhere((s) => s.key == key, orElse: () => medium);
}

/// 'app' follows the in-app theme; 'light' / 'dark' override it for the widget only.
enum WidgetThemeMode {
  app('app', 'Theo app'),
  light('light', 'Sáng'),
  dark('dark', 'Tối');

  const WidgetThemeMode(this.key, this.label);
  final String key;
  final String label;

  static WidgetThemeMode fromKey(String? key) =>
      values.firstWhere((m) => m.key == key, orElse: () => app);
}

class WidgetConfig {
  static const prefKey = 'widget_config';

  final bool showWeekday;
  final bool showLunar;
  final bool showAuspicious;
  final bool showEvents; // today's holiday + upcoming event rows
  final WidgetTextScale textScale;
  final WidgetThemeMode themeMode;

  const WidgetConfig({
    this.showWeekday = true,
    this.showLunar = true,
    this.showAuspicious = true,
    this.showEvents = true,
    this.textScale = WidgetTextScale.medium,
    this.themeMode = WidgetThemeMode.app,
  });

  WidgetConfig copyWith({
    bool? showWeekday,
    bool? showLunar,
    bool? showAuspicious,
    bool? showEvents,
    WidgetTextScale? textScale,
    WidgetThemeMode? themeMode,
  }) =>
      WidgetConfig(
        showWeekday: showWeekday ?? this.showWeekday,
        showLunar: showLunar ?? this.showLunar,
        showAuspicious: showAuspicious ?? this.showAuspicious,
        showEvents: showEvents ?? this.showEvents,
        textScale: textScale ?? this.textScale,
        themeMode: themeMode ?? this.themeMode,
      );

  /// 'dark' | 'light' — what the widget should actually render with.
  String resolveTheme(String appTheme) =>
      themeMode == WidgetThemeMode.app ? appTheme : themeMode.key;

  Map<String, dynamic> toJson() => {
        'showWeekday': showWeekday,
        'showLunar': showLunar,
        'showAuspicious': showAuspicious,
        'showEvents': showEvents,
        'textScale': textScale.key,
        'themeMode': themeMode.key,
      };

  factory WidgetConfig.fromJson(Map<String, dynamic> j) => WidgetConfig(
        showWeekday: j['showWeekday'] as bool? ?? true,
        showLunar: j['showLunar'] as bool? ?? true,
        showAuspicious: j['showAuspicious'] as bool? ?? true,
        showEvents: j['showEvents'] as bool? ?? true,
        textScale: WidgetTextScale.fromKey(j['textScale'] as String?),
        themeMode: WidgetThemeMode.fromKey(j['themeMode'] as String?),
      );

  String encode() => jsonEncode(toJson());

  /// Missing or corrupt data falls back to the defaults.
  factory WidgetConfig.decode(String? raw) {
    if (raw == null || raw.isEmpty) return const WidgetConfig();
    try {
      return WidgetConfig.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return const WidgetConfig();
    }
  }
}
