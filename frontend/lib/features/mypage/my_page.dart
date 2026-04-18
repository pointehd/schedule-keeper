import 'package:flutter/material.dart';
import '../../shared/providers/goals_provider.dart';
import '../../shared/providers/settings_provider.dart';
import '../../shared/widgets/page_sliver_app_bar.dart';
import '../routine/repositories/routine_checkin_repository.dart';
import 'widgets/stat_row.dart';

class MyPage extends StatefulWidget {
  const MyPage({super.key});

  @override
  State<MyPage> createState() => _MyPageState();
}

class _MyPageState extends State<MyPage> {
  final _checkinRepo = RoutineCheckinRepository();
  int _streak = 0;
  double _weeklyRate = 0.0;
  bool _isLoading = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final goals = GoalsProvider.of(context).goals;
    final streak = await _checkinRepo.calcStreak();

    // 이번 주 달성률: 각 목표의 이번 주 체크인 수 합산 / (목표 수 * 7)
    double weeklyRate = 0.0;
    if (goals.isNotEmpty) {
      int totalCheckins = 0;
      for (final goal in goals) {
        totalCheckins += await _checkinRepo.thisWeekCheckinCount(goal.id);
      }
      weeklyRate = (totalCheckins / (goals.length * 7)).clamp(0.0, 1.0);
    }

    if (mounted) {
      setState(() {
        _streak = streak;
        _weeklyRate = weeklyRate;
        _isLoading = false;
      });
    }
  }

  void _adjustFreeTime(double delta) {
    final current = SettingsProvider.of(context).freeTimeHours;
    SettingsProvider.of(context).setFreeTimeHours(current + delta);
  }

  @override
  Widget build(BuildContext context) {
    final goals = GoalsProvider.of(context).goals;
    final freeTime = SettingsProvider.of(context).freeTimeHours;
    final primary = Theme.of(context).colorScheme.primary;

    String freeTimeLabel() {
      if (freeTime == 0) return '0h';
      if (freeTime % 1 == 0) return '${freeTime.toInt()}h';
      return '${freeTime}h';
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: CustomScrollView(
        slivers: [
          const PageSliverAppBar(title: '마이페이지'),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 프로필 섹션
                  Center(
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: Colors.grey.shade200,
                          child: Icon(
                            Icons.person_outline,
                            size: 44,
                            color: Colors.grey.shade400,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          '게스트',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '로그인하면 데이터가 동기화됩니다',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade500,
                          ),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton(
                          onPressed: () {},
                          style: OutlinedButton.styleFrom(
                            foregroundColor: primary,
                            side: BorderSide(color: primary),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: const Text('로그인 / 회원가입'),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),
                  const Divider(height: 1),
                  const SizedBox(height: 24),

                  // 여유시간 설정
                  _SectionCard(
                    title: '오늘 여유시간 설정',
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('하루 여유시간', style: TextStyle(fontSize: 14)),
                        Row(
                          children: [
                            IconButton(
                              onPressed: freeTime > 0
                                  ? () => _adjustFreeTime(-0.5)
                                  : null,
                              icon: const Icon(Icons.remove_circle_outline),
                              color: primary,
                              constraints: const BoxConstraints(),
                              padding: const EdgeInsets.all(4),
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              child: Text(
                                freeTimeLabel(),
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: primary,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: freeTime < 24
                                  ? () => _adjustFreeTime(0.5)
                                  : null,
                              icon: const Icon(Icons.add_circle_outline),
                              color: primary,
                              constraints: const BoxConstraints(),
                              padding: const EdgeInsets.all(4),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 통계 섹션
                  _SectionCard(
                    title: '통계',
                    child: _isLoading
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(8),
                              child: CircularProgressIndicator(),
                            ),
                          )
                        : Column(
                            children: [
                              StatRow(
                                label: '활성 목표',
                                value: '${goals.length}개',
                              ),
                              const Divider(height: 1),
                              StatRow(
                                label: '현재 스트릭',
                                value: '$_streak일 연속',
                              ),
                              const Divider(height: 1),
                              StatRow(
                                label: '이번 주 달성률',
                                value: '${(_weeklyRate * 100).round()}%',
                              ),
                            ],
                          ),
                  ),

                  const SizedBox(height: 32),

                  Center(
                    child: Text(
                      '버전 1.0.0',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade400,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade500,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}
