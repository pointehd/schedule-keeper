import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../shared/providers/plan_provider.dart';
import '../../shared/models/plan.dart';
import '../../shared/widgets/page_header.dart';
import 'login_page.dart';

const Color kPrimary = Color(0xFF5B5FC7);
const Color kWeekend = Color(0xFFD4873A);
const Color kBg = Color(0xFFF2F3F8);

class MyPage extends StatelessWidget {
  const MyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _MyPageBody();
  }
}

class _MyPageBody extends StatelessWidget {
  const _MyPageBody();

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<PlanNotifier>();
    return _MyPageView(notifier: notifier);
  }
}

class _MyPageView extends StatefulWidget {
  final PlanNotifier notifier;
  const _MyPageView({required this.notifier});

  @override
  State<_MyPageView> createState() => _MyPageViewState();
}

class _MyPageViewState extends State<_MyPageView> {
  static const List<String> _dayNames = [
    '월요일',
    '화요일',
    '수요일',
    '목요일',
    '금요일',
    '토요일',
    '일요일',
  ];

  bool _isWeekend(int index) => index >= 5;

  @override
  Widget build(BuildContext context) {
    final notifier = widget.notifier;
    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(context),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    _buildProfileCard(notifier),
                    const SizedBox(height: 24),
                    _buildFreeTimeSection(notifier),
                    const SizedBox(height: 24),
                    _buildProjectSettings(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return const PageHeader(title: '설정');
  }

  Widget _buildProfileCard(PlanNotifier notifier) {
    if (!notifier.isLoggedIn) {
      return _buildLoginCard(notifier);
    }
    final name = notifier.userName!;
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: kPrimary,
            child: Text(
              initial,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  '연속 12일 · 누적 134회 달성',
                  style: TextStyle(fontSize: 12, color: Color(0xFF888888)),
                ),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF333333),
              side: const BorderSide(color: Color(0xFFDDDDDD)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            ),
            child: const Text('프로필 편집', style: TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginCard(PlanNotifier notifier) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: const Color(0xFFE8E8E8),
            child: const Icon(
              Icons.person_outline,
              size: 28,
              color: Color(0xFFAAAAAA),
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '로그인이 필요해요',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 4),
                Text(
                  '로그인하면 데이터를 안전하게 보관할 수 있어요.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF888888), height: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const LoginPage()),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            ),
            child: const Text('로그인', style: TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }


  Widget _buildFreeTimeSection(PlanNotifier notifier) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '요일별 여유시간',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        const Text(
          '하루에 계획에 쓸 수 있는 시간을 설정해주세요. 캘린더와 주간 계획에서 이 시간을 기준으로 배분 여유를 보여드려요.',
          style: TextStyle(fontSize: 12, color: Color(0xFF888888), height: 1.5),
        ),
        const SizedBox(height: 14),
        _buildWeeklySummaryCard(notifier),
        const SizedBox(height: 14),
        _buildPresetButtons(notifier),
        const SizedBox(height: 14),
        ...List.generate(
          _dayNames.length,
          (i) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _buildDaySliderCard(i, notifier),
          ),
        ),
      ],
    );
  }

  Widget _buildWeeklySummaryCard(PlanNotifier notifier) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFEEEFF8),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: kPrimary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.schedule_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '주간 여유시간',
                  style: TextStyle(
                    fontSize: 12,
                    color: kPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: fmtHours(notifier.weeklyFreeHours),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      const TextSpan(
                        text: '/주',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF555555),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: notifier.resetFreeHours,
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF555555),
              side: const BorderSide(color: Color(0xFFCCCCCC)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            ),
            child: const Text('초기화', style: TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _buildPresetButtons(PlanNotifier notifier) {
    final presets = [
      ('적게 (02:00)', 2.0),
      ('보통 (04:00)', 4.0),
      ('많이 (06:00)', 6.0),
    ];
    return Row(
      children: presets.map((p) {
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: OutlinedButton(
            onPressed: () {
              for (int i = 0; i < 7; i++) {
                notifier.setFreeHours(i, p.$2);
              }
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF444444),
              side: const BorderSide(color: Color(0xFFDDDDDD)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            ),
            child: Text(p.$1, style: const TextStyle(fontSize: 13)),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDaySliderCard(int index, PlanNotifier notifier) {
    final isWeekend = _isWeekend(index);
    final dotColor = isWeekend ? kWeekend : kPrimary;
    final sliderColor = isWeekend ? kWeekend : kPrimary;
    final hours = notifier.freeHours[index];

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.circle, size: 8, color: dotColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _dayNames[index],
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              _StepButton(
                icon: Icons.remove,
                outlined: true,
                onTap: () => notifier.setFreeHours(index, hours - 0.5),
              ),
              const SizedBox(width: 10),
              Text(
                fmtHours(hours),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(width: 10),
              _StepButton(
                icon: Icons.add,
                filled: true,
                color: kPrimary,
                onTap: () => notifier.setFreeHours(index, hours + 0.5),
              ),
            ],
          ),
          const SizedBox(height: 6),
          SliderTheme(
            data: SliderThemeData(
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
              activeTrackColor: sliderColor,
              inactiveTrackColor: const Color(0xFFE0E0E0),
              thumbColor: sliderColor,
              overlayColor: sliderColor.withValues(alpha: 0.15),
            ),
            child: Slider(
              value: hours,
              min: 0,
              max: 12,
              divisions: 24,
              onChanged: (v) => notifier.setFreeHours(index, v),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text(
                  '0h',
                  style: TextStyle(fontSize: 11, color: Color(0xFFAAAAAA)),
                ),
                Text(
                  '6h',
                  style: TextStyle(fontSize: 11, color: Color(0xFFAAAAAA)),
                ),
                Text(
                  '12h',
                  style: TextStyle(fontSize: 11, color: Color(0xFFAAAAAA)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '프로젝트 설정',
          style: TextStyle(
            fontSize: 13,
            color: Color(0xFF888888),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: [
              _SettingRow(
                icon: Icons.auto_awesome_outlined,
                label: '카테고리 관리',
                trailing: '7개',
                onTap: () {},
              ),
              const Divider(height: 1, indent: 52),
              _SettingRow(
                icon: Icons.water_drop_outlined,
                label: '알림 & 리마인더',
                trailing: '매일 21:00',
                onTap: () {},
              ),
              const Divider(height: 1, indent: 52),
              _SettingRow(
                icon: Icons.emoji_events_outlined,
                label: '통계 & 기록',
                onTap: () {},
              ),
              const Divider(height: 1, indent: 52),
              _SettingRow(
                icon: Icons.calendar_month_outlined,
                label: '한 주 시작일',
                trailing: '월요일',
                onTap: () {},
                showBorder: false,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StepButton extends StatelessWidget {
  final IconData icon;
  final bool outlined;
  final bool filled;
  final Color? color;
  final VoidCallback onTap;

  const _StepButton({
    required this.icon,
    this.outlined = false,
    this.filled = false,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: filled ? (color ?? kPrimary) : Colors.white,
          border: outlined ? Border.all(color: const Color(0xFFDDDDDD)) : null,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 18,
          color: filled ? Colors.white : const Color(0xFF555555),
        ),
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? trailing;
  final VoidCallback onTap;
  final bool showBorder;

  const _SettingRow({
    required this.icon,
    required this.label,
    this.trailing,
    required this.onTap,
    this.showBorder = true,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: const Color(0xFFF0F0F0),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 16, color: const Color(0xFF555555)),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(label, style: const TextStyle(fontSize: 15))),
            if (trailing != null)
              Text(
                trailing!,
                style: const TextStyle(fontSize: 13, color: Color(0xFF888888)),
              ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right, size: 18, color: Color(0xFFBBBBBB)),
          ],
        ),
      ),
    );
  }
}
