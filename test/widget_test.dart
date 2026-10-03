import 'package:flutter_test/flutter_test.dart';
import 'package:stores/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const JsonLdStudioApp());
    expect(find.byType(JsonLdStudioApp), findsOneWidget);
  });
}
