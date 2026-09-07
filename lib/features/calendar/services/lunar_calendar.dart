import 'dart:math' as math;

class LunarDate {
  final int day;
  final int month;
  final int year;
  final bool isLeap;
  final int jd;

  const LunarDate({
    required this.day,
    required this.month,
    required this.year,
    required this.isLeap,
    required this.jd,
  });
}

class CanChi {
  final String day;
  final String chiDay;
  final String month;
  final String year;
  final String chiYear;

  const CanChi({
    required this.day,
    required this.chiDay,
    required this.month,
    required this.year,
    required this.chiYear,
  });
}

class GioHoangDao {
  final String chi;
  final String frame;
  const GioHoangDao(this.chi, this.frame);
}

class HolidayEntry {
  final String name;
  final String type; // 'duong' | 'am'
  const HolidayEntry(this.name, this.type);
}

class LunarCalendar {
  static const int _tz = 7;
  static final _can = ['Giáp', 'Ất', 'Bính', 'Đinh', 'Mậu', 'Kỷ', 'Canh', 'Tân', 'Nhâm', 'Quý'];
  static final _chi = ['Tý', 'Sửu', 'Dần', 'Mão', 'Thìn', 'Tỵ', 'Ngọ', 'Mùi', 'Thân', 'Dậu', 'Tuất', 'Hợi'];
  static final weekdays = ['Chủ Nhật', 'Thứ Hai', 'Thứ Ba', 'Thứ Tư', 'Thứ Năm', 'Thứ Sáu', 'Thứ Bảy'];

  static final _gioChi = [
    ['Tý', '23:00 – 01:00'], ['Sửu', '01:00 – 03:00'], ['Dần', '03:00 – 05:00'],
    ['Mão', '05:00 – 07:00'], ['Thìn', '07:00 – 09:00'], ['Tỵ', '09:00 – 11:00'],
    ['Ngọ', '11:00 – 13:00'], ['Mùi', '13:00 – 15:00'], ['Thân', '15:00 – 17:00'],
    ['Dậu', '17:00 – 19:00'], ['Tuất', '19:00 – 21:00'], ['Hợi', '21:00 – 23:00'],
  ];

  static final _gioHD = {
    'Tý': ['Tý', 'Sửu', 'Mão', 'Ngọ', 'Thân', 'Dậu'],
    'Ngọ': ['Tý', 'Sửu', 'Mão', 'Ngọ', 'Thân', 'Dậu'],
    'Sửu': ['Dần', 'Mão', 'Tỵ', 'Thân', 'Tuất', 'Hợi'],
    'Mùi': ['Dần', 'Mão', 'Tỵ', 'Thân', 'Tuất', 'Hợi'],
    'Dần': ['Tý', 'Sửu', 'Thìn', 'Tỵ', 'Mùi', 'Tuất'],
    'Thân': ['Tý', 'Sửu', 'Thìn', 'Tỵ', 'Mùi', 'Tuất'],
    'Mão': ['Tý', 'Dần', 'Mão', 'Ngọ', 'Mùi', 'Dậu'],
    'Dậu': ['Tý', 'Dần', 'Mão', 'Ngọ', 'Mùi', 'Dậu'],
    'Thìn': ['Dần', 'Thìn', 'Tỵ', 'Thân', 'Dậu', 'Hợi'],
    'Tuất': ['Dần', 'Thìn', 'Tỵ', 'Thân', 'Dậu', 'Hợi'],
    'Tỵ': ['Sửu', 'Thìn', 'Ngọ', 'Mùi', 'Tuất', 'Hợi'],
    'Hợi': ['Sửu', 'Thìn', 'Ngọ', 'Mùi', 'Tuất', 'Hợi'],
  };

  static final _ngayHD = {
    1: ['Tý', 'Sửu', 'Thìn', 'Tỵ', 'Mùi', 'Tuất'],
    7: ['Tý', 'Sửu', 'Thìn', 'Tỵ', 'Mùi', 'Tuất'],
    2: ['Dần', 'Mão', 'Ngọ', 'Mùi', 'Dậu', 'Tý'],
    8: ['Dần', 'Mão', 'Ngọ', 'Mùi', 'Dậu', 'Tý'],
    3: ['Thìn', 'Tỵ', 'Thân', 'Dậu', 'Hợi', 'Dần'],
    9: ['Thìn', 'Tỵ', 'Thân', 'Dậu', 'Hợi', 'Dần'],
    4: ['Ngọ', 'Mùi', 'Tuất', 'Hợi', 'Sửu', 'Thìn'],
    10: ['Ngọ', 'Mùi', 'Tuất', 'Hợi', 'Sửu', 'Thìn'],
    5: ['Thân', 'Dậu', 'Tý', 'Sửu', 'Mão', 'Ngọ'],
    11: ['Thân', 'Dậu', 'Tý', 'Sửu', 'Mão', 'Ngọ'],
    6: ['Tuất', 'Hợi', 'Dần', 'Mão', 'Tỵ', 'Thân'],
    12: ['Tuất', 'Hợi', 'Dần', 'Mão', 'Tỵ', 'Thân'],
  };

