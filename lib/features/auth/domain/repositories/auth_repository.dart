import '../entities/auth_user.dart';

abstract class AuthRepository {
  // Sign up with email and password
  Future<AuthUser> signUpWithEmail({
    required String email,
    required String password,
  });

  // Sign in with email and password
  Future<AuthUser> signInWithEmail({
    required String email,
    required String password,
  });

  // Sign out
  Future<void> signOut();

  // Get current user
  Future<AuthUser?> getCurrentUser();

  // Stream of current user
  Stream<AuthUser?> authStateChanges();

  // Update user display name
  Future<void> updateDisplayName(String uid, String displayName);

  // Delete user account
  Future<void> deleteAccount(String uid);
}
