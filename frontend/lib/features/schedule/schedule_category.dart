import 'package:flutter/material.dart';

enum ScheduleCategory {
  study,
  reading,
  health,
  finance,
  relationship,
  hobby,
  etc;

  String get label => switch (this) {
        study => '학습',
        reading => '독서',
        health => '건강',
        finance => '재테크',
        relationship => '관계',
        hobby => '취미',
        etc => '기타',
      };

  Color get color => switch (this) {
        study => Colors.indigo,
        reading => Colors.amber.shade700,
        health => Colors.green,
        finance => Colors.teal,
        relationship => Colors.pink,
        hobby => Colors.deepOrange,
        etc => Colors.blueGrey,
      };
}
