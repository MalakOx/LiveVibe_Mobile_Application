import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../models/auth_user_model.dart';

class FirebaseAuthDatasource {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  FirebaseAuthDatasource({
    required FirebaseAuth auth,
    required FirebaseFirestore firestore,
  })  : _auth = auth,
        _firestore = firestore;

  // Sign up with email and password
  Future<AuthUserModel> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    print('=== Starting sign up for: $email ===');
    try {
      print('Step 1: Creating Firebase Auth user...');
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      if (user == null) {
        throw Exception('User creation failed - user is null');
      }
      print('Step 2: Firebase user created with UID: ${user.uid}');

      // Create user document in Firestore
      final userModel = AuthUserModel(
        uid: user.uid,
        email: email,
        displayName: null,
        role: 'host', // Default role for new users
        createdAt: DateTime.now(),
      );

      try {
        print('Step 3: Creating Firestore user document...');
        await _firestore.collection('users').doc(user.uid).set(
              userModel.toFirestore(),
            );
        print('Step 4: Firestore user document created successfully');
      } catch (firestoreError) {
        print('ERROR in Step 3: $firestoreError');
        // If Firestore write fails, attempt to delete the auth user
        try {
          // Re-authenticate if needed and delete the user
          print('Attempting to rollback Firebase user...');
          await _auth.currentUser?.delete();
          print('Firebase user deleted');
        } catch (deleteError) {
          // If delete fails, log it but don't mask the original error
          print('Warning: Failed to rollback Firebase user after Firestore error: $deleteError');
        }
        // Extract meaningful error message from Firestore error
        String errorMsg = _extractErrorMessage(firestoreError);
        print('Throwing error: Failed to create user profile: $errorMsg');
        throw Exception('Failed to create user profile: $errorMsg');
      }

      print('=== Sign up completed successfully ===');
      return userModel;
    } on FirebaseAuthException catch (e) {
      print('FirebaseAuthException: ${e.code} - ${e.message}');
      String errorMsg = _handleAuthException(e);
      print('Throwing: $errorMsg');
      throw Exception(errorMsg);
    } catch (e) {
      print('Unexpected sign-up error: $e');
      String errorMsg = _extractErrorMessage(e);
      print('Throwing: $errorMsg');
      throw Exception(errorMsg);
    }
  }

  // Sign in with email and password
  Future<AuthUserModel> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      if (user == null) throw Exception('Sign in failed');

      // Get user document from Firestore
      final doc = await _firestore.collection('users').doc(user.uid).get();

      if (!doc.exists) {
        // Create user document if it doesn't exist (shouldn't happen)
        final userModel = AuthUserModel(
          uid: user.uid,
          email: email,
          displayName: null,
          role: 'host',
          createdAt: DateTime.now(),
        );
        await _firestore
            .collection('users')
            .doc(user.uid)
            .set(userModel.toFirestore());
        return userModel;
      }

      return AuthUserModel.fromFirestore(doc);
    } on FirebaseAuthException catch (e) {
      throw Exception(_handleAuthException(e));
    }
  }

  // Get current user
  Future<AuthUserModel?> getCurrentUser() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final doc = await _firestore.collection('users').doc(user.uid).get();

      if (!doc.exists) {
        return null;
      }

      return AuthUserModel.fromFirestore(doc);
    } catch (e) {
      return null;
    }
  }

  // Stream of auth state changes
  Stream<AuthUserModel?> authStateChanges() {
    return _auth.authStateChanges().asyncMap((firebaseUser) async {
      if (firebaseUser == null) return null;

      final doc = await _firestore.collection('users').doc(firebaseUser.uid).get();

      if (!doc.exists) {
        return null;
      }

      return AuthUserModel.fromFirestore(doc);
    });
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Update display name
  Future<void> updateDisplayName(String uid, String displayName) async {
    await _firestore.collection('users').doc(uid).update({
      'displayName': displayName,
    });
  }

  // Delete user account
  Future<void> deleteAccount(String uid) async {
    try {
      // Delete Firestore document
      await _firestore.collection('users').doc(uid).delete();
      // Delete Firebase Auth user
      await _auth.currentUser?.delete();
    } catch (e) {
      throw Exception('Failed to delete account: $e');
    }
  }

  // Handle Firebase Auth exceptions
  String _handleAuthException(FirebaseAuthException e) {
    print('FirebaseAuthException code: ${e.code}');
    print('FirebaseAuthException message: ${e.message}');
    
    return switch (e.code) {
      'weak-password' => 'Password is too weak',
      'email-already-in-use' => 'Email already exists',
      'invalid-email' => 'Invalid email address',
      'user-disabled' => 'User account disabled',
      'user-not-found' => 'User not found',
      'wrong-password' => 'Wrong password',
      'invalid-credential' => 'Invalid credentials',
      'configuration-not-found' => 'Firebase not properly configured. Please check your Firebase setup.',
      'network-request-failed' => 'Network error. Please check your internet connection.',
      _ => e.message ?? 'Authentication failed: ${e.code}',
    };
  }

  // Extract meaningful error message from Firestore or other exceptions
  String _extractErrorMessage(dynamic error) {
    // Handle FirebaseException
    if (error is FirebaseException) {
      String msg = error.message ?? error.code;
      return msg.isEmpty ? 'Firebase error occurred' : msg;
    }
    
    // Handle Exception with message property
    if (error is Exception) {
      String msg = error.toString();
      // Remove exception wrapper prefixes
      if (msg.startsWith('Exception: ')) {
        msg = msg.substring(10);
      } else if (msg.startsWith('_Exception: ')) {
        msg = msg.substring(12);
      }
      
      // Ensure we have a meaningful message
      if (msg.isEmpty || msg == 'Error') {
        return 'An unexpected error occurred. Please try again.';
      }
      return msg;
    }
    
    // Handle String errors
    String msg = error.toString();
    if (msg.isEmpty || msg == 'Error' || msg == 'Exception: Error') {
      return 'An error occurred. Please check your internet connection and try again.';
    }
    
    return msg;
  }
}
