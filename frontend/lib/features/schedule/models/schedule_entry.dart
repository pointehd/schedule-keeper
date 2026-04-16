import '../schedule_category.dart';
import '../measurement_type.dart';

class ScheduleEntry {
  ScheduleEntry({
    required this.id,
    required this.category,
    required this.measurementType,
    this.period,
    this.value,
    this.deadline,
    required this.createdAt,
    this.syncedAt,
  });

  final String id;
  final ScheduleCategory category;
  final MeasurementType measurementType;

  /// 시간/횟수 선택 시 기간 라벨 ('하루', '일주일', '한달')
  final String? period;

  /// 시간(시간 수) 또는 횟수(번) 목표값
  final int? value;

  /// 완료여부 선택 시 기한
  final DateTime? deadline;

  final DateTime createdAt;

  /// null이면 아직 서버에 업로드되지 않은 상태
  final DateTime? syncedAt;

  bool get isPendingSync => syncedAt == null;

  Map<String, dynamic> toJson() => {
        'id': id,
        'category': category.name,
        'measurementType': measurementType.name,
        'period': period,
        'value': value,
        'deadline': deadline?.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
        'syncedAt': syncedAt?.toIso8601String(),
      };

  factory ScheduleEntry.fromJson(Map<String, dynamic> json) => ScheduleEntry(
        id: json['id'] as String,
        category: ScheduleCategory.values.byName(json['category'] as String),
        measurementType:
            MeasurementType.values.byName(json['measurementType'] as String),
        period: json['period'] as String?,
        value: json['value'] as int?,
        deadline: json['deadline'] != null
            ? DateTime.parse(json['deadline'] as String)
            : null,
        createdAt: DateTime.parse(json['createdAt'] as String),
        syncedAt: json['syncedAt'] != null
            ? DateTime.parse(json['syncedAt'] as String)
            : null,
      );

  ScheduleEntry copyWith({DateTime? syncedAt}) => ScheduleEntry(
        id: id,
        category: category,
        measurementType: measurementType,
        period: period,
        value: value,
        deadline: deadline,
        createdAt: createdAt,
        syncedAt: syncedAt ?? this.syncedAt,
      );
}
