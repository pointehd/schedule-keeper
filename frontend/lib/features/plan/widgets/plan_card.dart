import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../shared/models/plan.dart';
import '../../../shared/providers/plan_provider.dart';

const Color kPrimary = Color(0xFF5B5FC7);

class PlanCard extends StatelessWidget {
  final Plan plan;
  const PlanCard({super.key, required this.plan});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: switch (plan.measureType) {
        MeasureType.count => _CountCard(plan: plan),
        MeasureType.time => _TimeCard(plan: plan),
        MeasureType.check => _CheckCard(plan: plan),
      },
    );
  }
}

class _CardHeader extends StatelessWidget {
  final Plan plan;
  const _CardHeader({required this.plan});

  @override
  Widget build(BuildContext context) {
    final notifier = context.read<PlanNotifier>();
    final icon = switch (plan.measureType) {
      MeasureType.count => '#',
      MeasureType.time => '⏱',
      MeasureType.check => '✓',
    };
    final targetLabel = switch (plan.measureType) {
      MeasureType.time => plan.target >= 60
          ? '${(plan.target / 60).toStringAsFixed(1)}h'
          : '${plan.target.round()}분',
      MeasureType.count => '${plan.target.round()}개',
      MeasureType.check => '',
    };

    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: plan.category.color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              icon,
              style: TextStyle(
                  fontSize: 14,
                  color: plan.category.color,
                  fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(plan.name,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Row(
                children: [
                  _Tag(label: plan.category.label, color: plan.category.color),
                  if (targetLabel.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Text('목표 $targetLabel',
                        style: const TextStyle(
                            fontSize: 11, color: Color(0xFF888888))),
                  ],
                ],
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: () => notifier.reset(plan.id),
          child: const Icon(Icons.refresh, size: 20, color: Color(0xFFBBBBBB)),
        ),
      ],
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;
  final Color color;
  const _Tag({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label,
          style: TextStyle(fontSize: 11, color: color)),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final double progress;
  final Color color;
  const _ProgressBar({required this.progress, required this.color});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: LinearProgressIndicator(
        value: progress,
        backgroundColor: const Color(0xFFF0F0F0),
        valueColor: AlwaysStoppedAnimation(color),
        minHeight: 6,
      ),
    );
  }
}

class _CountCard extends StatelessWidget {
  final Plan plan;
  const _CountCard({required this.plan});

  @override
  Widget build(BuildContext context) {
    final notifier = context.read<PlanNotifier>();
    final pct = (plan.progress * 100).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _CardHeader(plan: plan),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text('${plan.current.round()}',
                style: const TextStyle(
                    fontSize: 28, fontWeight: FontWeight.bold)),
            Text(' / ${plan.target.round()}개',
                style: const TextStyle(
                    fontSize: 14, color: Color(0xFF888888))),
            const Spacer(),
            Text('$pct%',
                style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF888888),
                    fontWeight: FontWeight.w500)),
          ],
        ),
        const SizedBox(height: 8),
        _ProgressBar(progress: plan.progress, color: plan.category.color),
        const SizedBox(height: 12),
        Row(
          children: [
            _IconBtn(
              icon: Icons.remove,
              onTap: () => notifier.updateCount(plan.id, -1),
            ),
            Expanded(
              child: Center(
                child: Text('${plan.current.round()}',
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w600)),
              ),
            ),
            _IconBtn(
              icon: Icons.add,
              bgColor: kPrimary,
              iconColor: Colors.white,
              onTap: () => notifier.updateCount(plan.id, 1),
            ),
            const SizedBox(width: 8),
            _QuickAddBtn(
                label: '+5', onTap: () => notifier.updateCount(plan.id, 5)),
          ],
        ),
      ],
    );
  }
}

class _TimeCard extends StatelessWidget {
  final Plan plan;
  const _TimeCard({required this.plan});

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<PlanNotifier>();
    final isRunning = notifier.isTimerActive(plan.id);
    final liveMin = notifier.getLiveMinutes(plan.id);
    final rawProgress = plan.target > 0 ? liveMin / plan.target : 0.0;
    final progress = rawProgress.clamp(0.0, 1.0); // 프로그레스바는 100% 캡
    final pct = (rawProgress * 100).round(); // 퍼센트는 초과 표시

