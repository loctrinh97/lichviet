import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../model/event_model.dart';
import '../../services/notification_service.dart';
import '../../services/lunar_calendar.dart';
import '../../services/astrology.dart';
import '../../state/app_state.dart';
import '../../viewmodel/app_view_model.dart' hide TimeOfDay;
import '../app_colors_ext.dart';

class ProfileTab extends ConsumerStatefulWidget {
  const ProfileTab({super.key, required this.theme});
  final LvTheme theme;

  @override
  ConsumerState<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends ConsumerState<ProfileTab> {
  late final TextEditingController _nameCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: ref.read(appViewModelProvider).profile.name);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _awaitKeyboardDismiss(BuildContext context) async {
    if (MediaQuery.of(context).viewInsets.bottom > 0) {
      FocusManager.instance.primaryFocus?.unfocus();
      await Future.delayed(const Duration(milliseconds: 500));
    }
  }

  Future<void> _pickDate(BuildContext context, AppViewModel vm, String current) async {
    await _awaitKeyboardDismiss(context);
    if (!context.mounted) return;
    final parts = current.split('-');
    final initial = parts.length == 3
        ? DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]))
        : DateTime(1994, 8, 12);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (ctx, child) => _themeDialog(ctx, child, widget.theme),
    );
    if (picked != null) {
      vm.setBirthDate(
        '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}',
      );
    }
  }

  Future<void> _pickTime(BuildContext context, AppViewModel vm, String current) async {
    await _awaitKeyboardDismiss(context);
    if (!context.mounted) return;
    final parts = current.split(':');
    final initial = parts.length == 2
        ? TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]))
        : const TimeOfDay(hour: 7, minute: 30);
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      initialEntryMode: TimePickerEntryMode.dialOnly,
      builder: (ctx, child) => _themeDialog(ctx, child, widget.theme),
    );
    if (picked != null) {
      vm.setBirthTime(
        '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}',
      );
    }
  }

  Widget _themeDialog(BuildContext ctx, Widget? child, LvTheme t) {
    return MediaQuery(
      data: MediaQuery.of(ctx).copyWith(viewInsets: EdgeInsets.zero),
      child: Theme(
        data: ThemeData(
          colorScheme: ColorScheme(
            brightness: t.isDark ? Brightness.dark : Brightness.light,
            primary: t.accent,
            onPrimary: Colors.white,
            secondary: t.accent,
            onSecondary: Colors.white,
            surface: t.surface,
            onSurface: t.text,
            error: Colors.red,
            onError: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appViewModelProvider);
    final vm = ref.read(appViewModelProvider.notifier);
    final t = widget.theme;

    // Sync controller khi tên được điền từ Google (chỉ khi controller rỗng)
    if (_nameCtrl.text.isEmpty && state.profile.name.isNotEmpty) {
      _nameCtrl.text = state.profile.name;
    }

    // Compute summary
    final ps = state.profile;
    final bpParts = ps.birthDate.isNotEmpty
        ? ps.birthDate.split('-').map(int.tryParse).toList()
        : <int?>[];
    final hasBirthDate = bpParts.length == 3 && bpParts.every((v) => v != null);
    final alSinh = hasBirthDate
        ? LunarCalendar.solar2lunar(bpParts[2]!, bpParts[1]!, bpParts[0]!)
        : null;
    final ccSinh = alSinh != null ? LunarCalendar.canChi(alSinh) : null;
    final cg = ccSinh != null ? (AstrologyContent.conGiap[ccSinh.chiYear] ?? AstrologyContent.conGiap['Tý']!) : null;
    final na = alSinh != null ? AstrologyContent.napAm(alSinh.year) : null;
    final summary = hasBirthDate && alSinh != null && ccSinh != null
        ? 'Dùng để tính can chi và tử vi: ${alSinh.day}/${alSinh.month} âm lịch năm ${ccSinh.year} · ${cg!.name} · mệnh ${na!.hanh}.'
        : 'Nhập ngày sinh để xem can chi và tử vi.';

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Cá nhân',
              style: TextStyle(fontWeight: FontWeight.w500, fontSize: 26, letterSpacing: -0.5, color: t.text)),
          const SizedBox(height: 4),
          _sectionLabel('HỒ SƠ', t),
          const SizedBox(height: 12),

          _fieldLabel('Tên', t),
          _nameField(vm, t),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _fieldLabel('Ngày sinh', t),
                  _pickerField(
                    value: ps.birthDate.isEmpty ? '--/--/----' : _formatDate(ps.birthDate),
                    icon: Icons.calendar_today_outlined,
                    onTap: () => _pickDate(context, vm, ps.birthDate),
                    t: t,
                    isEmpty: ps.birthDate.isEmpty,
                  ),
                ],
              )),
              const SizedBox(width: 8),
              SizedBox(width: 110, child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _fieldLabel('Giờ sinh', t),
                  _pickerField(
                    value: ps.birthTime.isEmpty ? '--:--' : ps.birthTime,
                    icon: Icons.access_time_outlined,
                    onTap: () => _pickTime(context, vm, ps.birthTime),
                    t: t,
                    isEmpty: ps.birthTime.isEmpty,
                  ),
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
          _settingRow('Địa chỉ', t,
            trailing: GestureDetector(
              onTap: () => vm.useGeo(),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text(
                  state.city?.displayName ?? '----',
                  style: TextStyle(fontSize: 13.5, color: t.muted),
                ),
                const SizedBox(width: 6),
                Icon(Icons.my_location, size: 14, color: t.accent),
              ]),
            )),

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
                Text(state.importMsg, style: TextStyle(fontSize: 12, color: t.dim)),
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

          const SizedBox(height: 8),
          _outlineBtn('🔔 Test notification (5 giây)', t, () async {
            await NotificationService.sendTestNotification(seconds: 5);
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: const Text('Notification sẽ xuất hiện sau 5 giây — thoát app để thấy'),
              backgroundColor: t.surface,
              duration: const Duration(seconds: 4),
            ));
          }),

          const SizedBox(height: 16),
          Consumer(builder: (ctx, ref2, _) {
            final s2 = ref2.watch(appViewModelProvider);
            final syncState = s2.syncState;
            final email = s2.googleEmail;
            final isConnected = email != null;
            final isRunning = syncState == SyncState.running;
            return Container(
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
                    if (isConnected) ...[
                      const Spacer(),
                      GestureDetector(
                        onTap: vm.disconnectGoogle,
                        child: Text('Ngắt kết nối', style: TextStyle(fontSize: 12, color: t.muted)),
                      ),
                    ],
                  ]),
                  if (isConnected) ...[
                    const SizedBox(height: 4),
                    Row(children: [
                      Icon(Icons.check_circle_outline, color: LvColors.event, size: 13),
                      const SizedBox(width: 5),
                      Text(email, style: TextStyle(fontSize: 12, color: LvColors.event)),
                    ]),
                  ],
                  const SizedBox(height: 6),
                  Text(
                    'Dữ liệu được lưu riêng tư trong appDataFolder — chỉ app này đọc được. Merge tự động theo thời gian cập nhật.',
                    style: TextStyle(fontSize: 12, height: 1.6, color: t.muted),
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: isRunning ? null : vm.doSync,
                    child: Container(
                      width: double.infinity, height: 38,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(LvColors.radiusMd),
                        border: Border.all(color: isRunning ? t.divider : t.accent),
                        color: isRunning ? t.divider.withValues(alpha: 0.1) : Colors.transparent,
                      ),
                      alignment: Alignment.center,
                      child: isRunning
                          ? Row(mainAxisSize: MainAxisSize.min, children: [
                              SizedBox(width: 14, height: 14,
                                child: CircularProgressIndicator(strokeWidth: 1.5, color: t.accent)),
                              const SizedBox(width: 8),
                              Text('Đang đồng bộ…', style: TextStyle(fontSize: 13.5, color: t.muted)),
                            ])
                          : Text(
                              isConnected ? 'Đồng bộ ngay' : 'Kết nối Google Drive',
                              style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13.5, color: t.accent),
                            ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(s2.syncMsg, style: TextStyle(fontSize: 12, color: t.dim)),
                  if (s2.gcalEvents.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: () => _showSyncedEvents(context, s2, t),
                      child: Row(children: [
                        Icon(Icons.calendar_month_outlined, color: t.accent, size: 14),
                        const SizedBox(width: 6),
                        Text(
                          'Xem ${s2.gcalEvents.length} sự kiện đã đồng bộ từ Google Calendar',
                          style: TextStyle(fontSize: 12.5, color: t.accent),
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.chevron_right, color: t.accent, size: 14),
                      ]),
                    ),
                  ],
                ],
              ),
            );
          }),

          const SizedBox(height: 16),
          Text(
            'Dữ liệu luôn được lưu trên máy. Google Drive chỉ chạy khi bạn kích hoạt — app đầy đủ chức năng khi chưa cấu hình hoặc đang offline.',
            style: TextStyle(fontSize: 12, height: 1.65, color: t.dim),
          ),
        ],
      ),
    );
  }

  void _showSyncedEvents(BuildContext context, AppState s, LvTheme t) {
    final today = DateTime.now();
    final todayKey = EventModel.dateKey(today);

    final upcoming = [...s.gcalEvents.where((e) => e.date.compareTo(todayKey) >= 0)]
      ..sort((a, b) => a.date.compareTo(b.date));
    final past = [...s.gcalEvents.where((e) => e.date.compareTo(todayKey) < 0)]
      ..sort((a, b) => b.date.compareTo(a.date)); // newest past first

    // Merge: upcoming first, then past
    final events = [...upcoming, ...past];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.92,
        expand: false,
        builder: (_, ctrl) => Container(
          decoration: BoxDecoration(
            color: t.bg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            border: Border(top: BorderSide(color: t.divider)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Center(child: Container(
                width: 38, height: 4,
                decoration: BoxDecoration(color: t.divider, borderRadius: BorderRadius.circular(9999)),
              )),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(children: [
                  Icon(Icons.calendar_month, color: LvColors.event, size: 18),
                  const SizedBox(width: 8),
                  Text('Sự kiện Google Calendar',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: t.text)),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: LvColors.event.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text('${events.length}',
                        style: const TextStyle(fontSize: 12, color: LvColors.event, fontWeight: FontWeight.w600)),
                  ),
                ]),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: events.isEmpty
                    ? Center(child: Text('Không có sự kiện', style: TextStyle(color: t.muted)))
                    : ListView.separated(
                        controller: ctrl,
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                        itemCount: events.length,
                        separatorBuilder: (_, __) => Divider(color: t.divider, height: 1),
                        itemBuilder: (_, i) {
                          final e = events[i];
                          final isPast = e.date.compareTo(todayKey) < 0;
                          final barColor = isPast ? t.dim : LvColors.event;
                          final parts = e.date.split('-');
                          final dateLabel = parts.length == 3
                              ? '${parts[2]}/${parts[1]}/${parts[0]}'
                              : e.date;
                          // Section header
                          final showHeader = (i == 0 && upcoming.isNotEmpty) ||
                              (i == upcoming.length && past.isNotEmpty);
                          final headerLabel = i == 0 && upcoming.isNotEmpty
                              ? 'SẮP TỚI'
                              : 'ĐÃ QUA';
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (showHeader) ...[
                                if (i > 0) const SizedBox(height: 8),
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  child: Text(headerLabel,
                                      style: TextStyle(fontSize: 12, letterSpacing: 1.2, color: t.muted)),
                                ),
                              ],
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 11),
                                child: Row(children: [
                                  Container(width: 3, height: 36,
                                    decoration: BoxDecoration(
                                      color: barColor,
                                      borderRadius: BorderRadius.circular(2),
                                    )),
                                  const SizedBox(width: 12),
                                  Expanded(child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(e.title,
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: isPast ? t.muted : t.text,
                                          ),
                                          maxLines: 2, overflow: TextOverflow.ellipsis),
                                      const SizedBox(height: 2),
                                      Text(dateLabel,
                                          style: TextStyle(fontSize: 12, color: t.dim)),
                                    ],
                                  )),
                                ]),
                              ),
                            ],
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(String raw) {
    final parts = raw.split('-');
    if (parts.length != 3) return raw;
    return '${parts[2]}/${parts[1]}/${parts[0]}';
  }

  Widget _nameField(AppViewModel vm, LvTheme t) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(LvColors.radiusMd),
        border: Border.all(color: t.divider),
      ),
      alignment: Alignment.center,
      child: TextField(
        controller: _nameCtrl,
        onChanged: vm.setName,
        textAlign: TextAlign.center,
        decoration: InputDecoration(
          border: InputBorder.none,
          isDense: true,
          hintText: 'Nhập họ và tên',
          hintStyle: TextStyle(color: t.dim, fontSize: 14),
        ),
        style: TextStyle(fontSize: 14, color: t.text),
      ),
    );
  }

  Widget _pickerField({required String value, required IconData icon, required VoidCallback onTap, required LvTheme t, bool isEmpty = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: t.surface,
          borderRadius: BorderRadius.circular(LvColors.radiusMd),
          border: Border.all(color: t.divider),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isEmpty ? t.dim : t.muted, size: 14),
            const SizedBox(width: 6),
            Text(value, style: TextStyle(fontSize: 14, color: isEmpty ? t.dim : t.text)),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String label, LvTheme t) =>
      Text(label, style: TextStyle(fontSize: 12, letterSpacing: 1.2, color: t.muted));

  Widget _fieldLabel(String label, LvTheme t) =>
      Padding(padding: const EdgeInsets.only(bottom: 5),
          child: Text(label, style: TextStyle(fontSize: 12, color: t.muted)));

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
