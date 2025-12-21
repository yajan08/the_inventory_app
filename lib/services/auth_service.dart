import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // get current user 
  User? getCurrentUser() {
    return _auth.currentUser;
  }
  
  // sign in with email and password
  Future<UserCredential> signInWithEmailPassword(String email, String password) async {
    try {
    UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password
      );
      
      // saved user here too because we may add user from backend instead of through signup
      _firestore.collection('Users').doc(userCredential.user?.uid).set({
        'uid': userCredential.user?.uid,
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
      });

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw Exception(e.code);
    }
  }

  // sign up 
  Future<UserCredential> signUpWithEmailPassword(String email, String password) async {
    try {
      // sign user in
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email, 
        password: password
      );

      // save user data in seperate doc
      _firestore.collection('Users').doc(userCredential.user?.uid).set({
        'uid': userCredential.user?.uid,
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
      });

      return userCredential;
    } on FirebaseAuthException {
      // throw Exception(e.code);
      rethrow;
    }
  }

  // sign out
  Future<void> signOut() async {
    return await _auth.signOut();
  }

}
