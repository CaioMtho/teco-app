import 'package:latlong2/latlong.dart';

import '../../domain/entities/request_entity.dart';
import '../../domain/repositories/requests_repository.dart';
import '../datasources/requests_remote_datasource.dart';

class RequestsRepositoryImpl implements RequestsRepository {
  RequestsRepositoryImpl(this._remoteDataSource, {Distance? distance})
      : _distance = distance ?? const Distance();

  final RequestsRemoteDataSource _remoteDataSource;
  final Distance _distance;

  @override
  Future<List<RequestEntity>> getNearbyOpenRequests({
    required LatLng center,
    required double radiusKm,
  }) async {
    final openRequests = await _remoteDataSource.getOpenRequests();

    return openRequests.where((request) {
      final requestDistance =
          _distance.as(LengthUnit.Kilometer, center, request.location);
      return requestDistance <= radiusKm;
    }).toList(growable: false);
  }

  @override
  Future<List<RequestEntity>> getCurrentUserOpenRequests() {
    return _remoteDataSource.getCurrentUserOpenRequests();
  }

  @override
  Future<void> updateCurrentUserRequest({
    required String requestId,
    required String title,
    String? description,
    String? budgetRange,
    required bool isRemote,
  }) {
    return _remoteDataSource.updateCurrentUserRequest(
      requestId: requestId,
      title: title,
      description: description,
      budgetRange: budgetRange,
      isRemote: isRemote,
    );
  }

  @override
  Future<void> deleteCurrentUserRequest({
    required String requestId,
  }) {
    return _remoteDataSource.deleteCurrentUserRequest(requestId: requestId);
  }
}
