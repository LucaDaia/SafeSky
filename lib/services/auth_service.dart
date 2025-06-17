import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<User?> signIn(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(email: email, password: password);
      return result.user;
    } catch (e) {
      print("Login failed: $e");
      return null;
    }
  }

  Future<User?> register(String email, String password, String displayName) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      await result.user!.updateDisplayName(displayName);
      await result.user!.reload();
      return result.user;
    } catch (e) {
      print("Registration failed: $e");
      return null;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Stream<User?> get user => _auth.authStateChanges();
}