  static final _tietKhi = [
    'Xuân phân', 'Thanh minh', 'Cốc vũ', 'Lập hạ', 'Tiểu mãn', 'Mang chủng',
    'Hạ chí', 'Tiểu thử', 'Đại thử', 'Lập thu', 'Xử thử', 'Bạch lộ',
    'Thu phân', 'Hàn lộ', 'Sương giáng', 'Lập đông', 'Tiểu tuyết', 'Đại tuyết',
    'Đông chí', 'Tiểu hàn', 'Đại hàn', 'Lập xuân', 'Vũ thuỷ', 'Kinh trập',
  ];

  static final leLon = ['Tết Nguyên Đán', 'Lễ Vu Lan', 'Tết Trung Thu', 'Quốc khánh', 'Giỗ tổ Hùng Vương'];

  static final _leDuong = {
    '1-1': 'Tết Dương lịch', '2-14': 'Valentine', '3-8': 'Quốc tế Phụ nữ',
    '4-30': 'Giải phóng miền Nam', '5-1': 'Quốc tế Lao động', '6-1': 'Quốc tế Thiếu nhi',
    '9-2': 'Quốc khánh', '10-20': 'Phụ nữ Việt Nam', '11-20': 'Nhà giáo Việt Nam',
    '12-24': 'Giáng sinh', '12-25': 'Giáng sinh',
  };

  static final _leAm = {
    '1-1': 'Tết Nguyên Đán', '1-2': 'Mùng 2 Tết', '1-3': 'Mùng 3 Tết',
    '1-15': 'Tết Nguyên Tiêu', '3-3': 'Tết Hàn thực', '3-10': 'Giỗ tổ Hùng Vương',
    '5-5': 'Tết Đoan Ngọ', '7-15': 'Lễ Vu Lan', '8-15': 'Tết Trung Thu',
    '9-9': 'Tết Trùng Cửu', '12-23': 'Ông Công Ông Táo',
  };

  static int _jdFromDate(int dd, int mm, int yy) {
    final a = ((14 - mm) / 12).floor();
    final y = yy + 4800 - a;
    final m = mm + 12 * a - 3;
    int jd = dd + ((153 * m + 2) / 5).floor() + 365 * y + (y / 4).floor() - (y / 100).floor() + (y / 400).floor() - 32045;
    if (jd < 2299161) {
      jd = dd + ((153 * m + 2) / 5).floor() + 365 * y + (y / 4).floor() - 32083;
    }
    return jd;
  }

  static double _newMoon(int k) {
    final T = k / 1236.85;
    final T2 = T * T;
    final T3 = T2 * T;
    final dr = math.pi / 180;
    double Jd1 = 2415020.75933 + 29.53058868 * k + 0.0001178 * T2 - 0.000000155 * T3;
    Jd1 += 0.00033 * math.sin((166.56 + 132.87 * T - 0.009173 * T2) * dr);
    final M = 359.2242 + 29.10535608 * k - 0.0000333 * T2 - 0.00000347 * T3;
    final Mpr = 306.0253 + 385.81691806 * k + 0.0107306 * T2 + 0.00001236 * T3;
    final F = 21.2964 + 390.67050646 * k - 0.0016528 * T2 - 0.00000239 * T3;
    double C1 = (0.1734 - 0.000393 * T) * math.sin(M * dr) + 0.0021 * math.sin(2 * dr * M);
    C1 = C1 - 0.4068 * math.sin(Mpr * dr) + 0.0161 * math.sin(dr * 2 * Mpr);
    C1 = C1 - 0.0004 * math.sin(dr * 3 * Mpr);
    C1 = C1 + 0.0104 * math.sin(dr * 2 * F) - 0.0051 * math.sin(dr * (M + Mpr));
    C1 = C1 - 0.0074 * math.sin(dr * (M - Mpr)) + 0.0004 * math.sin(dr * (2 * F + M));
    C1 = C1 - 0.0004 * math.sin(dr * (2 * F - M)) - 0.0006 * math.sin(dr * (2 * F + Mpr));
    C1 = C1 + 0.001 * math.sin(dr * (2 * F - Mpr)) + 0.0005 * math.sin(dr * (2 * Mpr + M));
    double deltat;
    if (T < -11) {
      deltat = 0.001 + 0.000839 * T + 0.0002261 * T2 - 0.00000845 * T3 - 0.000000081 * T * T3;
    } else {
      deltat = -0.000278 + 0.000265 * T + 0.000262 * T2;
    }
    return Jd1 + C1 - deltat;
  }

