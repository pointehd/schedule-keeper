import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../shared/models/plan.dart';
import '../../shared/providers/plan_provider.dart';

const Color kPrimary = Color(0xFF5B5FC7);

class EditPlanPage extends StatefulWidget {
  final String planId;
  const EditPlanPage({super.key, required this.planId});

  @override
  State<EditPlanPage> createState() => _EditPlanPageState();
}

class _EditPlanPageState extends State<EditPlanPage> {
  final _nameCtrl = TextEditingController();
  late PlanCategory _category;
  late MeasureType _measureType;
  late double _target;
  late Set<int> _repeatDays;
  bool _loaded = false;

  static const _weekdayLabels = ['월', '화', '수', '목', '금', '토', '일'];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loaded) {
      final plan =
          context.read<PlanNotifier>().currentPlanSnapshot(widget.planId);
      if (plan != null) {
        _nameCtrl.text = plan.name;
        _category = plan.category;
        _measureType = plan.measureType;
        _target = plan.target;
        _repeatDays = Set.from(plan.repeatDays);
      } else {
        _category = PlanCategory.study;
        _measureType = MeasureType.time;
        _target = 30;
        _repeatDays = {};
      }
      _loaded = true;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  bool get _canSave => _nameCtrl.text.trim().isNotEmpty;

  void _save() {
    if (!_canSave) return;
    context.read<PlanNotifier>().editPlan(
          widget.planId,
          name: _nameCtrl.text.trim(),
          category: _category,
          measureType: _measureType,
          target: _target,
          repeatDays: _repeatDays.toList()..sort(),
        );
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F3F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF2F3F8),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          color: const Color(0xFF888888),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('계획 수정',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildVersionNotice(),
                  const SizedBox(height: 16),
                  _SectionLabel('계획 이름'),
                  const SizedBox(height: 8),
                  _Card(
                    child: TextField(
                      controller: _nameCtrl,
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        hintText: '계획 이름을 입력하세요',
                        hintStyle: TextStyle(color: Color(0xFFBBBBBB)),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _SectionLabel('카테고리'),
                  const SizedBox(height: 8),
                  _Card(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: PlanCategory.values.map((c) {
                        final sel = c == _category;
                        return GestureDetector(
                          onTap: () => setState(() => _category = c),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 7),
                            decoration: BoxDecoration(
                              color: sel
                                  ? c.color.withValues(alpha: 0.15)
                                  : const Color(0xFFF5F5F5),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: sel ? c.color : Colors.transparent),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                      color: c.color, shape: BoxShape.circle),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  c.label,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: sel
                                        ? c.color
                                        : const Color(0xFF555555),
                                    fontWeight: sel
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _SectionLabel('측정 방식'),
                      const Text('계획 진행률을 어떻게 기록할지 골라주세요',
                          style:
                              TextStyle(fontSize: 11, color: Color(0xFF888888))),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: MeasureType.values.asMap().entries.map((e) {
                      final m = e.value;
                      final sel = m == _measureType;
                      final isLast = e.key == MeasureType.values.length - 1;
                      final icon = switch (m) {
                        MeasureType.time => Icons.access_time_rounded,
                        MeasureType.count => Icons.tag,
                        MeasureType.check => Icons.check_circle_outline,
                      };
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() {
                            _measureType = m;
                            if (m == MeasureType.check) _target = 1;
                          }),
                          child: Container(
                            margin: isLast
                                ? EdgeInsets.zero
                                : const EdgeInsets.only(right: 8),
                            padding:
                                const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: sel ? kPrimary : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: sel
                                      ? kPrimary
                                      : const Color(0xFFEEEEEE)),
                            ),
                            child: Column(
                              children: [
                                Icon(icon,
                                    color: sel
                                        ? Colors.white
                                        : const Color(0xFF888888),
                                    size: 24),
                                const SizedBox(height: 6),
                                Text(m.label,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: sel
                                          ? Colors.white
                                          : const Color(0xFF333333),
                                    )),
                                Text(m.subtitle,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: sel
                                          ? Colors.white70
                                          : const Color(0xFF888888),
                                    )),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  if (_measureType != MeasureType.check) ...[
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _SectionLabel(_measureType == MeasureType.time
                            ? '목표 시간'
                            : '목표 개수'),
                        const Text('하루 목표',
                            style: TextStyle(
                                fontSize: 11, color: Color(0xFF888888))),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _Card(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            '${_target.round()}',
                            style: const TextStyle(
                                fontSize: 36, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _measureType == MeasureType.time ? '분' : '개',
                            style: const TextStyle(
                                fontSize: 18, color: Color(0xFF888888)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: _measureType == MeasureType.time
                          ? [
                              _QuickBtn(
                                  label: '10분',
                                  selected: _target == 10,
                                  onTap: () => setState(() => _target = 10)),
                              _QuickBtn(
                                  label: '30분',
                                  selected: _target == 30,
                                  onTap: () => setState(() => _target = 30)),
                              _QuickBtn(
                                  label: '1h',
                                  selected: _target == 60,
                                  onTap: () => setState(() => _target = 60)),
                              _QuickBtn(
                                  label: '2h',
                                  selected: _target == 120,
                                  onTap: () => setState(() => _target = 120)),
                            ]
                          : [
                              _QuickBtn(
                                  label: '5개',
                                  selected: _target == 5,
                                  onTap: () => setState(() => _target = 5)),
                              _QuickBtn(
                                  label: '10개',
                                  selected: _target == 10,
                                  onTap: () => setState(() => _target = 10)),
                              _QuickBtn(
                                  label: '20개',
                                  selected: _target == 20,
                                  onTap: () => setState(() => _target = 20)),
                              _QuickBtn(
                                  label: '30개',
                                  selected: _target == 30,
                                  onTap: () => setState(() => _target = 30)),
                            ],
                    ),
                  ],
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _SectionLabel('반복 요일'),
                      const Text('선택하지 않으면 매일 반복됩니다',
                          style: TextStyle(
                              fontSize: 11, color: Color(0xFF888888))),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _Card(
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: List.generate(7, (i) {
                            final day = i + 1;
                            final sel = _repeatDays.contains(day);
                            return GestureDetector(
                              onTap: () => setState(() => sel
                                  ? _repeatDays.remove(day)
                                  : _repeatDays.add(day)),
                              child: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: sel
                                      ? kPrimary
                                      : const Color(0xFFF5F5F5),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Center(
                                  child: Text(
                                    _weekdayLabels[i],
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: sel
                                          ? Colors.white
                                          : const Color(0xFF555555),
                                      fontWeight: sel
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            _QuickDayBtn(
                              label: '평일',
                              onTap: () => setState(() {
                                _repeatDays
                                  ..clear()
                                  ..addAll([1, 2, 3, 4, 5]);
                              }),
                            ),
                            const SizedBox(width: 8),
                            _QuickDayBtn(
                              label: '주말',
                              onTap: () => setState(() {
                                _repeatDays
                                  ..clear()
                                  ..addAll([6, 7]);
                              }),
                            ),
                            const SizedBox(width: 8),
                            _QuickDayBtn(
                              label: '매일',
                              onTap: () =>
                                  setState(() => _repeatDays.clear()),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                    color: Color(0x0F000000),
                    blurRadius: 8,
                    offset: Offset(0, -2))
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _canSave ? _save : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimary,
                  disabledBackgroundColor: const Color(0xFFDDDDDD),
                  foregroundColor: Colors.white,
                  disabledForegroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('수정 저장',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVersionNotice() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: kPrimary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: const [
          Icon(Icons.info_outline, size: 16, color: kPrimary),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              '오늘부터 변경 내용이 적용됩니다. 이전 날짜의 기록은 유지됩니다.',
              style: TextStyle(fontSize: 12, color: kPrimary),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1A1A)));
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: child,
    );
  }
}

class _QuickBtn extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _QuickBtn(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? kPrimary.withValues(alpha: 0.1)
              : const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(20),
          border:
              Border.all(color: selected ? kPrimary : Colors.transparent),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 13,
                color: selected ? kPrimary : const Color(0xFF555555),
                fontWeight:
                    selected ? FontWeight.w600 : FontWeight.normal)),
      ),
    );
  }
}

class _QuickDayBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _QuickDayBtn({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label,
            style: const TextStyle(fontSize: 13, color: Color(0xFF555555))),
      ),
    );
  }
}
