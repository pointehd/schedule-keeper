import 'package:flutter/material.dart';

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

class Plan {
  final String id;
  final String name;
  final PlanCategory category;
  final MeasureType measureType;
  final double target;
  final List<int> repeatDays;
  double current;
  bool isCompleted;

  Plan({
    required this.id,
    required this.name,
    required this.category,
    required this.measureType,
    required this.target,
    List<int>? repeatDays,
    this.current = 0,
    this.isCompleted = false,
  }) : repeatDays = repeatDays ?? [];

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
        final curH = current / 60;
        final tarH = target / 60;
        return '${curH.toStringAsFixed(1)}/${tarH.toStringAsFixed(1)}h';
      case MeasureType.count:
        return '${current.round()}/${target.round()}';
      case MeasureType.check:
        return isCompleted ? '완료' : '대기';
    }
  }
}
