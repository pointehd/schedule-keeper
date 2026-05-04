import 'package:flutter/material.dart';
import '../../features/home/home_page.dart';
import '../../features/plan/plan_page.dart';
import '../../features/calendar/calendar_page.dart';
import '../../features/mypage/my_page.dart';
import '../../features/add_plan/add_plan_page.dart';

const Color kPrimary = Color(0xFF5B5FC7);

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _index = 0;      // 0=홈 1=계획 2=캘린더 3=내정보 4=새계획
  int _prevIndex = 0;  // 새계획 열기 직전 탭
  String? _focusedPlanId;

  void _openAddPlan() {
    if (_index == 4) return;
    setState(() {
      _prevIndex = _index;
      _index = 4;
    });
  }

  void _closeAddPlan() => setState(() => _index = _prevIndex);

  void _onSaved() => setState(() => _index = 1);

  void _navigateToPlan(String planId) {
    setState(() {
      _focusedPlanId = planId;
      _prevIndex = 1;
      _index = 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F3F8),
      body: IndexedStack(
        index: _index,
        children: [
          HomePage(onNavigateToPlan: _navigateToPlan),
          PlanPage(focusedPlanId: _focusedPlanId),
          const CalendarPage(),
          const MyPage(),
          AddPlanPage(
            onCancel: _closeAddPlan,
            onSaved: _onSaved,
          ),
        ],
      ),
      bottomNavigationBar: _BottomNav(
        tabIndex: _index < 4 ? _index : -1,
        addPlanActive: _index == 4,
        onTap: (i) => setState(() {
          if (i != 1) _focusedPlanId = null;
          _prevIndex = i;
          _index = i;
        }),
        onAdd: _openAddPlan,
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  final int tabIndex;        // 활성 탭 (0-3), -1이면 없음
  final bool addPlanActive;
  final void Function(int) onTap;
  final VoidCallback onAdd;

  const _BottomNav({
    required this.tabIndex,
    required this.addPlanActive,
    required this.onTap,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 16,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              _NavItem(icon: Icons.home_outlined, activeIcon: Icons.home_rounded,
                  label: '홈', index: 0, tabIndex: tabIndex, onTap: onTap),
              _NavItem(icon: Icons.flag_outlined, activeIcon: Icons.flag,
                  label: '계획', index: 1, tabIndex: tabIndex, onTap: onTap),
              Expanded(
                child: Center(
                  child: GestureDetector(
                    onTap: onAdd,
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: addPlanActive
                            ? kPrimary.withValues(alpha: 0.75)
                            : kPrimary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.add, color: Colors.white, size: 28),
                    ),
                  ),
                ),
              ),
              _NavItem(icon: Icons.calendar_month_outlined, activeIcon: Icons.calendar_month,
                  label: '캘린더', index: 2, tabIndex: tabIndex, onTap: onTap),
              _NavItem(icon: Icons.person_outline, activeIcon: Icons.person,
                  label: '내정보', index: 3, tabIndex: tabIndex, onTap: onTap),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int index;
  final int tabIndex;
  final void Function(int) onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.index,
    required this.tabIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = index == tabIndex;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onTap(index),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              color: isActive ? kPrimary : const Color(0xFFB0B0B0),
              size: 24,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: isActive ? kPrimary : const Color(0xFFB0B0B0),
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
