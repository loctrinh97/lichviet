import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/lunar_calendar.dart';
import '../../services/astrology.dart';
import '../../viewmodel/app_view_model.dart';
import '../app_colors_ext.dart';

class AstrologyTab extends ConsumerWidget {
  const AstrologyTab({super.key, required this.theme});
  final LvTheme theme;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appViewModelProvider);
    final vm = ref.read(appViewModelProvider.notifier);
    final t = theme;

    final ps = state.profile;
    final today = DateTime.now();
    final alToday = LunarCalendar.solar2lunar(today.day, today.month, today.year);
    final ccToday = LunarCalendar.canChi(alToday);
    final totHomNay = LunarCalendar.ngayTot(alToday.month, ccToday.chiDay);

    // Parse birth date safely
    final bpRaw = ps.birthDate;
    final bpParts = bpRaw.isNotEmpty
        ? bpRaw.split('-').map(int.tryParse).toList()
        : <int?>[];
    final hasBirth = bpParts.length == 3 && bpParts.every((v) => v != null);

    if (!hasBirth) {
      return _NoBirthView(theme: t, alToday: alToday, ccToday: ccToday, totHomNay: totHomNay, vm: vm);
    }

    final alSinh = LunarCalendar.solar2lunar(bpParts[2]!, bpParts[1]!, bpParts[0]!);
    final ccSinh = LunarCalendar.canChi(alSinh);
    final cg = AstrologyContent.conGiap[ccSinh.chiYear] ?? AstrologyContent.conGiap['Tý']!;
    final qh = AstrologyContent.quanHe(ccSinh.chiYear, ccToday.chiDay);
    final luan = AstrologyContent.homNay[qh]!;
    final na = AstrologyContent.napAm(alSinh.year);
    final hk = AstrologyContent.hopKhac(ccSinh.chiYear);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('TỬ VI HÔM NAY', style: TextStyle(fontSize: 12, letterSpacing: 1.2, color: t.muted)),
          const SizedBox(height: 5),
          Text('${cg.name} · ${ccSinh.year}',
              style: TextStyle(fontWeight: FontWeight.w500, fontSize: 26, letterSpacing: -0.5, color: t.text)),
          const SizedBox(height: 4),
          Text('Mệnh ${na.name} (${na.hanh}) · sao chiếu ${cg.sao}',
              style: TextStyle(fontSize: 13.5, color: t.muted)),

          const SizedBox(height: 16),

          // Main reading card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: t.surface,
              borderRadius: BorderRadius.circular(LvColors.radiusLg),
              border: Border.all(color: t.divider),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text('Ngày ${ccToday.day} · ${alToday.day}/${alToday.month} âm lịch',
                          style: TextStyle(fontSize: 12.5, color: t.muted)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(9999),
                        border: Border.all(color: t.accent),
                      ),
                      child: Text(luan.diem,
                          style: TextStyle(fontWeight: FontWeight.w500, fontSize: 12, color: t.accent)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(luan.ngan, style: TextStyle(fontSize: 14.5, height: 1.6, color: t.text)),

                if (state.tvOpen) ...[
                  const SizedBox(height: 16),
                  Divider(color: t.divider, height: 1),
                  const SizedBox(height: 16),
                  ...luan.dai.map((p) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(p, style: TextStyle(fontSize: 13.5, height: 1.68, color: LvColors.neutral300)),
                  )),
                  Text(na.luan, style: TextStyle(fontSize: 13.5, height: 1.68, color: LvColors.neutral300)),
                ],

                const SizedBox(height: 16),
                GestureDetector(
                  onTap: vm.toggleTuVi,
                  child: Container(
                    width: double.infinity, height: 38,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(LvColors.radiusMd),
                      border: Border.all(color: t.accent),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      state.tvOpen ? 'Thu gọn' : 'Xem phân tích chi tiết',
                      style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13.5, color: t.accent),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Info cards grid
          GridView.count(
            crossAxisCount: 2, shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 8, mainAxisSpacing: 8,
            childAspectRatio: 1.8,
            children: [
              _InfoCard(label: 'NGÀY HÔM NAY', value: totHomNay ? 'Hoàng đạo' : 'Hắc đạo',
                  sub: 'Tháng ${alToday.month} âm · chi ${ccToday.chiDay}',
                  icon: Icons.wb_twilight, theme: t),
              _InfoCard(label: 'TUỔI HỢP', value: hk.hop.join(', '),
                  sub: 'Tam hợp với ${ccSinh.chiYear}',
                  icon: Icons.handshake, theme: t),
              _InfoCard(label: 'TUỔI KHẮC', value: hk.khac.join(', '),
                  sub: 'Tứ hành xung', icon: Icons.warning_amber, theme: t),
              _InfoCard(label: 'HƯỚNG TỐT', value: cg.huong.join(' · '),
                  sub: 'Xuất hành, kê bàn làm việc', icon: Icons.explore, theme: t),
            ],
          ),

          const SizedBox(height: 16),
          // Row(
          //   crossAxisAlignment: CrossAxisAlignment.start,
          //   children: [
          //     Icon(Icons.auto_awesome, color: t.dim, size: 14),
          //     const SizedBox(width: 8),
          //     Expanded(
          //       child: Text(
          //         'Luận giải lấy từ kho nội dung tĩnh trong app, chạy offline. Phân tích AI: tuỳ chọn, cấu hình sau.',
          //         style: TextStyle(fontSize: 12, height: 1.6, color: t.dim),
          //       ),
          //     ),
          //   ],
          // ),
        ],
      ),
    );
  }
}

