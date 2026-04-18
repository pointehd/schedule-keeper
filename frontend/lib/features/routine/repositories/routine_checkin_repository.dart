import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class RoutineCheckinRepository {
  static const _storageKey = 'routine_checkins';

  String _key(String entryId, DateTime date) {
    final d = DateTime(date.year, date.month, date.day);
    return '${entryId}_${d.toIso8601String().substring(0, 10)}';
  }

  Future<Map<String, bool>> _loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null) return {};
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    return decoded.map((k, v) => MapEntry(k, v as bool));
  }

  Future<void> _saveAll(Map<String, bool> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(data));
  }

  Future<bool> getCheckin(String entryId, DateTime date) async {
    final all = await _loadAll();
    return all[_key(entryId, date)] ?? false;
  }

  /// 특정 월의 모든 체크인 반환 (key: "entryId_yyyy-MM-dd")
  Future<Map<String, bool>> getCheckinsForMonth(int year, int month) async {
    final all = await _loadAll();
    final monthStr =
        '${year.toString()}-${month.toString().padLeft(2, '0')}-';
    return Map.fromEntries(
      all.entries.where((e) => e.key.contains('_$monthStr')),
    );
  }

  /// 특정 날짜의 모든 체크인 반환 (entryId → isDone)
  Future<Map<String, bool>> getCheckinsForDate(DateTime date) async {
    final all = await _loadAll();
    final suffix = '_${DateTime(date.year, date.month, date.day).toIso8601String().substring(0, 10)}';
    final result = <String, bool>{};
    for (final entry in all.entries) {
      if (entry.key.endsWith(suffix)) {
        final entryId = entry.key.replaceAll(suffix, '');
        result[entryId] = entry.value;
      }
    }
    return result;
  }

  Future<void> setCheckin(String entryId, DateTime date, bool isDone) async {
    final all = await _loadAll();
    all[_key(entryId, date)] = isDone;
    await _saveAll(all);
  }

  /// 특정 날짜에 체크인이 하나라도 있는지 확인
  Future<bool> hasAnyCheckinOnDate(DateTime date) async {
    final checkins = await getCheckinsForDate(date);
    return checkins.values.any((v) => v);
  }

  /// 현재 연속 달성 스트릭 (어제부터 역순 계산)
  Future<int> calcStreak() async {
    int streak = 0;
    var day = DateTime.now().subtract(const Duration(days: 1));
    for (int i = 0; i < 365; i++) {
      final has = await hasAnyCheckinOnDate(day);
      if (!has) break;
      streak++;
      day = day.subtract(const Duration(days: 1));
    }
    return streak;
  }

  /// 이번 주(월~일) 날짜별 체크인 여부 목록
  Future<List<bool>> thisWeekDailyCheckins(String entryId) async {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final result = <bool>[];
    for (int i = 0; i < 7; i++) {
      final day = DateTime(monday.year, monday.month, monday.day + i);
      result.add(await getCheckin(entryId, day));
    }
    return result;
  }

  /// 이번 주 체크인 횟수
  Future<int> thisWeekCheckinCount(String entryId) async {
    final days = await thisWeekDailyCheckins(entryId);
    return days.where((v) => v).length;
  }

  /// 이번 달 체크인 횟수
  Future<int> thisMonthCheckinCount(String entryId) async {
    final now = DateTime.now();
    final lastDay = DateTime(now.year, now.month + 1, 0).day;
    int count = 0;
    for (int d = 1; d <= lastDay; d++) {
      final day = DateTime(now.year, now.month, d);
      if (await getCheckin(entryId, day)) count++;
    }
    return count;
  }
}
