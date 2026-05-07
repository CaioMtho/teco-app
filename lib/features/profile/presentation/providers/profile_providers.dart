import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/profile_remote_datasource.dart';
import '../../data/repositories/profile_repository_impl.dart';
import '../../domain/repositories/profile_repository.dart';
import '../../domain/usecases/get_current_user_profile_usecase.dart';
import '../../domain/usecases/update_current_user_profile_usecase.dart';

final profileRemoteDataSourceProvider = Provider<ProfileRemoteDataSource>((ref) {
  return ProfileRemoteDataSource();
});

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepositoryImpl(ref.read(profileRemoteDataSourceProvider));
});

final getCurrentUserProfileUseCaseProvider =
    Provider<GetCurrentUserProfileUseCase>((ref) {
  return GetCurrentUserProfileUseCase(ref.read(profileRepositoryProvider));
});

final updateCurrentUserProfileUseCaseProvider =
    Provider<UpdateCurrentUserProfileUseCase>((ref) {
  return UpdateCurrentUserProfileUseCase(ref.read(profileRepositoryProvider));
});
