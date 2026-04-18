import '../../features/schedule/models/schedule_entry.dart';
import '../../features/schedule/measurement_type.dart';

/// 특정 날짜에 루틴 목록에 표시할 항목인지 판단한다.
bool isApplicableOnDate(ScheduleEntry entry, DateTime date) {
  final dateOnly = DateTime(date.year, date.month, date.day);

  // 종료된 계획은 종료일 이후 표시하지 않음
  if (entry.endedAt != null) {
    final endDate = DateTime(
      entry.endedAt!.year,
      entry.endedAt!.month,
      entry.endedAt!.day,
    );
    if (dateOnly.isAfter(endDate)) return false;
  }

  if (entry.measurementType == MeasurementType.completion) {
    final deadline = entry.deadline;
    if (deadline == null) return false;
    final dl = DateTime(deadline.year, deadline.month, deadline.day);
    return !dateOnly.isAfter(dl);
  }
  // 반복 요일이 지정된 경우 해당 요일에만 표시
  if (entry.repeatDays.isNotEmpty &&
      !entry.repeatDays.contains(date.weekday)) {
    return false;
  }
  return true;
}

/// 오늘 루틴 목록에 표시할 항목인지 판단한다.
bool isApplicableToday(ScheduleEntry entry) =>
    isApplicableOnDate(entry, DateTime.now());

/// 측정 방식 요약 레이블 (예: "하루 2시간", "일주일 5번", "완료여부")
String targetLabel(ScheduleEntry entry) {
  switch (entry.measurementType) {
    case MeasurementType.time:
      return '${entry.period ?? ''} ${entry.value ?? 0}시간';
    case MeasurementType.count:
      return '${entry.period ?? ''} ${entry.value ?? 0}번';
    case MeasurementType.completion:
      final deadline = entry.deadline;
      if (deadline == null) return '완료여부';
      return '기한: ${deadline.year}.${deadline.month.toString().padLeft(2, '0')}.${deadline.day.toString().padLeft(2, '0')}';
  }
}
