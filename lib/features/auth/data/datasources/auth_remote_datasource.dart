import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/auth_sign_up_payload.dart';
import '../../domain/entities/auth_user.dart' as auth_entity;

class AuthRemoteDataSource {
  final SupabaseClient supabaseClient;

  AuthRemoteDataSource({required this.supabaseClient});

  Stream<auth_entity.AuthUser?> authStateChanges() {
    return supabaseClient.auth.onAuthStateChange.map((authState) {
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
    final user = supabaseClient.auth.currentUser;
    if (user == null) {
      return null;
    }

    return auth_entity.AuthUser(
      id: user.id,
      email: user.email,
    );
  }

  Future<void> sendPasswordResetEmail({
    required String email,
    required String redirectTo,
  }) async {
    await supabaseClient.auth.resetPasswordForEmail(
      email,
      redirectTo: redirectTo,
    );
  }

  Future<void> updatePassword({
    required String password,
  }) async {
    await supabaseClient.auth.updateUser(
      UserAttributes(password: password),
    );
  }

  Future<void> signInWithPassword({
    required String email,
    required String password,
  }) async {
    await supabaseClient.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signUpWithPassword(AuthSignUpPayload payload) async {
    await supabaseClient.auth.signUp(
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
    await supabaseClient.auth.signOut();
  }
}
