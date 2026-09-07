import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../state/app_state.dart';
import '../../viewmodel/app_view_model.dart';
import '../app_colors_ext.dart';

class OnboardingOverlay extends ConsumerStatefulWidget {
  const OnboardingOverlay({super.key, required this.theme});
  final LvTheme theme;

  @override
  ConsumerState<OnboardingOverlay> createState() => _OnboardingOverlayState();
}

class _OnboardingOverlayState extends ConsumerState<OnboardingOverlay> {
  final _nameCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _cityCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = ref.read(appViewModelProvider.notifier);
    final state = ref.watch(appViewModelProvider);
    final t = widget.theme;
    final ps = state.profile;

    return AnimatedOpacity(
      opacity: 1,
      duration: const Duration(milliseconds: 300),
      child: Container(
        color: t.bg,
        child: SingleChildScrollView(
          child: Stack(
            children: [
              // Background glow
              Positioned(
                top: -130, left: -80,
                child: Container(
                  width: 380, height: 380,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(colors: [
                      t.accent.withValues(alpha: 0.18),
                      Colors.transparent,
                    ]),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  20,
                  MediaQuery.of(context).padding.top + 56,
                  20, 40,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Text('Bắt đầu',
                        style: TextStyle(fontSize: 11, letterSpacing: 1.2, color: t.muted)),
                    const SizedBox(height: 6),
                    Text('Chào bạn',
                        style: TextStyle(
                            fontWeight: FontWeight.w500, fontSize: 29,
                            letterSpacing: -0.6, height: 1.1, color: t.text)),
                    const SizedBox(height: 8),
                    Text('Không cần tạo tài khoản. Điền thông tin để tính tử vi và can chi, mọi thứ lưu trên máy bạn.',
                        style: TextStyle(fontSize: 13.5, height: 1.6, color: t.muted)),

                    const SizedBox(height: 24),

                    // Google Sign-In button
                    _GoogleBtn(theme: t, vm: vm, state: state),
                    const SizedBox(height: 8),
                    Text(
                      state.googleEmail != null
                          ? 'Đã kết nối · ${state.googleEmail}'
                          : 'Đồng bộ lịch, Drive và lấy tên tự động.',
                      style: TextStyle(fontSize: 11.5, height: 1.6, color: t.dim),
                    ),

                    // Divider
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Row(children: [
                        Expanded(child: Divider(color: t.divider)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text('hoặc tự nhập',
                              style: TextStyle(fontSize: 11, letterSpacing: 1.0, color: t.dim)),
                        ),
                        Expanded(child: Divider(color: t.divider)),
                      ]),
                    ),

                    // Name field
                    _FieldLabel('Tên', t),
                    _InputField(
                      controller: _nameCtrl,
                      hint: 'Nhập họ và tên',
                      t: t,
                      onChanged: vm.setName,
                      initialValue: ps.name,
                    ),
                    const SizedBox(height: 16),

                    // Birthdate + Birthtime
                    Row(children: [
                      Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _FieldLabel('Ngày sinh', t),
                          _DatePickerField(
                            value: ps.birthDate,
                            t: t,
                            onPicked: vm.setBirthDate,
                          ),
                        ],
                      )),
                      const SizedBox(width: 10),
                      SizedBox(width: 110, child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _FieldLabel('Giờ sinh', t),
                          _TimePickerField(
                            value: ps.birthTime,
                            t: t,
                            onPicked: vm.setBirthTime,
                          ),
                        ],
                      )),
                    ]),
                    const SizedBox(height: 16),

                    // Gender
                    _FieldLabel('Giới tính', t),
                    _SegmentedGender(
                      selected: ps.gender,
                      onSelect: vm.setGender,
                      t: t,
                    ),
                    const SizedBox(height: 16),

                    // City
                    _FieldLabel('Thành phố', t),
                    _InputField(
                      controller: _cityCtrl,
                      hint: 'Hà Nội',
                      t: t,
                      onChanged: (_) {},
                      onSubmitted: (v) {
                        if (v.trim().isNotEmpty) vm.setCityDraft(v.trim());
                        vm.submitCity();
                      },
                    ),

                    const SizedBox(height: 28),

                    // CTA
                    GestureDetector(
                      onTap: vm.obDone,
                      child: Container(
                        width: double.infinity, height: 44,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(LvColors.radiusMd),
                          border: Border.all(color: t.accent),
                          color: t.accent.withValues(alpha: 0.14),
                        ),
                        alignment: Alignment.center,
                        child: Text('Bắt đầu dùng',
                            style: TextStyle(
                                fontWeight: FontWeight.w500, fontSize: 14.5, color: t.accent)),
                      ),
                    ),
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: vm.obSkip,
                      child: Container(
                        width: double.infinity, height: 38,
                        alignment: Alignment.center,
                        child: Text('Bỏ qua, điền sau',
                            style: TextStyle(fontSize: 13, color: t.muted)),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Privacy note
                    Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Icon(Icons.lock_outline, size: 14, color: t.dim),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Google chỉ dùng để đồng bộ lịch qua Drive (scope drive.appdata). Hồ sơ và sự kiện vẫn nằm ở máy bạn kể cả khi không kết nối.',
                          style: TextStyle(fontSize: 11.5, height: 1.6, color: t.dim),
                        ),
                      ),
                    ]),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GoogleBtn extends StatelessWidget {
  const _GoogleBtn({required this.theme, required this.vm, required this.state});
  final LvTheme theme;
  final AppViewModel vm;
  final dynamic state;

  @override
  Widget build(BuildContext context) {
    final t = theme;
    final isConnected = state.googleEmail != null;
    final isRunning = state.syncState == SyncState.running;
    return GestureDetector(
      onTap: isRunning ? null : vm.doSync,
      child: Container(
        width: double.infinity, height: 44,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(LvColors.radiusMd),
          border: Border.all(color: isConnected ? LvColors.event : t.divider),
          color: isConnected
              ? LvColors.event.withValues(alpha: 0.1)
              : t.surface,
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          if (isRunning)
            SizedBox(width: 16, height: 16,
                child: CircularProgressIndicator(strokeWidth: 1.5, color: t.accent))
          else
            Icon(Icons.g_mobiledata_rounded,
                size: 22, color: isConnected ? LvColors.event : t.muted),
          const SizedBox(width: 8),
          Text(
            isRunning
                ? 'Đang kết nối…'
                : isConnected
                    ? 'Đã kết nối Google'
                    : 'Tiếp tục với Google',
            style: TextStyle(
                fontSize: 14, fontWeight: FontWeight.w500,
                color: isConnected ? LvColors.event : t.text),
          ),
        ]),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.label, this.t);
  final String label;
  final LvTheme t;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 5),
        child: Text(label, style: TextStyle(fontSize: 12, color: t.muted)),
      );
}

