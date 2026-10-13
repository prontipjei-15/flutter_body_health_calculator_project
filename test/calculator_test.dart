import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_body_health_calculator_project/main.dart';

Future<void> openApp(WidgetTester tester) async {
  tester.view.physicalSize = const ui.Size(1290, 2796);
  tester.view.devicePixelRatio = 3;
  tester.view.padding = const FakeViewPadding(top: 177, bottom: 102);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPadding);
  await tester.pumpWidget(const FlutterBodyHealthCalculatorProject());
  await tester.runAsync(() async {
    final context = tester.element(find.byType(Scaffold).first);
    for (final name in ['calculate', 'saulogo', 'bmi', 'bmr']) {
      await precacheImage(AssetImage('assets/images/$name.png'), context);
    }
  });
  await tester.pump(const Duration(seconds: 3));
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

Future<void> press(WidgetTester tester, String text) async {
  final button = find.widgetWithText(ElevatedButton, text);
  await tester.ensureVisible(button);
  await tester.tap(button);
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

Future<void> capture(WidgetTester tester, String name) async {
  final directory = Platform.environment['BODY_SCREENSHOTS'];
  if (directory == null) return;
  final boundary =
      tester.allRenderObjects.whereType<RenderRepaintBoundary>().first;
  await tester.runAsync(() async {
    final image = await boundary.toImage();
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    await File('$directory/$name.png').writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
  });
}

void main() {
  testWidgets('BMI boundaries, invalid input and reset on iPhone size',
      (tester) async {
    await openApp(tester);
    await capture(tester, 'about');
    await tester.tap(find.text('BMI'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await capture(tester, 'bmi');

    final cases = <String, String>{
      '18.4': 'น้ำหนักต่ำกว่าเกณฑ์',
      '18.5': 'น้ำหนักสมส่วน',
      '22.9': 'น้ำหนักสมส่วน',
      '23': 'น้ำหนักเกิน',
      '24.9': 'น้ำหนักเกิน',
      '25': 'โรคอ้วนระดับ 1',
      '29.9': 'โรคอ้วนระดับ 1',
      '30': 'โรคอ้วนระดับ 2',
    };
    for (final entry in cases.entries) {
      await tester.enterText(find.byType(TextField).at(0), entry.key);
      await tester.enterText(find.byType(TextField).at(1), '100');
      await press(tester, 'คำนวณ BMI');
      expect(find.text(double.parse(entry.key).toStringAsFixed(2)),
          findsOneWidget);
      expect(find.text(entry.value), findsOneWidget);
    }
    await press(tester, 'ล้างข้อมูล');
    expect(find.text('0.00'), findsOneWidget);
    for (final invalid in ['abc', '0', '-1']) {
      await tester.enterText(find.byType(TextField).at(0), invalid);
      await tester.enterText(find.byType(TextField).at(1), '170');
      await press(tester, 'คำนวณ BMI');
      expect(find.text('0.00'), findsOneWidget);
    }
  });

  testWidgets('BMR male and female, clear and invalid age on iPhone size',
      (tester) async {
    await openApp(tester);
    await tester.tap(find.text('BMR'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await capture(tester, 'bmr');
    await tester.enterText(find.byType(TextField).at(0), '70');
    await tester.enterText(find.byType(TextField).at(1), '175');
    await tester.enterText(find.byType(TextField).at(2), '30');
    await press(tester, 'คำนวณ BMR');
    expect(find.text('1695.67'), findsOneWidget);
    await press(tester, 'หญิง');
    await press(tester, 'คำนวณ BMR');
    expect(find.text('1507.13'), findsOneWidget);
    await press(tester, 'ล้างข้อมูล');
    expect(find.text('0.00'), findsOneWidget);
    for (final field in tester.widgetList<TextField>(find.byType(TextField))) {
      expect(field.controller!.text, isEmpty);
    }
    await tester.enterText(find.byType(TextField).at(0), '70');
    await tester.enterText(find.byType(TextField).at(1), '175');
    await tester.enterText(find.byType(TextField).at(2), '30.5');
    await press(tester, 'คำนวณ BMR');
    expect(find.text('0.00'), findsOneWidget);
  });
}