class _NoBirthView extends StatelessWidget {
  const _NoBirthView({
    required this.theme, required this.alToday, required this.ccToday,
    required this.totHomNay, required this.vm,
  });
  final LvTheme theme;
  final LunarDate alToday;
  final CanChi ccToday;
  final bool totHomNay;
  final AppViewModel vm;

  @override
  Widget build(BuildContext context) {
    final t = theme;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('TỬ VI HÔM NAY', style: TextStyle(fontSize: 12, letterSpacing: 1.2, color: t.muted)),
          const SizedBox(height: 16),

          // Ngày hôm nay — không cần thông tin cá nhân
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: t.surface,
              borderRadius: BorderRadius.circular(LvColors.radiusLg),
              border: Border.all(color: t.divider),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Hôm nay · ${alToday.day}/${alToday.month} âm lịch',
                    style: TextStyle(fontSize: 13, color: t.muted)),
                const SizedBox(height: 8),
                Text(ccToday.day,
                    style: TextStyle(fontWeight: FontWeight.w500, fontSize: 24,
                        letterSpacing: -0.5, color: t.text)),
                const SizedBox(height: 4),
                Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(9999),
                      border: Border.all(
                          color: totHomNay ? LvColors.event : t.divider),
                      color: totHomNay
                          ? LvColors.event.withValues(alpha: 0.1)
                          : Colors.transparent,
                    ),
                    child: Text(
                      totHomNay ? 'Hoàng đạo' : 'Hắc đạo',
                      style: TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w500,
                          color: totHomNay ? LvColors.event : t.muted),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('Chi ${ccToday.chiDay} · Tháng ${alToday.month} âm',
                      style: TextStyle(fontSize: 12, color: t.muted)),
                ]),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // CTA nhắc điền thông tin
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(LvColors.radiusLg),
              border: Border.all(color: t.accent.withValues(alpha: 0.4)),
              color: t.accent.withValues(alpha: 0.06),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Icon(Icons.person_outline, color: t.accent, size: 18),
                  const SizedBox(width: 8),
                  Text('Thêm thông tin cá nhân',
                      style: TextStyle(fontWeight: FontWeight.w500,
                          fontSize: 15, color: t.text)),
                ]),
                const SizedBox(height: 8),
                Text(
                  'Điền ngày sinh để xem con giáp, mệnh, luận giải tử vi theo ngày và các thông tin phong thuỷ cá nhân.',
                  style: TextStyle(fontSize: 13, height: 1.6, color: t.muted),
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () => vm.replayOb(),
                  child: Container(
                    width: double.infinity, height: 42,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(LvColors.radiusMd),
                      border: Border.all(color: t.accent),
                      color: t.accent.withValues(alpha: 0.12),
                    ),
                    alignment: Alignment.center,
                    child: Text('Điền thông tin ngay',
                        style: TextStyle(fontWeight: FontWeight.w500,
                            fontSize: 14, color: t.accent)),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(Icons.lock_outline, size: 13, color: t.dim),
            const SizedBox(width: 6),
            Expanded(child: Text(
              'Mọi thông tin lưu trên máy bạn, không gửi đi đâu.',
              style: TextStyle(fontSize: 12, height: 1.6, color: t.dim),
            )),
          ]),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.label, required this.value, required this.sub,
    required this.icon, required this.theme,
  });
  final String label, value, sub;
  final IconData icon;
  final LvTheme theme;

  @override
  Widget build(BuildContext context) {
    final t = theme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(LvColors.radiusMd),
        border: Border.all(color: t.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, color: t.muted, size: 13),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(fontSize: 12, letterSpacing: 0.8, color: t.muted)),
          ]),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16, color: t.text)),
          const SizedBox(height: 3),
          Text(sub, style: TextStyle(fontSize: 12, color: t.dim), overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}
