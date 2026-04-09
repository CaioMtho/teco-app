import '../entities/auth_sign_up_payload.dart';
import '../repositories/auth_repository.dart';

class SignUpUseCase {
  SignUpUseCase(this._repository);

  final AuthRepository _repository;

  Future<void> call(AuthSignUpPayload payload) {
    return _repository.signUpWithPassword(payload);
  }
}
