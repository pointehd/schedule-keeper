import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../shared/models/plan.dart';
import '../../shared/providers/plan_provider.dart';

const Color kPrimary = Color(0xFF5B5FC7);

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<PlanNotifier>();
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));

    return Scaffold(
      backgroundColor: const Color(0xFFF2F3F8),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Text(
                '${now.month}월 ${now.day}일 · ${_weekdayName(now.weekday)}',
                style: const TextStyle(fontSize: 14, color: Color(0xFF888888)),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Text(
                    '오늘의 계획 ',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  Text(
                    '${notifier.completedCount}/${notifier.totalCount}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: kPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _ProgressCard(notifier: notifier),
              const SizedBox(height: 20),
              _WeeklyView(now: now, weekStart: weekStart),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '오늘의 계획',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: const Text(
                      '전체 >',
                      style: TextStyle(color: kPrimary, fontSize: 14),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              ...notifier.plans.map((p) => _PlanListTile(plan: p)),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  String _weekdayName(int weekday) {
    const names = ['월요일', '화요일', '수요일', '목요일', '금요일', '토요일', '일요일'];
    return names[weekday - 1];
  }
}

class _ProgressCard extends StatelessWidget {
  final PlanNotifier notifier;
  const _ProgressCard({required this.notifier});

  @override
  Widget build(BuildContext context) {
    final progress = notifier.overallProgress;
    final hours = notifier.totalFocusHours;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF7B7FE0), Color(0xFF5B5FC7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            height: 110,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size(110, 110),
                  painter: _CircularGaugePainter(progress: progress),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${(progress * 100).round()}%',
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const Text(
                      '달성률',
                      style: TextStyle(fontSize: 11, color: Colors.white70),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '오늘 집중한 시간',
                  style: TextStyle(fontSize: 12, color: Colors.white70),
                ),
                Text(
                  fmtHours(hours),
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.local_fire_department,
                          color: Colors.orange, size: 14),
                      SizedBox(width: 4),
                      Text(
                        '연속 12일 달성 중',
                        style: TextStyle(fontSize: 12, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CircularGaugePainter extends CustomPainter {
  final double progress;
  const _CircularGaugePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;
    const strokeWidth = 10.0;

    final bgPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2 + 0.3,
      2 * pi - 0.6,
      false,
      bgPaint,
    );

    if (progress > 0) {
      final fgPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -pi / 2,
        2 * pi * progress,
        false,
        fgPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_CircularGaugePainter old) => old.progress != progress;
}

class _WeeklyView extends StatelessWidget {
  final DateTime now;
  final DateTime weekStart;

  const _WeeklyView({required this.now, required this.weekStart});

  @override
  Widget build(BuildContext context) {
    const weekdayLabels = ['월', '화', '수', '목', '금', '토', '일'];
    final today = DateTime(now.year, now.month, now.day);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '이번 주',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A1A),
              ),
            ),
            Text(
              '${weekStart.month}/${weekStart.day} — ${weekStart.add(const Duration(days: 6)).month}/${weekStart.add(const Duration(days: 6)).day}',
              style: const TextStyle(fontSize: 12, color: Color(0xFF888888)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(7, (i) {
            final date = weekStart.add(Duration(days: i));
            final isToday = date.year == today.year &&
                date.month == today.month &&
                date.day == today.day;
            final isPast = date.isBefore(today);
            final isCompleted = isPast && i != 2;

            return Column(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isToday
                        ? kPrimary
                        : isCompleted
                            ? const Color(0xFFE8EAF6)
                            : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: isCompleted && !isToday
                        ? Border.all(color: kPrimary.withValues(alpha: 0.3))
                        : null,
                  ),
                  child: isCompleted || isToday
                      ? Icon(
                          Icons.check,
                          color: isToday ? Colors.white : kPrimary,
                          size: 20,
                        )
                      : null,
                ),
                const SizedBox(height: 4),
                Text(
                  weekdayLabels[i],
                  style: TextStyle(
                    fontSize: 12,
                    color: isToday ? kPrimary : const Color(0xFF888888),
                    fontWeight:
                        isToday ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            );
          }),
        ),
      ],
    );
  }
}

class _PlanListTile extends StatelessWidget {
  final Plan plan;
  const _PlanListTile({required this.plan});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: plan.category.color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              plan.name,
              style:
                  const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
          Text(
            plan.shortProgressLabel,
            style: TextStyle(
              fontSize: 13,
              color: plan.isDone
                  ? const Color(0xFF34C759)
                  : const Color(0xFF888888),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
