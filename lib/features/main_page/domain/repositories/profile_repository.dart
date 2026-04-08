import '../entities/profile_entity.dart';

abstract class ProfileRepository {
  Future<ProfileEntity> getCurrentUserProfile();

  Future<ProfileEntity> updateCurrentUserProfile({
    required String fullName,
    String? cpfCnpj,
  });
}
