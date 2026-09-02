import 'package:flutter_test/flutter_test.dart';
import 'package:viraly_mobile/main.dart';

void main() {
  testWidgets('Viraly app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ViralyApp());
    expect(find.byType(ViralyApp), findsOneWidget);
  });
}
