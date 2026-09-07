import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/lunar_calendar.dart';
import '../../model/event_model.dart';
import '../../state/app_state.dart';
import '../../viewmodel/app_view_model.dart';
import '../app_colors_ext.dart';

class CalendarTab extends ConsumerWidget {
  const CalendarTab({super.key, required this.theme});
  final LvTheme theme;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appViewModelProvider);
    final vm = ref.read(appViewModelProvider.notifier);
    final t = theme;

    final now = DateTime.now();
    final vy = state.viewYear;
    final vm0 = state.viewMonth; // 0-based

    final todayAl = LunarCalendar.solar2lunar(now.day, now.month, now.year);
    final todayCc = LunarCalendar.canChi(todayAl);
    final alFirst = LunarCalendar.solar2lunar(1, vm0 + 1, vy);
    final alLast = LunarCalendar.solar2lunar(DateTime(vy, vm0 + 2, 0).day, vm0 + 1, vy);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Năm ${todayCc.year}',
                        style: TextStyle(fontSize: 11, letterSpacing: 1.2, color: t.muted)),
                    const SizedBox(height: 4),
                    Text('Tháng ${vm0 + 1} / $vy',
                        style: TextStyle(
                            fontWeight: FontWeight.w500, fontSize: 27, color: t.text, height: 1.05, letterSpacing: -0.5)),
                    const SizedBox(height: 5),
                    Text('Tháng ${alFirst.month} – ${alLast.month} âm lịch',
                        style: TextStyle(fontSize: 13, color: t.muted)),
                  ],
                ),
              ),
              _NavButtons(theme: t, vm: vm),
            ],
          ),
          const SizedBox(height: 16),
          _CalendarGrid(theme: t, state: state, vm: vm, now: now, vy: vy, vm0: vm0),
          const SizedBox(height: 12),
          _Legend(theme: t),
          const SizedBox(height: 24),
          _UpcomingSection(theme: t, state: state, vm: vm, now: now),
        ],
      ),
    );
  }
}

class _NavButtons extends StatelessWidget {
  const _NavButtons({required this.theme, required this.vm});
  final LvTheme theme;
  final AppViewModel vm;

  @override
  Widget build(BuildContext context) {
    final t = theme;
    return Row(
      children: [
        _iconBtn(Icons.chevron_left, vm.prevMonth, t),
        const SizedBox(width: 6),
        _iconBtn(Icons.chevron_right, vm.nextMonth, t),
        const SizedBox(width: 6),
        _textBtn('Hôm nay', vm.goToday, t),
      ],
    );
  }

  Widget _iconBtn(IconData icon, VoidCallback onTap, LvTheme t) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34, height: 34,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(LvColors.radiusMd),
          border: Border.all(color: t.divider),
        ),
        child: Icon(icon, color: t.text, size: 18),
      ),
    );
  }

  Widget _textBtn(String label, VoidCallback onTap, LvTheme t) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: 13),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(LvColors.radiusMd),
          border: Border.all(color: t.accent),
        ),
        alignment: Alignment.center,
        child: Text(label, style: TextStyle(color: t.accent, fontWeight: FontWeight.w500, fontSize: 13)),
      ),
    );
  }
}

class _CalendarGrid extends StatelessWidget {
  const _CalendarGrid({
    required this.theme, required this.state, required this.vm,
    required this.now, required this.vy, required this.vm0,
  });
  final LvTheme theme;
  final AppState state;
  final AppViewModel vm;
  final DateTime now;
  final int vy, vm0;

  @override
  Widget build(BuildContext context) {
    final t = theme;
    const weekdays = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];

    final first = DateTime(vy, vm0 + 1, 1);
    int lead = first.weekday - 1;
    if (lead < 0) lead = 6;

    final cells = <_CellData>[];
    for (int i = 0; i < 42; i++) {
      final d = DateTime(vy, vm0 + 1, 1 - lead + i);
      final k = EventModel.dateKey(d);
      final al = LunarCalendar.solar2lunar(d.day, d.month, d.year);
      final le = LunarCalendar.holidays(d, al);
      final inMonth = d.month == vm0 + 1;
      final isToday = k == EventModel.dateKey(now);
      final weekend = d.weekday >= 6;
      final evs = state.events.where((e) => !e.deleted && e.date == k).toList();
      cells.add(_CellData(d: d, k: k, al: al, le: le, inMonth: inMonth, isToday: isToday, weekend: weekend, evs: evs));
    }

    return Column(
      children: [
        GridView.count(
          crossAxisCount: 7, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 2, mainAxisSpacing: 2, crossAxisSpacing: 2,
          children: weekdays.asMap().entries.map((e) {
            final isWe = e.key >= 5;
            return Center(
              child: Text(e.value,
                  style: TextStyle(fontSize: 11, letterSpacing: 0.6, color: isWe ? t.weekend : t.muted)),
            );
          }).toList(),
        ),
        GridView.count(
          crossAxisCount: 7, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 0.82, mainAxisSpacing: 3, crossAxisSpacing: 3,
          children: cells.map((c) => _CalCell(cell: c, theme: t, onTap: () => vm.selectDate(c.k))).toList(),
        ),
      ],
    );
  }
}

class _CellData {
  final DateTime d;
  final String k;
  final LunarDate al;
  final List<HolidayEntry> le;
  final bool inMonth, isToday, weekend;
  final List<dynamic> evs;
  _CellData({
    required this.d, required this.k, required this.al, required this.le,
    required this.inMonth, required this.isToday, required this.weekend, required this.evs,
  });
}

