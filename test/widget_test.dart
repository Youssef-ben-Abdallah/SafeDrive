import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:safedrive/main.dart';

void main() {
  testWidgets('SafeDrive app renders without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(const SafeDriveApp());

    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
