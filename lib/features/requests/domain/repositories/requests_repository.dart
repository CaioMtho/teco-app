import 'package:latlong2/latlong.dart';

import '../entities/request_entity.dart';

abstract class RequestsRepository {
  Future<List<RequestEntity>> getNearbyOpenRequests({
    required LatLng center,
    required double radiusKm,
  });
}
