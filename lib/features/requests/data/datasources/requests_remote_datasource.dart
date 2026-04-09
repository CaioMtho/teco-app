import 'package:latlong2/latlong.dart';

import '../../../../core/services/supabase_service.dart';
import '../../domain/entities/request_entity.dart';

class RequestsRemoteDataSource {
  Future<List<RequestEntity>> getOpenRequests() async {
    final response = await SupabaseService.client.rpc('list_requests_with_geojson');

    final rows = List<Map<String, dynamic>>.from(response as List);

    return rows.map(_mapRowToEntity).toList(growable: false);
  }

  Future<List<RequestEntity>> getCurrentUserOpenRequests() async {
    final userId = SupabaseService.client.auth.currentUser?.id;
    if (userId == null) {
      throw StateError('No authenticated user found to load requests');
    }

    final response = await SupabaseService.client.rpc('list_requests_with_geojson');
    final rows = List<Map<String, dynamic>>.from(response as List);

    return rows
        .where((row) => row['requester_id'] == userId && row['status'] == 'open')
        .map(_mapRowToEntity)
        .toList(growable: false);
  }

  Future<void> updateCurrentUserRequest({
    required String requestId,
    required String title,
    String? description,
    String? budgetRange,
    required bool isRemote,
  }) async {
    final userId = SupabaseService.client.auth.currentUser?.id;
    if (userId == null) {
      throw StateError('No authenticated user found to update request');
    }

    await SupabaseService.client
        .from('requests')
        .update({
          'title': title,
          'description': description,
          'budget_range': budgetRange,
          'is_remote': isRemote,
        })
        .eq('id', requestId)
        .eq('requester_id', userId)
        .select('id')
        .single();
  }

  Future<void> deleteCurrentUserRequest({
    required String requestId,
  }) async {
    final userId = SupabaseService.client.auth.currentUser?.id;
    if (userId == null) {
      throw StateError('No authenticated user found to delete request');
    }

    await SupabaseService.client
        .from('requests')
        .delete()
        .eq('id', requestId)
        .eq('requester_id', userId)
        .select('id')
        .single();
  }

  RequestEntity _mapRowToEntity(Map<String, dynamic> row) {
    final id = row['id'].toString();
    final title = row['title'].toString();
    final status = row['status'].toString();
    final description = row['description']?.toString();
    final requesterId = row['requester_id']?.toString();
    final budgetRange = row['budget_range']?.toString();
    final isRemote = _boolFromDynamic(row['is_remote']);
    final createdAt = _dateFromDynamic(row['created_at']);
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
      description: description,
      requesterId: requesterId,
      budgetRange: budgetRange,
      isRemote: isRemote,
      createdAt: createdAt,
      location: LatLng(latitude, longitude),
    );
  }

  bool? _boolFromDynamic(dynamic value) {
    if (value is bool) {
      return value;
    }

    if (value is num) {
      return value != 0;
    }

    if (value is String) {
      final normalized = value.toLowerCase();
      if (normalized == 'true' || normalized == 't' || normalized == '1') {
        return true;
      }

      if (normalized == 'false' || normalized == 'f' || normalized == '0') {
        return false;
      }
    }

    return null;
  }

  DateTime? _dateFromDynamic(dynamic value) {
    if (value is DateTime) {
      return value;
    }

    if (value is String) {
      return DateTime.tryParse(value);
    }

    return null;
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
