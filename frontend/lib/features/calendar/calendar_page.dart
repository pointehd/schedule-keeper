import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../shared/providers/plan_provider.dart';

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

  int get _firstWeekday =>
      DateTime(_focusedMonth.year, _focusedMonth.month, 1).weekday;

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
                  const Icon(Icons.settings_outlined,
                      color: Color(0xFF888888)),
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
                      children: ['월', '화', '수', '목', '금', '토', '일']
                          .asMap()
                          .entries
                          .map((e) => Expanded(
                                child: Center(
                                  child: Text(
                                    e.value,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: e.key >= 5
                                          ? const Color(0xFFFF3B30)
                                          : const Color(0xFF888888),
                                    ),
                                  ),
                                ),
                              ))
                          .toList(),
                    ),
                    const SizedBox(height: 8),
                    _buildGrid(),
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

  Widget _buildGrid() {
    final offset = _firstWeekday - 1;
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
            final isPast = date.isBefore(DateTime(now.year, now.month, now.day));
            final isWeekend = date.weekday >= 6;
            final indicatorColors = [kPrimary, const Color(0xFF34C759), const Color(0xFFFF9500)];
            final indColor = indicatorColors[date.weekday % indicatorColors.length];

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
                                  : isWeekend
                                      ? const Color(0xFFFF3B30)
                                      : const Color(0xFF1A1A1A),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      if (isPast)
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
    final plans = notifier.plans;
    final done = plans.where((p) => p.isDone).length;

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
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Expanded(
                      child: Text('여유시간 사용',
                          style: TextStyle(
                              fontSize: 13, color: Color(0xFF555555))),
                    ),
                    Text('1.3h / 6h',
                        style: TextStyle(
                            fontSize: 13, color: Color(0xFF888888))),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: const LinearProgressIndicator(
                    value: 0.22,
                    backgroundColor: Color(0xFFF0F0F0),
                    valueColor: AlwaysStoppedAnimation(kPrimary),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
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
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: plan.isDone ? kPrimary : Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                              color: plan.isDone
                                  ? kPrimary
                                  : const Color(0xFFCCCCCC)),
                        ),
                        child: plan.isDone
                            ? const Icon(Icons.check,
                                color: Colors.white, size: 14)
                            : null,
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
                      Container(
                        width: 4,
                        height: 32,
                        decoration: BoxDecoration(
                          color: plan.category.color,
                          borderRadius: BorderRadius.circular(2),
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
}
