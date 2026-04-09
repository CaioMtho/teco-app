import '../entities/auth_user.dart';
import '../repositories/auth_repository.dart';

class GetCurrentAuthUserUseCase {
  GetCurrentAuthUserUseCase(this._repository);

  final AuthRepository _repository;

  AuthUser? call() {
    return _repository.currentAuthUser;
  }
}
