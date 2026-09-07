class WeatherCity {
  final String name;
  final String admin;
  final double lat;
  final double lon;

  const WeatherCity({required this.name, required this.admin, required this.lat, required this.lon});

  String get displayName {
    if (name == 'Vị trí của bạn') {
      return admin.isNotEmpty ? 'Vị trí của bạn – $admin' : 'Vị trí của bạn';
    }
    return admin.isNotEmpty ? '$name, $admin' : name;
  }
}

class WeatherData {
  final Map<String, dynamic> raw;
  const WeatherData(this.raw);

  Map<String, dynamic>? get current => raw['current'] as Map<String, dynamic>?;
  Map<String, dynamic>? get hourly => raw['hourly'] as Map<String, dynamic>?;
  Map<String, dynamic>? get daily => raw['daily'] as Map<String, dynamic>?;
}

class WeatherDescIcon {
  final String desc;
  final String icon; // phosphor icon name e.g. 'ph-sun'
  const WeatherDescIcon(this.desc, this.icon);

  static WeatherDescIcon fromCode(int code) {
    const map = {
      0: ('Trời quang', 'ph-sun'),
      1: ('Ít mây', 'ph-cloud-sun'),
      2: ('Có mây', 'ph-cloud-sun'),
      3: ('Nhiều mây', 'ph-cloud'),
      45: ('Sương mù', 'ph-cloud-fog'),
      48: ('Sương mù đóng băng', 'ph-cloud-fog'),
      51: ('Mưa phùn nhẹ', 'ph-cloud-rain'),
      53: ('Mưa phùn', 'ph-cloud-rain'),
      55: ('Mưa phùn dày', 'ph-cloud-rain'),
      61: ('Mưa nhẹ', 'ph-cloud-rain'),
      63: ('Mưa', 'ph-cloud-rain'),
      65: ('Mưa to', 'ph-cloud-rain'),
      66: ('Mưa lạnh', 'ph-cloud-rain'),
      67: ('Mưa lạnh nặng', 'ph-cloud-rain'),
      71: ('Tuyết nhẹ', 'ph-snowflake'),
      73: ('Tuyết', 'ph-snowflake'),
      75: ('Tuyết dày', 'ph-snowflake'),
      77: ('Hạt tuyết', 'ph-snowflake'),
      80: ('Mưa rào nhẹ', 'ph-cloud-rain'),
      81: ('Mưa rào', 'ph-cloud-rain'),
      82: ('Mưa rào mạnh', 'ph-cloud-rain'),
      85: ('Mưa tuyết', 'ph-snowflake'),
      86: ('Mưa tuyết nặng', 'ph-snowflake'),
      95: ('Dông', 'ph-cloud-lightning'),
      96: ('Dông kèm mưa đá', 'ph-cloud-lightning'),
      99: ('Dông mạnh, mưa đá', 'ph-cloud-lightning'),
    };
    final entry = map[code] ?? ('—', 'ph-cloud');
    return WeatherDescIcon(entry.$1, entry.$2);
  }
}
