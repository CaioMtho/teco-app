import 'package:latlong2/latlong.dart';

import '../entities/request_entity.dart';
import '../repositories/requests_repository.dart';

class GetNearbyOpenRequestsUseCase {
  GetNearbyOpenRequestsUseCase(this._repository);

  final RequestsRepository _repository;

  Future<List<RequestEntity>> call({
    required LatLng center,
    required double radiusKm,
  }) {
    return _repository.getNearbyOpenRequests(
      center: center,
      radiusKm: radiusKm,
    );
  }
}
