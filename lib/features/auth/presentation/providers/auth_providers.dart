import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../main_page/data/datasources/profile_remote_datasource.dart';
import '../../../main_page/data/repositories/profile_repository_impl.dart';
import '../../../main_page/domain/repositories/profile_repository.dart';
import '../../../main_page/domain/usecases/get_current_user_profile_usecase.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/app_auth_state.dart';
import '../../domain/entities/auth_sign_up_payload.dart';
import '../../domain/entities/auth_user.dart' as auth_entity;
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/get_current_auth_user_usecase.dart';
import '../../domain/usecases/observe_auth_state_usecase.dart';
import '../../domain/usecases/sign_in_usecase.dart';
import '../../domain/usecases/sign_out_usecase.dart';
import '../../domain/usecases/sign_up_usecase.dart';

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  return AuthRemoteDataSource();
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(ref.read(authRemoteDataSourceProvider));
});

final signInUseCaseProvider = Provider<SignInUseCase>((ref) {
  return SignInUseCase(ref.read(authRepositoryProvider));
});

final signUpUseCaseProvider = Provider<SignUpUseCase>((ref) {
  return SignUpUseCase(ref.read(authRepositoryProvider));
});

final signOutUseCaseProvider = Provider<SignOutUseCase>((ref) {
  return SignOutUseCase(ref.read(authRepositoryProvider));
});

final observeAuthStateUseCaseProvider = Provider<ObserveAuthStateUseCase>((ref) {
  return ObserveAuthStateUseCase(ref.read(authRepositoryProvider));
});

final getCurrentAuthUserUseCaseProvider = Provider<GetCurrentAuthUserUseCase>((ref) {
  return GetCurrentAuthUserUseCase(ref.read(authRepositoryProvider));
});

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepositoryImpl(ProfileRemoteDataSource());
});

final getCurrentUserProfileUseCaseProvider =
    Provider<GetCurrentUserProfileUseCase>((ref) {
  return GetCurrentUserProfileUseCase(ref.read(profileRepositoryProvider));
});

final authControllerProvider =
    AsyncNotifierProvider<AuthController, AppAuthState>(AuthController.new);

class AuthController extends AsyncNotifier<AppAuthState> {
  StreamSubscription<auth_entity.AuthUser?>? _authSubscription;

  @override
  Future<AppAuthState> build() async {
    _authSubscription ??= ref
        .read(observeAuthStateUseCaseProvider)
        .call()
        .listen((authUser) {
      unawaited(_refreshFromAuthState(authUser));
    });

    ref.onDispose(() {
      _authSubscription?.cancel();
      _authSubscription = null;
    });

    final authUser = ref.read(getCurrentAuthUserUseCaseProvider).call();
    return _resolveAuthState(authUser);
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) {
    return ref.read(signInUseCaseProvider).call(
          email: email,
          password: password,
        );
  }

  Future<void> signUp(AuthSignUpPayload payload) {
    return ref.read(signUpUseCaseProvider).call(payload);
  }

  Future<void> signOut() {
    return ref.read(signOutUseCaseProvider).call();
  }

  Future<void> _refreshFromAuthState(auth_entity.AuthUser? authUser) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      return _resolveAuthState(authUser);
    });
  }

  Future<AppAuthState> _resolveAuthState(auth_entity.AuthUser? authUser) async {
    if (authUser == null) {
      return const AppAuthState.unauthenticated();
    }

    try {
      final profile = await ref.read(getCurrentUserProfileUseCaseProvider).call();
      return AppAuthState.authenticated(
        user: authUser,
        profile: profile,
      );
    } on ProfileNotFoundException {
      await ref.read(signOutUseCaseProvider).call();
      return const AppAuthState.unauthenticated(
        message:
            'Perfil de usuario nao encontrado. Faça login novamente apos concluir o cadastro.',
      );
    } on ProfileAuthRequiredException {
      return const AppAuthState.unauthenticated();
    } on AuthException catch (error) {
      return AppAuthState.unauthenticated(message: error.message);
    } catch (_) {
      await ref.read(signOutUseCaseProvider).call();
      return const AppAuthState.unauthenticated(
        message: 'Erro ao carregar perfil. Efetue o login novamente.',
      );
    }
  }
}
