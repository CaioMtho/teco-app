import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/requests_remote_datasource.dart';
import '../../data/repositories/requests_repository_impl.dart';
import '../../domain/repositories/requests_repository.dart';
import '../../domain/usecases/create_request_usecase.dart';
import '../../domain/usecases/delete_current_user_request_usecase.dart';
import '../../domain/usecases/get_current_user_open_requests_usecase.dart';
import '../../domain/usecases/get_nearby_open_requests_usecase.dart';
import '../../domain/usecases/update_current_user_request_usecase.dart';

final requestsRemoteDataSourceProvider = Provider<RequestsRemoteDataSource>((ref) {
  return RequestsRemoteDataSource();
});

final requestsRepositoryProvider = Provider<RequestsRepository>((ref) {
  return RequestsRepositoryImpl(ref.read(requestsRemoteDataSourceProvider));
});

final createRequestUseCaseProvider = Provider<CreateRequestUseCase>((ref) {
  return CreateRequestUseCase(ref.read(requestsRepositoryProvider));
});

final getNearbyOpenRequestsUseCaseProvider =
    Provider<GetNearbyOpenRequestsUseCase>((ref) {
  return GetNearbyOpenRequestsUseCase(ref.read(requestsRepositoryProvider));
});

final getCurrentUserOpenRequestsUseCaseProvider =
    Provider<GetCurrentUserOpenRequestsUseCase>((ref) {
  return GetCurrentUserOpenRequestsUseCase(ref.read(requestsRepositoryProvider));
});

final updateCurrentUserRequestUseCaseProvider =
    Provider<UpdateCurrentUserRequestUseCase>((ref) {
  return UpdateCurrentUserRequestUseCase(ref.read(requestsRepositoryProvider));
});

final deleteCurrentUserRequestUseCaseProvider =
    Provider<DeleteCurrentUserRequestUseCase>((ref) {
  return DeleteCurrentUserRequestUseCase(ref.read(requestsRepositoryProvider));
});
