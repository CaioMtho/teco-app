import '../repositories/auth_repository.dart';

class SendPasswordResetEmailUseCase {
  SendPasswordResetEmailUseCase(this._repository);

  final AuthRepository _repository;

  Future<void> call({
    required String email,
    required String redirectTo,
  }) {
    return _repository.sendPasswordResetEmail(
      email: email,
      redirectTo: redirectTo,
    );
  }
}