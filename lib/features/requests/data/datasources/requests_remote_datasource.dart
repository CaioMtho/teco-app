import 'package:latlong2/latlong.dart';

import '../../../../core/services/supabase_service.dart';
import '../../domain/entities/request_entity.dart';

class RequestsRemoteDataSource {
  Future<List<RequestEntity>> getOpenRequests() async {
    final response = await SupabaseService.client.rpc('list_requests_with_geojson');

    final rows = List<Map<String, dynamic>>.from(response as List);

    return rows.map(_mapRowToEntity).toList(growable: false);
  }

  RequestEntity _mapRowToEntity(Map<String, dynamic> row) {
    final id = row['id'] as String;
    final title = row['title'] as String;
    final status = row['status'] as String;
    final locationGeoJson = row['location_geojson'] as Map<String, dynamic>?;

    final latitude = _latFromGeo(locationGeoJson);
    final longitude = _lonFromGeo(locationGeoJson);

    if (latitude == null || longitude == null) {
      throw StateError('Invalid location_geojson for request $id');
    }

    return RequestEntity(
      id: id,
      title: title,
      status: status,
      location: LatLng(latitude, longitude),
    );
  }

  double? _latFromGeo(Map<String, dynamic>? geo) {
    if (geo == null) {
      return null;
    }

    final coords = geo['coordinates'];
    if (coords is! List || coords.length < 2) {
      return null;
    }

    final latValue = coords[1];
    if (latValue is! num) {
      return null;
    }

    return latValue.toDouble();
  }

  double? _lonFromGeo(Map<String, dynamic>? geo) {
    if (geo == null) {
      return null;
    }

    final coords = geo['coordinates'];
    if (coords is! List || coords.length < 2) {
      return null;
    }

    final lonValue = coords[0];
    if (lonValue is! num) {
      return null;
    }

    return lonValue.toDouble();
  }
}
