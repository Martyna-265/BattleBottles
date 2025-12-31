import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Logowanie
  Future<void> login(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' || e.code == 'invalid-email') {
        throw 'User not found.';
      } else if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        throw 'Wrong password.';
      } else if (e.code == 'too-many-requests') {
        throw 'Too many attempts. Try again later.';
      }
      throw 'Login failed: ${e.message}';
    } catch (e) {
      throw 'An unknown error occurred.';
    }
  }

  // Rejestracja
  Future<void> register(String email, String password, String username) async {
    try {
      UserCredential cred = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password
      );

      if (cred.user != null) {
        await cred.user!.updateDisplayName(username);
        await cred.user!.reload();
      }

    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        throw 'The password is too weak (min. 6 characters).';
      } else if (e.code == 'email-already-in-use') {
        throw 'This email is already in use.';
      } else if (e.code == 'invalid-email') {
        throw 'Invalid email format.';
      }
      throw 'Registration failed: ${e.message}';
    } catch (e) {
      throw 'An unknown error occurred.';
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
  }
}