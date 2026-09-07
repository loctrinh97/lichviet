import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/lunar_calendar.dart';
import '../../services/astrology.dart';
import '../../state/app_state.dart';
import '../../viewmodel/app_view_model.dart';
import '../app_colors_ext.dart';

class ProfileTab extends ConsumerWidget {
  const ProfileTab({super.key, required this.theme});
  final LvTheme theme;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appViewModelProvider);
    final vm = ref.read(appViewModelProvider.notifier);
    final t = theme;

    // Compute summary
    final ps = state.profile;
    final bpParts = ps.birthDate.split('-').map(int.parse).toList();
    final alSinh = bpParts.length == 3
        ? LunarCalendar.solar2lunar(bpParts[2], bpParts[1], bpParts[0])
        : LunarCalendar.solar2lunar(12, 8, 1994);
    final ccSinh = LunarCalendar.canChi(alSinh);
    final cg = AstrologyContent.conGiap[ccSinh.chiYear] ?? AstrologyContent.conGiap['Tý']!;
    final na = AstrologyContent.napAm(alSinh.year);
    final summary = 'Dùng để tính can chi và tử vi: ${alSinh.day}/${alSinh.month} âm lịch năm ${ccSinh.year} · ${cg.name} · mệnh ${na.hanh}.';

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Cá nhân',
              style: TextStyle(fontWeight: FontWeight.w500, fontSize: 26, letterSpacing: -0.5, color: t.text)),
          const SizedBox(height: 4),
          Text('Hồ sơ lưu trên máy bạn. Không có tài khoản đăng nhập.',
              style: TextStyle(fontSize: 12.5, color: t.muted)),

          const SizedBox(height: 24),
          _sectionLabel('HỒ SƠ', t),
          const SizedBox(height: 12),

          _fieldLabel('Tên', t),
          _inputField(ps.name, (v) => vm.setName(v), t),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _fieldLabel('Ngày sinh', t),
                  _inputField(ps.birthDate, (v) => vm.setBirthDate(v), t),
                ],
              )),
              const SizedBox(width: 8),
              SizedBox(width: 104, child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _fieldLabel('Giờ sinh', t),
                  _inputField(ps.birthTime, (v) => vm.setBirthTime(v), t),
                ],
              )),
            ],
          ),
          const SizedBox(height: 12),

          _fieldLabel('Giới tính', t),
          _SegmentedPicker(
            options: const ['Nam', 'Nữ', 'Khác'],
            selected: ps.gender,
            onSelect: vm.setGender,
            theme: t,
          ),
          const SizedBox(height: 8),
          Text(summary, style: TextStyle(fontSize: 12, height: 1.6, color: t.dim)),

          const SizedBox(height: 24),
          _sectionLabel('CÀI ĐẶT', t),
          const SizedBox(height: 12),

          _settingRow('Chế độ hiển thị', t,
            trailing: _SegmentedPicker(
              options: const ['Tối', 'Sáng'],
              selected: state.theme == 'dark' ? 'Tối' : 'Sáng',
              onSelect: (v) => vm.setTheme(v == 'Tối' ? 'dark' : 'light'),
              theme: t, compact: true,
            ),
          ),
          const SizedBox(height: 12),
          _settingRow('Ngôn ngữ', t, trailing: Text('Tiếng Việt', style: TextStyle(fontSize: 13.5, color: t.muted))),
          const SizedBox(height: 12),
          _settingRow('Thành phố mặc định', t,
            trailing: Text(state.city?.name ?? 'Hà Nội', style: TextStyle(fontSize: 13.5, color: t.muted))),

          const SizedBox(height: 24),
          _sectionLabel('DỮ LIỆU', t),
          const SizedBox(height: 12),

          // Drop zone (simulated)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(LvColors.radiusLg),
              border: Border.all(
                color: state.dropOver ? t.accent : t.divider,
                style: BorderStyle.solid,
              ),
              color: state.dropOver ? t.accent.withOpacity(0.10) : Colors.transparent,
            ),
            child: Column(
              children: [
                Icon(Icons.download_rounded, color: LvColors.accent400, size: 22),
                const SizedBox(height: 8),
                Text('Kéo-thả file .ics vào đây', style: TextStyle(fontSize: 13.5, color: t.text)),
                const SizedBox(height: 3),
                Text(state.importMsg, style: TextStyle(fontSize: 11.5, color: t.dim)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _outlineBtn('Xuất .ics', t, () {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(vm.buildIcsContent().substring(0, 50) + '…'),
                  backgroundColor: t.surface,
                ));
              })),
              const SizedBox(width: 8),
              Expanded(child: _outlineBtn('Xuất JSON', t, () {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: const Text('JSON đã tạo (xem console)'),
                  backgroundColor: t.surface,
                ));
              })),
            ],
          ),

          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(LvColors.radiusLg),
              border: Border.all(color: t.divider),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Icon(Icons.cloud_upload, color: LvColors.accent400, size: 17),
                  const SizedBox(width: 8),
                  Text('Đồng bộ với Google Drive', style: TextStyle(fontSize: 14, color: t.text)),
                ]),
                const SizedBox(height: 6),
                Text(
                  'Chỉ hiện đăng nhập Google khi bạn bấm. Dữ liệu mới hơn sẽ được ưu tiên, đồng bộ thủ công và một lần khi mở app.',
                  style: TextStyle(fontSize: 12, height: 1.6, color: t.muted),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: vm.doSync,
                  child: Consumer(builder: (ctx, ref2, _) {
                    final s = ref2.watch(appViewModelProvider).syncState;
                    final isDone = s == SyncState.done;
                    return Container(
                      width: double.infinity, height: 38,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(LvColors.radiusMd),
                        border: Border.all(color: isDone ? t.divider : t.accent),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        s == SyncState.idle
                            ? 'Kết nối Google Drive'
                            : s == SyncState.running
                                ? 'Đang đồng bộ…'
                                : 'Đồng bộ lại',
                        style: TextStyle(
                          fontWeight: FontWeight.w500, fontSize: 13.5,
                          color: isDone ? t.text : t.accent,
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 8),
                Consumer(builder: (ctx, ref2, _) {
                  final msg = ref2.watch(appViewModelProvider).syncMsg;
                  return Text(msg, style: TextStyle(fontSize: 11.5, color: t.dim));
                }),
              ],
            ),
          ),

          const SizedBox(height: 16),
          Text(
            'Dữ liệu luôn được lưu trên máy. Google Drive chỉ chạy khi bạn kích hoạt — app đầy đủ chức năng khi chưa cấu hình hoặc đang offline.',
            style: TextStyle(fontSize: 11.5, height: 1.65, color: t.dim),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String label, LvTheme t) =>
      Text(label, style: TextStyle(fontSize: 11, letterSpacing: 1.2, color: t.muted));

  Widget _fieldLabel(String label, LvTheme t) =>
      Padding(padding: const EdgeInsets.only(bottom: 5),
          child: Text(label, style: TextStyle(fontSize: 12, color: t.muted)));

  Widget _inputField(String value, ValueChanged<String> onChange, LvTheme t) {
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 11),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(LvColors.radiusMd),
        border: Border.all(color: t.divider),
      ),
      child: TextFormField(
        initialValue: value,
        onChanged: onChange,
        decoration: const InputDecoration(border: InputBorder.none, isDense: true),
        style: TextStyle(fontSize: 14, color: t.text),
      ),
    );
  }

  Widget _settingRow(String label, LvTheme t, {required Widget trailing}) {
    return Row(
      children: [
        Expanded(child: Text(label, style: TextStyle(fontSize: 14, color: t.text))),
        trailing,
      ],
    );
  }

  Widget _outlineBtn(String label, LvTheme t, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 38,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(LvColors.radiusMd),
          border: Border.all(color: t.divider),
        ),
        alignment: Alignment.center,
        child: Text(label, style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13, color: t.text)),
      ),
    );
  }
}

class _SegmentedPicker extends StatelessWidget {
  const _SegmentedPicker({
    required this.options, required this.selected, required this.onSelect,
    required this.theme, this.compact = false,
  });
  final List<String> options;
  final String selected;
  final ValueChanged<String> onSelect;
  final LvTheme theme;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final t = theme;
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(LvColors.radiusMd),
        border: Border.all(color: t.divider),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: options.map((g) {
          final on = selected == g;
          return GestureDetector(
            onTap: () => onSelect(g),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              width: compact ? 56 : null,
              padding: compact
                  ? const EdgeInsets.symmetric(vertical: 5)
                  : const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(LvColors.radiusSm),
                color: on ? t.accent.withOpacity(0.18) : Colors.transparent,
              ),
              alignment: Alignment.center,
              child: Text(g,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 12.5,
                      color: on ? t.accent : t.muted)),
            ),
          );
        }).toList(),
      ),
    );
  }
}
