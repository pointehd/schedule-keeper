import 'package:flutter/material.dart';
import '../../shared/providers/goals_provider.dart';
import '../../shared/utils/routine_utils.dart';
import '../../shared/widgets/main_shell.dart';
import '../schedule/models/schedule_entry.dart';
import 'repositories/routine_checkin_repository.dart';
import 'widgets/routine_calendar.dart';
import 'widgets/routine_check_item.dart';

class RoutinePage extends StatefulWidget {
  const RoutinePage({super.key});

  @override
  State<RoutinePage> createState() => _RoutinePageState();
}

class _RoutinePageState extends State<RoutinePage> {
  final _checkinRepo = RoutineCheckinRepository();

  DateTime _selectedDate = _today();
  DateTime _displayMonth = _today();

  /// 현재 표시 중인 달의 체크인 데이터 (key: "entryId_yyyy-MM-dd")
  Map<String, bool> _monthCheckins = {};
  bool _isLoading = true;

  static DateTime _today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  static String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadMonthCheckins();
  }

  Future<void> _loadMonthCheckins() async {
    setState(() => _isLoading = true);
    final checkins = await _checkinRepo.getCheckinsForMonth(
      _displayMonth.year,
      _displayMonth.month,
    );
    if (mounted) {
      setState(() {
        _monthCheckins = checkins;
        _isLoading = false;
      });
    }
  }

  void _onMonthChanged(int delta) {
    setState(() {
      _displayMonth = DateTime(
        _displayMonth.year,
        _displayMonth.month + delta,
        1,
      );
    });
    _loadMonthCheckins();
  }

  void _onDateSelected(DateTime date) {
    setState(() => _selectedDate = date);
    // 다른 달 날짜를 눌렀을 때 캘린더도 해당 달로 이동
    if (date.year != _displayMonth.year || date.month != _displayMonth.month) {
      setState(() {
        _displayMonth = DateTime(date.year, date.month, 1);
      });
      _loadMonthCheckins();
    }
  }

  Future<void> _toggleCheckin(String entryId, bool value) async {
    final key = '${entryId}_${_fmt(_selectedDate)}';
    setState(() => _monthCheckins[key] = value);
    await _checkinRepo.setCheckin(entryId, _selectedDate, value);
  }

  /// 선택된 날짜의 체크인 (entryId → isDone)
  Map<String, bool> get _selectedDateCheckins {
    final suffix = '_${_fmt(_selectedDate)}';
    final result = <String, bool>{};
    for (final e in _monthCheckins.entries) {
      if (e.key.endsWith(suffix)) {
        result[e.key.substring(0, e.key.length - suffix.length)] = e.value;
      }
    }
    return result;
  }

  List<ScheduleEntry> _entriesForDate(
    List<ScheduleEntry> goals,
    DateTime date,
  ) =>
      goals.where((e) => isApplicableOnDate(e, date)).toList();

  String _selectedDateLabel() {
    final today = _today();
    final d = _selectedDate;
    final weekdays = ['월', '화', '수', '목', '금', '토', '일'];
    final weekday = weekdays[d.weekday - 1];
    if (d == today) return '오늘 ($weekday)';
    final diff = d.difference(today).inDays;
    if (diff == 1) return '내일 ($weekday)';
    if (diff == -1) return '어제 ($weekday)';
    return '${d.month}월 ${d.day}일 ($weekday)';
  }

  @override
  Widget build(BuildContext context) {
    final goals = GoalsProvider.of(context).goals;
    final selectedEntries = _entriesForDate(goals, _selectedDate);
    final checkins = _selectedDateCheckins;
    final doneCount = selectedEntries.where((e) => checkins[e.id] ?? false).length;
    final totalCount = selectedEntries.length;
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
            title: const Text(
              '루틴',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  final today = _today();
                  setState(() {
                    _selectedDate = today;
                    _displayMonth = today;
                  });
                  _loadMonthCheckins();
                },
                style: TextButton.styleFrom(foregroundColor: Colors.white),
                child: const Text(
                  '오늘',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),

          // 달력
          SliverToBoxAdapter(
            child: _isLoading && _monthCheckins.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(child: CircularProgressIndicator()),
                  )
                : RoutineCalendar(
                    displayMonth: _displayMonth,
                    selectedDate: _selectedDate,
                    goals: goals,
                    monthCheckins: _monthCheckins,
                    onDateSelected: _onDateSelected,
                    onMonthChanged: _onMonthChanged,
                  ),
          ),

          // 선택한 날짜 헤더 + 진행 바
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _selectedDateLabel(),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (totalCount > 0) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          '루틴',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '$doneCount / $totalCount',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: totalCount == 0 ? 0 : doneCount / totalCount,
                        minHeight: 8,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation<Color>(primary),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ],
              ),
            ),
          ),

          // 루틴 리스트 or 빈 상태
          if (selectedEntries.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.checklist_outlined,
                        size: 64,
                        color: Colors.grey.shade300,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '이 날의 루틴이 없어요',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '목표 탭에서 새 계획을 추가해보세요',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade400,
                        ),
                      ),
                      const SizedBox(height: 24),
                      FilledButton.tonal(
                        onPressed: () {
                          context
                              .findAncestorStateOfType<MainShellState>()
                              ?.switchTab(1);
                        },
                        child: const Text('목표 탭으로 가기'),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) {
                    final entry = selectedEntries[i];
                    return RoutineCheckItem(
                      entry: entry,
                      isDone: checkins[entry.id] ?? false,
                      onToggle: (v) => _toggleCheckin(entry.id, v),
                    );
                  },
                  childCount: selectedEntries.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
