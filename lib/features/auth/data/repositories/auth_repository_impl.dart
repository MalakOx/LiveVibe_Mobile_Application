import '../datasources/firebase_auth_datasource.dart';
import '../../domain/entities/auth_user.dart';
import '../../domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final FirebaseAuthDatasource _datasource;

  AuthRepositoryImpl(this._datasource);

  @override
  Future<AuthUser> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    final userModel = await _datasource.signUpWithEmail(
      email: email,
      password: password,
    );
    return userModel.toEntity();
  }

  @override
  Future<AuthUser> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final userModel = await _datasource.signInWithEmail(
      email: email,
      password: password,
    );
    return userModel.toEntity();
  }

  @override
  Future<void> signOut() => _datasource.signOut();

  @override
  Future<AuthUser?> getCurrentUser() async {
    final userModel = await _datasource.getCurrentUser();
    return userModel?.toEntity();
  }

  @override
  Stream<AuthUser?> authStateChanges() {
    return _datasource.authStateChanges().map((userModel) {
      return userModel?.toEntity();
    });
  }

  @override
  Future<void> updateDisplayName(String uid, String displayName) =>
      _datasource.updateDisplayName(uid, displayName);

  @override
  Future<void> deleteAccount(String uid) => _datasource.deleteAccount(uid);
}
