import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final _auth = FirebaseAuth.instance;

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  Future<void> signIn(String email, String pwd) =>
      _auth.signInWithEmailAndPassword(email: email, password: pwd);

  Future<void> signOut() => _auth.signOut();

  Future<String> idToken() async =>
      (await _auth.currentUser!.getIdToken())!;
}
