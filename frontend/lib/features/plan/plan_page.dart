import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../shared/providers/plan_provider.dart';
import '../../shared/widgets/page_header.dart';
import '../../shared/theme/app_colors.dart';
import 'widgets/plan_card.dart';

class PlanPage extends StatefulWidget {
  final String? focusedPlanId;
  const PlanPage({super.key, this.focusedPlanId});

  @override
  State<PlanPage> createState() => _PlanPageState();
}

class _PlanPageState extends State<PlanPage> {
  int _filterIndex = 0;
  final Map<String, GlobalKey> _itemKeys = {};

  @override
  void didUpdateWidget(PlanPage old) {
    super.didUpdateWidget(old);
    if (widget.focusedPlanId != null &&
        widget.focusedPlanId != old.focusedPlanId) {
      setState(() => _filterIndex = 0);
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToFocused());
    }
  }

  void _scrollToFocused() {
    final key = _itemKeys[widget.focusedPlanId];
    if (key?.currentContext != null) {
      Scrollable.ensureVisible(
        key!.currentContext!,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
        alignment: 0.15,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<PlanNotifier>();
    final plans = notifier.plans;

    final filtered = switch (_filterIndex) {
      1 => plans.where((p) => !p.isDone).toList(),
      2 => plans.where((p) => p.isDone).toList(),
      _ => plans.toList(),
    };

    final inProgress = plans.where((p) => !p.isDone).length;
    final done = plans.where((p) => p.isDone).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF2F3F8),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PageHeader(
              title: '오늘의 계획',
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: kPrimary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check, color: kPrimary, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      '${notifier.completedCount}/${notifier.totalCount}',
                      style: const TextStyle(
                          color: kPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  _FilterChip(
                    label: '전체 ${plans.length}',
                    selected: _filterIndex == 0,
                    onTap: () => setState(() => _filterIndex = 0),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: '진행중 $inProgress',
                    selected: _filterIndex == 1,
                    onTap: () => setState(() => _filterIndex = 1),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: '완료 $done',
                    selected: _filterIndex == 2,
                    onTap: () => setState(() => _filterIndex = 2),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: filtered.length,
                itemBuilder: (context, i) {
                  final plan = filtered[i];
                  _itemKeys[plan.id] ??= GlobalKey();
                  return Container(
                    key: _itemKeys[plan.id],
                    child: PlanCard(
                      plan: plan,
                      isFocused: plan.id == widget.focusedPlanId,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? kPrimary : Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: selected ? Colors.white : const Color(0xFF888888),
            fontWeight:
                selected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
