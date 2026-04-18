import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../measurement_type.dart';
import '../models/measurement_config.dart';

class MeasurementSelector extends StatefulWidget {
  const MeasurementSelector({
    super.key,
    this.onChanged,
    this.initialType,
    this.initialPeriodLabel,
    this.initialValue,
    this.initialDeadline,
  });

  final ValueChanged<MeasurementConfig?>? onChanged;
  final MeasurementType? initialType;
  final String? initialPeriodLabel; // 저장된 period 문자열 ('하루', '일주일', '한달')
  final int? initialValue;
  final DateTime? initialDeadline;

  @override
  State<MeasurementSelector> createState() => _MeasurementSelectorState();
}

class _MeasurementSelectorState extends State<MeasurementSelector> {
  MeasurementType? _selectedType;
  TimePeriod? _selectedTimePeriod;
  CountPeriod? _selectedCountPeriod;
  DateTime? _deadline;
  final _valueController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // 수정 모드 초기값 세팅
    _selectedType = widget.initialType;
    if (widget.initialType == MeasurementType.time) {
      _selectedTimePeriod = TimePeriod.values.firstWhere(
        (p) => p.label == widget.initialPeriodLabel,
        orElse: () => TimePeriod.daily,
      );
    } else if (widget.initialType == MeasurementType.count) {
      _selectedCountPeriod = CountPeriod.values.firstWhere(
        (p) => p.label == widget.initialPeriodLabel,
        orElse: () => CountPeriod.daily,
      );
    }
    _deadline = widget.initialDeadline;
    if (widget.initialValue != null) {
      _valueController.text = widget.initialValue.toString();
    }
    _valueController.addListener(_notify);
  }

  @override
  void dispose() {
    _valueController.dispose();
    super.dispose();
  }

  void _notify() {
    if (widget.onChanged == null) return;
    if (_selectedType == null) {
      widget.onChanged!(null);
      return;
    }
    final config = MeasurementConfig(
      type: _selectedType!,
      period: _selectedType == MeasurementType.time
          ? _selectedTimePeriod?.label
          : _selectedType == MeasurementType.count
              ? _selectedCountPeriod?.label
              : null,
      value: int.tryParse(_valueController.text),
      deadline: _deadline,
    );
    widget.onChanged!(config);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('측정 방식'),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: MeasurementType.values.map((type) {
            final isSelected = _selectedType == type;
            return _TypeCard(
              label: type.label,
              isSelected: isSelected,
              onTap: () {
                setState(() {
                  _selectedType = isSelected ? null : type;
                  _selectedTimePeriod = null;
                  _selectedCountPeriod = null;
                  _deadline = null;
                  _valueController.clear();
                });
                _notify();
              },
            );
          }).toList(),
        ),
        if (_selectedType != null) ...[
          const SizedBox(height: 20),
          _buildSubOptions(),
        ],
      ],
    );
  }

  Widget _buildSubOptions() {
    return switch (_selectedType!) {
      MeasurementType.time => _buildTimeOptions(),
      MeasurementType.count => _buildCountOptions(),
      MeasurementType.completion => _buildCompletionOptions(),
    };
  }

  Widget _buildTimeOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('기간'),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: TimePeriod.values.map((period) {
            final isSelected = _selectedTimePeriod == period;
            return _PeriodChip(
              label: period.label,
              isSelected: isSelected,
              onTap: () {
                setState(() => _selectedTimePeriod = isSelected ? null : period);
                _notify();
              },
            );
          }).toList(),
        ),
        if (_selectedTimePeriod != null) ...[
          const SizedBox(height: 16),
          _sectionLabel('목표 시간'),
          const SizedBox(height: 10),
          _NumberInput(controller: _valueController, suffix: '시간'),
        ],
      ],
    );
  }

  Widget _buildCountOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('기간'),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: CountPeriod.values.map((period) {
            final isSelected = _selectedCountPeriod == period;
            return _PeriodChip(
              label: period.label,
              isSelected: isSelected,
              onTap: () {
                setState(() => _selectedCountPeriod = isSelected ? null : period);
                _notify();
              },
            );
          }).toList(),
        ),
        if (_selectedCountPeriod != null) ...[
          const SizedBox(height: 16),
          _sectionLabel('목표 횟수'),
          const SizedBox(height: 10),
          _NumberInput(controller: _valueController, suffix: '번'),
        ],
      ],
    );
  }

  Widget _buildCompletionOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('완료 기한'),
        const SizedBox(height: 10),
        _DateButton(
          deadline: _deadline,
          onPicked: (date) {
          setState(() => _deadline = date);
          _notify();
        },
        ),
      ],
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 12,
        color: Colors.grey.shade500,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
    );
  }
}

class _TypeCard extends StatelessWidget {
  const _TypeCard({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: isSelected ? primary.withValues(alpha: 0.08) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? primary : Colors.grey.shade300,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: isSelected ? primary : Colors.grey.shade600,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _PeriodChip extends StatelessWidget {
  const _PeriodChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? primary.withValues(alpha: 0.08) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? primary : Colors.grey.shade300,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isSelected ? primary : Colors.grey.shade500,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _NumberInput extends StatelessWidget {
  const _NumberInput({required this.controller, required this.suffix});

  final TextEditingController controller;
  final String suffix;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 80,
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: primary, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: primary, width: 1.5),
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(suffix, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
      ],
    );
  }
}

class _DateButton extends StatelessWidget {
  const _DateButton({required this.deadline, required this.onPicked});

  final DateTime? deadline;
  final ValueChanged<DateTime> onPicked;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: deadline ?? DateTime.now(),
          firstDate: DateTime(DateTime.now().year - 10),
          lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
        );
        if (picked != null) onPicked(picked);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: deadline != null ? primary.withValues(alpha: 0.06) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: deadline != null ? primary : Colors.grey.shade300,
            width: deadline != null ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 15,
              color: deadline != null ? primary : Colors.grey.shade400,
            ),
            const SizedBox(width: 8),
            Text(
              deadline != null
                  ? '${deadline!.year}.${deadline!.month.toString().padLeft(2, '0')}.${deadline!.day.toString().padLeft(2, '0')}'
                  : '날짜 선택',
              style: TextStyle(
                fontSize: 13,
                color: deadline != null ? primary : Colors.grey.shade500,
                fontWeight: deadline != null ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
