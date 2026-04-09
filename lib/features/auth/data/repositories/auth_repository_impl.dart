import '../../domain/entities/auth_sign_up_payload.dart';
import '../../domain/entities/auth_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._remoteDataSource);

  final AuthRemoteDataSource _remoteDataSource;

  @override
  Stream<AuthUser?> authStateChanges() {
    return _remoteDataSource.authStateChanges();
  }

  @override
  AuthUser? get currentAuthUser {
    return _remoteDataSource.currentAuthUser;
  }

  @override
  Future<void> signInWithPassword({
    required String email,
    required String password,
  }) {
    return _remoteDataSource.signInWithPassword(
      email: email,
      password: password,
    );
  }

  @override
  Future<void> signUpWithPassword(AuthSignUpPayload payload) {
    return _remoteDataSource.signUpWithPassword(payload);
  }

  @override
  Future<void> signOut() {
    return _remoteDataSource.signOut();
  }
}
