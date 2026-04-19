import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_amazon_chime_example/main.dart';

void main() {
  testWidgets('Join screen renders correctly', (WidgetTester tester) async {
    await tester.pumpWidget(const ChimeExampleApp());

    // Verify the join screen elements are present.
    expect(find.text('Amazon Chime'), findsOneWidget);
    expect(find.text('Join Meeting'), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(2));
  });
}
