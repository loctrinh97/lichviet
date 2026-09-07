class AstrologyContent {
  static const _chi = ['Tý', 'Sửu', 'Dần', 'Mão', 'Thìn', 'Tỵ', 'Ngọ', 'Mùi', 'Thân', 'Dậu', 'Tuất', 'Hợi'];

  static const _tamHop = [
    ['Tý', 'Thân', 'Thìn'],
    ['Sửu', 'Tỵ', 'Dậu'],
    ['Dần', 'Ngọ', 'Tuất'],
    ['Mão', 'Mùi', 'Hợi'],
  ];

  static const _tuHanhXung = [
    ['Tý', 'Ngọ', 'Mão', 'Dậu'],
    ['Dần', 'Thân', 'Tỵ', 'Hợi'],
    ['Thìn', 'Tuất', 'Sửu', 'Mùi'],
  ];

  static final conGiap = {
    'Tý': ConGiap('Tý (Chuột)', ['Bắc', 'Tây Bắc'], 'Thái Bạch'),
    'Sửu': ConGiap('Sửu (Trâu)', ['Đông Bắc', 'Nam'], 'Thổ Tú'),
    'Dần': ConGiap('Dần (Hổ)', ['Đông', 'Nam'], 'Thái Dương'),
    'Mão': ConGiap('Mão (Mèo)', ['Đông', 'Đông Nam'], 'Vân Hán'),
    'Thìn': ConGiap('Thìn (Rồng)', ['Đông Nam', 'Bắc'], 'Mộc Đức'),
    'Tỵ': ConGiap('Tỵ (Rắn)', ['Nam', 'Đông Nam'], 'La Hầu'),
    'Ngọ': ConGiap('Ngọ (Ngựa)', ['Nam', 'Tây Nam'], 'Thái Âm'),
    'Mùi': ConGiap('Mùi (Dê)', ['Tây Nam', 'Đông'], 'Kế Đô'),
    'Thân': ConGiap('Thân (Khỉ)', ['Tây', 'Tây Bắc'], 'Thuỷ Diệu'),
    'Dậu': ConGiap('Dậu (Gà)', ['Tây', 'Đông Bắc'], 'Thái Bạch'),
    'Tuất': ConGiap('Tuất (Chó)', ['Tây Bắc', 'Đông'], 'Thổ Tú'),
    'Hợi': ConGiap('Hợi (Lợn)', ['Bắc', 'Đông Nam'], 'Thái Dương'),
  };

  static final homNay = {
    'tamhop': TuViHomNay(
      diem: 'Rất tốt',
      ngan: 'Ngày tam hợp với tuổi của bạn. Việc gì đã chuẩn bị sẵn thì hôm nay nên khởi động: giấy tờ, thương lượng, gặp người có thể quyết.',
      dai: [
        'Chi ngày nằm trong tam hợp với chi năm sinh, nên khí ngày và khí tuổi cùng chiều. Trong ngày kiểu này, việc cần người khác đồng ý thường trôi hơn bình thường — ký kết, xin phê duyệt, hỏi vay, nhờ giới thiệu.',
        'Buổi sáng dành cho việc cần tập trung một mình, đầu giờ chiều dành cho gặp gỡ. Nếu phải chọn giữa hai việc, chọn việc có người thứ ba tham gia: hôm nay bạn được trợ lực từ quan hệ nhiều hơn từ sức mình.',
        'Điểm cần giữ: đừng nhận thêm việc chỉ vì mọi thứ đang dễ. Ngày thuận dễ dẫn tới cam kết quá tay, và phần trả giá rơi vào tuần sau.',
      ],
    ),
    'xung': TuViHomNay(
      diem: 'Cần cẩn trọng',
      ngan: 'Chi ngày xung với tuổi. Không phải ngày xấu toàn diện, nhưng nên lùi các quyết định lớn và tránh tranh luận thắng thua.',
      dai: [
        'Chi ngày và chi năm sinh cùng nằm trong một bộ tứ hành xung, vì vậy nhịp ngày dễ lệch khỏi nhịp của bạn. Biểu hiện thường thấy là việc bị đổi giờ, người hẹn đến muộn, thông tin đến thiếu một nửa.',
        'Cách dùng ngày này: làm việc dọn dẹp và kiểm tra thay vì việc mở đầu. Rà lại hợp đồng, đối chiếu số liệu, sửa lỗi cũ. Những việc đó hôm nay cho kết quả tốt bất ngờ vì bạn nhìn ra chỗ hỏng nhanh hơn.',
        'Tránh: mua tài sản lớn, đổi việc, nói lời dứt khoát trong lúc nóng. Nếu bắt buộc phải quyết, viết ra ba lý do rồi để qua một đêm.',
      ],
    ),
    'thuan': TuViHomNay(
      diem: 'Khá tốt',
      ngan: 'Ngày trung hoà, nghiêng về thuận. Việc thường ngày chạy đều; thích hợp để đẩy một việc dở dang về đích.',
      dai: [
        'Không có quan hệ xung hay tam hợp rõ giữa chi ngày và chi tuổi, nên ngày này lấy sức mình làm chính. Đây là ngày của việc dở dang: thứ đã làm 70% thì hôm nay đủ khí để đóng lại.',
        'Giờ hoàng đạo trong ngày nên dành cho một việc duy nhất, không chia nhỏ. Người tuổi này thường được lợi khi làm việc theo thứ tự cố định chứ không nhảy giữa các đầu việc.',
        'Về tiền: chi tiêu đã dự tính thì cứ tiến hành, khoản phát sinh thì để sang ngày khác xem lại.',
      ],
    ),
    'binh': TuViHomNay(
      diem: 'Bình hoà',
      ngan: 'Ngày bình. Nên giữ nhịp cũ, không cần cố thay đổi gì; sức khoẻ và giấc ngủ đáng để ưu tiên hơn công việc.',
      dai: [
        'Khí ngày không hỗ trợ cũng không cản tuổi bạn. Ngày như vậy thích hợp cho việc duy trì: học thêm, tập luyện, chăm sóc quan hệ gia đình, sắp xếp lại chỗ ở.',
        'Nếu trong tuần bạn có một việc lớn, hôm nay là ngày chuẩn bị tài liệu cho việc đó chứ không phải ngày thực hiện.',
        'Điều nên tránh duy nhất: hứa hẹn về thời hạn. Ngày bình hoà làm người ta lạc quan quá mức về tốc độ của chính mình.',
      ],
    ),
  };

  static final _napAm = [
    'Hải Trung Kim', 'Lư Trung Hoả', 'Đại Lâm Mộc', 'Lộ Bàng Thổ', 'Kiếm Phong Kim',
    'Sơn Đầu Hoả', 'Giản Hạ Thuỷ', 'Thành Đầu Thổ', 'Bạch Lạp Kim', 'Dương Liễu Mộc',
    'Tuyền Trung Thuỷ', 'Ốc Thượng Thổ', 'Tích Lịch Hoả', 'Tùng Bách Mộc', 'Trường Lưu Thuỷ',
    'Sa Trung Kim', 'Sơn Hạ Hoả', 'Bình Địa Mộc', 'Bích Thượng Thổ', 'Kim Bạch Kim',
    'Phú Đăng Hoả', 'Thiên Hà Thuỷ', 'Đại Trạch Thổ', 'Thoa Xuyến Kim', 'Tang Đố Mộc',
    'Đại Khê Thuỷ', 'Sa Trung Thổ', 'Thiên Thượng Hoả', 'Thạch Lựu Mộc', 'Đại Hải Thuỷ',
  ];

  static final _nguHanhLuan = {
    'Kim': 'Mệnh Kim: quyết đoán, coi trọng nguyên tắc và chữ tín. Hợp việc có khuôn khổ rõ ràng; nên bù thêm phần mềm dẻo trong giao tiếp.',
    'Mộc': 'Mệnh Mộc: cầu tiến, thích học và mở rộng. Hợp việc phát triển dài hạn; cần giữ sức, tránh dàn trải quá nhiều hướng cùng lúc.',
    'Thuỷ': 'Mệnh Thuỷ: linh hoạt, giỏi thích ứng và kết nối. Hợp việc di chuyển, thương lượng; nên đặt mốc cố định để không trôi theo hoàn cảnh.',
    'Hoả': 'Mệnh Hoả: nhiệt, nhanh, có sức thuyết phục. Hợp việc mở đầu và dẫn dắt; cần một người điềm tĩnh bên cạnh để giữ nhịp.',
    'Thổ': 'Mệnh Thổ: bền, đáng tin, làm gì cũng có nền. Hợp việc quản lý, tích lũy; nên chủ động thay đổi trước khi bị hoàn cảnh buộc đổi.',
  };

  static String quanHe(String chiTuoi, String chiNgay) {
    if (chiTuoi == chiNgay) return 'thuan';
    if (_tamHop.any((g) => g.contains(chiTuoi) && g.contains(chiNgay))) return 'tamhop';
    final bo = _tuHanhXung.where((g) => g.contains(chiTuoi)).toList();
    if (bo.isNotEmpty && bo.first.contains(chiNgay)) return 'xung';
    final iT = _chi.indexOf(chiTuoi);
    final iN = _chi.indexOf(chiNgay);
    return (iT + iN) % 2 == 0 ? 'thuan' : 'binh';
  }

  static NapAm napAm(int namAmLich) {
    final idx = ((namAmLich - 4) % 60 + 60) % 60;
    final ten = _napAm[(idx / 2).floor()];
    String hanh;
    if (ten.contains('Kim')) hanh = 'Kim';
    else if (ten.contains('Mộc')) hanh = 'Mộc';
    else if (ten.contains('Thuỷ')) hanh = 'Thuỷ';
    else if (ten.contains('Hoả')) hanh = 'Hoả';
    else hanh = 'Thổ';
    return NapAm(ten, hanh, _nguHanhLuan[hanh] ?? '');
  }

  static HopKhac hopKhac(String chiTuoi) {
    final hopGroup = _tamHop.where((g) => g.contains(chiTuoi)).toList();
    final hop = hopGroup.isEmpty ? <String>[] : hopGroup.first.where((c) => c != chiTuoi).toList();
    final khacGroup = _tuHanhXung.where((g) => g.contains(chiTuoi)).toList();
    final khac = khacGroup.isEmpty ? <String>[] : khacGroup.first.where((c) => c != chiTuoi).toList();
    return HopKhac(hop, khac);
  }
}

class ConGiap {
  final String name;
  final List<String> huong;
  final String sao;
  const ConGiap(this.name, this.huong, this.sao);
}

class TuViHomNay {
  final String diem;
  final String ngan;
  final List<String> dai;
  const TuViHomNay({required this.diem, required this.ngan, required this.dai});
}

class NapAm {
  final String name;
  final String hanh;
  final String luan;
  const NapAm(this.name, this.hanh, this.luan);
}

class HopKhac {
  final List<String> hop;
  final List<String> khac;
  const HopKhac(this.hop, this.khac);
}
