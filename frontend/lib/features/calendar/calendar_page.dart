import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../shared/providers/plan_provider.dart';
import '../../shared/models/plan.dart';
import '../edit_plan/edit_plan_page.dart';

const Color kPrimary = Color(0xFF5B5FC7);

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  DateTime _focusedMonth = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  int get _daysInMonth =>
      DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0).day;

  // Sunday-first: Sun=0, Mon=1, … Sat=6  (DateTime.weekday: Mon=1…Sun=7)
  int get _firstWeekday =>
      DateTime(_focusedMonth.year, _focusedMonth.month, 1).weekday % 7;

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<PlanNotifier>();

    return Scaffold(
      backgroundColor: const Color(0xFFF2F3F8),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  const Text('캘린더',
                      style: TextStyle(
                          fontSize: 22, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => setState(() {
                      _selectedDay = DateTime.now();
                      _focusedMonth = DateTime.now();
                    }),
                    child: const Icon(Icons.today_outlined,
                        color: Color(0xFF888888)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16)),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTap: () => setState(() => _focusedMonth =
                              DateTime(_focusedMonth.year,
                                  _focusedMonth.month - 1)),
                          child: const Icon(Icons.chevron_left,
                              color: Color(0xFF888888)),
                        ),
                        Column(
                          children: [
                            Text(
                              '${_focusedMonth.year}년 ${_focusedMonth.month}월',
                              style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold),
                            ),
                            const Text('이번 달 70회 달성',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF888888))),
                          ],
                        ),
                        GestureDetector(
                          onTap: () => setState(() => _focusedMonth =
                              DateTime(_focusedMonth.year,
                                  _focusedMonth.month + 1)),
                          child: const Icon(Icons.chevron_right,
                              color: Color(0xFF888888)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: ['일', '월', '화', '수', '목', '금', '토']
                          .asMap()
                          .entries
                          .map((e) => Expanded(
                                child: Center(
                                  child: Text(
                                    e.value,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: e.key == 0
                                          ? const Color(0xFFFF3B30)
                                          : e.key == 6
                                              ? const Color(0xFF2979FF)
                                              : const Color(0xFF888888),
                                    ),
                                  ),
                                ),
                              ))
                          .toList(),
                    ),
                    const SizedBox(height: 8),
                    _buildGrid(notifier),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _SelectedDayDetail(
                  selectedDay: _selectedDay, notifier: notifier),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGrid(PlanNotifier notifier) {
    final offset = _firstWeekday; // Sunday-first offset (0=Sun)
    final total = offset + _daysInMonth;
    final rows = (total / 7).ceil();
    final now = DateTime.now();

    return Column(
      children: List.generate(rows, (row) {
        return Row(
          children: List.generate(7, (col) {
            final idx = row * 7 + col;
            final day = idx - offset + 1;
            if (day < 1 || day > _daysInMonth) {
              return const Expanded(child: SizedBox(height: 44));
            }
            final date =
                DateTime(_focusedMonth.year, _focusedMonth.month, day);
            final isToday = _sameDay(date, now);
            final isSel = _sameDay(date, _selectedDay);
            final isSaturday = date.weekday == 6;
            final isSunday = date.weekday == 7;
            final indColor = _dayIndicatorColor(date, now, notifier);

            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _selectedDay = date),
                child: SizedBox(
                  height: 44,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: isSel
                              ? kPrimary
                              : isToday
                                  ? kPrimary.withValues(alpha: 0.15)
                                  : Colors.transparent,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '$day',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isToday || isSel
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: isSel
                                  ? Colors.white
                                  : isSunday
                                      ? const Color(0xFFFF3B30)
                                      : isSaturday
                                          ? const Color(0xFF2979FF)
                                          : const Color(0xFF1A1A1A),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      if (indColor != null)
                        Container(
                          width: 20,
                          height: 3,
                          decoration: BoxDecoration(
                            color: indColor,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        )
                      else
                        const SizedBox(height: 3),
                    ],
                  ),
                ),
              ),
            );
          }),
        );
      }),
    );
  }

  // Purple : focus time > daily free time (초과 달성)
  // Green  : completion rate ≥ 80 %
  // Red    : focus time < 20 % of daily free time
  // Orange : anything in between
  // null   : no plans for that date (no dot)
  Color? _dayIndicatorColor(DateTime date, DateTime now, PlanNotifier notifier) {
    if (date.isAfter(DateTime(now.year, now.month, now.day))) return null;
    final plans = notifier.plansForDate(date);
    if (plans.isEmpty) return null;

    final freeHours = notifier.freeHoursForDate(date);
    final focusHours = notifier.focusHoursForDate(date);
    final completionRate = notifier.completedCountForDate(date) / plans.length;

    if (freeHours > 0 && focusHours > freeHours) return kPrimary;
    if (freeHours > 0 && focusHours < freeHours * 0.2) return const Color(0xFFFF3B30);
    if (completionRate >= 0.8) return const Color(0xFF34C759);
    return const Color(0xFFFF9500);
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

class _SelectedDayDetail extends StatelessWidget {
  final DateTime selectedDay;
  final PlanNotifier notifier;

  const _SelectedDayDetail(
      {required this.selectedDay, required this.notifier});

  @override
  Widget build(BuildContext context) {
    const weekdayNames = [
      '월요일', '화요일', '수요일', '목요일', '금요일', '토요일', '일요일'
    ];
    final weekdayName = weekdayNames[selectedDay.weekday - 1];
    final plans = notifier.plansForDate(selectedDay);
    final done = notifier.completedCountForDate(selectedDay);
    final freeH = notifier.freeHoursForDate(selectedDay);
    final usedH = notifier.focusHoursForDate(selectedDay);
    final progress = freeH > 0 ? (usedH / freeH).clamp(0.0, 1.0) : 0.0;
    final isOver = usedH > freeH;
    final today = DateTime.now();
    final isPast = selectedDay.isBefore(DateTime(today.year, today.month, today.day));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${selectedDay.month}월 ${selectedDay.day}일 · $weekdayName',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF34C759).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$done/${plans.length} 달성',
                  style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF34C759),
                      fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onLongPress: isPast ? null : () => _showFreeTimeEditor(context, selectedDay, freeH, notifier),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text('여유시간 사용',
                            style: TextStyle(
                                fontSize: 13, color: Color(0xFF555555))),
                      ),
                      Text(
                        '${fmtHours(usedH)} / ${fmtHours(freeH)}',
                        style: TextStyle(
                            fontSize: 13,
                            color: isOver ? kPrimary : const Color(0xFF888888),
                            fontWeight: isOver ? FontWeight.w600 : FontWeight.normal),
                      ),
                      if (!isPast) ...[
                        const SizedBox(width: 6),
                        const Icon(Icons.edit_outlined,
                            size: 13, color: Color(0xFFCCCCCC)),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: const Color(0xFFF0F0F0),
                      valueColor: const AlwaysStoppedAnimation(kPrimary),
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: plans.isEmpty
                ? const Center(
                    child: Text('이 날의 계획이 없습니다',
                        style: TextStyle(
                            fontSize: 14, color: Color(0xFFBBBBBB))),
                  )
                : ListView.builder(
                    itemCount: plans.length,
                    itemBuilder: (context, i) {
                      final plan = plans[i];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12)),
                        child: Row(
                          children: [
                            Container(
                              width: 4,
                              height: 32,
                              decoration: BoxDecoration(
                                color: plan.category.color,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(plan.name,
                                      style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500)),
                                  Text(
                                    '${plan.category.label} · ${plan.shortProgressLabel}',
                                    style: const TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFF888888)),
                                  ),
                                ],
                              ),
                            ),
                            GestureDetector(
                              onTap: () =>
                                  _showPlanOptions(context, plan, notifier),
                              child: const Padding(
                                padding: EdgeInsets.only(left: 8),
                                child: Icon(Icons.edit_outlined,
                                    size: 18, color: Color(0xFFBBBBBB)),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showFreeTimeEditor(
      BuildContext context, DateTime date, double currentHours, PlanNotifier notifier) {
    const weekdayNames = ['월', '화', '수', '목', '금', '토', '일'];
    final weekdayIndex = (date.weekday - 1) % 7;
    final dayLabel = '${date.month}월 ${date.day}일 (${weekdayNames[weekdayIndex]})';
    double tempHours = currentHours;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFDDDDDD),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(Icons.schedule_rounded, color: kPrimary, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      '$dayLabel 여유시간',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _FreeTimeStepButton(
                      icon: Icons.remove,
                      onTap: () {
                        if (tempHours > 0) {
                          setModalState(() => tempHours = (tempHours - 0.5).clamp(0, 12));
                        }
                      },
                    ),
                    const SizedBox(width: 24),
                    Text(
                      fmtHours(tempHours),
                      style: const TextStyle(
                        fontSize: 36, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(width: 24),
                    _FreeTimeStepButton(
                      icon: Icons.add,
                      filled: true,
                      onTap: () {
                        if (tempHours < 12) {
                          setModalState(() => tempHours = (tempHours + 0.5).clamp(0, 12));
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SliderTheme(
                  data: SliderThemeData(
                    trackHeight: 4,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
                    activeTrackColor: kPrimary,
                    inactiveTrackColor: const Color(0xFFE0E0E0),
                    thumbColor: kPrimary,
                    overlayColor: kPrimary.withValues(alpha: 0.15),
                  ),
                  child: Slider(
                    value: tempHours,
                    min: 0,
                    max: 12,
                    divisions: 24,
                    onChanged: (v) => setModalState(() => tempHours = v),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      notifier.setFreeHoursForDate(date, weekdayIndex, tempHours);
                      Navigator.pop(ctx);
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: kPrimary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('저장', style: TextStyle(fontSize: 15)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showPlanOptions(
      BuildContext context, Plan plan, PlanNotifier notifier) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFDDDDDD),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                        color: plan.category.color, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      plan.name,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                plan.category.label,
                style: const TextStyle(fontSize: 12, color: Color(0xFF888888)),
              ),
              const SizedBox(height: 16),
              const Divider(height: 1),
              _OptionTile(
                icon: Icons.edit_outlined,
                label: '수정',
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EditPlanPage(planId: plan.id),
                    ),
                  );
                },
              ),
              _OptionTile(
                icon: Icons.stop_circle_outlined,
                label: '종료',
                subtitle: '오늘부터 이 계획을 중단합니다 (과거 기록 유지)',
                onTap: () {
                  Navigator.pop(ctx);
                  notifier.endPlan(plan.id);
                },
              ),
              _OptionTile(
                icon: Icons.delete_outline,
                label: '삭제',
                subtitle: '계획과 모든 기록을 완전히 삭제합니다',
                color: const Color(0xFFFF3B30),
                onTap: () {
                  Navigator.pop(ctx);
                  _confirmDelete(context, plan, notifier);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete(
      BuildContext context, Plan plan, PlanNotifier notifier) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('계획 삭제'),
        content: Text('"${plan.name}" 계획과 모든 수행 기록이 삭제됩니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              notifier.deletePlan(plan.id);
            },
            child: const Text('삭제', style: TextStyle(color: Color(0xFFFF3B30))),
          ),
        ],
      ),
    );
  }
}

class _FreeTimeStepButton extends StatelessWidget {
  final IconData icon;
  final bool filled;
  final VoidCallback onTap;

  const _FreeTimeStepButton({
    required this.icon,
    this.filled = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: filled ? kPrimary : Colors.white,
          border: filled ? null : Border.all(color: const Color(0xFFDDDDDD)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          size: 20,
          color: filled ? Colors.white : const Color(0xFF555555),
        ),
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final Color? color;
  final VoidCallback onTap;

  const _OptionTile({
    required this.icon,
    required this.label,
    this.subtitle,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? const Color(0xFF1A1A1A);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 22, color: c),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: c)),
                  if (subtitle != null)
                    Text(subtitle!,
                        style: const TextStyle(
                            fontSize: 11, color: Color(0xFF888888))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
