import '../entities/profile_entity.dart';
import '../repositories/profile_repository.dart';

class UpdateCurrentUserProfileUseCase {
  UpdateCurrentUserProfileUseCase(this._repository);

  final ProfileRepository _repository;

  Future<ProfileEntity> call({
    required String fullName,
    String? cpfCnpj,
  }) {
    return _repository.updateCurrentUserProfile(
      fullName: fullName,
      cpfCnpj: cpfCnpj,
    );
  }
}
