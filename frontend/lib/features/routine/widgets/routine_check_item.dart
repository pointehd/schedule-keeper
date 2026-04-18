import 'package:flutter/material.dart';
import '../../../shared/utils/routine_utils.dart';
import '../../schedule/models/schedule_entry.dart';

class RoutineCheckItem extends StatelessWidget {
  const RoutineCheckItem({
    super.key,
    required this.entry,
    required this.isDone,
    required this.onToggle,
  });

  final ScheduleEntry entry;
  final bool isDone;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    final color = entry.category.color;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 0,
      color: isDone ? color.withValues(alpha: 0.06) : Colors.white,
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 10,
          height: 10,
          margin: const EdgeInsets.only(top: 4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
          ),
        ),
        title: Text(
          entry.title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            decoration: isDone ? TextDecoration.lineThrough : null,
            color: isDone ? Colors.grey.shade400 : null,
          ),
        ),
        subtitle: Text(
          targetLabel(entry),
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade500,
          ),
        ),
        trailing: Checkbox(
          value: isDone,
          activeColor: color,
          shape: const CircleBorder(),
          onChanged: (v) => onToggle(v ?? false),
        ),
      ),
    );
  }
}
