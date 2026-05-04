import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../shared/models/plan.dart';
import '../../shared/providers/plan_provider.dart';
import '../../shared/utils/plan_color_utils.dart';
import '../../shared/theme/app_colors.dart';

class HomePage extends StatelessWidget {
  final void Function(String planId)? onNavigateToPlan;
  const HomePage({super.key, this.onNavigateToPlan});

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
              _WeeklyView(now: now, weekStart: weekStart, notifier: notifier),
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
                  TextButton.icon(
                    onPressed: () {},
                    label: const Text(
                      '전체',
                      style: TextStyle(color: kPrimary, fontSize: 14),
                    ),
                    icon: const Icon(
                      Icons.chevron_right,
                      color: kPrimary,
                      size: 18,
                    ),
                    iconAlignment: IconAlignment.end,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              ...notifier.plans.map((p) => _PlanListTile(
                    plan: p,
                    onTap: onNavigateToPlan != null
                        ? () => onNavigateToPlan!(p.id)
                        : null,
                  )),
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
  final PlanNotifier notifier;

  const _WeeklyView({
    required this.now,
    required this.weekStart,
    required this.notifier,
  });

  static const double _maxBarHeight = 64.0;
  static const double _minBarHeight = 8.0;

  Color? _barColor(DateTime date, DateTime today) =>
      dayProgressColor(date, today, notifier);

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
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(7, (i) {
            final date = weekStart.add(Duration(days: i));
            final isToday = date.year == today.year &&
                date.month == today.month &&
                date.day == today.day;
            final isFuture = date.isAfter(today);

            final plans = notifier.plansForDate(date);
            final hasPlans = plans.isNotEmpty;

            double completionRate = 0;
            if (!isFuture && hasPlans) {
              final done = notifier.completedCountForDate(date);
              completionRate = done / plans.length;
            }

            final color = isToday
                ? (_barColor(date, today) ?? kPrimary)
                : _barColor(date, today);

            final isOver = !isFuture && hasPlans &&
                notifier.freeHoursForDate(date) > 0 &&
                notifier.focusHoursForDate(date) > notifier.freeHoursForDate(date);

            final showCheck = !isFuture && hasPlans && (completionRate >= 1.0 || isOver);

            final barHeight = (isFuture || !hasPlans)
                ? _minBarHeight
                : (completionRate.clamp(0.0, 1.0) * _maxBarHeight)
                    .clamp(_minBarHeight, _maxBarHeight);

            final barColor = color ?? const Color(0xFFE8EAF6);

            return Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                SizedBox(
                  width: 40,
                  height: _maxBarHeight + 10,
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.bottomCenter,
                      children: [
                        Container(
                          width: 40,
                          height: barHeight,
                          decoration: BoxDecoration(
                            color: barColor,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        if (showCheck)
                          Positioned(
                            top: _maxBarHeight - barHeight - 8,
                            right: -5,
                            child: Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 1.5),
                              ),
                              child: const Icon(Icons.check, size: 9, color: Colors.white),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  weekdayLabels[i],
                  style: TextStyle(
                    fontSize: 12,
                    color: isToday ? kPrimary : const Color(0xFF888888),
                    fontWeight: isToday ? FontWeight.w600 : FontWeight.normal,
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
  final VoidCallback? onTap;
  const _PlanListTile({required this.plan, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right, size: 16, color: Color(0xFFCCCCCC)),
          ],
        ),
      ),
    );
  }
}
