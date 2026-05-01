import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:field_agent/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const FieldAgentApp());
  });
}
