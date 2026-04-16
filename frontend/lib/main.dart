import 'package:flutter/material.dart';
import 'app/app.dart';
import 'core/api/api_client.dart';
import 'core/api/health_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _checkHealth();
  runApp(const App());
}

Future<void> _checkHealth() async {
  final healthy = await HealthService(ApiClient()).check();
  debugPrint('Server health: ${healthy ? 'ok' : 'unavailable'}');
}
