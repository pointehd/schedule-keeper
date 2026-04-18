import 'package:flutter/material.dart';
import '../../schedule/models/schedule_entry.dart';
import '../../../shared/utils/routine_utils.dart';

class TodayRoutinePreview extends StatelessWidget {
  const TodayRoutinePreview({
    super.key,
    required this.entries,
    required this.checkins,
  });

  final List<ScheduleEntry> entries;
  final Map<String, bool> checkins;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(
          '오늘 등록된 루틴이 없어요',
          style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
        ),
      );
    }

    return Column(
      children: entries.map((entry) {
        final isDone = checkins[entry.id] ?? false;
        final color = entry.category.color;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDone ? Colors.grey.shade300 : color,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  entry.title,
                  style: TextStyle(
                    fontSize: 14,
                    decoration: isDone ? TextDecoration.lineThrough : null,
                    color: isDone ? Colors.grey.shade400 : null,
                  ),
                ),
              ),
              Text(
                targetLabel(entry),
                style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
              ),
              const SizedBox(width: 8),
              Icon(
                isDone ? Icons.check_circle : Icons.radio_button_unchecked,
                size: 18,
                color: isDone ? color : Colors.grey.shade300,
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
