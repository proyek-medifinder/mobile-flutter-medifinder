import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final _auth = FirebaseAuth.instance;
  final _google = GoogleSignIn.instance;

  Future<User?> signInWithGoogle() async {
    try {
      await _google.initialize();
      final account = await _google.authenticate();
      final tokens = account.authentication;

      final credential = GoogleAuthProvider.credential(
        idToken: tokens.idToken,
      );

      final userCredential =
          await _auth.signInWithCredential(credential);
      return userCredential.user;
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) return null;
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _google.signOut();
    await _auth.signOut();
  }

  Stream<GoogleSignInAuthenticationEvent> get authEvents =>
      _google.authenticationEvents;
}
