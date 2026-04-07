import '../repositories/requests_repository.dart';

class DeleteCurrentUserRequestUseCase {
  DeleteCurrentUserRequestUseCase(this._repository);

  final RequestsRepository _repository;

  Future<void> call({
    required String requestId,
  }) {
    return _repository.deleteCurrentUserRequest(requestId: requestId);
  }
}
