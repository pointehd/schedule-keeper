import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'app/app.dart';
import 'core/api/api_client.dart';
import 'core/api/health_service.dart';
import 'shared/models/plan.dart';
import 'shared/models/hive_adapters.dart';
// FreeHoursSnapshot is part of plan.dart — imported above

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  Hive.registerAdapter(PlanVersionAdapter());
  Hive.registerAdapter(DailyProgressAdapter());
  Hive.registerAdapter(PlanRecordAdapter());
  Hive.registerAdapter(FreeHoursSnapshotAdapter());
  await Hive.openBox<PlanRecord>('plan_records');
  await Hive.openBox<DailyProgress>('progress');
  await Hive.openBox<FreeHoursSnapshot>('free_hours_history');

  await _checkHealth();
  runApp(const App());
}

Future<void> _checkHealth() async {
  final healthy = await HealthService(ApiClient()).check();
  debugPrint('Server health: ${healthy ? 'ok' : 'unavailable'}');
}
