import 'package:flutter/material.dart';
import '../../shared/providers/goals_provider.dart';
import '../../shared/providers/settings_provider.dart';
import '../../shared/utils/routine_utils.dart';
import '../../shared/widgets/main_shell.dart';
import '../routine/repositories/routine_checkin_repository.dart';
import '../schedule/measurement_type.dart';
import '../schedule/models/schedule_entry.dart';
import 'widgets/goal_progress_card.dart';
import 'widgets/today_routine_preview.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _checkinRepo = RoutineCheckinRepository();
  Map<String, bool> _checkins = {};
  Map<String, int> _progressCounts = {};
  bool _isLoading = true;
  bool _completionExpanded = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _load();
  }

  Future<void> _load() async {
    final goals = GoalsProvider.of(context).goals;
    final checkins = await _checkinRepo.getCheckinsForDate(DateTime.now());
    final counts = <String, int>{};
    for (final goal in goals) {
      counts[goal.id] = await _checkinCount(goal);
    }
    if (mounted) {
      setState(() {
        _checkins = checkins;
        _progressCounts = counts;
        _isLoading = false;
      });
    }
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

  List<ScheduleEntry> _routineEntries(List<ScheduleEntry> goals) => goals
      .where((e) =>
          e.measurementType != MeasurementType.completion &&
          isApplicableToday(e))
      .toList();

  List<ScheduleEntry> _completionEntries(List<ScheduleEntry> goals) => goals
      .where((e) =>
          e.measurementType == MeasurementType.completion &&
          isApplicableToday(e))
      .toList();

  String _dateHeader() {
    final now = DateTime.now();
    final weekdays = ['월요일', '화요일', '수요일', '목요일', '금요일', '토요일', '일요일'];
    return '${now.month}월 ${now.day}일 ${weekdays[now.weekday - 1]}';
  }

  String _deadlineLabel(ScheduleEntry entry) {
    final d = entry.deadline;
    if (d == null) return '기한 없음';
    return '기한: ${d.year}.${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final goals = GoalsProvider.of(context).goals;
    final freeTime = SettingsProvider.of(context).freeTimeHours;
    final routineEntries = _routineEntries(goals);
    final completionEntries = _completionEntries(goals);
    final doneCount =
        routineEntries.where((e) => _checkins[e.id] ?? false).length;
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            snap: true,
            backgroundColor: primary,
            foregroundColor: Colors.white,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '데일리 스케줄 키퍼',
                  style: TextStyle(fontSize: 11, color: Colors.white70),
                ),
                Text(
                  _dateHeader(),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.notifications_none_outlined),
                onPressed: () {},
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 상단 그라데이션 카드
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [primary, primary.withValues(alpha: 0.75)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '안녕하세요!',
                          style: TextStyle(fontSize: 12, color: Colors.white70),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          '오늘도 목표를 향해 나아가세요',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            _InfoChip(
                              icon: Icons.access_time_outlined,
                              label: freeTime == 0
                                  ? '여유시간 미설정'
                                  : '여유시간 ${freeTime % 1 == 0 ? freeTime.toInt() : freeTime}h',
                            ),
                            const SizedBox(width: 8),
                            _InfoChip(
                              icon: Icons.check_circle_outline,
                              label: '루틴 $doneCount/${routineEntries.length} 완료',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── 오늘의 루틴 ──────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '오늘의 루틴',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          context
                              .findAncestorStateOfType<MainShellState>()
                              ?.switchTab(3);
                        },
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          '전체 보기',
                          style: TextStyle(fontSize: 13, color: primary),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  if (_isLoading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade100),
                      ),
                      child: TodayRoutinePreview(
                        entries: routineEntries.take(5).toList(),
                        checkins: _checkins,
                      ),
                    ),

                  // ── 완료 목표 ────────────────────────────────
                  if (completionEntries.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    // 섹션 헤더 (탭으로 접기/펼치기)
                    GestureDetector(
                      onTap: () => setState(
                          () => _completionExpanded = !_completionExpanded),
                      child: Row(
                        children: [
                          const Text(
                            '완료 목표',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${completionEntries.length}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: primary,
                              ),
                            ),
                          ),
                          const Spacer(),
                          AnimatedRotation(
                            turns: _completionExpanded ? 0 : -0.25,
                            duration: const Duration(milliseconds: 200),
                            child: Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: Colors.grey.shade500,
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    // 접기/펼치기 콘텐츠
                    AnimatedSize(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeInOut,
                      child: _completionExpanded
                          ? Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade100),
                              ),
                              child: Column(
                                children: completionEntries
                                    .asMap()
                                    .entries
                                    .map((entry) {
                                  final i = entry.key;
                                  final e = entry.value;
                                  final isDone = _checkins[e.id] ?? false;
                                  final color = e.category.color;
                                  final isLast =
                                      i == completionEntries.length - 1;
                                  return Column(
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 12,
                                        ),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 8,
                                              height: 8,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: isDone
                                                    ? Colors.grey.shade300
                                                    : color,
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    e.title,
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      decoration: isDone
                                                          ? TextDecoration
                                                              .lineThrough
                                                          : null,
                                                      color: isDone
                                                          ? Colors.grey.shade400
                                                          : null,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    _deadlineLabel(e),
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      color:
                                                          Colors.grey.shade400,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            GestureDetector(
                                              onTap: () async {
                                                await _checkinRepo.setCheckin(
                                                    e.id,
                                                    DateTime.now(),
                                                    !isDone);
                                                _load();
                                              },
                                              child: Icon(
                                                isDone
                                                    ? Icons.check_circle
                                                    : Icons
                                                        .radio_button_unchecked,
                                                size: 20,
                                                color: isDone
                                                    ? color
                                                    : Colors.grey.shade300,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (!isLast)
                                        Divider(
                                          height: 1,
                                          indent: 34,
                                          color: Colors.grey.shade100,
                                        ),
                                    ],
                                  );
                                }).toList(),
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // ── 이번 주 목표 진행 ─────────────────────────
                  if (goals.isNotEmpty) ...[
                    const Text(
                      '이번 주 목표 진행',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 160,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: goals.length,
                        itemBuilder: (_, i) => GoalProgressCard(
                          entry: goals[i],
                          progressCount: _progressCounts[goals[i].id] ?? 0,
                          progressTotal: _progressTotal(goals[i]),
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Colors.white),
          ),
        ],
      ),
    );
  }
}
