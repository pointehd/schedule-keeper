import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/plan.dart';

const _kTimerId = 'timer_plan_id';
const _kTimerStartMs = 'timer_start_ms';
const _kFreeHoursLegacy = 'free_hours';
const _kFreeHoursInitKey = '19700101';
const _kFirstOpenDate = 'first_open_date_ms';
const _kUserName = 'user_name';

class PlanNotifier extends ChangeNotifier {
  PlanNotifier() {
    _init();
  }

  late final Box<PlanRecord> _planBox;
  late final Box<DailyProgress> _progressBox;
  late final Box<FreeHoursSnapshot> _freeHoursBox;

  static const List<double> _defaultHours = [4, 4, 4, 4, 3, 6, 6];

  SharedPreferences? _prefs;
  String? _activeTimerId;
  DateTime? _timerStartedAt;
  Timer? _ticker;
  String? _userName;

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

      if (v.scheduleType == PlanScheduleType.floating) {
        final completionDay = _getFloatingCompletionDay(record.id, v);
        if (completionDay != null && d.isAfter(completionDay)) continue;
      }

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

  /// For floating plans: find the earliest day where the goal was met.
  DateTime? _getFloatingCompletionDay(String planId, PlanVersion v) {
    DateTime? earliest;
    for (final key in _progressBox.keys.cast<String>()) {
      if (!key.startsWith('${planId}_')) continue;
      final prog = _progressBox.get(key);
      if (prog == null) continue;
      final done = v.measureType == MeasureType.check
          ? prog.isCompleted
          : v.target > 0 && prog.current >= v.target;
      if (done) {
        final d = _dateOnly(prog.date);
        if (earliest == null || d.isBefore(earliest)) earliest = d;
      }
    }
    return earliest;
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

  static String _freeHoursKey(DateTime date) =>
      '${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}';

  static DateTime? _parseDateKey(String key) {
    if (key.length != 8) return null;
    final y = int.tryParse(key.substring(0, 4));
    final m = int.tryParse(key.substring(4, 6));
    final d = int.tryParse(key.substring(6, 8));
    if (y == null || m == null || d == null) return null;
    return DateTime(y, m, d);
  }

  /// Finds the most recent snapshot whose effectiveFrom is on or before [date].
  FreeHoursSnapshot? _snapshotForDate(DateTime date) {
    final d = _dateOnly(date);
    FreeHoursSnapshot? result;
    for (final snap in _freeHoursBox.values) {
      if (!snap.effectiveFrom.isAfter(d)) {
        if (result == null || snap.effectiveFrom.isAfter(result.effectiveFrom)) {
          result = snap;
        }
      }
    }
    return result;
  }

  // Returns the current (today's) free-hours settings for the settings UI.
  List<double> get freeHours {
    final snap = _snapshotForDate(DateTime.now());
    return List.unmodifiable(snap?.hours ?? _defaultHours);
  }

  double get weeklyFreeHours => freeHours.fold(0, (a, b) => a + b);

  // Returns free hours for a specific calendar date — uses the snapshot active on that date.
  double freeHoursForDate(DateTime date) {
    final snap = _snapshotForDate(date);
    final hours = snap?.hours ?? _defaultHours;
    return hours[(date.weekday - 1) % 7];
  }

  // Returns current snapshot's value for a weekday (used by settings UI).
  double freeHoursForWeekday(int weekday) {
    final snap = _snapshotForDate(DateTime.now());
    return (snap?.hours ?? _defaultHours)[(weekday - 1) % 7];
  }

  double get todayFreeHours => freeHoursForDate(DateTime.now());

  bool get isLoggedIn => _userName != null;
  String? get userName => _userName;

  void login(String name) {
    _userName = name.trim().isEmpty ? null : name.trim();
    _prefs?.setString(_kUserName, _userName ?? '');
    notifyListeners();
  }

  void logout() {
    _userName = null;
    _prefs?.remove(_kUserName);
    notifyListeners();
  }

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
    prog.current = value.clamp(0, double.infinity);
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
    final today = _dateOnly(DateTime.now());
    final key = _freeHoursKey(today);
    final base = List<double>.from(_snapshotForDate(today)?.hours ?? _defaultHours);
    base[index] = hours.clamp(0, 12);
    _freeHoursBox.put(key, FreeHoursSnapshot(effectiveFrom: today, hours: base));
    notifyListeners();
  }

  void resetFreeHours() {
    final today = _dateOnly(DateTime.now());
    _freeHoursBox.put(
      _freeHoursKey(today),
      FreeHoursSnapshot(effectiveFrom: today, hours: List.of(_defaultHours)),
    );
    notifyListeners();
  }

