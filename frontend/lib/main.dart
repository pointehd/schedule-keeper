import 'package:flutter/material.dart';
import 'app/app.dart';
import 'core/api/api_client.dart';
import 'core/api/health_service.dart';
import 'shared/providers/goals_provider.dart';
import 'shared/providers/settings_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _checkHealth();

  final goalsNotifier = GoalsNotifier();
  final settingsNotifier = SettingsNotifier();
  await Future.wait([goalsNotifier.load(), settingsNotifier.load()]);

  runApp(
    GoalsProvider(
      notifier: goalsNotifier,
      child: SettingsProvider(
        notifier: settingsNotifier,
        child: const App(),
      ),
    ),
  );
}

Future<void> _checkHealth() async {
  final healthy = await HealthService(ApiClient()).check();
  debugPrint('Server health: ${healthy ? 'ok' : 'unavailable'}');
}
