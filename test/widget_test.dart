import 'package:flutter_test/flutter_test.dart';
import 'package:medifinder/main.dart';

void main() {
  testWidgets('App loads successfully', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MyApp(langsungKeHasil: false),
    );

    expect(find.byType(MyApp), findsOneWidget);
  });
}