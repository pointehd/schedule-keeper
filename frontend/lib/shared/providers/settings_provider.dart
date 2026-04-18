import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsNotifier extends ChangeNotifier {
  static const _keyFreeTime = 'free_time_hours';
  double _freeTimeHours = 0.0;

  double get freeTimeHours => _freeTimeHours;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _freeTimeHours = prefs.getDouble(_keyFreeTime) ?? 0.0;
    notifyListeners();
  }

  Future<void> setFreeTimeHours(double hours) async {
    _freeTimeHours = hours.clamp(0.0, 24.0);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyFreeTime, _freeTimeHours);
  }
}

class SettingsProvider extends InheritedNotifier<SettingsNotifier> {
  const SettingsProvider({
    super.key,
    required SettingsNotifier super.notifier,
    required super.child,
  });

  static SettingsNotifier of(BuildContext context) {
    final provider =
        context.dependOnInheritedWidgetOfExactType<SettingsProvider>();
    assert(provider != null, 'SettingsProvider가 위젯 트리에 없습니다');
    return provider!.notifier!;
  }
}