  /// Finds the most recent snapshot whose effectiveFrom is strictly before [date].
  FreeHoursSnapshot? _snapshotBeforeDate(DateTime date) {
    final d = _dateOnly(date);
    FreeHoursSnapshot? result;
    for (final snap in _freeHoursBox.values) {
      if (snap.effectiveFrom.isBefore(d)) {
        if (result == null || snap.effectiveFrom.isAfter(result.effectiveFrom)) {
          result = snap;
        }
      }
    }
    return result;
  }

  /// Calendar edit: change free hours only for [date], without affecting future dates.
  void setFreeHoursForDate(DateTime date, int index, double hours) {
    if (index < 0 || index >= 7) return;
    final d = _dateOnly(date);
    final key = _freeHoursKey(d);

    final currentSnap = _snapshotForDate(d);
    // Hours to continue into future: use the snapshot before d if we're replacing d's own snapshot.
    final continuationHours = (currentSnap != null && currentSnap.effectiveFrom == d)
        ? List<double>.from(_snapshotBeforeDate(d)?.hours ?? _defaultHours)
        : List<double>.from(currentSnap?.hours ?? _defaultHours);

    final base = List<double>.from(currentSnap?.hours ?? _defaultHours);
    base[index] = hours.clamp(0, 12);
    _freeHoursBox.put(key, FreeHoursSnapshot(effectiveFrom: d, hours: base));

    // Protect future dates: anchor d+1 with the pre-edit default so they aren't affected.
    final nextDay = d.add(const Duration(days: 1));
    final nextKey = _freeHoursKey(nextDay);
    if (!_freeHoursBox.containsKey(nextKey)) {
      _freeHoursBox.put(nextKey, FreeHoursSnapshot(effectiveFrom: nextDay, hours: continuationHours));
    }

    notifyListeners();
  }

  // ── free time gap-fill ────────────────────────────────────

  /// On every app open: fills any days since last recorded snapshot up to today.
  void _fillMissingDays() {
    final today = _dateOnly(DateTime.now());
    final firstOpenMs = _prefs?.getInt(_kFirstOpenDate);

    if (firstOpenMs == null) {
      _prefs?.setInt(_kFirstOpenDate, today.millisecondsSinceEpoch);
      _ensureSnapshot(today);
      return;
    }

    // Find the latest explicitly-snapshotted day (skip the sentinel).
    DateTime? lastSnapshotted;
    for (final key in _freeHoursBox.keys.cast<String>()) {
      if (key == _kFreeHoursInitKey) continue;
      final date = _parseDateKey(key);
      if (date != null && (lastSnapshotted == null || date.isAfter(lastSnapshotted))) {
        lastSnapshotted = date;
      }
    }

    final firstOpen = _dateOnly(DateTime.fromMillisecondsSinceEpoch(firstOpenMs));
    DateTime cursor = lastSnapshotted != null
        ? lastSnapshotted.add(const Duration(days: 1))
        : firstOpen;

    while (!cursor.isAfter(today)) {
      _ensureSnapshot(cursor);
      cursor = cursor.add(const Duration(days: 1));
    }
  }

  void _ensureSnapshot(DateTime date) {
    final d = _dateOnly(date);
    final key = _freeHoursKey(d);
    if (!_freeHoursBox.containsKey(key)) {
      final snap = _snapshotForDate(d);
      _freeHoursBox.put(
        key,
        FreeHoursSnapshot(effectiveFrom: d, hours: List.of(snap?.hours ?? _defaultHours)),
      );
    }
  }

  // ── internal ──────────────────────────────────────────────

  Future<void> _init() async {
    _planBox = Hive.box<PlanRecord>('plan_records');
    _progressBox = Hive.box<DailyProgress>('progress');
    _freeHoursBox = Hive.box<FreeHoursSnapshot>('free_hours_history');

    _prefs = await SharedPreferences.getInstance();

    // Migrate from legacy SharedPreferences on first launch after update.
    if (_freeHoursBox.isEmpty) {
      final saved = _prefs?.getString(_kFreeHoursLegacy);
      List<double> migratedHours = List.of(_defaultHours);
      if (saved != null) {
        final parts = saved.split(',');
        if (parts.length == 7) {
          migratedHours = parts
              .asMap()
              .entries
              .map((e) => double.tryParse(e.value) ?? _defaultHours[e.key])
              .toList();
        }
      }
      _freeHoursBox.put(
        _kFreeHoursInitKey,
        FreeHoursSnapshot(effectiveFrom: DateTime(1970), hours: migratedHours),
      );
    }

    _fillMissingDays();

    final savedName = _prefs?.getString(_kUserName);
    if (savedName != null && savedName.isNotEmpty) _userName = savedName;

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

  @override
  void dispose() {
    _flushActiveTimer();
    _ticker?.cancel();
    super.dispose();
  }
}
