import 'package:flutter_test/flutter_test.dart';

import 'package:animation_app/app.dart';

void main() {
  testWidgets('Animation App loads', (WidgetTester tester) async {
    await tester.pumpWidget(const AnimationApp());

    expect(find.text('Animation App'), findsOneWidget);
    expect(find.text('Animation Editor'), findsOneWidget);
  });
}
