import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../shared/models/plan.dart';
import '../../shared/providers/plan_provider.dart';
import '../../shared/widgets/plan_form_widgets.dart';
import '../../shared/theme/app_colors.dart';

class AddPlanPage extends StatefulWidget {
  final VoidCallback onCancel;
  final VoidCallback onSaved;

  const AddPlanPage({
    super.key,
    required this.onCancel,
    required this.onSaved,
  });

  @override
  State<AddPlanPage> createState() => _AddPlanPageState();
}

class _AddPlanPageState extends State<AddPlanPage> {
  final _nameCtrl = TextEditingController();
  PlanCategory _category = PlanCategory.study;
  MeasureType _measureType = MeasureType.time;
  double _target = 30;
  PlanScheduleType _scheduleMode = PlanScheduleType.daily;
  Set<int> _repeatDays = {};
  List<DateTime> _specificDates = [];

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  bool get _canSave => _nameCtrl.text.trim().isNotEmpty;

  void _reset() {
    _nameCtrl.clear();
    setState(() {
      _category = PlanCategory.study;
      _measureType = MeasureType.time;
      _target = 30;
      _scheduleMode = PlanScheduleType.daily;
      _repeatDays = {};
      _specificDates = [];
    });
  }

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
    context.read<PlanNotifier>().addPlan(Plan(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: _nameCtrl.text.trim(),
          category: _category,
          measureType: _measureType,
          target: _target,
          repeatDays: encodedRepeat,
          createdDate: DateTime.now(),
        ));
    _reset();
    widget.onSaved();
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
          onPressed: widget.onCancel,
        ),
        title: const Text('새 계획',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            color: const Color(0xFF888888),
            tooltip: '초기화',
            onPressed: _reset,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  PlanSectionLabel('계획 이름'),
                  const SizedBox(height: 8),
                  PlanFormCard(
                    child: TextField(
                      controller: _nameCtrl,
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        hintText: '예: 매일 영어 단어 30개',
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
                  offset: Offset(0, -2),
                ),
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
                child: const Text('저장',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
