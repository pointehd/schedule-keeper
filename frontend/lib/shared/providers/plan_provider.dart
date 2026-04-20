import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/plan.dart';

const _kTimerId = 'timer_plan_id';
const _kTimerStartMs = 'timer_start_ms';
const _kFreeHours = 'free_hours';

class PlanNotifier extends ChangeNotifier {
  PlanNotifier() {
    _init();
  }

  late final Box<PlanRecord> _planBox;
  late final Box<DailyProgress> _progressBox;

  final List<double> _freeHours = [4, 4, 4, 4, 3, 6, 6];

  SharedPreferences? _prefs;
  String? _activeTimerId;
  DateTime? _timerStartedAt;
  Timer? _ticker;

  // ── helpers ───────────────────────────────────────────────

  static DateTime _dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

  static String _progressKey(String planId, DateTime date) {
    final d = _dateOnly(date);
    return '${planId}_${d.year}${d.month.toString().padLeft(2, '0')}${d.day.toString().padLeft(2, '0')}';
  }

  DailyProgress _progressFor(String planId, DateTime date) {
    final key = _progressKey(planId, date);
    if (!_progressBox.containsKey(key)) {
      _progressBox.put(key, DailyProgress(planId: planId, date: _dateOnly(date)));
    }
    return _progressBox.get(key)!;
  }

  // ── public getters ────────────────────────────────────────

  List<Plan> plansForDate(DateTime date) {
    final d = _dateOnly(date);
    final result = <Plan>[];
    for (final record in _planBox.values) {
      if (!record.appliesOnDate(d)) continue;
      final v = record.versionForDate(d)!;
      final prog = _progressFor(record.id, d);
      result.add(Plan(
        id: record.id,
        name: v.name,
        category: v.category,
        measureType: v.measureType,
        target: v.target,
        repeatDays: v.repeatDays,
        createdDate: record.createdDate,
        current: prog.current,
        isCompleted: prog.isCompleted,
      ));
    }
    return result;
  }

  List<Plan> get plans => plansForDate(DateTime.now());
  int get completedCount => plans.where((p) => p.isDone).length;
  int get totalCount => plans.length;
  double get overallProgress =>
      totalCount == 0 ? 0 : completedCount / totalCount;
  double get totalFocusHours => focusHoursForDate(DateTime.now());

  int completedCountForDate(DateTime date) =>
      plansForDate(date).where((p) => p.isDone).length;

  double focusHoursForDate(DateTime date) {
    final d = _dateOnly(date);
    final isToday = d == _dateOnly(DateTime.now());
    return plansForDate(d).fold(0.0, (sum, p) {
      if (p.measureType != MeasureType.time) return sum;
      final minutes =
          isToday ? getLiveMinutes(p.id) : _progressFor(p.id, d).current;
      return sum + minutes / 60;
    });
  }

  /// Returns the latest version of the plan (for pre-filling the edit form).
  Plan? currentPlanSnapshot(String id) {
    final record = _planBox.get(id);
    if (record == null) return null;
    final today = _dateOnly(DateTime.now());
    final v = record.versionForDate(today) ?? record.versions.last;
    return Plan(
      id: record.id,
      name: v.name,
      category: v.category,
      measureType: v.measureType,
      target: v.target,
      repeatDays: v.repeatDays,
      createdDate: record.createdDate,
    );
  }

  List<double> get freeHours => List.unmodifiable(_freeHours);
  double get weeklyFreeHours => _freeHours.fold(0, (a, b) => a + b);
  double freeHoursForWeekday(int weekday) => _freeHours[(weekday - 1) % 7];
  double get todayFreeHours => freeHoursForWeekday(DateTime.now().weekday);

  bool isTimerActive(String id) => _activeTimerId == id;

  double getLiveMinutes(String id) {
    final today = _dateOnly(DateTime.now());
    final prog = _progressFor(id, today);
    if (_activeTimerId == id && _timerStartedAt != null) {
      final elapsed =
          DateTime.now().difference(_timerStartedAt!).inMilliseconds / 60000;
      return (prog.current + elapsed).clamp(0.0, double.infinity);
    }
    return prog.current;
  }

  // ── timer control ─────────────────────────────────────────

  void startTimer(String id) {
    if (_activeTimerId == id) return;
    _flushActiveTimer();
    _activeTimerId = id;
    _timerStartedAt = DateTime.now();
    _saveTimerState();
    _startTicker();
    notifyListeners();
  }

  void pauseTimer(String id) {
    if (_activeTimerId != id) return;
    _flushActiveTimer();
    _activeTimerId = null;
    _timerStartedAt = null;
    _clearTimerState();
    _ticker?.cancel();
    _ticker = null;
    notifyListeners();
  }

  // ── plan mutations ────────────────────────────────────────

  void addPlan(Plan plan) {
    final today = _dateOnly(DateTime.now());
    final record = PlanRecord(
      id: plan.id,
      createdDate: today,
      versions: [
        PlanVersion(
          effectiveFrom: today,
          name: plan.name,
          category: plan.category,
          measureType: plan.measureType,
          target: plan.target,
          repeatDays: plan.repeatDays,
        ),
      ],
    );
    _planBox.put(record.id, record);
    notifyListeners();
  }

  /// Adds a new version effective from today — past dates keep the old version.
  void editPlan(
    String id, {
    required String name,
    required PlanCategory category,
    required MeasureType measureType,
    required double target,
    required List<int> repeatDays,
  }) {
    final record = _planBox.get(id);
    if (record == null) return;
    final today = _dateOnly(DateTime.now());
    // Replace today's version if one already exists (idempotent edits)
    record.versions.removeWhere((v) => v.effectiveFrom == today);
    record.versions.add(PlanVersion(
      effectiveFrom: today,
      name: name,
      category: category,
      measureType: measureType,
      target: target,
      repeatDays: repeatDays,
    ));
    record.versions.sort((a, b) => a.effectiveFrom.compareTo(b.effectiveFrom));
    _planBox.put(id, record);
    notifyListeners();
  }

