import '../model/event_model.dart';
import '../model/weather_model.dart';
import '../model/profile_model.dart';

enum AppTab { calendar, weather, astrology, profile }

enum SyncState { idle, running, done }

class AppState {
  final String theme; // 'dark' | 'light'
  final AppTab tab;
  final int viewYear;
  final int viewMonth;
  final String? selectedDateKey;
  final List<EventModel> events;
  final String eventDraft;
  final ProfileModel profile;
  final String cityDraft;
  final WeatherCity? city;
  final WeatherData? wx;
  final String wxErr;
  final int? wxAt;
  final bool wxCached;
  final bool tvOpen;
  final bool dropOver;
  final String importMsg;
  final SyncState syncState;
  final String syncMsg;
  final bool splashVisible;

  const AppState({
    this.theme = 'dark',
    this.tab = AppTab.calendar,
    required this.viewYear,
    required this.viewMonth,
    this.selectedDateKey,
    this.events = const [],
    this.eventDraft = '',
    this.profile = const ProfileModel(),
    this.cityDraft = '',
    this.city,
    this.wx,
    this.wxErr = '',
    this.wxAt,
    this.wxCached = false,
    this.tvOpen = false,
    this.dropOver = false,
    this.importMsg = 'Chưa import file nào',
    this.syncState = SyncState.idle,
    this.syncMsg = 'Chưa kết nối. Dữ liệu chỉ ở máy này.',
    this.splashVisible = true,
  });

  AppState copyWith({
    String? theme,
    AppTab? tab,
    int? viewYear,
    int? viewMonth,
    String? Function()? selectedDateKey,
    List<EventModel>? events,
    String? eventDraft,
    ProfileModel? profile,
    String? cityDraft,
    WeatherCity? Function()? city,
    WeatherData? Function()? wx,
    String? wxErr,
    int? Function()? wxAt,
    bool? wxCached,
    bool? tvOpen,
    bool? dropOver,
    String? importMsg,
    SyncState? syncState,
    String? syncMsg,
    bool? splashVisible,
  }) {
    return AppState(
      theme: theme ?? this.theme,
      tab: tab ?? this.tab,
      viewYear: viewYear ?? this.viewYear,
      viewMonth: viewMonth ?? this.viewMonth,
      selectedDateKey: selectedDateKey != null ? selectedDateKey() : this.selectedDateKey,
      events: events ?? this.events,
      eventDraft: eventDraft ?? this.eventDraft,
      profile: profile ?? this.profile,
      cityDraft: cityDraft ?? this.cityDraft,
      city: city != null ? city() : this.city,
      wx: wx != null ? wx() : this.wx,
      wxErr: wxErr ?? this.wxErr,
      wxAt: wxAt != null ? wxAt() : this.wxAt,
      wxCached: wxCached ?? this.wxCached,
      tvOpen: tvOpen ?? this.tvOpen,
      dropOver: dropOver ?? this.dropOver,
      importMsg: importMsg ?? this.importMsg,
      syncState: syncState ?? this.syncState,
      syncMsg: syncMsg ?? this.syncMsg,
      splashVisible: splashVisible ?? this.splashVisible,
    );
  }
}
