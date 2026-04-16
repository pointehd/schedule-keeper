import 'package:flutter/material.dart';
import '../../shared/widgets/page_sliver_app_bar.dart';
import 'models/measurement_config.dart';
import 'models/schedule_entry.dart';
import 'repositories/schedule_repository.dart';
import 'schedule_category.dart';
import 'widgets/category_card.dart';
import 'widgets/measurement_selector.dart';

class SchedulePage extends StatefulWidget {
  const SchedulePage({super.key});

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  ScheduleCategory? _selectedCategory;
  MeasurementConfig? _measurementConfig;
  int _resetKey = 0;
  bool _isSaving = false;

  final _repository = ScheduleRepository();

  void _reset() {
    setState(() {
      _selectedCategory = null;
      _measurementConfig = null;
      _resetKey++;
    });
  }

  bool get _canSave =>
      _selectedCategory != null &&
      _measurementConfig != null &&
      _measurementConfig!.isComplete;

  Future<void> _save() async {
    if (!_canSave) return;
    setState(() => _isSaving = true);

    final entry = ScheduleEntry(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      category: _selectedCategory!,
      measurementType: _measurementConfig!.type,
      period: _measurementConfig!.period,
      value: _measurementConfig!.value,
      deadline: _measurementConfig!.deadline,
      createdAt: DateTime.now(),
    );

    await _repository.save(entry);
    setState(() => _isSaving = false);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${entry.category.label} 계획이 저장됐어요.'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
    _reset();
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return CustomScrollView(
      slivers: [
        PageSliverAppBar(title: '계획 추가', onRefresh: _reset),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              Text(
                '카테고리',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
              ),
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
                onChanged: (config) =>
                    setState(() => _measurementConfig = config),
              ),
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
                          '확인',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: _canSave ? Colors.white : Colors.grey.shade400,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
