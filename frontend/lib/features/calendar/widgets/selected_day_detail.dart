import 'package:flutter/material.dart';
import '../../../shared/providers/plan_provider.dart';
import '../../../shared/models/plan.dart';
import '../../../shared/theme/app_colors.dart';
import '../../edit_plan/edit_plan_page.dart';

class SelectedDayDetail extends StatelessWidget {
  final DateTime selectedDay;
  final PlanNotifier notifier;

  const SelectedDayDetail(
      {super.key, required this.selectedDay, required this.notifier});

  @override
  Widget build(BuildContext context) {
    const weekdayNames = [
      '월요일', '화요일', '수요일', '목요일', '금요일', '토요일', '일요일'
    ];
    final weekdayName = weekdayNames[selectedDay.weekday - 1];
    final plans = notifier.plansForDate(selectedDay);
    final done = notifier.completedCountForDate(selectedDay);
    final freeH = notifier.freeHoursForDate(selectedDay);
    final usedH = notifier.focusHoursForDate(selectedDay);
    final progress = freeH > 0 ? (usedH / freeH).clamp(0.0, 1.0) : 0.0;
    final isOver = usedH > freeH;
    final today = DateTime.now();
    final isPast = selectedDay
        .isBefore(DateTime(today.year, today.month, today.day));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${selectedDay.month}월 ${selectedDay.day}일 · $weekdayName',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: kSuccess.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$done/${plans.length} 달성',
                  style: const TextStyle(
                      fontSize: 12,
                      color: kSuccess,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text('여유시간 사용',
                          style: TextStyle(
                              fontSize: 13, color: Color(0xFF555555))),
                    ),
                    Text(
                      '${fmtHours(usedH)} / ${fmtHours(freeH)}',
                      style: TextStyle(
                          fontSize: 13,
                          color: isOver
                              ? kPrimary
                              : const Color(0xFF888888),
                          fontWeight: isOver
                              ? FontWeight.w600
                              : FontWeight.normal),
                    ),
                    if (!isPast) ...[
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: () => _showFreeTimeEditor(
                            context, selectedDay, freeH, notifier),
                        child: const Icon(Icons.edit_outlined,
                            size: 13, color: Color(0xFFCCCCCC)),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: const Color(0xFFF0F0F0),
                    valueColor: const AlwaysStoppedAnimation(kPrimary),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: plans.isEmpty
                ? const Center(
                    child: Text('이 날의 계획이 없습니다',
                        style: TextStyle(
                            fontSize: 14, color: Color(0xFFBBBBBB))),
                  )
                : ListView.builder(
                    itemCount: plans.length,
                    itemBuilder: (context, i) {
                      final plan = plans[i];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12)),
                        child: Row(
                          children: [
                            Container(
                              width: 4,
                              height: 32,
                              decoration: BoxDecoration(
                                color: plan.category.color,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(plan.name,
                                      style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500)),
                                  Text(
                                    '${plan.category.label} · ${plan.shortProgressLabel}',
                                    style: const TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFF888888)),
                                  ),
                                ],
                              ),
                            ),
                            GestureDetector(
                              onTap: () =>
                                  _showPlanOptions(context, plan, notifier),
                              child: const Padding(
                                padding: EdgeInsets.only(left: 8),
                                child: Icon(Icons.edit_outlined,
                                    size: 18, color: Color(0xFFBBBBBB)),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showFreeTimeEditor(BuildContext context, DateTime date,
      double currentHours, PlanNotifier notifier) {
    const weekdayNames = ['월', '화', '수', '목', '금', '토', '일'];
    final weekdayIndex = (date.weekday - 1) % 7;
    final dayLabel =
        '${date.month}월 ${date.day}일 (${weekdayNames[weekdayIndex]})';
    double tempHours = currentHours;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFDDDDDD),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(Icons.schedule_rounded,
                        color: kPrimary, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      '$dayLabel 여유시간',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _FreeTimeStepButton(
                      icon: Icons.remove,
                      onTap: () {
                        if (tempHours > 0) {
                          setModalState(() =>
                              tempHours = (tempHours - 0.5).clamp(0, 12));
                        }
                      },
                    ),
                    const SizedBox(width: 24),
                    Text(
                      fmtHours(tempHours),
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(width: 24),
                    _FreeTimeStepButton(
                      icon: Icons.add,
                      filled: true,
                      onTap: () {
                        if (tempHours < 12) {
                          setModalState(() =>
                              tempHours = (tempHours + 0.5).clamp(0, 12));
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SliderTheme(
                  data: SliderThemeData(
                    trackHeight: 4,
                    thumbShape:
                        const RoundSliderThumbShape(enabledThumbRadius: 8),
                    overlayShape:
                        const RoundSliderOverlayShape(overlayRadius: 16),
                    activeTrackColor: kPrimary,
                    inactiveTrackColor: const Color(0xFFE0E0E0),
                    thumbColor: kPrimary,
                    overlayColor: kPrimary.withValues(alpha: 0.15),
                  ),
                  child: Slider(
                    value: tempHours,
                    min: 0,
                    max: 12,
                    divisions: 24,
                    onChanged: (v) => setModalState(() => tempHours = v),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      notifier.setFreeHoursForDate(
                          date, weekdayIndex, tempHours);
                      Navigator.pop(ctx);
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: kPrimary,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('저장',
                        style: TextStyle(fontSize: 15)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showPlanOptions(
      BuildContext context, Plan plan, PlanNotifier notifier) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFDDDDDD),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                        color: plan.category.color, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      plan.name,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                plan.category.label,
                style: const TextStyle(
                    fontSize: 12, color: Color(0xFF888888)),
              ),
              const SizedBox(height: 16),
              const Divider(height: 1),
              _OptionTile(
                icon: Icons.edit_outlined,
                label: '수정',
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EditPlanPage(planId: plan.id),
                    ),
                  );
                },
              ),
              _OptionTile(
                icon: Icons.stop_circle_outlined,
                label: '종료',
                subtitle: '오늘부터 이 계획을 중단합니다 (과거 기록 유지)',
                onTap: () {
                  Navigator.pop(ctx);
                  notifier.endPlan(plan.id);
                },
              ),
              _OptionTile(
                icon: Icons.delete_outline,
                label: '삭제',
                subtitle: '계획과 모든 기록을 완전히 삭제합니다',
                color: kDanger,
                onTap: () {
                  Navigator.pop(ctx);
                  _confirmDelete(context, plan, notifier);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete(
      BuildContext context, Plan plan, PlanNotifier notifier) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('계획 삭제'),
        content: Text('"${plan.name}" 계획과 모든 수행 기록이 삭제됩니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              notifier.deletePlan(plan.id);
            },
            child: const Text('삭제',
                style: TextStyle(color: kDanger)),
          ),
        ],
      ),
    );
  }
}

class _FreeTimeStepButton extends StatelessWidget {
  final IconData icon;
  final bool filled;
  final VoidCallback onTap;

  const _FreeTimeStepButton({
    required this.icon,
    this.filled = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: filled ? kPrimary : Colors.white,
          border: filled ? null : Border.all(color: const Color(0xFFDDDDDD)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          size: 20,
          color: filled ? Colors.white : const Color(0xFF555555),
        ),
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final Color? color;
  final VoidCallback onTap;

  const _OptionTile({
    required this.icon,
    required this.label,
    this.subtitle,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? const Color(0xFF1A1A1A);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 22, color: c),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: c)),
                  if (subtitle != null)
                    Text(subtitle!,
                        style: const TextStyle(
                            fontSize: 11, color: Color(0xFF888888))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
