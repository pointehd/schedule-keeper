enum MeasurementType {
  time,
  count,
  completion;

  String get label => switch (this) {
        time => '시간',
        count => '횟수',
        completion => '완료여부',
      };
}

enum TimePeriod {
  daily,
  weekly,
  monthly;

  String get label => switch (this) {
        daily => '하루',
        weekly => '일주일',
        monthly => '한달',
      };
}

enum CountPeriod {
  daily,
  weekly,
  monthly;

  String get label => switch (this) {
        daily => '하루',
        weekly => '일주일',
        monthly => '한달',
      };
}
