import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/plan.dart';

const _kTimerId = 'timer_plan_id';
const _kTimerStartMs = 'timer_start_ms';

class PlanNotifier extends ChangeNotifier {
  PlanNotifier() {
    _init();
  }

  final List<Plan> _plans = [
    Plan(
      id: '1',
      name: '매일 영어 단어 30개',
      category: PlanCategory.study,
      measureType: MeasureType.count,
      target: 30,
      current: 18,
    ),
    Plan(
      id: '2',
      name: '독서 30분',
      category: PlanCategory.reading,
      measureType: MeasureType.time,
      target: 30,
      current: 18,
    ),
    Plan(
      id: '3',
      name: '홈트 30분',
      category: PlanCategory.health,
      measureType: MeasureType.time,
      target: 30,
      current: 30,
      isCompleted: true,
    ),
    Plan(
      id: '4',
      name: '가계부 쓰기',
      category: PlanCategory.finance,
      measureType: MeasureType.check,
      target: 1,
    ),
  ];

  SharedPreferences? _prefs;
  String? _activeTimerId;
  DateTime? _timerStartedAt;
  Timer? _ticker;

  // ── getters ──────────────────────────────────────────────

  List<Plan> get plans => List.unmodifiable(_plans);
  int get completedCount => _plans.where((p) => p.isDone).length;
  int get totalCount => _plans.length;
  double get overallProgress =>
      totalCount == 0 ? 0 : completedCount / totalCount;
  double get totalFocusHours => _plans.fold(
        0.0,
        (sum, p) => sum +
            (p.measureType == MeasureType.time ? getLiveMinutes(p.id) / 60 : 0),
      );

  bool isTimerActive(String id) => _activeTimerId == id;

  /// Returns plan.current + live elapsed seconds if timer is running.
  double getLiveMinutes(String id) {
    final i = _plans.indexWhere((p) => p.id == id);
    if (i < 0) return 0;
    final plan = _plans[i];
    if (_activeTimerId == id && _timerStartedAt != null) {
      final elapsed =
          DateTime.now().difference(_timerStartedAt!).inMilliseconds / 60000;
      return (plan.current + elapsed).clamp(0.0, double.infinity);
    }
    return plan.current;
  }

  // ── timer control ─────────────────────────────────────────

  void startTimer(String id) {
    if (_activeTimerId == id) return;
    _flushActiveTimer(); // save elapsed time of previous plan
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

  void updateCount(String id, double delta) {
    final i = _plans.indexWhere((p) => p.id == id);
    if (i < 0) return;
    _plans[i].current =
        (_plans[i].current + delta).clamp(0, _plans[i].target);
    notifyListeners();
  }

  void setCurrentValue(String id, double value) {
    final i = _plans.indexWhere((p) => p.id == id);
    if (i < 0) return;
    // If timer is running for this plan, pause it first
    if (_activeTimerId == id) {
      _ticker?.cancel();
      _ticker = null;
      _activeTimerId = null;
      _timerStartedAt = null;
      _clearTimerState();
    }
    _plans[i].current = value.clamp(0, _plans[i].target);
    notifyListeners();
  }

  void toggleCheck(String id) {
    final i = _plans.indexWhere((p) => p.id == id);
    if (i < 0) return;
    _plans[i].isCompleted = !_plans[i].isCompleted;
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
    final i = _plans.indexWhere((p) => p.id == id);
    if (i < 0) return;
    _plans[i].current = 0;
    _plans[i].isCompleted = false;
    notifyListeners();
  }

  void addPlan(Plan plan) {
    _plans.add(plan);
    notifyListeners();
  }

  // ── internal ──────────────────────────────────────────────

  Future<void> _init() async {
    _prefs = await SharedPreferences.getInstance();
    final id = _prefs?.getString(_kTimerId);
    final startMs = _prefs?.getInt(_kTimerStartMs);
    if (id != null && startMs != null) {
      final i = _plans.indexWhere((p) => p.id == id);
      if (i >= 0) {
        _activeTimerId = id;
        _timerStartedAt = DateTime.fromMillisecondsSinceEpoch(startMs);
        // Apply elapsed immediately so current is up to date
        _flushActiveTimer();
        // Restart from now so ticker stays accurate
        _timerStartedAt = DateTime.now();
        _saveTimerState();
        _startTicker();
        notifyListeners();
      } else {
        _clearTimerState();
      }
    }
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      notifyListeners();
    });
  }

  /// Applies elapsed time since _timerStartedAt to plan.current.
  void _flushActiveTimer() {
    if (_activeTimerId == null || _timerStartedAt == null) return;
    final i = _plans.indexWhere((p) => p.id == _activeTimerId);
    if (i < 0) return;
    final elapsed =
        DateTime.now().difference(_timerStartedAt!).inMilliseconds / 60000;
    _plans[i].current = (_plans[i].current + elapsed).clamp(0.0, double.infinity);
    _timerStartedAt = null;
  }

  void _saveTimerState() {
    if (_activeTimerId == null || _timerStartedAt == null) return;
    _prefs?.setString(_kTimerId, _activeTimerId!);
    _prefs?.setInt(
        _kTimerStartMs, _timerStartedAt!.millisecondsSinceEpoch);
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
