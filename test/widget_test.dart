import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_body_health_calculator_project/main.dart';

void main() {
  testWidgets('Splash screen opens before the home screen', (tester) async {
    tester.view.physicalSize = const ui.Size(1290, 2796);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const FlutterBodyHealthCalculatorProject());
    expect(find.text('Body Health Calculator'), findsOneWidget);

    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    expect(find.text('About'), findsOneWidget);
  });
}
