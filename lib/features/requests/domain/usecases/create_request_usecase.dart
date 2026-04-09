import '../../domain/repositories/requests_repository.dart';

class CreateRequestUseCase {
  const CreateRequestUseCase(this._repository);

  final RequestsRepository _repository;

  Future<void> call({
    required String title,
    String? description,
    double? budgetRange,
    bool isRemote = false,
    required double lat,
    required double lon,
  }) async {
    await _repository.createRequest(
      title: title,
      description: description,
      budgetRange: budgetRange,
      isRemote: isRemote,
      lat: lat,
      lon: lon,
    );
  }
}