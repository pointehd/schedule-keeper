import 'package:flutter/material.dart';
import '../models/plan.dart';
import '../../shared/theme/app_colors.dart';

class PlanSectionLabel extends StatelessWidget {
  final String text;
  const PlanSectionLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
          fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A)),
    );
  }
}

class PlanFormCard extends StatelessWidget {
  final Widget child;
  const PlanFormCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: child,
    );
  }
}

class PlanQuickBtn extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const PlanQuickBtn(
      {super.key,
      required this.label,
      required this.selected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? kPrimary.withValues(alpha: 0.1)
              : const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? kPrimary : Colors.transparent),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: selected ? kPrimary : const Color(0xFF555555),
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class PlanQuickDayBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const PlanQuickDayBtn({super.key, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label,
            style: const TextStyle(fontSize: 13, color: Color(0xFF555555))),
      ),
    );
  }
}

class PlanCategorySelector extends StatelessWidget {
  final PlanCategory selected;
  final ValueChanged<PlanCategory> onChanged;
  const PlanCategorySelector(
      {super.key, required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return PlanFormCard(
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: PlanCategory.values.map((c) {
          final sel = c == selected;
          return GestureDetector(
            onTap: () => onChanged(c),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: sel
                    ? c.color.withValues(alpha: 0.15)
                    : const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(20),
                border:
                    Border.all(color: sel ? c.color : Colors.transparent),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration:
                        BoxDecoration(color: c.color, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    c.label,
                    style: TextStyle(
                      fontSize: 13,
                      color: sel ? c.color : const Color(0xFF555555),
                      fontWeight:
                          sel ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class PlanMeasureTypeSelector extends StatelessWidget {
  final MeasureType selected;
  final ValueChanged<MeasureType> onChanged;
  const PlanMeasureTypeSelector(
      {super.key, required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: MeasureType.values.asMap().entries.map((e) {
        final m = e.value;
        final sel = m == selected;
        final isLast = e.key == MeasureType.values.length - 1;
        final icon = switch (m) {
          MeasureType.time => Icons.access_time_rounded,
          MeasureType.count => Icons.tag,
          MeasureType.check => Icons.check_circle_outline,
        };
        return Expanded(
          child: GestureDetector(
            onTap: () => onChanged(m),
            child: Container(
              margin:
                  isLast ? EdgeInsets.zero : const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: sel ? kPrimary : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: sel ? kPrimary : const Color(0xFFEEEEEE)),
              ),
              child: Column(
                children: [
                  Icon(icon,
                      color:
                          sel ? Colors.white : const Color(0xFF888888),
                      size: 24),
                  const SizedBox(height: 6),
                  Text(
                    m.label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: sel ? Colors.white : const Color(0xFF333333),
                    ),
                  ),
                  Text(
                    m.subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: sel ? Colors.white70 : const Color(0xFF888888),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class PlanTargetSection extends StatelessWidget {
  final MeasureType measureType;
  final double target;
  final ValueChanged<double> onChanged;
  const PlanTargetSection(
      {super.key,
      required this.measureType,
      required this.target,
      required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PlanFormCard(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '${target.round()}',
                style: const TextStyle(
                    fontSize: 36, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 6),
              Text(
                measureType == MeasureType.time ? '분' : '개',
                style: const TextStyle(
                    fontSize: 18, color: Color(0xFF888888)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: measureType == MeasureType.time
              ? [
                  PlanQuickBtn(
                      label: '10분',
                      selected: target == 10,
                      onTap: () => onChanged(10)),
                  PlanQuickBtn(
                      label: '30분',
                      selected: target == 30,
                      onTap: () => onChanged(30)),
                  PlanQuickBtn(
                      label: '1h',
                      selected: target == 60,
                      onTap: () => onChanged(60)),
                  PlanQuickBtn(
                      label: '2h',
                      selected: target == 120,
                      onTap: () => onChanged(120)),
                ]
              : [
                  PlanQuickBtn(
                      label: '5개',
                      selected: target == 5,
                      onTap: () => onChanged(5)),
                  PlanQuickBtn(
                      label: '10개',
                      selected: target == 10,
                      onTap: () => onChanged(10)),
                  PlanQuickBtn(
                      label: '20개',
                      selected: target == 20,
                      onTap: () => onChanged(20)),
                  PlanQuickBtn(
                      label: '30개',
                      selected: target == 30,
                      onTap: () => onChanged(30)),
                ],
        ),
      ],
    );
  }
}

class PlanScheduleSelector extends StatelessWidget {
  static const _weekdayLabels = ['월', '화', '수', '목', '금', '토', '일'];

  final PlanScheduleType scheduleMode;
  final Set<int> repeatDays;
  final List<DateTime> specificDates;
  final ValueChanged<PlanScheduleType> onScheduleModeChanged;
  final ValueChanged<Set<int>> onRepeatDaysChanged;
  final ValueChanged<List<DateTime>> onSpecificDatesChanged;

  const PlanScheduleSelector({
    super.key,
    required this.scheduleMode,
    required this.repeatDays,
    required this.specificDates,
    required this.onScheduleModeChanged,
    required this.onRepeatDaysChanged,
    required this.onSpecificDatesChanged,
  });

  @override
  Widget build(BuildContext context) {
    return PlanFormCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              PlanScheduleType.daily,
              PlanScheduleType.weekdays,
              PlanScheduleType.specific,
              PlanScheduleType.floating,
            ].asMap().entries.map((e) {
              final mode = e.value;
              final sel = mode == scheduleMode;
              final isLast = e.key == 3;
              final label = switch (mode) {
                PlanScheduleType.daily => '매일',
                PlanScheduleType.weekdays => '특정 요일',
                PlanScheduleType.specific => '특정일',
                PlanScheduleType.floating => '반복 없음',
              };
              return Expanded(
                child: GestureDetector(
                  onTap: () => onScheduleModeChanged(mode),
                  child: Container(
                    margin: isLast
                        ? EdgeInsets.zero
                        : const EdgeInsets.only(right: 6),
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    decoration: BoxDecoration(
                      color: sel ? kPrimary : const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: 12,
                          color: sel ? Colors.white : const Color(0xFF555555),
                          fontWeight:
                              sel ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          if (scheduleMode == PlanScheduleType.weekdays) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(7, (i) {
                final day = i + 1;
                final sel = repeatDays.contains(day);
                return GestureDetector(
                  onTap: () {
                    final updated = Set<int>.from(repeatDays);
                    sel ? updated.remove(day) : updated.add(day);
                    onRepeatDaysChanged(updated);
                  },
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: sel ? kPrimary : const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        _weekdayLabels[i],
                        style: TextStyle(
                          fontSize: 13,
                          color: sel ? Colors.white : const Color(0xFF555555),
                          fontWeight:
                              sel ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                PlanQuickDayBtn(
                  label: '평일',
                  onTap: () => onRepeatDaysChanged({1, 2, 3, 4, 5}),
                ),
                const SizedBox(width: 8),
                PlanQuickDayBtn(
                  label: '주말',
                  onTap: () => onRepeatDaysChanged({6, 7}),
                ),
              ],
            ),
          ],
          if (scheduleMode == PlanScheduleType.specific) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ...specificDates.map((d) => GestureDetector(
                      onTap: () {
                        final updated = List<DateTime>.from(specificDates)
                          ..remove(d);
                        onSpecificDatesChanged(updated);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: kPrimary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: kPrimary),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${d.month}/${d.day}',
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: kPrimary,
                                  fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.close,
                                size: 12, color: kPrimary),
                          ],
                        ),
                      ),
                    )),
                GestureDetector(
                  onTap: () async {
                    final now = DateTime.now();
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: now,
                      firstDate:
                          now.subtract(const Duration(days: 365)),
                      lastDate: now.add(const Duration(days: 365 * 2)),
                    );
                    if (picked != null) {
                      final d = DateTime(
                          picked.year, picked.month, picked.day);
                      if (!specificDates.any((x) =>
                          x.year == d.year &&
                          x.month == d.month &&
                          x.day == d.day)) {
                        onSpecificDatesChanged(
                            List<DateTime>.from(specificDates)..add(d));
                      }
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add,
                            size: 14, color: Color(0xFF888888)),
                        SizedBox(width: 4),
                        Text('날짜 추가',
                            style: TextStyle(
                                fontSize: 12, color: Color(0xFF888888))),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (scheduleMode == PlanScheduleType.floating) ...[
            const SizedBox(height: 10),
            const Text(
              '목표를 달성할 때까지 매일 할일로 표시됩니다',
              style: TextStyle(fontSize: 12, color: Color(0xFF888888)),
            ),
          ],
        ],
      ),
    );
  }
}