class _InputField extends StatelessWidget {
  const _InputField({
    required this.controller,
    required this.hint,
    required this.t,
    required this.onChanged,
    this.onSubmitted,
    this.initialValue,
  });
  final TextEditingController controller;
  final String hint;
  final LvTheme t;
  final ValueChanged<String> onChanged;
  final ValueChanged<String>? onSubmitted;
  final String? initialValue;

  @override
  Widget build(BuildContext context) {
    if (initialValue != null && controller.text.isEmpty && initialValue!.isNotEmpty) {
      controller.text = initialValue!;
    }
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(LvColors.radiusMd),
        border: Border.all(color: t.divider),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: t.dim, fontSize: 14),
          border: InputBorder.none,
          isDense: true,
        ),
        style: TextStyle(fontSize: 14, color: t.text),
      ),
    );
  }
}

class _DatePickerField extends StatelessWidget {
  const _DatePickerField({required this.value, required this.t, required this.onPicked});
  final String value;
  final LvTheme t;
  final ValueChanged<String> onPicked;

  @override
  Widget build(BuildContext context) {
    final display = value.isEmpty ? '--/--/----' : _format(value);
    return GestureDetector(
      onTap: () async {
        FocusScope.of(context).unfocus();
        await Future.delayed(const Duration(milliseconds: 150));
        if (!context.mounted) return;
        final parts = value.split('-');
        final initial = parts.length == 3
            ? DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]))
            : DateTime(1995, 1, 1);
        final picked = await showDatePicker(
          context: context,
          initialDate: initial,
          firstDate: DateTime(1900),
          lastDate: DateTime.now(),
        );
        if (picked != null) {
          onPicked('${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}');
        }
      },
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: t.surface,
          borderRadius: BorderRadius.circular(LvColors.radiusMd),
          border: Border.all(color: t.divider),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.calendar_today_outlined, size: 14,
              color: value.isEmpty ? t.dim : t.muted),
          const SizedBox(width: 6),
          Text(display, style: TextStyle(fontSize: 14,
              color: value.isEmpty ? t.dim : t.text)),
        ]),
      ),
    );
  }

  String _format(String raw) {
    final p = raw.split('-');
    return p.length == 3 ? '${p[2]}/${p[1]}/${p[0]}' : raw;
  }
}

class _TimePickerField extends StatelessWidget {
  const _TimePickerField({required this.value, required this.t, required this.onPicked});
  final String value;
  final LvTheme t;
  final ValueChanged<String> onPicked;

  @override
  Widget build(BuildContext context) {
    final display = value.isEmpty ? '--:--' : value;
    return GestureDetector(
      onTap: () async {
        FocusScope.of(context).unfocus();
        await Future.delayed(const Duration(milliseconds: 150));
        if (!context.mounted) return;
        final parts = value.split(':');
        final initial = parts.length == 2
            ? TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]))
            : const TimeOfDay(hour: 7, minute: 0);
        final picked = await showTimePicker(
          context: context,
          initialTime: initial,
          initialEntryMode: TimePickerEntryMode.dialOnly,
          builder: (ctx, child) => MediaQuery(
            data: MediaQuery.of(ctx).copyWith(viewInsets: EdgeInsets.zero),
            child: child!,
          ),
        );
        if (picked != null) {
          onPicked('${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}');
        }
      },
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: t.surface,
          borderRadius: BorderRadius.circular(LvColors.radiusMd),
          border: Border.all(color: t.divider),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.access_time_outlined, size: 14,
              color: value.isEmpty ? t.dim : t.muted),
          const SizedBox(width: 6),
          Text(display, style: TextStyle(fontSize: 14,
              color: value.isEmpty ? t.dim : t.text)),
        ]),
      ),
    );
  }
}

class _SegmentedGender extends StatelessWidget {
  const _SegmentedGender({required this.selected, required this.onSelect, required this.t});
  final String selected;
  final ValueChanged<String> onSelect;
  final LvTheme t;

  @override
  Widget build(BuildContext context) {
    const opts = ['Nam', 'Nữ', 'Khác'];
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(LvColors.radiusMd),
        border: Border.all(color: t.divider),
      ),
      child: Row(
        children: opts.map((g) {
          final on = selected == g;
          return Expanded(
            child: GestureDetector(
              onTap: () => onSelect(g),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                padding: const EdgeInsets.symmetric(vertical: 5),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(LvColors.radiusSm),
                  color: on ? t.accent.withValues(alpha: 0.18) : Colors.transparent,
                ),
                alignment: Alignment.center,
                child: Text(g,
                    style: TextStyle(
                        fontWeight: FontWeight.w500, fontSize: 12.5,
                        color: on ? t.accent : t.muted)),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
