import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../shared/providers/plan_provider.dart';
import '../shared/widgets/main_scaffold.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PlanNotifier(),
      child: MaterialApp(
        title: '데일리 스케줄 키퍼',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF5B5FC7),
          ),
          scaffoldBackgroundColor: const Color(0xFFF2F3F8),
          useMaterial3: true,
        ),
        home: const MainScaffold(),
      ),
    );
  }
}
