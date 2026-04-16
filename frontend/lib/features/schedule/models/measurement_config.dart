import '../measurement_type.dart';

/// MeasurementSelector의 현재 선택 상태를 담는 값 객체.
/// 저장 가능한 상태인지 [isComplete]로 확인한다.
class MeasurementConfig {
  const MeasurementConfig({
    required this.type,
    this.period,
    this.value,
    this.deadline,
  });

  final MeasurementType type;
  final String? period;   // 시간/횟수 기간 라벨
  final int? value;       // 목표 시간 or 횟수
  final DateTime? deadline;

  bool get isComplete => switch (type) {
        MeasurementType.time => period != null && value != null && value! > 0,
        MeasurementType.count => period != null && value != null && value! > 0,
        MeasurementType.completion => deadline != null,
      };
}
