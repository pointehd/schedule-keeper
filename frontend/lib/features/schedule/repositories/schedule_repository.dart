import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/schedule_entry.dart';

class ScheduleRepository {
  static const _storageKey = 'schedule_entries';

  // ── 로컬 저장 ──────────────────────────────────────────────

  Future<void> save(ScheduleEntry entry) async {
    final prefs = await SharedPreferences.getInstance();
    final entries = await getAll();
    entries.add(entry);
    await prefs.setString(
      _storageKey,
      jsonEncode(entries.map((e) => e.toJson()).toList()),
    );
  }

  Future<List<ScheduleEntry>> getAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => ScheduleEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> update(ScheduleEntry entry) async {
    final prefs = await SharedPreferences.getInstance();
    final entries = await getAll();
    final index = entries.indexWhere((e) => e.id == entry.id);
    if (index == -1) return;
    entries[index] = entry;
    await prefs.setString(
      _storageKey,
      jsonEncode(entries.map((e) => e.toJson()).toList()),
    );
  }

  Future<void> delete(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final entries = await getAll();
    entries.removeWhere((e) => e.id == id);
    await prefs.setString(
      _storageKey,
      jsonEncode(entries.map((e) => e.toJson()).toList()),
    );
  }

  // ── 서버 동기화 (추후 구현) ────────────────────────────────

  /// 아직 서버에 업로드되지 않은 항목(syncedAt == null)을 서버로 전송한다.
  /// 서버 연동 준비가 되면 이 메서드 내부를 채운다.
  Future<void> syncPending() async {
    final entries = await getAll();
    final pending = entries.where((e) => e.isPendingSync).toList();
    if (pending.isEmpty) return;

    // TODO: API 호출 후 syncedAt 업데이트
    // for (final entry in pending) {
    //   await _apiClient.post('/schedules', entry.toJson());
    //   await _markAsSynced(entry);
    // }
  }

  // ignore: unused_element
  Future<void> _markAsSynced(ScheduleEntry entry) async {
    final prefs = await SharedPreferences.getInstance();
    final entries = await getAll();
    final index = entries.indexWhere((e) => e.id == entry.id);
    if (index == -1) return;
    entries[index] = entry.copyWith(syncedAt: DateTime.now());
    await prefs.setString(
      _storageKey,
      jsonEncode(entries.map((e) => e.toJson()).toList()),
    );
  }
}
