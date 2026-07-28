// 1. THIS IS THE MISSING PIECE
import 'package:flutter/material.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:curf_app/main.dart';

void main() {
  testWidgets('CurfApp initializes without crashing', (WidgetTester tester) async {
    // 2. This structure is correct for Riverpod apps
    await tester.pumpWidget(const ProviderScope(child: CurfApp()));

    // 3. Now 'MaterialApp' is recognized because of the import above
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}