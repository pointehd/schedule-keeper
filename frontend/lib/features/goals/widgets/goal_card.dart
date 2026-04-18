import 'package:flutter/material.dart';
import '../../schedule/measurement_type.dart';
import '../../schedule/models/schedule_entry.dart';

class GoalCard extends StatelessWidget {
  const GoalCard({
    super.key,
    required this.entry,
    required this.progressCount,
    required this.progressTotal,
    required this.onDelete,
    required this.onLongPress,
  });

  final ScheduleEntry entry;
  final int progressCount;
  final int progressTotal;
  final VoidCallback onDelete;
  final VoidCallback onLongPress;

  static const _dayLabels = ['월', '화', '수', '목', '금', '토', '일'];

  String get _measurementLabel {
    String base;
    switch (entry.measurementType) {
      case MeasurementType.time:
        base = '${entry.period ?? ''} ${entry.value ?? 0}시간';
      case MeasurementType.count:
        base = '${entry.period ?? ''} ${entry.value ?? 0}번';
      case MeasurementType.completion:
        final deadline = entry.deadline;
        if (deadline == null) return '완료여부';
        return '기한: ${deadline.year}.${deadline.month.toString().padLeft(2, '0')}.${deadline.day.toString().padLeft(2, '0')}';
    }
    if (entry.repeatDays.isEmpty) return base;
    final days = entry.repeatDays.map((d) => _dayLabels[d - 1]).join('·');
    return '$base  ·  $days';
  }

  String get _periodLabel {
    if (entry.measurementType == MeasurementType.completion) return '달성 현황';
    if (entry.period == '한달') return '이번 달 진행';
    return '이번 주 진행';
  }

  @override
  Widget build(BuildContext context) {
    final color = entry.category.color;
    final progress = progressTotal == 0
        ? 0.0
        : (progressCount / progressTotal).clamp(0.0, 1.0);

    return GestureDetector(
      onLongPress: onLongPress,
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: entry.isEnded ? Colors.grey.shade300 : color,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      entry.title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: entry.isEnded ? Colors.grey.shade400 : null,
                        decoration: entry.isEnded
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                  ),
                  if (entry.isEnded)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '종료',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade400,
                        ),
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        entry.category.label,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: color,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.only(left: 20),
                child: Text(
                  _measurementLabel,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade500,
                  ),
                ),
              ),
              if (!entry.isEnded) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 6,
                          backgroundColor: Colors.grey.shade100,
                          valueColor: AlwaysStoppedAnimation<Color>(color),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '$progressCount / $progressTotal',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  _periodLabel,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                ),
              ] else ...[
                const SizedBox(height: 6),
                Text(
                  '${entry.endedAt!.year}.${entry.endedAt!.month.toString().padLeft(2, '0')}.${entry.endedAt!.day.toString().padLeft(2, '0')} 종료',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
