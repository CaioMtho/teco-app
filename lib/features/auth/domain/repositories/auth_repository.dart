import '../entities/auth_sign_up_payload.dart';
import '../entities/auth_user.dart';

abstract class AuthRepository {
  Stream<AuthUser?> authStateChanges();

  AuthUser? get currentAuthUser;

  Future<void> sendPasswordResetEmail({
    required String email,
    required String redirectTo,
  });

  Future<void> updatePassword({
    required String password,
  });

  Future<void> signInWithPassword({
    required String email,
    required String password,
  });

  Future<void> signUpWithPassword(AuthSignUpPayload payload);

  Future<void> signOut();
}
