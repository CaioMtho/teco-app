import '../repositories/auth_repository.dart';

class UpdatePasswordUseCase {
  UpdatePasswordUseCase(this._repository);

  final AuthRepository _repository;

  Future<void> call({
    required String password,
  }) {
    return _repository.updatePassword(password: password);
  }
}