import '../repositories/requests_repository.dart';

class UpdateRequestStatusUseCase {
  UpdateRequestStatusUseCase(this._repository);

  final RequestsRepository _repository;

  Future<void> call({
    required String requestId,
    required String status,
  }) {
    return _repository.updateRequestStatus(
      requestId: requestId,
      status: status,
    );
  }
}