    final totalSec = (liveMin * 60).round();
    final hh = totalSec ~/ 3600;
    final mm = ((totalSec % 3600) ~/ 60).toString().padLeft(2, '0');
    final ss = (totalSec % 60).toString().padLeft(2, '0');
    final timeStr = hh > 0 ? '$hh:$mm:$ss' : '$mm:$ss';

    final targetStr = plan.target >= 60
        ? '${(plan.target / 60).toStringAsFixed(1)}h'
        : '${plan.target.round()}분';
    final barColor = progress >= 1.0
        ? const Color(0xFF34C759)
        : isRunning
            ? kPrimary
            : const Color(0xFFFF9500);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _CardHeader(plan: plan),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Running indicator dot
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: isRunning ? 8 : 0,
              height: isRunning ? 8 : 0,
              margin: EdgeInsets.only(right: isRunning ? 6 : 0),
              decoration: const BoxDecoration(
                color: Color(0xFF34C759),
                shape: BoxShape.circle,
              ),
            ),
            Text(
              timeStr,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: isRunning ? kPrimary : const Color(0xFF1A1A1A),
              ),
            ),
            Text(
              ' / $targetStr',
              style: const TextStyle(fontSize: 14, color: Color(0xFF888888)),
            ),
            const Spacer(),
            Text(
              '$pct%',
              style: TextStyle(
                fontSize: 13,
                color: progress >= 1.0
                    ? const Color(0xFF34C759)
                    : const Color(0xFF888888),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _ProgressBar(progress: progress, color: barColor),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => isRunning
                    ? notifier.pauseTimer(plan.id)
                    : notifier.startTimer(plan.id),
                icon: Icon(isRunning ? Icons.pause : Icons.play_arrow, size: 18),
                label: Text(isRunning ? '일시정지' : '이어서'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isRunning ? const Color(0xFFFF9500) : kPrimary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
            const SizedBox(width: 8),
            TextButton.icon(
              onPressed: () => _showDirectInput(context, notifier),
              icon: const Icon(Icons.edit_outlined,
                  size: 15, color: Color(0xFF888888)),
              label: const Text('직접 입력',
                  style: TextStyle(color: Color(0xFF888888), fontSize: 13)),
            ),
          ],
        ),
      ],
    );
  }

  void _showDirectInput(BuildContext context, PlanNotifier notifier) {
    final liveMin = notifier.getLiveMinutes(plan.id);
    final ctrl = TextEditingController(text: liveMin.round().toString());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('시간 직접 입력'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(suffixText: '분'),
          autofocus: true,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('취소')),
          TextButton(
            onPressed: () {
              final v = double.tryParse(ctrl.text);
              if (v != null) notifier.setCurrentValue(plan.id, v);
              Navigator.pop(ctx);
            },
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }
}

class _CheckCard extends StatelessWidget {
  final Plan plan;
  const _CheckCard({required this.plan});

  @override
  Widget build(BuildContext context) {
    final notifier = context.read<PlanNotifier>();
    return Row(
      children: [
        GestureDetector(
          onTap: () => notifier.toggleCheck(plan.id),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: plan.isCompleted ? kPrimary : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: plan.isCompleted ? kPrimary : const Color(0xFFCCCCCC),
                width: 2,
              ),
            ),
            child: plan.isCompleted
                ? const Icon(Icons.check, color: Colors.white, size: 18)
                : null,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                plan.name,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  decoration: plan.isCompleted
                      ? TextDecoration.lineThrough
                      : null,
                  color: plan.isCompleted
                      ? const Color(0xFF888888)
                      : const Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 3),
              _Tag(
                  label: plan.category.label, color: plan.category.color),
            ],
          ),
        ),
        GestureDetector(
          onTap: () => notifier.reset(plan.id),
          child: const Icon(Icons.refresh,
              size: 20, color: Color(0xFFBBBBBB)),
        ),
      ],
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final Color bgColor;
  final Color iconColor;
  final VoidCallback onTap;

  const _IconBtn({
    required this.icon,
    this.bgColor = const Color(0xFFF0F0F0),
    this.iconColor = const Color(0xFF666666),
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
            color: bgColor, borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, size: 20, color: iconColor),
      ),
    );
  }
}

class _QuickAddBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _QuickAddBtn({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: kPrimary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(label,
            style: const TextStyle(
                fontSize: 13,
                color: kPrimary,
                fontWeight: FontWeight.w600)),
      ),
    );
  }
}