class _CalCell extends StatelessWidget {
  const _CalCell({required this.cell, required this.theme, required this.onTap});
  final _CellData cell;
  final LvTheme theme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = theme;
    final c = cell;
    Color solColor = t.text;
    if (!c.inMonth) {
      solColor = t.dim;
    } else if (c.weekend || c.le.isNotEmpty) {
      solColor = t.weekend;
    }

    final hasLeLon = c.le.isNotEmpty && LunarCalendar.leLon.contains(c.le.first.name);
    final isFirst15 = c.al.day == 1 || c.al.day == 15;

    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: c.inMonth ? 1.0 : 0.42,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          decoration: BoxDecoration(
            color: c.isToday ? t.accent.withValues(alpha: 0.16) : Colors.transparent,
            borderRadius: BorderRadius.circular(LvColors.radiusMd),
            border: Border.all(color: c.isToday ? t.accent : Colors.transparent),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('${c.d.day}',
                  style: TextStyle(fontWeight: FontWeight.w500, fontSize: 15, letterSpacing: -0.2, color: solColor, height: 1)),
              const SizedBox(height: 1),
              Text(
                c.al.day == 1 ? '1/${c.al.month}' : '${c.al.day}',
                style: TextStyle(fontSize: 8.5, height: 1,
                    color: isFirst15 ? t.muted : t.dim.withValues(alpha: 0.9)),
              ),
              const SizedBox(height: 3),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (c.le.isNotEmpty)
                    Container(
                      width: 5, height: 5,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: hasLeLon ? t.accent : t.accent.withValues(alpha: 0.5),
                      ),
                    ),
                  if (c.le.isEmpty && isFirst15)
                    Container(
                      width: 5, height: 5,
                      decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: t.dim)),
                    ),
                  if (c.evs.isNotEmpty) ...[
                    if (c.le.isNotEmpty || isFirst15) const SizedBox(width: 3),
                    Container(width: 9, height: 2,
                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(2), color: LvColors.accent300)),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.theme});
  final LvTheme theme;

  @override
  Widget build(BuildContext context) {
    final t = theme;
    return Wrap(
      spacing: 16, runSpacing: 8,
      children: [
        _item(Container(width: 5, height: 5, decoration: BoxDecoration(shape: BoxShape.circle, color: t.accent)), 'Ngày lễ', t),
        _item(Container(width: 5, height: 5, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: t.dim))), 'Mùng 1 / Rằm', t),
        _item(Container(width: 9, height: 2, decoration: BoxDecoration(borderRadius: BorderRadius.circular(2), color: LvColors.accent300)), 'Sự kiện', t),
      ],
    );
  }

  Widget _item(Widget dot, String label, LvTheme t) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      dot, const SizedBox(width: 6),
      Text(label, style: TextStyle(fontSize: 11.5, color: t.muted)),
    ]);
  }
}

class _UpcomingSection extends StatelessWidget {
  const _UpcomingSection({required this.theme, required this.state, required this.vm, required this.now});
  final LvTheme theme;
  final AppState state;
  final AppViewModel vm;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final t = theme;
    final items = _buildUpcoming();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('SẮP TỚI', style: TextStyle(fontSize: 11, letterSpacing: 1.2, color: t.muted)),
        const SizedBox(height: 12),
        ...items.map((s) => _UpcomingItem(item: s, theme: t, onTap: () => vm.selectDate(s.dateKey))),
      ],
    );
  }

  List<_UpcomingData> _buildUpcoming() {
    final items = <_UpcomingData>[];
    for (int i = 0; i < 90 && items.length < 4; i++) {
      final d = DateTime(now.year, now.month, now.day + i);
      final k = EventModel.dateKey(d);
      final al = LunarCalendar.solar2lunar(d.day, d.month, d.year);
      final le = LunarCalendar.holidays(d, al);
      final evs = state.events.where((e) => !e.deleted && e.date == k).toList();
      final name = le.isNotEmpty ? le.first.name : (evs.isNotEmpty ? evs.first.title : null);
      if (name == null) continue;
      items.add(_UpcomingData(
        dateKey: k,
        day: '${d.day}',
        month: 'Th${d.month}',
        name: name,
        sub: (i == 0 ? 'Hôm nay' : i == 1 ? 'Ngày mai' : 'Còn $i ngày') + ' · Âm ${al.day}/${al.month}',
      ));
    }
    return items;
  }
}

class _UpcomingData {
  final String dateKey, day, month, name, sub;
  const _UpcomingData({required this.dateKey, required this.day, required this.month, required this.name, required this.sub});
}

class _UpcomingItem extends StatelessWidget {
  const _UpcomingItem({required this.item, required this.theme, required this.onTap});
  final _UpcomingData item;
  final LvTheme theme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = theme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        child: Row(
          children: [
            SizedBox(width: 38, child: Column(children: [
              Text(item.day, style: TextStyle(fontWeight: FontWeight.w500, fontSize: 17, color: t.text, height: 1)),
              const SizedBox(height: 2),
              Text(item.month, style: TextStyle(fontSize: 10.5, color: t.muted)),
            ])),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(item.name, style: TextStyle(fontSize: 14, color: t.text)),
              const SizedBox(height: 1),
              Text(item.sub, style: TextStyle(fontSize: 11.5, color: t.muted)),
            ])),
            Icon(Icons.chevron_right, color: t.dim, size: 16),
          ],
        ),
      ),
    );
  }
}
