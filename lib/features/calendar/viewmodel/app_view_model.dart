import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../services/drive_service.dart';
import '../model/event_model.dart';
import '../model/profile_model.dart';
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
    _restoreSession();

    Future.delayed(const Duration(milliseconds: 2500), () {
      safeSetState(state.copyWith(splashVisible: false));
    });
  }

  static const _prefObDone      = 'ob_done';
  static const _prefGoogleEmail = 'google_email';
  static const _prefCityName    = 'city_name';
  static const _prefCityAdmin   = 'city_admin';
  static const _prefCityLat     = 'city_lat';
  static const _prefCityLon     = 'city_lon';
  static const _prefTheme       = 'app_theme';
  static const _prefName        = 'profile_name';
  static const _prefBirthDate   = 'profile_birth_date';
  static const _prefBirthTime   = 'profile_birth_time';
  static const _prefGender      = 'profile_gender';
  static const _prefNameEdited  = 'profile_name_edited';
  static const _prefBirthEdited = 'profile_birth_edited';

  Future<void> _restoreSession() async {
    final prefs = await SharedPreferences.getInstance();

    // Restore theme
    final theme = prefs.getString(_prefTheme);
    if (theme != null) safeSetState(state.copyWith(theme: theme));

    // Restore city
    final cityName = prefs.getString(_prefCityName);
    if (cityName != null) {
      final city = WeatherCity(
        name: cityName,
        admin: prefs.getString(_prefCityAdmin) ?? '',
        lat: prefs.getDouble(_prefCityLat) ?? 21.0285,
        lon: prefs.getDouble(_prefCityLon) ?? 105.8542,
      );
      safeSetState(state.copyWith(city: () => city));
    }

    // Show onboarding if first launch
    final obDone = prefs.getBool(_prefObDone) ?? false;
    if (!obDone) {
      safeSetState(state.copyWith(obVisible: true));
      return; // don't restore Google session until onboarding is done
    }

    // Restore profile
    final name       = prefs.getString(_prefName) ?? '';
    final birthDate  = prefs.getString(_prefBirthDate) ?? '';
    final birthTime  = prefs.getString(_prefBirthTime) ?? '';
    final gender     = prefs.getString(_prefGender) ?? 'Nam';
    final nameEdited = prefs.getBool(_prefNameEdited) ?? false;
    final birthEdited = prefs.getBool(_prefBirthEdited) ?? false;
    safeSetState(state.copyWith(
      profile: ProfileModel(
        name: name,
        birthDate: birthDate,
        birthTime: birthTime,
        gender: gender,
        nameEdited: nameEdited,
        birthDateEdited: birthEdited,
      ),
    ));

    // Restore Google session
    final savedEmail = prefs.getString(_prefGoogleEmail);
    if (savedEmail == null) return;
    safeSetState(state.copyWith(
      googleEmail: () => savedEmail,
      syncMsg: 'Đã kết nối · Ấn "Đồng bộ ngay" để cập nhật',
    ));
    try {
      final account = await DriveService.signInSilently();
      if (account != null) await _runSync(account);
    } catch (_) {}
  }

  Future<void> _saveProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final p = state.profile;
    await prefs.setString(_prefName, p.name);
    await prefs.setString(_prefBirthDate, p.birthDate);
    await prefs.setString(_prefBirthTime, p.birthTime);
    await prefs.setString(_prefGender, p.gender);
    await prefs.setBool(_prefNameEdited, p.nameEdited);
    await prefs.setBool(_prefBirthEdited, p.birthDateEdited);
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

  Future<void> setTheme(String theme) async {
    safeSetState(state.copyWith(theme: theme));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefTheme, theme);
    WidgetService.updateWidget();
  }

  Future<void> obDone() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefObDone, true);
    _saveProfile();
    safeSetState(state.copyWith(obVisible: false));
    // Now restore Google session if any
    final savedEmail = prefs.getString(_prefGoogleEmail);
    if (savedEmail != null) {
      safeSetState(state.copyWith(
        googleEmail: () => savedEmail,
        syncMsg: 'Đã kết nối · Ấn "Đồng bộ ngay" để cập nhật',
      ));
      try {
        final account = await DriveService.signInSilently();
        if (account != null) await _runSync(account);
      } catch (_) {}
    }
  }

  Future<void> obSkip() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefObDone, true);
    safeSetState(state.copyWith(obVisible: false));
  }

  void replayOb() => safeSetState(state.copyWith(obVisible: true));

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

  void setName(String v) {
    safeSetState(state.copyWith(profile: state.profile.copyWith(name: v, nameEdited: true)));
    _saveProfile();
  }

  void setBirthDate(String v) {
    safeSetState(state.copyWith(profile: state.profile.copyWith(birthDate: v, birthDateEdited: true)));
    _saveProfile();
  }
  void setBirthTime(String v) {
    safeSetState(state.copyWith(profile: state.profile.copyWith(birthTime: v)));
    _saveProfile();
  }

  void setGender(String v) {
    safeSetState(state.copyWith(profile: state.profile.copyWith(gender: v)));
    _saveProfile();
  }

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

  void clearSuggestions() {
    _suggestionTimer?.cancel();
    safeSetState(state.copyWith(citySuggestions: []));
  }

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
      // Nominatim OpenStreetMap — free, no key required
      final uri = Uri.parse(
          'https://nominatim.openstreetmap.org/reverse?lat=$lat&lon=$lon&format=json&accept-language=vi');
      final r = await http.get(uri, headers: {'User-Agent': 'LichViet/1.0'});
      String name = 'Vị trí của bạn';
      String admin = '';
      if (r.statusCode == 200) {
        final j = jsonDecode(r.body) as Map<String, dynamic>;
        final addr = j['address'] as Map<String, dynamic>? ?? {};
        // Pick the most specific non-null locality name
        name = (addr['suburb'] ?? addr['quarter'] ?? addr['neighbourhood'] ??
                addr['village'] ?? addr['town'] ?? addr['city'] ??
                addr['county'] ?? addr['state'] ?? j['display_name'] ?? 'Vị trí của bạn')
            as String;
        admin = (addr['city'] ?? addr['town'] ?? addr['state'] ?? '') as String;
        // Avoid duplicating name and admin when they're the same
        if (admin == name) admin = (addr['state'] ?? '') as String;
      }
      final city = WeatherCity(name: name, admin: admin, lat: lat, lon: lon);
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
      _saveCity(city);
    } catch (_) {
      safeSetState(state.copyWith(wxErr: 'Mất mạng. Đang xem bản cache lần cập nhật gần nhất.'));
    }
  }

  Future<void> _saveCity(WeatherCity city) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefCityName, city.name);
    await prefs.setString(_prefCityAdmin, city.admin);
    await prefs.setDouble(_prefCityLat, city.lat);
    await prefs.setDouble(_prefCityLon, city.lon);
  }

  // ── Tử vi ──

  void toggleTuVi() => safeSetState(state.copyWith(tvOpen: !state.tvOpen));

  // ── Sync ──

  Future<void> doSync() async {
    if (state.syncState == SyncState.running) return;
    safeSetState(state.copyWith(
      syncState: SyncState.running,
      syncMsg: 'Đang kết nối Google…',
    ));
    try {
      // Try silent sign-in first (already connected), fall back to interactive
      var account = await DriveService.signInSilently();
      account ??= await DriveService.signIn();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefGoogleEmail, account.email);

      // Điền tên từ Google nếu user chưa tự sửa
      final googleName = account.displayName ?? '';
      final profile = state.profile;
      if (!profile.nameEdited && googleName.isNotEmpty) {
        safeSetState(state.copyWith(
          profile: profile.copyWith(name: googleName),
        ));
        _saveProfile();
      }

      safeSetState(state.copyWith(
        googleEmail: () => account!.email,
        syncMsg: 'Đang đọc dữ liệu từ Drive…',
      ));
      await _runSync(account);
    } catch (e) {
      safeSetState(state.copyWith(
        syncState: SyncState.idle,
        syncMsg: 'Lỗi: ${e.toString().replaceAll('Exception: ', '')}',
      ));
    }
  }

  Future<void> _runSync(dynamic account) async {
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
  }

  Future<void> disconnectGoogle() async {
    await DriveService.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefGoogleEmail);
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

