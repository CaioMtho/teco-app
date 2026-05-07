import '../entities/profile_entity.dart';
import '../repositories/profile_repository.dart';

class GetCurrentUserProfileUseCase {
  GetCurrentUserProfileUseCase(this._repository);

  final ProfileRepository _repository;

  Future<ProfileEntity> call() {
    return _repository.getCurrentUserProfile();
  }
}
