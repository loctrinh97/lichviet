import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import '../model/event_model.dart';
import '../model/weather_model.dart';
import '../services/widget_service.dart';
import '../state/app_state.dart';
import '../../../core/base/base_view_model.dart';

final appViewModelProvider = StateNotifierProvider<AppViewModel, AppState>((ref) {
  final now = DateTime.now();
  return AppViewModel(now);
});

class AppViewModel extends BaseViewModel<AppState> {
  final _uuid = const Uuid();
  Timer? _suggestionTimer;

  AppViewModel(DateTime now)
      : super(AppState(
          viewYear: now.year,
          viewMonth: now.month - 1, // 0-based to match design
          city: const WeatherCity(name: 'Hà Nội', admin: '', lat: 21.0285, lon: 105.8542),
        )) {
    _init(now);
  }

  void _init(DateTime now) {
    safeSetState(state.copyWith(events: const []));
    WidgetService.updateWidget();
    _fetchWeather(const WeatherCity(name: 'Hà Nội', admin: '', lat: 21.0285, lon: 105.8542));

    // Hide splash after 2.5s
    Future.delayed(const Duration(milliseconds: 2500), () {
      safeSetState(state.copyWith(splashVisible: false));
    });
  }

  List<EventModel> eventsOn(String dateKey) =>
      state.events.where((e) => !e.deleted && e.date == dateKey).toList();

  // ── Navigation ──

  void prevMonth() {
    final d = DateTime(state.viewYear, state.viewMonth, 1); // month is 0-based so this goes back
    safeSetState(state.copyWith(viewYear: d.year, viewMonth: d.month - 1));
  }

  void nextMonth() {
    final d = DateTime(state.viewYear, state.viewMonth + 2, 1);
    safeSetState(state.copyWith(viewYear: d.year, viewMonth: d.month - 1));
  }

  void goToday() {
    final now = DateTime.now();
    safeSetState(state.copyWith(
      viewYear: now.year,
      viewMonth: now.month - 1,
      selectedDateKey: () => EventModel.dateKey(now),
    ));
  }

  void selectDate(String key) {
    safeSetState(state.copyWith(selectedDateKey: () => key, eventDraft: ''));
  }

  void closeDetail() {
    safeSetState(state.copyWith(selectedDateKey: () => null, eventDraft: ''));
  }

  void setTab(AppTab tab) => safeSetState(state.copyWith(tab: tab));

  void setTheme(String theme) => safeSetState(state.copyWith(theme: theme));

  void replaySplash() {
    safeSetState(state.copyWith(splashVisible: true));
    Future.delayed(const Duration(milliseconds: 2500), () {
      safeSetState(state.copyWith(splashVisible: false));
    });
  }

  // ── Events ──

  void setEventDraft(String v) => safeSetState(state.copyWith(eventDraft: v));

  void addEvent() {
    final t = state.eventDraft.trim();
    final sel = state.selectedDateKey;
    if (t.isEmpty || sel == null) return;
    final ev = EventModel(
      id: _uuid.v4(),
      date: sel,
      title: t,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );
    safeSetState(state.copyWith(events: [...state.events, ev], eventDraft: ''));
  }

  void deleteEvent(String id) {
    final updated = state.events.map((e) {
      if (e.id == id) return e.copyWith(deleted: true, updatedAt: DateTime.now().millisecondsSinceEpoch);
      return e;
    }).toList();
    safeSetState(state.copyWith(events: updated));
  }

  // ── Profile ──

  void setName(String v) => safeSetState(state.copyWith(profile: state.profile.copyWith(name: v)));
  void setBirthDate(String v) => safeSetState(state.copyWith(profile: state.profile.copyWith(birthDate: v)));
  void setBirthTime(String v) => safeSetState(state.copyWith(profile: state.profile.copyWith(birthTime: v)));
  void setGender(String v) => safeSetState(state.copyWith(profile: state.profile.copyWith(gender: v)));

  // ── Weather ──

  void setCityDraft(String v) {
    safeSetState(state.copyWith(cityDraft: v));
    _suggestionTimer?.cancel();
    if (v.trim().isEmpty) {
      safeSetState(state.copyWith(citySuggestions: []));
      return;
    }
    _suggestionTimer = Timer(const Duration(milliseconds: 400), () => _searchSuggestions(v.trim()));
  }

  Future<void> _searchSuggestions(String name) async {
    try {
      final uri = Uri.parse(
          'https://geocoding-api.open-meteo.com/v1/search?count=5&language=vi&name=${Uri.encodeComponent(name)}');
      final r = await http.get(uri);
      if (r.statusCode != 200) return;
      final j = jsonDecode(r.body) as Map<String, dynamic>;
      final results = j['results'] as List? ?? [];
      final suggestions = results.map((g) {
        final m = g as Map<String, dynamic>;
        return WeatherCity(
          name: m['name'] as String,
          admin: (m['admin1'] as String?) ?? '',
          lat: (m['latitude'] as num).toDouble(),
          lon: (m['longitude'] as num).toDouble(),
        );
      }).toList();
      safeSetState(state.copyWith(citySuggestions: suggestions));
    } catch (_) {}
  }

