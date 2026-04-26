
import '../../../../core/services/supabase_service.dart';
import '../../domain/entities/auth_sign_up_payload.dart';
import '../../domain/entities/auth_user.dart' as auth_entity;

class AuthRemoteDataSource {
  Stream<auth_entity.AuthUser?> authStateChanges() {
    return SupabaseService.client.auth.onAuthStateChange.map((authState) {
      final user = authState.session?.user;
      if (user == null) {
        return null;
      }

      return auth_entity.AuthUser(
        id: user.id,
        email: user.email,
      );
    });
  }

  auth_entity.AuthUser? get currentAuthUser {
    final user = SupabaseService.client.auth.currentUser;
    if (user == null) {
      return null;
    }

    return auth_entity.AuthUser(
      id: user.id,
      email: user.email,
    );
  }

  Future<void> signInWithPassword({
    required String email,
    required String password,
  }) async {
    await SupabaseService.client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signUpWithPassword(AuthSignUpPayload payload) async {
    await SupabaseService.client.auth.signUp(
      email: payload.email,
      password: payload.password,
      data: {
        'full_name': payload.fullName,
        'type': payload.userType,
        'cpf_cnpj': payload.cpfCnpj,
        'location': {
          'lat': payload.location.latitude,
          'lng': payload.location.longitude,
        },
      },
    );
  }

  Future<void> signOut() async {
    await SupabaseService.client.auth.signOut();
  }
}
