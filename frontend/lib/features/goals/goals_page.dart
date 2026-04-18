import 'package:flutter/material.dart';
import '../../shared/providers/goals_provider.dart';
import '../../shared/widgets/main_shell.dart';
import '../../shared/widgets/page_sliver_app_bar.dart';
import '../routine/repositories/routine_checkin_repository.dart';
import '../schedule/measurement_type.dart';
import '../schedule/models/schedule_entry.dart';
import '../schedule/schedule_page.dart';
import 'widgets/empty_goals_state.dart';
import 'widgets/goal_card.dart';

class GoalsPage extends StatefulWidget {
  const GoalsPage({super.key});

  @override
  State<GoalsPage> createState() => _GoalsPageState();
}

class _GoalsPageState extends State<GoalsPage> {
  final _checkinRepo = RoutineCheckinRepository();
  Map<String, int> _progressCounts = {};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadCheckins();
  }

  Future<void> _loadCheckins() async {
    final goals = GoalsProvider.of(context).goals;
    final counts = <String, int>{};
    for (final goal in goals) {
      counts[goal.id] = await _checkinCount(goal);
    }
    if (mounted) setState(() => _progressCounts = counts);
  }

  Future<int> _checkinCount(ScheduleEntry entry) async {
    if (entry.measurementType == MeasurementType.completion) {
      return (await _checkinRepo.getCheckin(entry.id, DateTime.now())) ? 1 : 0;
    }
    if (entry.period == '한달') {
      return _checkinRepo.thisMonthCheckinCount(entry.id);
    }
    return _checkinRepo.thisWeekCheckinCount(entry.id);
  }

  int _progressTotal(ScheduleEntry entry) {
    if (entry.measurementType == MeasurementType.completion) return 1;
    if (entry.period == '하루') return 7;
    return entry.value ?? 1;
  }

  void _showActionMenu(BuildContext context, ScheduleEntry entry) {
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Text(
                  entry.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Divider(height: 1),
              // 수정
              if (!entry.isEnded)
                ListTile(
                  leading: const Icon(Icons.edit_outlined),
                  title: const Text('수정'),
                  onTap: () {
                    Navigator.pop(ctx);
                    _editGoal(entry);
                  },
                ),
              if (!entry.isEnded) const Divider(height: 1),
              // 종료
              if (!entry.isEnded)
                ListTile(
                  leading: Icon(
                    Icons.stop_circle_outlined,
                    color: Colors.orange.shade600,
                  ),
                  title: Text(
                    '종료',
                    style: TextStyle(color: Colors.orange.shade600),
                  ),
                  subtitle: const Text(
                    '오늘로 마무리 · 이후 루틴에서 제외',
                    style: TextStyle(fontSize: 11),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _endGoal(entry);
                  },
                ),
              if (!entry.isEnded) const Divider(height: 1),
              // 삭제
              ListTile(
                leading:
                    Icon(Icons.delete_outline, color: Colors.red.shade400),
                title: Text(
                  '삭제',
                  style: TextStyle(color: Colors.red.shade400),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _deleteGoal(entry);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _editGoal(ScheduleEntry entry) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SchedulePage(initialEntry: entry),
      ),
    ).then((_) => _loadCheckins());
  }

  Future<void> _endGoal(ScheduleEntry entry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('계획 종료'),
        content: Text(
          '\'${entry.title}\' 계획을 오늘로 종료할까요?\n이후 루틴에서 표시되지 않습니다.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              '종료',
              style: TextStyle(color: Colors.orange.shade600),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      GoalsProvider.of(context).endGoal(entry.id);
    }
  }

  Future<void> _deleteGoal(ScheduleEntry entry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('목표 삭제'),
        content: Text('\'${entry.title}\' 목표를 삭제할까요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              '삭제',
              style: TextStyle(color: Colors.red.shade400),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      GoalsProvider.of(context).delete(entry.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final notifier = GoalsProvider.of(context);
    final goals = notifier.goals;
    final isLoading = notifier.isLoading;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: CustomScrollView(
        slivers: [
          PageSliverAppBar(
            title: '목표',
            onRefresh: () async {
              await notifier.load();
              await _loadCheckins();
            },
          ),
          if (isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (goals.isEmpty)
            SliverFillRemaining(
              child: EmptyGoalsState(
                onAddTap: () {
                  context
                      .findAncestorStateOfType<MainShellState>()
                      ?.switchTab(2);
                },
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) => GoalCard(
                    entry: goals[i],
                    progressCount: _progressCounts[goals[i].id] ?? 0,
                    progressTotal: _progressTotal(goals[i]),
                    onDelete: () => _deleteGoal(goals[i]),
                    onLongPress: () => _showActionMenu(context, goals[i]),
                  ),
                  childCount: goals.length,
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: goals.isEmpty
          ? null
          : FloatingActionButton.extended(
              heroTag: 'goalsPageFab',
              onPressed: () {
                context
                    .findAncestorStateOfType<MainShellState>()
                    ?.switchTab(2);
              },
              icon: const Icon(Icons.add),
              label: const Text('계획 추가'),
            ),
    );
  }
}
