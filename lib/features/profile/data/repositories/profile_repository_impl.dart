import 'package:latlong2/latlong.dart';

import '../../domain/entities/profile_entity.dart';
import '../../domain/repositories/profile_repository.dart';
import '../datasources/profile_remote_datasource.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  ProfileRepositoryImpl(this._remoteDataSource);

  final ProfileRemoteDataSource _remoteDataSource;

  @override
  Future<ProfileEntity> getCurrentUserProfile() {
    return _remoteDataSource.getCurrentUserProfile();
  }

  @override
  Future<ProfileEntity> updateCurrentUserProfile({
    required String fullName,
    String? cpfCnpj,
    LatLng? location,
  }) {
    return _remoteDataSource.updateCurrentUserProfile(
      fullName: fullName,
      cpfCnpj: cpfCnpj,
      location: location,
    );
  }
}
