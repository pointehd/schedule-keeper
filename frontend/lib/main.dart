import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'app/app.dart';
import 'core/api/api_client.dart';
import 'core/api/health_service.dart';
import 'shared/models/plan.dart';
import 'shared/models/hive_adapters.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  Hive.registerAdapter(PlanVersionAdapter());
  Hive.registerAdapter(DailyProgressAdapter());
  Hive.registerAdapter(PlanRecordAdapter());
  await Hive.openBox<PlanRecord>('plan_records');
  await Hive.openBox<DailyProgress>('progress');

  await _checkHealth();
  runApp(const App());
}

Future<void> _checkHealth() async {
  final healthy = await HealthService(ApiClient()).check();
  debugPrint('Server health: ${healthy ? 'ok' : 'unavailable'}');
}
