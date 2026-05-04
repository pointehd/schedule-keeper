import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../shared/models/plan.dart';
import '../../shared/providers/plan_provider.dart';
import '../../shared/widgets/plan_form_widgets.dart';
import '../../shared/theme/app_colors.dart';

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
  late PlanScheduleType _scheduleMode;
  late Set<int> _repeatDays;
  late List<DateTime> _specificDates;
  bool _loaded = false;

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
        _scheduleMode = plan.scheduleType;
        _repeatDays = _scheduleMode == PlanScheduleType.weekdays
            ? Set.from(plan.repeatDays.where((d) => d >= 1 && d <= 7))
            : {};
        _specificDates = _scheduleMode == PlanScheduleType.specific
            ? List.from(plan.specificDates)
            : [];
      } else {
        _category = PlanCategory.study;
        _measureType = MeasureType.time;
        _target = 30;
        _scheduleMode = PlanScheduleType.daily;
        _repeatDays = {};
        _specificDates = [];
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
    final List<int> encodedRepeat;
    switch (_scheduleMode) {
      case PlanScheduleType.daily:
        encodedRepeat = [];
      case PlanScheduleType.floating:
        encodedRepeat = [-1];
      case PlanScheduleType.weekdays:
        encodedRepeat = _repeatDays.toList()..sort();
      case PlanScheduleType.specific:
        encodedRepeat =
            _specificDates.map(PlanVersion.dateToInt).toList()..sort();
    }
    context.read<PlanNotifier>().editPlan(
          widget.planId,
          name: _nameCtrl.text.trim(),
          category: _category,
          measureType: _measureType,
          target: _target,
          repeatDays: encodedRepeat,
        );
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kBg,
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
                  PlanSectionLabel('계획 이름'),
                  const SizedBox(height: 8),
                  PlanFormCard(
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
                  PlanSectionLabel('카테고리'),
                  const SizedBox(height: 8),
                  PlanCategorySelector(
                    selected: _category,
                    onChanged: (c) => setState(() => _category = c),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      PlanSectionLabel('측정 방식'),
                      const Text('계획 진행률을 어떻게 기록할지 골라주세요',
                          style: TextStyle(
                              fontSize: 11, color: Color(0xFF888888))),
                    ],
                  ),
                  const SizedBox(height: 8),
                  PlanMeasureTypeSelector(
                    selected: _measureType,
                    onChanged: (m) => setState(() {
                      _measureType = m;
                      if (m == MeasureType.check) _target = 1;
                    }),
                  ),
                  if (_measureType != MeasureType.check) ...[
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        PlanSectionLabel(_measureType == MeasureType.time
                            ? '목표 시간'
                            : '목표 개수'),
                        const Text('하루 목표',
                            style: TextStyle(
                                fontSize: 11, color: Color(0xFF888888))),
                      ],
                    ),
                    const SizedBox(height: 8),
                    PlanTargetSection(
                      measureType: _measureType,
                      target: _target,
                      onChanged: (v) => setState(() => _target = v),
                    ),
                  ],
                  const SizedBox(height: 20),
                  PlanSectionLabel('일정'),
                  const SizedBox(height: 8),
                  PlanScheduleSelector(
                    scheduleMode: _scheduleMode,
                    repeatDays: _repeatDays,
                    specificDates: _specificDates,
                    onScheduleModeChanged: (m) =>
                        setState(() => _scheduleMode = m),
                    onRepeatDaysChanged: (d) =>
                        setState(() => _repeatDays = d),
                    onSpecificDatesChanged: (d) =>
                        setState(() => _specificDates = d),
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
      child: const Row(
        children: [
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
