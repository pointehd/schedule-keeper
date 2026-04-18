import 'package:flutter/material.dart';
import '../../shared/providers/goals_provider.dart';
import '../../shared/widgets/page_sliver_app_bar.dart';
import 'models/measurement_config.dart';
import 'models/schedule_entry.dart';
import 'repositories/schedule_repository.dart';
import 'schedule_category.dart';
import 'measurement_type.dart';
import 'widgets/category_card.dart';
import 'widgets/measurement_selector.dart';

class SchedulePage extends StatefulWidget {
  /// 수정 모드일 때 기존 항목을 전달한다. null이면 신규 생성 모드.
  const SchedulePage({super.key, this.initialEntry});

  final ScheduleEntry? initialEntry;

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  late final TextEditingController _titleController;
  ScheduleCategory? _selectedCategory;
  MeasurementConfig? _measurementConfig;
  late final Set<int> _repeatDays;
  int _resetKey = 0;
  bool _isSaving = false;

  final _repository = ScheduleRepository();

  static const _dayLabels = ['월', '화', '수', '목', '금', '토', '일'];

  bool get _isEditMode => widget.initialEntry != null;

  bool get _showRepeatDays =>
      _measurementConfig?.type == MeasurementType.time ||
      _measurementConfig?.type == MeasurementType.count;

  @override
  void initState() {
    super.initState();
    final e = widget.initialEntry;
    _titleController = TextEditingController(text: e?.title ?? '');
    _selectedCategory = e?.category;
    _repeatDays = Set<int>.from(e?.repeatDays ?? []);
    _titleController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  void _reset() {
    setState(() {
      _titleController.clear();
      _selectedCategory = null;
      _measurementConfig = null;
      _repeatDays.clear();
      _resetKey++;
    });
  }

  bool get _canSave =>
      _titleController.text.trim().isNotEmpty &&
      _selectedCategory != null &&
      _measurementConfig != null &&
      _measurementConfig!.isComplete;

  Future<void> _save() async {
    if (!_canSave) return;
    setState(() => _isSaving = true);

    final sortedDays = _showRepeatDays ? (_repeatDays.toList()..sort()) : <int>[];

    if (_isEditMode) {
      // 수정 모드: 기존 entry 업데이트
      final updated = widget.initialEntry!.copyWith(
        title: _titleController.text.trim(),
        category: _selectedCategory,
        measurementType: _measurementConfig!.type,
        period: _measurementConfig!.period,
        value: _measurementConfig!.value,
        deadline: _measurementConfig!.deadline,
        repeatDays: sortedDays,
      );
      await _repository.update(updated);
      if (!mounted) return;
      GoalsProvider.of(context).updateGoal(updated);
      setState(() => _isSaving = false);
      Navigator.pop(context);
    } else {
      // 신규 생성 모드
      final entry = ScheduleEntry(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        title: _titleController.text.trim(),
        category: _selectedCategory!,
        measurementType: _measurementConfig!.type,
        period: _measurementConfig!.period,
        value: _measurementConfig!.value,
        deadline: _measurementConfig!.deadline,
        repeatDays: sortedDays,
        createdAt: DateTime.now(),
      );
      await _repository.save(entry);
      if (!mounted) return;
      GoalsProvider.of(context).load();
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('\'${entry.title}\' 계획이 저장됐어요.'),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
      _reset();
    }
  }

  Widget _buildSectionLabel(BuildContext context, String text) {
    return Text(
      text,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: Colors.grey.shade500,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
    );
  }

  Widget _buildRepeatDaysSection(Color primary) {
    final allSelected = _repeatDays.isEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '반복 요일',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade500,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              allSelected ? '매일' : '선택한 요일만',
              style: TextStyle(
                fontSize: 11,
                color: allSelected ? Colors.grey.shade400 : primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: List.generate(7, (i) {
            final weekday = i + 1;
            final isSelected = _repeatDays.contains(weekday);
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() {
                  isSelected
                      ? _repeatDays.remove(weekday)
                      : _repeatDays.add(weekday);
                }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  margin: EdgeInsets.only(right: i < 6 ? 5 : 0),
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? primary.withValues(alpha: 0.08)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected ? primary : Colors.grey.shade300,
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Text(
                    _dayLabels[i],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.normal,
                      color: isSelected ? primary : Colors.grey.shade500,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 6),
        Text(
          '선택하지 않으면 매일 표시됩니다',
          style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final e = widget.initialEntry;

    final body = CustomScrollView(
      slivers: [
        if (!_isEditMode)
          PageSliverAppBar(title: '계획 추가', onRefresh: _reset)
        else
          SliverAppBar(
            floating: true,
            snap: true,
            backgroundColor: primary,
            foregroundColor: Colors.white,
            title: const Text(
              '계획 수정',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            leading: const BackButton(),
          ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _buildSectionLabel(context, '계획 이름'),
              const SizedBox(height: 8),
              TextField(
                controller: _titleController,
                textInputAction: TextInputAction.next,
                maxLength: 40,
                decoration: InputDecoration(
                  hintText: '예: 매일 영어 단어 30개',
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  counterText: '',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: primary, width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
              const SizedBox(height: 28),
              const Divider(height: 1),
              const SizedBox(height: 24),
              _buildSectionLabel(context, '카테고리'),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ScheduleCategory.values.map((category) {
                  return CategoryCard(
                    category: category,
                    isSelected: _selectedCategory == category,
                    onTap: () => setState(() {
                      _selectedCategory =
                          _selectedCategory == category ? null : category;
                    }),
                  );
                }).toList(),
              ),
              const SizedBox(height: 28),
              const Divider(height: 1),
              const SizedBox(height: 24),
              MeasurementSelector(
                key: ValueKey(_resetKey),
                initialType: e?.measurementType,
                initialPeriodLabel: e?.period,
                initialValue: e?.value,
                initialDeadline: e?.deadline,
                onChanged: (config) => setState(() {
                  _measurementConfig = config;
                  if (config?.type == MeasurementType.completion) {
                    _repeatDays.clear();
                  }
                }),
              ),
              if (_showRepeatDays) ...[
                const SizedBox(height: 24),
                const Divider(height: 1),
                const SizedBox(height: 24),
                _buildRepeatDaysSection(primary),
              ],
            ]),
          ),
        ),
        SliverFillRemaining(
          hasScrollBody: false,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton(
                  onPressed: _canSave && !_isSaving ? _save : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: primary,
                    disabledBackgroundColor: Colors.grey.shade200,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          _isEditMode ? '저장' : '확인',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: _canSave
                                ? Colors.white
                                : Colors.grey.shade400,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ),
      ],
    );

    // 수정 모드는 별도 Scaffold로 push, 탭 모드는 그대로
    return _isEditMode ? Scaffold(body: body) : body;
  }
}
