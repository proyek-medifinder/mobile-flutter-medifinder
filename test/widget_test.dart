import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_core/firebase_core.dart';

import 'package:medifinder/main.dart';

void main() {

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();

    await Firebase.initializeApp();
  });

  testWidgets('App loads successfully', (WidgetTester tester) async {

    await tester.pumpWidget(
      const MyApp(langsungKeHasil: false),
    );

    expect(find.byType(MyApp), findsOneWidget);
  });
}