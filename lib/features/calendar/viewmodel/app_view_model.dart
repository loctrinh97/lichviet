import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import '../services/drive_service.dart';
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

  List<EventModel> eventsOn(String dateKey) => [
        ...state.events.where((e) => !e.deleted && e.date == dateKey),
        ...state.gcalEvents.where((e) => e.date == dateKey),
      ];

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

  Future<void> useGeo() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        safeSetState(state.copyWith(wxErr: 'Dịch vụ vị trí bị tắt. Vui lòng bật trong cài đặt.'));
        return;
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          safeSetState(state.copyWith(wxErr: 'Không được cấp quyền truy cập vị trí.'));
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        safeSetState(state.copyWith(wxErr: 'Quyền vị trí bị từ chối vĩnh viễn. Vào Cài đặt để cấp lại.'));
        return;
      }
      safeSetState(state.copyWith(wxErr: '', wxLocating: true));
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.low),
      );
      await _reverseGeocode(pos.latitude, pos.longitude);
    } catch (_) {
      safeSetState(state.copyWith(wxErr: 'Không lấy được vị trí. Thử lại sau.', wxLocating: false));
    }
  }

  Future<void> _reverseGeocode(double lat, double lon) async {
    try {
      final uri = Uri.parse(
          'https://geocoding-api.open-meteo.com/v1/reverse?latitude=$lat&longitude=$lon&language=vi');
      final r = await http.get(uri);
      String cityName = '';
      String admin = '';
      if (r.statusCode == 200) {
        final j = jsonDecode(r.body) as Map<String, dynamic>;
        cityName = (j['name'] as String?) ?? '';
        admin = (j['admin1'] as String?) ?? '';
      }
      final city = WeatherCity(
        name: 'Vị trí của bạn',
        admin: cityName.isNotEmpty ? cityName : '',
        lat: lat,
        lon: lon,
      );
      await _fetchWeather(city);
    } catch (_) {
      final city = WeatherCity(name: 'Vị trí của bạn', admin: '', lat: lat, lon: lon);
      await _fetchWeather(city);
    } finally {
      safeSetState(state.copyWith(wxLocating: false));
    }
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

  Future<void> doSync() async {
    if (state.syncState == SyncState.running) return;
    safeSetState(state.copyWith(
      syncState: SyncState.running,
      syncMsg: 'Đang đăng nhập Google…',
    ));
    try {
      final account = await DriveService.signIn();
      safeSetState(state.copyWith(
        googleEmail: () => account.email,
        syncMsg: 'Đang đọc dữ liệu từ Drive…',
      ));

      // ── Step 1: Merge với Drive (bỏ qua nếu Drive full) ──
      String driveNote = '';
      try {
        final remote = await DriveService.download(account);
        final localEvents = state.events;

        List<EventModel> merged = localEvents;
        if (remote != null) {
          final remoteEvents = (remote['events'] as List? ?? [])
              .map((e) => EventModel.fromJson(e as Map<String, dynamic>))
              .toList();
          final map = <String, EventModel>{};
          for (final e in [...remoteEvents, ...localEvents]) {
            final existing = map[e.id];
            if (existing == null || e.updatedAt > existing.updatedAt) {
              map[e.id] = e;
            }
          }
          merged = map.values.toList();
        }
        safeSetState(state.copyWith(
          events: merged,
          syncMsg: 'Đang ghi dữ liệu lên Drive…',
        ));
        await DriveService.upload(account, {
          'version': 1,
          'syncedAt': DateTime.now().toIso8601String(),
          'events': merged.map((e) => e.toJson()).toList(),
        });
      } catch (driveErr) {
        final msg = driveErr.toString();
        if (msg.contains('quota') || msg.contains('storageQuota') || msg.contains('403')) {
          driveNote = ' · Drive bị đầy, chỉ đọc GCal';
        } else {
          driveNote = ' · Drive lỗi';
        }
      }

      // ── Step 2: Fetch Google Calendar (độc lập với Drive) ──
      safeSetState(state.copyWith(syncMsg: 'Đang đọc Google Calendar…'));
      final gcalEvents = await DriveService.fetchCalendarEvents(account);

      final timeStr = _timeStr(DateTime.now());
      safeSetState(state.copyWith(
        gcalEvents: gcalEvents,
        syncState: SyncState.done,
        syncMsg: 'Đồng bộ lúc $timeStr · ${gcalEvents.length} sự kiện$driveNote',
      ));
    } catch (e) {
      safeSetState(state.copyWith(
        syncState: SyncState.idle,
        syncMsg: 'Lỗi: ${e.toString().replaceAll('Exception: ', '')}',
      ));
    }
  }

  Future<void> disconnectGoogle() async {
    await DriveService.signOut();
    safeSetState(state.copyWith(
      googleEmail: () => null,
      gcalEvents: [],
      syncState: SyncState.idle,
      syncMsg: 'Đã ngắt kết nối Google. Dữ liệu vẫn ở máy này.',
    ));
  }

  String _timeStr(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

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

