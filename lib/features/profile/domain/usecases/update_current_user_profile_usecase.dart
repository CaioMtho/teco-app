import 'package:latlong2/latlong.dart';

import '../entities/profile_entity.dart';
import '../repositories/profile_repository.dart';

class UpdateCurrentUserProfileUseCase {
  UpdateCurrentUserProfileUseCase(this._repository);

  final ProfileRepository _repository;

  Future<ProfileEntity> call({
    required String fullName,
    String? cpfCnpj,
    LatLng? location,
  }) {
    return _repository.updateCurrentUserProfile(
      fullName: fullName,
      cpfCnpj: cpfCnpj,
      location: location,
    );
  }
}
