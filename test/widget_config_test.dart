import 'package:flutter_test/flutter_test.dart';
import 'package:tvf_mobile/features/calendar/model/weather_model.dart';
import 'package:tvf_mobile/features/calendar/model/widget_config.dart';

void main() {
  test('defaults show everything at medium size following the app theme', () {
    const c = WidgetConfig();
    expect([c.showWeekday, c.showLunar, c.showAuspicious, c.showEvents, c.showWeather],
        everyElement(isTrue));
    expect(c.textScale, WidgetTextScale.medium);
    expect(c.themeMode, WidgetThemeMode.app);
  });

  test('encode/decode round-trips', () {
    final c = const WidgetConfig().copyWith(
      showLunar: false,
      showEvents: false,
      showWeather: false,
      textScale: WidgetTextScale.large,
      themeMode: WidgetThemeMode.light,
    );
    final d = WidgetConfig.decode(c.encode());
    expect(d.showLunar, isFalse);
    expect(d.showEvents, isFalse);
    expect(d.showWeather, isFalse);
    expect(d.showWeekday, isTrue);
    expect(d.textScale, WidgetTextScale.large);
    expect(d.themeMode, WidgetThemeMode.light);
  });

  test('missing, corrupt or unknown values fall back to defaults', () {
    expect(WidgetConfig.decode(null).textScale, WidgetTextScale.medium);
    expect(WidgetConfig.decode('not json').showLunar, isTrue);
    final d = WidgetConfig.decode('{"textScale":"huge","themeMode":"neon"}');
    expect(d.textScale, WidgetTextScale.medium);
    expect(d.themeMode, WidgetThemeMode.app);
  });

  test('resolveTheme follows the app unless overridden', () {
    expect(const WidgetConfig().resolveTheme('dark'), 'dark');
    expect(const WidgetConfig().resolveTheme('light'), 'light');
    expect(const WidgetConfig(themeMode: WidgetThemeMode.light).resolveTheme('dark'), 'light');
  });

  test('weatherEmoji maps WMO codes and falls back to cloud', () {
    expect(weatherEmoji(0), '☀️');
    expect(weatherEmoji(63), '🌧️');
    expect(weatherEmoji(95), '⛈️');
    expect(weatherEmoji(12345), '☁️');
  });
}
