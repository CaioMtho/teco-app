import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/services/supabase_service.dart';
import '../../domain/entities/request_entity.dart';

class RequestsRemoteDataSource {
  Future<List<RequestEntity>> getOpenRequests() async {
    debugPrint('[RequestsRemoteDataSource] Iniciando carregamento de requisições abertas');
    try {
      final response = await SupabaseService.client.rpc('list_requests_with_geojson');
      final rows = List<Map<String, dynamic>>.from(response as List);
      debugPrint('[RequestsRemoteDataSource] RPC retornou ${rows.length} requisições');
      return rows.map(_mapRowToEntity).toList(growable: false);
    } catch (e, st) {
      debugPrint('[RequestsRemoteDataSource] Erro ao carregar requisições abertas: $e\nStackTrace: $st');
      rethrow;
    }
  }

  Future<List<RequestEntity>> getCurrentUserOpenRequests() async {
    debugPrint('[RequestsRemoteDataSource] Iniciando carregamento de requisições do usuário atual');
    final userId = SupabaseService.client.auth.currentUser?.id;
    if (userId == null) {
      debugPrint('[RequestsRemoteDataSource] Usuário não autenticado');
      throw StateError('No authenticated user found to load requests');
    }
    debugPrint('[RequestsRemoteDataSource] userId obtido: $userId');

    try {
      final response = await SupabaseService.client.rpc('list_requests_with_geojson');
      final rows = List<Map<String, dynamic>>.from(response as List);
      debugPrint('[RequestsRemoteDataSource] RPC retornou ${rows.length} requisições totais');
      
      final userRequests = rows
          .where((row) => row['requester_id'] == userId && row['status'] == 'open')
          .map(_mapRowToEntity)
          .toList(growable: false);
      debugPrint('[RequestsRemoteDataSource] Filtrado para ${userRequests.length} requisições do usuário');
      return userRequests;
    } catch (e, st) {
      debugPrint('[RequestsRemoteDataSource] Erro ao carregar requisições do usuário: $e\nStackTrace: $st');
      rethrow;
    }
  }

  Future<void> createRequest({
    required String title,
    String? description,
    double? budgetRange,
    bool isRemote = false,
    required double lat,
    required double lon,
  }) async {
    debugPrint('[RequestsRemoteDataSource] Criando requisição: título=$title, remota=$isRemote, lat=$lat, lon=$lon');
    try {
      await SupabaseService.client.rpc('create_request_with_location', params: {
        'p_title': title,
        'p_description': description,
        'p_status': 'open',
        'p_budget_range': budgetRange,
        'p_is_remote': isRemote,
        'p_lat': lat,
        'p_lon': lon,
      });
      debugPrint('[RequestsRemoteDataSource] Requisição criada com sucesso');
    } catch (e, st) {
      debugPrint('[RequestsRemoteDataSource] Erro ao criar requisição: $e\nStackTrace: $st');
      rethrow;
    }
  }

  Future<void> updateCurrentUserRequest({
    required String requestId,
    required String title,
    String? description,
    String? budgetRange,
    required bool isRemote,
  }) async {
    debugPrint('[RequestsRemoteDataSource] Atualizando requisição: id=$requestId, título=$title, remota=$isRemote');
    final userId = SupabaseService.client.auth.currentUser?.id;
    if (userId == null) {
      debugPrint('[RequestsRemoteDataSource] Usuário não autenticado para atualizar');
      throw StateError('No authenticated user found to update request');
    }

    try {
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
      debugPrint('[RequestsRemoteDataSource] Requisição atualizada com sucesso');
    } catch (e, st) {
      debugPrint('[RequestsRemoteDataSource] Erro ao atualizar requisição: $e\nStackTrace: $st');
      rethrow;
    }
  }

  Future<void> deleteCurrentUserRequest({
    required String requestId,
  }) async {
    debugPrint('[RequestsRemoteDataSource] Deletando requisição: id=$requestId');
    final userId = SupabaseService.client.auth.currentUser?.id;
    if (userId == null) {
      debugPrint('[RequestsRemoteDataSource] Usuário não autenticado para deletar');
      throw StateError('No authenticated user found to delete request');
    }

    try {
      await SupabaseService.client
          .from('requests')
          .delete()
          .eq('id', requestId)
          .eq('requester_id', userId)
          .select('id')
          .single();
      debugPrint('[RequestsRemoteDataSource] Requisição deletada com sucesso');
    } catch (e, st) {
      debugPrint('[RequestsRemoteDataSource] Erro ao deletar requisição: $e\nStackTrace: $st');
      rethrow;
    }
  }

  RequestEntity _mapRowToEntity(Map<String, dynamic> row) {
    debugPrint('[RequestsRemoteDataSource] Mapeando requisição: id=${row['id']}, título=${row['title']}');
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
      debugPrint('[RequestsRemoteDataSource] GeoJSON inválido para requisição $id');
      throw StateError('Invalid location_geojson for request $id');
    }

    final entity = RequestEntity(
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
    debugPrint('[Requisição mapeada: ID=$id, título=$title, location=($latitude, $longitude)');
    return entity;
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
