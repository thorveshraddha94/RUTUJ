import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:airport_management/main.dart';

void main() {
  testWidgets('Airport Admin App initial render test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: AirportAdminApp(),
      ),
    );

    expect(find.byType(AirportAdminApp), findsOneWidget);
  });
}
