import '../../../main_page/domain/entities/profile_entity.dart';
import 'auth_user.dart';

class AppAuthState {
  const AppAuthState._({
    required this.isAuthenticated,
    this.user,
    this.profile,
    this.message,
  });

  const AppAuthState.unauthenticated({String? message})
      : this._(
          isAuthenticated: false,
          message: message,
        );

  const AppAuthState.authenticated({
    required AuthUser user,
    required ProfileEntity profile,
  }) : this._(
          isAuthenticated: true,
          user: user,
          profile: profile,
        );

  final bool isAuthenticated;
  final AuthUser? user;
  final ProfileEntity? profile;
  final String? message;
}
