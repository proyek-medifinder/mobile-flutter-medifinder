import 'package:flutter_test/flutter_test.dart';
import 'package:medifinder/services/auth_session_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'fresh app requires backend login and no Firebase initialization',
    () async {
      SharedPreferences.setMockInitialValues({});
      expect(await AuthSessionStore().restore(), isFalse);
    },
  );
}