  static double _sunLongitudeDeg(double jdn) {
    final T = (jdn - 2451545.5 - _tz / 24) / 36525;
    final T2 = T * T;
    final dr = math.pi / 180;
    final M = 357.5291 + 35999.0503 * T - 0.0001559 * T2 - 0.00000048 * T * T2;
    final L0 = 280.46645 + 36000.76983 * T + 0.0003032 * T2;
    double DL = (1.9146 - 0.004817 * T - 0.000014 * T2) * math.sin(dr * M);
    DL += (0.019993 - 0.000101 * T) * math.sin(dr * 2 * M) + 0.00029 * math.sin(dr * 3 * M);
    double L = (L0 + DL) % 360;
    if (L < 0) L += 360;
    return L;
  }

  static int _sunLongitude(double jdn) => (_sunLongitudeDeg(jdn) / 30).floor();

  static int _getNewMoonDay(int k) => (_newMoon(k) + 0.5 + _tz / 24).floor();

  static int _lunarMonth11(int yy) {
    final off = _jdFromDate(31, 12, yy) - 2415021;
    final k = (off / 29.530588853).floor();
    int nm = _getNewMoonDay(k);
    if (_sunLongitude(nm.toDouble()) >= 9) nm = _getNewMoonDay(k - 1);
    return nm;
  }

  static int _leapMonthOffset(int a11) {
    final k = ((a11 - 2415021.076998695) / 29.530588853 + 0.5).floor();
    int last = 0, i = 1;
    int arc = _sunLongitude(_getNewMoonDay(k + i).toDouble());
    do {
      last = arc;
      i++;
      arc = _sunLongitude(_getNewMoonDay(k + i).toDouble());
    } while (arc != last && i < 14);
    return i - 1;
  }

  static LunarDate solar2lunar(int dd, int mm, int yy) {
    final dayNumber = _jdFromDate(dd, mm, yy);
    final k = ((dayNumber - 2415021.076998695) / 29.530588853).floor();
    int monthStart = _getNewMoonDay(k + 1);
    if (monthStart > dayNumber) monthStart = _getNewMoonDay(k);
    int a11 = _lunarMonth11(yy), b11 = a11;
    int lunarYear;
    if (a11 >= monthStart) {
      lunarYear = yy;
      a11 = _lunarMonth11(yy - 1);
    } else {
      lunarYear = yy + 1;
      b11 = _lunarMonth11(yy + 1);
    }
    final lunarDay = dayNumber - monthStart + 1;
    final diff = ((monthStart - a11) / 29).floor();
    int lunarLeap = 0, lunarMonth = diff + 11;
    if (b11 - a11 > 365) {
      final lo = _leapMonthOffset(a11);
      if (diff >= lo) {
        lunarMonth = diff + 10;
        if (diff == lo) lunarLeap = 1;
      }
    }
    if (lunarMonth > 12) lunarMonth -= 12;
    if (lunarMonth >= 11 && diff < 4) lunarYear -= 1;
    return LunarDate(day: lunarDay, month: lunarMonth, year: lunarYear, isLeap: lunarLeap == 1, jd: dayNumber);
  }

  static CanChi canChi(LunarDate al) {
    final jd = al.jd;
    return CanChi(
      day: '${_can[(jd + 9) % 10]} ${_chi[(jd + 1) % 12]}',
      chiDay: _chi[(jd + 1) % 12],
      month: '${_can[(al.year * 12 + al.month + 3) % 10]} ${_chi[(al.month + 1) % 12]}',
      year: '${_can[(al.year + 6) % 10]} ${_chi[(al.year + 8) % 12]}',
      chiYear: _chi[(al.year + 8) % 12],
    );
  }

  static String tietKhi(int jd) {
    final deg = _sunLongitudeDeg(jd.toDouble());
    return _tietKhi[(deg / 15).floor() % 24];
  }

  static List<GioHoangDao> gioHoangDao(String chiNgay) {
    final tot = _gioHD[chiNgay] ?? [];
    return _gioChi
        .where((g) => tot.contains(g[0]))
        .map((g) => GioHoangDao(g[0], g[1]))
        .toList();
  }

  static bool ngayTot(int thangAm, String chiNgay) {
    final list = _ngayHD[thangAm] ?? [];
    return list.contains(chiNgay);
  }

  static List<HolidayEntry> holidays(DateTime d, LunarDate al) {
    final out = <HolidayEntry>[];
    final duongKey = '${d.month}-${d.day}';
    if (_leDuong.containsKey(duongKey)) {
      out.add(HolidayEntry(_leDuong[duongKey]!, 'duong'));
    }
    final amKey = '${al.month}-${al.day}';
    if (_leAm.containsKey(amKey) && !al.isLeap) {
      out.add(HolidayEntry(_leAm[amKey]!, 'am'));
    }
    return out;
  }
}
