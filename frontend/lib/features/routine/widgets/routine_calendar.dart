import 'package:flutter/material.dart';
import '../../../shared/utils/routine_utils.dart';
import '../../schedule/measurement_type.dart';
import '../../schedule/models/schedule_entry.dart';

class RoutineCalendar extends StatelessWidget {
  const RoutineCalendar({
    super.key,
    required this.displayMonth,
    required this.selectedDate,
    required this.goals,
    required this.monthCheckins,
    required this.onDateSelected,
    required this.onMonthChanged,
  });

  final DateTime displayMonth;
  final DateTime selectedDate;
  final List<ScheduleEntry> goals;

  /// key: "entryId_yyyy-MM-dd", value: isDone
  final Map<String, bool> monthCheckins;

  final ValueChanged<DateTime> onDateSelected;

  /// +1 = 다음달, -1 = 이전달
  final ValueChanged<int> onMonthChanged;

  static const _weekdays = ['월', '화', '수', '목', '금', '토', '일'];

  int get _daysInMonth =>
      DateTime(displayMonth.year, displayMonth.month + 1, 0).day;

  /// 월의 첫날 요일 (1=월요일 기준 0-index)
  int get _firstWeekdayIndex =>
      DateTime(displayMonth.year, displayMonth.month, 1).weekday - 1;

  String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// 달력 dot 표시용 — 완료여부는 기한 당일에만 표시
  List<ScheduleEntry> _applicableGoals(DateTime date) {
    final d = DateTime(date.year, date.month, date.day);
    return goals.where((e) {
      if (e.measurementType == MeasurementType.completion) {
        final deadline = e.deadline;
        if (deadline == null) return false;
        final dl = DateTime(deadline.year, deadline.month, deadline.day);
        return d == dl;
      }
      return isApplicableOnDate(e, date);
    }).toList();
  }

  /// 해당 날짜에 체크된 entryId 집합
  Set<String> _checkedIds(DateTime date) {
    final dateStr = _fmt(date);
    final suffix = '_$dateStr';
    final result = <String>{};
    for (final e in monthCheckins.entries) {
      if (e.value && e.key.endsWith(suffix)) {
        result.add(e.key.substring(0, e.key.length - suffix.length));
      }
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final selectedDateOnly =
        DateTime(selectedDate.year, selectedDate.month, selectedDate.day);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        children: [
          // 월 헤더
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () => onMonthChanged(-1),
                  visualDensity: VisualDensity.compact,
                ),
                Text(
                  '${displayMonth.year}년 ${displayMonth.month}월',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () => onMonthChanged(1),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),

          // 요일 헤더
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: _weekdays
                  .map(
                    (d) => Expanded(
                      child: Center(
                        child: Text(
                          d,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade400,
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 6),

          // 날짜 그리드
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
            child: _buildGrid(context, primary, todayDate, selectedDateOnly),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid(
    BuildContext context,
    Color primary,
    DateTime todayDate,
    DateTime selectedDateOnly,
  ) {
    final totalCells = _firstWeekdayIndex + _daysInMonth;
    final rows = (totalCells / 7).ceil();

    return Column(
      children: List.generate(rows, (row) {
        return Row(
          children: List.generate(7, (col) {
            final cellIndex = row * 7 + col;
            final dayNum = cellIndex - _firstWeekdayIndex + 1;

            if (dayNum < 1 || dayNum > _daysInMonth) {
              return const Expanded(child: SizedBox(height: 56));
            }

            final date = DateTime(
              displayMonth.year,
              displayMonth.month,
              dayNum,
            );
            final dateOnly = DateTime(date.year, date.month, date.day);
            final isToday = dateOnly == todayDate;
            final isSelected = dateOnly == selectedDateOnly;
            final applicable = _applicableGoals(date);
            final checkedIds = _checkedIds(date);

            return Expanded(
              child: GestureDetector(
                onTap: () => onDateSelected(date),
                child: _DayCell(
                  dayNum: dayNum,
                  isToday: isToday,
                  isSelected: isSelected,
                  applicable: applicable,
                  checkedIds: checkedIds,
                  primary: primary,
                ),
              ),
            );
          }),
        );
      }),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.dayNum,
    required this.isToday,
    required this.isSelected,
    required this.applicable,
    required this.checkedIds,
    required this.primary,
  });

  final int dayNum;
  final bool isToday;
  final bool isSelected;
  final List<ScheduleEntry> applicable;
  final Set<String> checkedIds;
  final Color primary;

  @override
  Widget build(BuildContext context) {
    Color numberColor = Colors.black87;
    Color? bgColor;
    BoxBorder? border;

    if (isSelected) {
      bgColor = primary;
      numberColor = Colors.white;
    } else if (isToday) {
      border = Border.all(color: primary, width: 1.5);
      numberColor = primary;
    }

    // 도트 목록 (최대 4개)
    final dotsToShow = applicable.take(4).toList();
    final hasMore = applicable.length > 4;

    return Container(
      height: 56,
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 날짜 숫자
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: bgColor,
              border: border,
            ),
            alignment: Alignment.center,
            child: Text(
              '$dayNum',
              style: TextStyle(
                fontSize: 13,
                fontWeight:
                    isToday || isSelected ? FontWeight.w700 : FontWeight.w400,
                color: numberColor,
              ),
            ),
          ),

          // 도트 인디케이터
          if (applicable.isNotEmpty) ...[
            const SizedBox(height: 3),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ...dotsToShow.map((entry) {
                  final isDone = checkedIds.contains(entry.id);
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 1),
                    child: Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDone
                            ? (isSelected
                                ? Colors.white
                                : entry.category.color)
                            : (isSelected
                                ? Colors.white.withValues(alpha: 0.5)
                                : Colors.grey.shade300),
                      ),
                    ),
                  );
                }),
                if (hasMore)
                  Padding(
                    padding: const EdgeInsets.only(left: 1),
                    child: Text(
                      '+',
                      style: TextStyle(
                        fontSize: 8,
                        color: isSelected
                            ? Colors.white70
                            : Colors.grey.shade400,
                        height: 1.2,
                      ),
                    ),
                  ),
              ],
            ),
          ] else
            const SizedBox(height: 8),
        ],
      ),
    );
  }
}
