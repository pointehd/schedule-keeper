import 'package:flutter/material.dart';

/// Formats [minutes] as "HH:MM".
String fmtMins(double minutes) {
  final h = (minutes / 60).floor();
  final m = (minutes % 60).round();
  return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
}

/// Formats [hours] as "HH:MM".
String fmtHours(double hours) => fmtMins(hours * 60);

enum PlanCategory {
  study('학습', Color(0xFF4A90E2)),
  reading('독서', Color(0xFFFF9500)),
  health('건강', Color(0xFF34C759)),
  finance('재테크', Color(0xFFFFCC00)),
  relationship('관계', Color(0xFFFF2D55)),
  hobby('취미', Color(0xFFFF6B35)),
  other('기타', Color(0xFF8E8E93));

  const PlanCategory(this.label, this.color);
  final String label;
  final Color color;
}

enum MeasureType {
  time('시간', '분 단위'),
  count('횟수', '개수 기록'),
  check('완료', '체크만');

  const MeasureType(this.label, this.subtitle);
  final String label;
  final String subtitle;
}

enum PlanScheduleType { daily, weekdays, specific, floating }

/// One snapshot of plan fields — created when a plan is first added or edited.
class PlanVersion {
  final DateTime effectiveFrom; // this version applies from this date onwards
  final String name;
  final PlanCategory category;
  final MeasureType measureType;
  final double target;
  final List<int> repeatDays; // empty = every day; 1=Mon…7=Sun

  PlanVersion({
    required this.effectiveFrom,
    required this.name,
    required this.category,
    required this.measureType,
    required this.target,
    List<int>? repeatDays,
  }) : repeatDays = repeatDays ?? [];

  // repeatDays encoding:
  //   []       = daily (매일)
  //   [-1]     = floating (반복 없음, shows until done)
  //   [1..7]   = weekdays (특정 요일, weekday numbers)
  //   [>10000] = specific dates (특정일, YYYYMMDD ints)
  PlanScheduleType get scheduleType {
    if (repeatDays.isEmpty) return PlanScheduleType.daily;
    if (repeatDays.length == 1 && repeatDays[0] == -1) return PlanScheduleType.floating;
    if (repeatDays.any((d) => d > 10000)) return PlanScheduleType.specific;
    return PlanScheduleType.weekdays;
  }

  List<DateTime> get specificDates => repeatDays
      .where((d) => d > 10000)
      .map((d) => DateTime(d ~/ 10000, (d % 10000) ~/ 100, d % 100))
      .toList()
        ..sort();

  static int dateToInt(DateTime dt) => dt.year * 10000 + dt.month * 100 + dt.day;
}

/// Persistent plan definition stored in Hive.
class PlanRecord {
  final String id;
  final DateTime createdDate;
  DateTime? endDate; // set by '종료' — plan hidden from this date onwards
  List<PlanVersion> versions; // sorted ASC by effectiveFrom

  PlanRecord({
    required this.id,
    required this.createdDate,
    required this.versions,
    this.endDate,
  });

  static DateTime _dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

  /// Returns the applicable version for [date], or null if none.
  PlanVersion? versionForDate(DateTime date) {
    final d = _dateOnly(date);
    PlanVersion? result;
    for (final v in versions) {
      if (!v.effectiveFrom.isAfter(d)) result = v;
    }
    return result;
  }

  /// Whether this plan should appear on [date].
  bool appliesOnDate(DateTime date) {
    final d = _dateOnly(date);
    if (createdDate.isAfter(d)) return false;
    if (endDate != null && !d.isBefore(endDate!)) return false;
    final v = versionForDate(d);
    if (v == null) return false;
    switch (v.scheduleType) {
      case PlanScheduleType.daily:
      case PlanScheduleType.floating:
        return true;
      case PlanScheduleType.weekdays:
        return v.repeatDays.contains(d.weekday);
      case PlanScheduleType.specific:
        return v.repeatDays.contains(PlanVersion.dateToInt(d));
    }
  }
}

/// Display model — combines PlanRecord version + DailyProgress for the UI.
class Plan {
  final String id;
  final String name;
  final PlanCategory category;
  final MeasureType measureType;
  final double target;
  final List<int> repeatDays;
  final DateTime createdDate;
  double current;
  bool isCompleted;

  Plan({
    required this.id,
    required this.name,
    required this.category,
    required this.measureType,
    required this.target,
    List<int>? repeatDays,
    DateTime? createdDate,
    this.current = 0,
    this.isCompleted = false,
  })  : repeatDays = repeatDays ?? [],
        createdDate = _dateOnly(createdDate ?? DateTime.now());

  static DateTime _dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

  PlanScheduleType get scheduleType {
    if (repeatDays.isEmpty) return PlanScheduleType.daily;
    if (repeatDays.length == 1 && repeatDays[0] == -1) return PlanScheduleType.floating;
    if (repeatDays.any((d) => d > 10000)) return PlanScheduleType.specific;
    return PlanScheduleType.weekdays;
  }

  List<DateTime> get specificDates => repeatDays
      .where((d) => d > 10000)
      .map((d) => DateTime(d ~/ 10000, (d % 10000) ~/ 100, d % 100))
      .toList()
        ..sort();

  double get progress {
    if (measureType == MeasureType.check) return isCompleted ? 1.0 : 0.0;
    if (target <= 0) return 0;
    return (current / target).clamp(0.0, 1.0);
  }

  bool get isDone =>
      measureType == MeasureType.check ? isCompleted : progress >= 1.0;

  String get shortProgressLabel {
    switch (measureType) {
      case MeasureType.time:
        return '${fmtMins(current)}/${fmtMins(target)}';
      case MeasureType.count:
        return '${current.round()}/${target.round()}';
      case MeasureType.check:
        return isCompleted ? '완료' : '대기';
    }
  }
}

/// One snapshot of free-time settings — created whenever the user changes a value.
/// Applies from [effectiveFrom] until a newer snapshot exists.
class FreeHoursSnapshot {
  final DateTime effectiveFrom;
  final List<double> hours; // index 0=Mon … 6=Sun

  FreeHoursSnapshot({required this.effectiveFrom, required this.hours});
}

/// Per-day execution record for a single plan.
class DailyProgress {
  final String planId;
  final DateTime date;
  double current;
  bool isCompleted;

  DailyProgress({
    required this.planId,
    required this.date,
    this.current = 0,
    this.isCompleted = false,
  });
}