  /// Stops the plan from today — past records are preserved.
  void endPlan(String id) {
    final record = _planBox.get(id);
    if (record == null) return;
    record.endDate = _dateOnly(DateTime.now());
    _planBox.put(id, record);
    if (_activeTimerId == id) pauseTimer(id);
    notifyListeners();
  }

  /// Removes the plan and all its progress records.
  void deletePlan(String id) {
    final keysToDelete = _progressBox.keys
        .where((k) => k.toString().startsWith('${id}_'))
        .toList();
    _progressBox.deleteAll(keysToDelete);
    _planBox.delete(id);
    if (_activeTimerId == id) {
      _ticker?.cancel();
      _ticker = null;
      _activeTimerId = null;
      _timerStartedAt = null;
      _clearTimerState();
    }
    notifyListeners();
  }

  void updateCount(String id, double delta) {
    final today = _dateOnly(DateTime.now());
    final record = _planBox.get(id);
    if (record == null) return;
    final v = record.versionForDate(today);
    if (v == null) return;
    final prog = _progressFor(id, today);
    prog.current = (prog.current + delta).clamp(0, v.target);
    _progressBox.put(_progressKey(id, today), prog);
    notifyListeners();
  }

  void setCurrentValue(String id, double value) {
    final today = _dateOnly(DateTime.now());
    final record = _planBox.get(id);
    if (record == null) return;
    final v = record.versionForDate(today);
    if (v == null) return;
    if (_activeTimerId == id) {
      _ticker?.cancel();
      _ticker = null;
      _activeTimerId = null;
      _timerStartedAt = null;
      _clearTimerState();
    }
    final prog = _progressFor(id, today);
    prog.current = value.clamp(0, v.target);
    _progressBox.put(_progressKey(id, today), prog);
    notifyListeners();
  }

  void toggleCheck(String id) {
    final today = _dateOnly(DateTime.now());
    final prog = _progressFor(id, today);
    prog.isCompleted = !prog.isCompleted;
    _progressBox.put(_progressKey(id, today), prog);
    notifyListeners();
  }

  void reset(String id) {
    if (_activeTimerId == id) {
      _ticker?.cancel();
      _ticker = null;
      _activeTimerId = null;
      _timerStartedAt = null;
      _clearTimerState();
    }
    final today = _dateOnly(DateTime.now());
    final prog = _progressFor(id, today);
    prog.current = 0;
    prog.isCompleted = false;
    _progressBox.put(_progressKey(id, today), prog);
    notifyListeners();
  }

  // ── free time mutations ───────────────────────────────────

  void setFreeHours(int index, double hours) {
    if (index < 0 || index >= 7) return;
    _freeHours[index] = hours.clamp(0, 12);
    _saveFreeHours();
    notifyListeners();
  }

  void resetFreeHours() {
    const defaults = [4.0, 4.0, 4.0, 4.0, 3.0, 6.0, 6.0];
    for (int i = 0; i < 7; i++) {
      _freeHours[i] = defaults[i];
    }
    _saveFreeHours();
    notifyListeners();
  }

  // ── internal ──────────────────────────────────────────────

  Future<void> _init() async {
    _planBox = Hive.box<PlanRecord>('plan_records');
    _progressBox = Hive.box<DailyProgress>('progress');

    _prefs = await SharedPreferences.getInstance();

    final saved = _prefs?.getString(_kFreeHours);
    if (saved != null) {
      final parts = saved.split(',');
      if (parts.length == 7) {
        for (int i = 0; i < 7; i++) {
          _freeHours[i] = double.tryParse(parts[i]) ?? _freeHours[i];
        }
      }
    }

    final id = _prefs?.getString(_kTimerId);
    final startMs = _prefs?.getInt(_kTimerStartMs);
    if (id != null && startMs != null && _planBox.containsKey(id)) {
      _activeTimerId = id;
      _timerStartedAt = DateTime.fromMillisecondsSinceEpoch(startMs);
      _flushActiveTimer();
      _timerStartedAt = DateTime.now();
      _saveTimerState();
      _startTicker();
    }

    notifyListeners();
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      notifyListeners();
    });
  }

  void _flushActiveTimer() {
    if (_activeTimerId == null || _timerStartedAt == null) return;
    final today = _dateOnly(DateTime.now());
    final prog = _progressFor(_activeTimerId!, today);
    final elapsed =
        DateTime.now().difference(_timerStartedAt!).inMilliseconds / 60000;
    prog.current = (prog.current + elapsed).clamp(0.0, double.infinity);
    _progressBox.put(_progressKey(_activeTimerId!, today), prog);
    _timerStartedAt = null;
  }

  void _saveTimerState() {
    if (_activeTimerId == null || _timerStartedAt == null) return;
    _prefs?.setString(_kTimerId, _activeTimerId!);
    _prefs?.setInt(_kTimerStartMs, _timerStartedAt!.millisecondsSinceEpoch);
  }

  void _clearTimerState() {
    _prefs?.remove(_kTimerId);
    _prefs?.remove(_kTimerStartMs);
  }

  void _saveFreeHours() {
    _prefs?.setString(_kFreeHours, _freeHours.join(','));
  }

  @override
  void dispose() {
    _flushActiveTimer();
    _ticker?.cancel();
    super.dispose();
  }
}
