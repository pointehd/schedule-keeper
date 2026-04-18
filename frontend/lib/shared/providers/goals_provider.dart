import 'package:flutter/material.dart';
import '../../features/schedule/models/schedule_entry.dart';
import '../../features/schedule/repositories/schedule_repository.dart';

class GoalsNotifier extends ChangeNotifier {
  final _repository = ScheduleRepository();
  List<ScheduleEntry> _goals = [];
  bool isLoading = true;

  List<ScheduleEntry> get goals => List.unmodifiable(_goals);

  Future<void> load() async {
    isLoading = true;
    notifyListeners();
    _goals = await _repository.getAll();
    isLoading = false;
    notifyListeners();
  }

  Future<void> delete(String id) async {
    await _repository.delete(id);
    _goals.removeWhere((e) => e.id == id);
    notifyListeners();
  }

  Future<void> updateGoal(ScheduleEntry entry) async {
    await _repository.update(entry);
    final i = _goals.indexWhere((e) => e.id == entry.id);
    if (i != -1) _goals[i] = entry;
    notifyListeners();
  }

  Future<void> endGoal(String id) async {
    final i = _goals.indexWhere((e) => e.id == id);
    if (i == -1) return;
    final ended = _goals[i].copyWith(endedAt: DateTime.now());
    await _repository.update(ended);
    _goals[i] = ended;
    notifyListeners();
  }
}

class GoalsProvider extends InheritedNotifier<GoalsNotifier> {
  const GoalsProvider({
    super.key,
    required GoalsNotifier super.notifier,
    required super.child,
  });

  static GoalsNotifier of(BuildContext context) {
    final provider =
        context.dependOnInheritedWidgetOfExactType<GoalsProvider>();
    assert(provider != null, 'GoalsProvider가 위젯 트리에 없습니다');
    return provider!.notifier!;
  }
}
