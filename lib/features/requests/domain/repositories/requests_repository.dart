import 'package:latlong2/latlong.dart';

import '../entities/request_entity.dart';

abstract class RequestsRepository {
  Future<List<RequestEntity>> getNearbyOpenRequests({
    required LatLng center,
    required double radiusKm,
  });

  Future<List<RequestEntity>> getCurrentUserOpenRequests();

  Future<void> updateCurrentUserRequest({
    required String requestId,
    required String title,
    String? description,
    String? budgetRange,
    required bool isRemote,
  });

  Future<void> deleteCurrentUserRequest({
    required String requestId,
  });
}
