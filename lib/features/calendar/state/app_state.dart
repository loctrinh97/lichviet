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
  final List<WeatherCity> citySuggestions;
  final WeatherCity? city;
  final WeatherData? wx;
  final String wxErr;
  final int? wxAt;
  final bool wxCached;
  final bool wxLocating;
  final bool tvOpen;
  final bool dropOver;
  final String importMsg;
  final SyncState syncState;
  final String syncMsg;
  final String? googleEmail;
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
    this.citySuggestions = const [],
    this.city,
    this.wx,
    this.wxErr = '',
    this.wxAt,
    this.wxCached = false,
    this.wxLocating = false,
    this.tvOpen = false,
    this.dropOver = false,
    this.importMsg = 'Chưa import file nào',
    this.syncState = SyncState.idle,
    this.syncMsg = 'Chưa kết nối. Dữ liệu chỉ ở máy này.',
    this.googleEmail,
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
    List<WeatherCity>? citySuggestions,
    WeatherCity? Function()? city,
    WeatherData? Function()? wx,
    String? wxErr,
    int? Function()? wxAt,
    bool? wxCached,
    bool? wxLocating,
    bool? tvOpen,
    bool? dropOver,
    String? importMsg,
    SyncState? syncState,
    String? syncMsg,
    String? Function()? googleEmail,
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
      citySuggestions: citySuggestions ?? this.citySuggestions,
      city: city != null ? city() : this.city,
      wx: wx != null ? wx() : this.wx,
      wxErr: wxErr ?? this.wxErr,
      wxAt: wxAt != null ? wxAt() : this.wxAt,
      wxCached: wxCached ?? this.wxCached,
      wxLocating: wxLocating ?? this.wxLocating,
      tvOpen: tvOpen ?? this.tvOpen,
      dropOver: dropOver ?? this.dropOver,
      importMsg: importMsg ?? this.importMsg,
      syncState: syncState ?? this.syncState,
      syncMsg: syncMsg ?? this.syncMsg,
      googleEmail: googleEmail != null ? googleEmail() : this.googleEmail,
      splashVisible: splashVisible ?? this.splashVisible,
    );
  }
}