  void selectSuggestion(WeatherCity city) {
    safeSetState(state.copyWith(citySuggestions: [], cityDraft: ''));
    _fetchWeather(city);
  }

  void clearSuggestions() => safeSetState(state.copyWith(citySuggestions: []));

  void submitCity() {
    final name = state.cityDraft.trim();
    if (name.isEmpty) return;
    safeSetState(state.copyWith(citySuggestions: []));
    _lookupCity(name);
  }

  void useGeo() {
    // Flutter doesn't have browser geolocation; show a hint
    safeSetState(state.copyWith(wxErr: 'Dùng ô tìm thành phố để tra thời tiết.'));
  }

  Future<void> _lookupCity(String name) async {
    try {
      final uri = Uri.parse(
          'https://geocoding-api.open-meteo.com/v1/search?count=1&language=vi&name=${Uri.encodeComponent(name)}');
      final r = await http.get(uri);
      if (r.statusCode != 200) {
        safeSetState(state.copyWith(wxErr: 'Không tìm thấy "$name".'));
        return;
      }
      final j = jsonDecode(r.body) as Map<String, dynamic>;
      final results = j['results'] as List?;
      if (results == null || results.isEmpty) {
        safeSetState(state.copyWith(wxErr: 'Không tìm thấy "$name".'));
        return;
      }
      final g = results.first as Map<String, dynamic>;
      final city = WeatherCity(
        name: g['name'] as String,
        admin: (g['admin1'] as String?) ?? '',
        lat: (g['latitude'] as num).toDouble(),
        lon: (g['longitude'] as num).toDouble(),
      );
      await _fetchWeather(city);
    } catch (_) {
      safeSetState(state.copyWith(wxErr: 'Không gọi được Open-Meteo. Đang xem dữ liệu đã cache.'));
    }
  }

  Future<void> _fetchWeather(WeatherCity city) async {
    try {
      final url = 'https://api.open-meteo.com/v1/forecast'
          '?latitude=${city.lat}&longitude=${city.lon}'
          '&current=temperature_2m,relative_humidity_2m,apparent_temperature,weather_code,wind_speed_10m'
          '&hourly=temperature_2m,weather_code,precipitation_probability'
          '&daily=weather_code,temperature_2m_max,temperature_2m_min'
          '&timezone=auto&forecast_days=7';
      final r = await http.get(Uri.parse(url));
      if (r.statusCode != 200) return;
      final j = jsonDecode(r.body) as Map<String, dynamic>;
      safeSetState(state.copyWith(
        wx: () => WeatherData(j),
        city: () => city,
        wxErr: '',
        wxAt: () => DateTime.now().millisecondsSinceEpoch,
        wxCached: false,
        cityDraft: '',
      ));
    } catch (_) {
      safeSetState(state.copyWith(wxErr: 'Mất mạng. Đang xem bản cache lần cập nhật gần nhất.'));
    }
  }

  // ── Tử vi ──

  void toggleTuVi() => safeSetState(state.copyWith(tvOpen: !state.tvOpen));

  // ── Sync ──

  void doSync() {
    if (state.syncState == SyncState.running) return;
    safeSetState(state.copyWith(
      syncState: SyncState.running,
      syncMsg: 'Đang đăng nhập Google…',
    ));
    Future.delayed(const Duration(milliseconds: 700), () {
      safeSetState(state.copyWith(syncMsg: 'Đang đọc dữ liệu từ Drive…'));
    });
    Future.delayed(const Duration(milliseconds: 1500), () {
      final now = TimeOfDay.fromDateTime(DateTime.now());
      final timeStr = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
      safeSetState(state.copyWith(
        syncState: SyncState.done,
        syncMsg: 'Đồng bộ thành công lúc $timeStr',
      ));
    });
  }

  // ── Export ──

  String buildIcsContent() {
    final live = state.events.where((e) => !e.deleted).toList();
    final lines = [
      'BEGIN:VCALENDAR', 'VERSION:2.0',
      'PRODID:-//Lich Viet//prototype//VI', 'CALSCALE:GREGORIAN',
    ];
    for (final e in live) {
      final parts = e.date.split('-').map(int.parse).toList();
      final dtStr = '${parts[0]}${parts[1].toString().padLeft(2, '0')}${parts[2].toString().padLeft(2, '0')}';
      lines.addAll([
        'BEGIN:VEVENT', 'UID:${e.id}',
        'DTSTART;VALUE=DATE:$dtStr', 'SUMMARY:${e.title}',
        'END:VEVENT',
      ]);
    }
    lines.add('END:VCALENDAR');
    return lines.join('\r\n');
  }

  String buildJsonContent() {
    return jsonEncode({
      'version': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'events': state.events.map((e) => e.toJson()).toList(),
    });
  }
}

// Minimal TimeOfDay shim (Flutter widget, but we only need hour/minute)
class TimeOfDay {
  final int hour;
  final int minute;
  const TimeOfDay({required this.hour, required this.minute});
  factory TimeOfDay.fromDateTime(DateTime dt) => TimeOfDay(hour: dt.hour, minute: dt.minute);
}
