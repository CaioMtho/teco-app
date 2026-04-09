import '../entities/auth_user.dart';
import '../repositories/auth_repository.dart';

class ObserveAuthStateUseCase {
  ObserveAuthStateUseCase(this._repository);

  final AuthRepository _repository;

  Stream<AuthUser?> call() {
    return _repository.authStateChanges();
  }
}
