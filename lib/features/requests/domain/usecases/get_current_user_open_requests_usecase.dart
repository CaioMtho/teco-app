import '../entities/request_entity.dart';
import '../repositories/requests_repository.dart';

class GetCurrentUserOpenRequestsUseCase {
  GetCurrentUserOpenRequestsUseCase(this._repository);

  final RequestsRepository _repository;

  Future<List<RequestEntity>> call() {
    return _repository.getCurrentUserOpenRequests();
  }
}
