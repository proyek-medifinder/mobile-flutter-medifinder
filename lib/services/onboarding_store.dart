import 'package:shared_preferences/shared_preferences.dart';

class OnboardingStore {
  static const key = 'onboarding_completed_v1';
  static Future<bool> hasCompleted() async =>
      (await SharedPreferences.getInstance()).getBool(key) ?? false;
  static Future<void> complete() async {
    await (await SharedPreferences.getInstance()).setBool(key, true);
  }
}
