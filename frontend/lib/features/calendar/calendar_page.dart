import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../shared/providers/plan_provider.dart';
import '../../shared/widgets/page_header.dart';
import '../../shared/utils/plan_color_utils.dart';
import '../../shared/theme/app_colors.dart';
import 'widgets/selected_day_detail.dart';

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
      backgroundColor: kBg,
      body: SafeArea(
        child: Column(
          children: [
            PageHeader(
              title: '캘린더',
              trailing: GestureDetector(
                onTap: () => setState(() {
                  _selectedDay = DateTime.now();
                  _focusedMonth = DateTime.now();
                }),
                child: const Icon(Icons.today_outlined,
                    color: Color(0xFF888888)),
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
                            Builder(builder: (_) {
                              final pct = _monthlyAdherencePct(notifier);
                              if (pct == null) {
                                return const Text('기록 없음',
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFF888888)));
                              }
                              final color = pct >= 80
                                  ? kSuccess
                                  : pct >= 50
                                      ? kWarning
                                      : kDanger;
                              return Text('달성률 $pct%',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: color,
                                      fontWeight: FontWeight.w600));
                            }),
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
                                          ? kDanger
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
              child: SelectedDayDetail(
                  selectedDay: _selectedDay, notifier: notifier),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGrid(PlanNotifier notifier) {
    final offset = _firstWeekday;
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
            final indColor = dayProgressColor(
                date, DateTime(now.year, now.month, now.day), notifier);

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
                                      ? kDanger
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

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  int? _monthlyAdherencePct(PlanNotifier notifier) {
    final now = DateTime.now();
    final isCurrentMonth =
        _focusedMonth.year == now.year && _focusedMonth.month == now.month;
    final lastDay = isCurrentMonth
        ? now.day
        : DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0).day;

    int daysWithPlans = 0;
    double totalRate = 0;

    for (int d = 1; d <= lastDay; d++) {
      final date = DateTime(_focusedMonth.year, _focusedMonth.month, d);
      final plans = notifier.plansForDate(date);
      if (plans.isEmpty) continue;
      totalRate += notifier.completedCountForDate(date) / plans.length;
      daysWithPlans++;
    }

    if (daysWithPlans == 0) return null;
    return (totalRate / daysWithPlans * 100).round();
  }
}
