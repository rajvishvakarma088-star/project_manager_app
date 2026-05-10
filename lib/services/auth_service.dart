import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserCredential> signUp(String email, String password) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw FirebaseAuthException(
        code: e.code,
        message: _messageFor(e.code, e.message),
      );
    } catch (_) {
      throw FirebaseAuthException(
        code: 'unknown',
        message: 'Could not create your account. Please try again.',
      );
    }
  }

  Future<UserCredential> signIn(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw FirebaseAuthException(
        code: e.code,
        message: _messageFor(e.code, e.message),
      );
    } catch (_) {
      throw FirebaseAuthException(
        code: 'unknown',
        message: 'Could not sign you in. Please try again.',
      );
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } on FirebaseAuthException catch (e) {
      throw FirebaseAuthException(
        code: e.code,
        message: _messageFor(e.code, e.message),
      );
    } catch (_) {
      throw FirebaseAuthException(
        code: 'unknown',
        message: 'Could not sign out. Please try again.',
      );
    }
  }

  String _messageFor(String code, String? message) {
    final raw = message ?? '';
    switch (code) {
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Email or password is incorrect.';
      case 'email-already-in-use':
        return 'An account already exists for this email.';
      case 'weak-password':
        return 'Password is too weak.';
      case 'network-request-failed':
        return 'Network error. Check your connection and try again.';
      case 'internal-error':
        if (raw.contains('CONFIGURATION_NOT_FOUND')) {
          return 'Firebase Auth is not configured for this app. Enable Email/Password sign-in in Firebase Console and check API key restrictions.';
        }
        return 'Firebase Auth configuration failed. Please check your Firebase project setup.';
      default:
        return 'Authentication failed. Please try again.';
    }
  }
}
