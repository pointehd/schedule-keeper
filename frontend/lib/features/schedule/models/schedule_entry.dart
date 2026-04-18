import '../schedule_category.dart';
import '../measurement_type.dart';

class ScheduleEntry {
  ScheduleEntry({
    required this.id,
    required this.title,
    required this.category,
    required this.measurementType,
    this.period,
    this.value,
    this.deadline,
    this.repeatDays = const [],
    required this.createdAt,
    this.syncedAt,
    this.endedAt,
  });

  final String id;
  final String title;
  final ScheduleCategory category;
  final MeasurementType measurementType;

  /// 시간/횟수 선택 시 기간 라벨 ('하루', '일주일', '한달')
  final String? period;

  /// 시간(시간 수) 또는 횟수(번) 목표값
  final int? value;

  /// 완료여부 선택 시 기한
  final DateTime? deadline;

  /// 반복 요일 (1=월 ~ 7=일). 비어 있으면 매일 반복.
  final List<int> repeatDays;

  final DateTime createdAt;

  /// null이면 아직 서버에 업로드되지 않은 상태
  final DateTime? syncedAt;

  /// 종료일. 설정되면 해당 날짜 이후 루틴에 표시되지 않음.
  final DateTime? endedAt;

  bool get isPendingSync => syncedAt == null;
  bool get isEnded => endedAt != null;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'category': category.name,
        'measurementType': measurementType.name,
        'period': period,
        'value': value,
        'deadline': deadline?.toIso8601String(),
        'repeatDays': repeatDays,
        'createdAt': createdAt.toIso8601String(),
        'syncedAt': syncedAt?.toIso8601String(),
        'endedAt': endedAt?.toIso8601String(),
      };

  factory ScheduleEntry.fromJson(Map<String, dynamic> json) => ScheduleEntry(
        id: json['id'] as String,
        title: (json['title'] as String?) ?? '',
        category: ScheduleCategory.values.byName(json['category'] as String),
        measurementType:
            MeasurementType.values.byName(json['measurementType'] as String),
        period: json['period'] as String?,
        value: json['value'] as int?,
        deadline: json['deadline'] != null
            ? DateTime.parse(json['deadline'] as String)
            : null,
        repeatDays: (json['repeatDays'] as List<dynamic>?)
                ?.map((e) => e as int)
                .toList() ??
            const [],
        createdAt: DateTime.parse(json['createdAt'] as String),
        syncedAt: json['syncedAt'] != null
            ? DateTime.parse(json['syncedAt'] as String)
            : null,
        endedAt: json['endedAt'] != null
            ? DateTime.parse(json['endedAt'] as String)
            : null,
      );

  ScheduleEntry copyWith({
    String? title,
    ScheduleCategory? category,
    MeasurementType? measurementType,
    String? period,
    int? value,
    DateTime? deadline,
    List<int>? repeatDays,
    DateTime? syncedAt,
    Object? endedAt = _sentinel,
  }) =>
      ScheduleEntry(
        id: id,
        title: title ?? this.title,
        category: category ?? this.category,
        measurementType: measurementType ?? this.measurementType,
        period: period ?? this.period,
        value: value ?? this.value,
        deadline: deadline ?? this.deadline,
        repeatDays: repeatDays ?? this.repeatDays,
        createdAt: createdAt,
        syncedAt: syncedAt ?? this.syncedAt,
        endedAt: endedAt == _sentinel ? this.endedAt : endedAt as DateTime?,
      );
}

// endedAt을 명시적으로 null로 설정하기 위한 sentinel
const _sentinel = Object();
