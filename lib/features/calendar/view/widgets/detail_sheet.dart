import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/lunar_calendar.dart';
import '../../viewmodel/app_view_model.dart';
import '../app_colors_ext.dart';

class DetailSheet extends ConsumerStatefulWidget {
  const DetailSheet({super.key, required this.theme, required this.dateKey});
  final LvTheme theme;
  final String dateKey;

  @override
  ConsumerState<DetailSheet> createState() => _DetailSheetState();
}

class _DetailSheetState extends ConsumerState<DetailSheet> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(appViewModelProvider);
    final vm = ref.read(appViewModelProvider.notifier);
    final t = widget.theme;
    final dk = widget.dateKey;

    final parts = dk.split('-').map(int.parse).toList();
    final d = DateTime(parts[0], parts[1], parts[2]);
    final al = LunarCalendar.solar2lunar(d.day, d.month, d.year);
    final cc = LunarCalendar.canChi(al);
    final le = LunarCalendar.holidays(d, al);
    final tot = LunarCalendar.ngayTot(al.month, cc.chiDay);
    final gioHD = LunarCalendar.gioHoangDao(cc.chiDay);
    final tiet = LunarCalendar.tietKhi(al.jd);
    final events = vm.eventsOn(dk);

    return GestureDetector(
      onTap: () {}, // prevent dismiss on sheet tap
      child: Container(
        decoration: BoxDecoration(
          color: t.bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
          border: Border(top: BorderSide(color: t.divider)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.65), blurRadius: 40, offset: const Offset(0, -16))],
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(child: Container(
                width: 38, height: 4,
                decoration: BoxDecoration(color: t.divider, borderRadius: BorderRadius.circular(9999)),
              )),
              const SizedBox(height: 20),

              // Header
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(LunarCalendar.weekdays[d.weekday % 7],
                          style: TextStyle(fontSize: 12.5, color: t.muted)),
                      const SizedBox(height: 2),
                      Text('${d.day}/${d.month}/${d.year}',
                          style: TextStyle(fontWeight: FontWeight.w500, fontSize: 32,
                              letterSpacing: -0.5, height: 1.1, color: t.text)),
                      const SizedBox(height: 5),
                      Text(
                        'Ngày ${al.day} tháng ${al.month}${al.isLeap ? ' (nhuận)' : ''} năm ${cc.year}',
                        style: const TextStyle(fontSize: 14, color: LvColors.accent300),
                      ),
                    ],
                  )),
                  GestureDetector(
                    onTap: vm.closeDetail,
                    child: Container(
                      width: 32, height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: t.divider),
                      ),
                      child: Icon(Icons.close, color: t.muted, size: 15),
                    ),
                  ),
                ],
              ),

              // Holidays
              if (le.isNotEmpty) ...[
                const SizedBox(height: 16),
                Wrap(
                  spacing: 6, runSpacing: 6,
                  children: le.map((l) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(9999),
                      border: Border.all(color: l.type == 'am' ? t.accent : t.divider),
                    ),
                    child: Text(l.name,
                        style: TextStyle(
                            fontWeight: FontWeight.w500, fontSize: 12,
                            color: l.type == 'am' ? t.accent : t.muted)),
                  )).toList(),
                ),
              ],

              const SizedBox(height: 16),

              // Can chi grid
              Row(
                children: [
                  _InfoBox('Ngày', cc.day, t),
                  const SizedBox(width: 8),
                  _InfoBox('Tháng', cc.month, t),
                  const SizedBox(width: 8),
                  _InfoBox('Năm', cc.year, t),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(LvColors.radiusMd),
                        border: Border.all(color: tot ? t.accent : t.divider),
                        color: tot ? t.accent.withOpacity(0.10) : Colors.transparent,
                      ),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Ngày tốt/xấu', style: TextStyle(fontSize: 10.5, letterSpacing: 0.8, color: t.muted)),
                        const SizedBox(height: 5),
                        Text(tot ? 'Hoàng đạo' : 'Hắc đạo',
                            style: TextStyle(fontWeight: FontWeight.w500, fontSize: 15, color: t.text)),
                      ]),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: _InfoBox('Tiết khí', tiet, t)),
                ],
              ),

              const SizedBox(height: 20),
              Text('GIỜ HOÀNG ĐẠO', style: TextStyle(fontSize: 11, letterSpacing: 1.2, color: t.muted)),
              const SizedBox(height: 10),
              GridView.count(
                crossAxisCount: 2, shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 3.5,
                crossAxisSpacing: 8, mainAxisSpacing: 8,
                children: gioHD.map((g) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(LvColors.radiusMd),
                    border: Border.all(color: t.divider),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(g.chi, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14, color: LvColors.accent300)),
                      const SizedBox(width: 8),
                      Text(g.frame, style: TextStyle(fontSize: 12, color: t.muted)),
                    ],
                  ),
                )).toList(),
              ),

              const SizedBox(height: 20),
              Text('SỰ KIỆN', style: TextStyle(fontSize: 11, letterSpacing: 1.2, color: t.muted)),
              const SizedBox(height: 8),

              ...events.map((e) => Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(children: [
                      Container(width: 3, height: 22, decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(2), color: LvColors.accent400)),
                      const SizedBox(width: 12),
                      Expanded(child: Text(e.title, style: TextStyle(fontSize: 14, color: t.text))),
                      GestureDetector(
                        onTap: () => vm.deleteEvent(e.id),
                        child: Container(
                          width: 28, height: 28,
                          decoration: BoxDecoration(borderRadius: BorderRadius.circular(LvColors.radiusSm)),
                          child: Icon(Icons.delete_outline, color: t.dim, size: 15),
                        ),
                      ),
                    ]),
                  ),
                  Divider(color: t.divider, height: 1),
                ],
              )),

              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 38,
                      padding: const EdgeInsets.symmetric(horizontal: 11),
                      decoration: BoxDecoration(
                        color: t.surface,
                        borderRadius: BorderRadius.circular(LvColors.radiusMd),
                        border: Border.all(color: t.divider),
                      ),
                      child: TextField(
                        controller: _ctrl,
                        onChanged: vm.setEventDraft,
                        onSubmitted: (_) {
                          vm.addEvent();
                          _ctrl.clear();
                        },
                        decoration: InputDecoration(
                          hintText: 'Thêm sự kiện…',
                          hintStyle: TextStyle(color: t.muted, fontSize: 14),
                          border: InputBorder.none, isDense: true,
                        ),
                        style: TextStyle(fontSize: 14, color: t.text),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      vm.addEvent();
                      _ctrl.clear();
                    },
                    child: Container(
                      width: 38, height: 38,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(LvColors.radiusMd),
                        border: Border.all(color: t.accent),
                      ),
                      child: Icon(Icons.add, color: t.accent, size: 18),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),
              Text(
                'Đã lưu ${events.length} sự kiện trên thiết bị',
                style: TextStyle(fontSize: 11, color: t.dim, fontFamily: 'monospace'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoBox extends StatelessWidget {
  const _InfoBox(this.label, this.value, this.theme);
  final String label, value;
  final LvTheme theme;

  @override
  Widget build(BuildContext context) {
    final t = theme;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(LvColors.radiusMd),
          border: Border.all(color: t.divider),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label.toUpperCase(), style: TextStyle(fontSize: 10.5, letterSpacing: 0.8, color: t.muted)),
          const SizedBox(height: 5),
          Text(value, style: TextStyle(fontWeight: FontWeight.w500, fontSize: 15, color: t.text)),
        ]),
      ),
    );
  }
}
