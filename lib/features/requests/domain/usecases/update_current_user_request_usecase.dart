import '../repositories/requests_repository.dart';

class UpdateCurrentUserRequestUseCase {
  UpdateCurrentUserRequestUseCase(this._repository);

  final RequestsRepository _repository;

  Future<void> call({
    required String requestId,
    required String title,
    String? description,
    String? budgetRange,
    required bool isRemote,
  }) {
    return _repository.updateCurrentUserRequest(
      requestId: requestId,
      title: title,
      description: description,
      budgetRange: budgetRange,
      isRemote: isRemote,
    );
  }
}
