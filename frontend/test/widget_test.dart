import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/app/app.dart';

void main() {
  testWidgets('HomePage renders AppBar with menu and guest', (WidgetTester tester) async {
    await tester.pumpWidget(const App());

    expect(find.byIcon(Icons.menu), findsOneWidget);
    expect(find.text('게스트'), findsOneWidget);
  });
}
