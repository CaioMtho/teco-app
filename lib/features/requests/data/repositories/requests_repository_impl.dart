import 'package:flutter/foundation.dart';
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
    debugPrint('[RequestsRepository] Buscando requisições próximas: centro=(${ center.latitude},${center.longitude}), raio=${radiusKm}km');
    try {
      final openRequests = await _remoteDataSource.getOpenRequests();
      debugPrint('[RequestsRepository] ${openRequests.length} requisições abertas obtidas');

      final nearby = openRequests.where((request) {
        final requestDistance =
            _distance.as(LengthUnit.Kilometer, center, request.location);
        final isWithinRadius = requestDistance <= radiusKm;
        if (!isWithinRadius) {
          debugPrint('[RequestsRepository] Requisição fora do raio: ${request.title} (${requestDistance.toStringAsFixed(2)}km)');
        }
        return isWithinRadius;
      }).toList(growable: false);
      
      debugPrint('[RequestsRepository] ${nearby.length} requisições dentro do raio de ${radiusKm}km');
      return nearby;
    } catch (e, st) {
      debugPrint('[RequestsRepository] Erro ao buscar requisições próximas: $e\nStackTrace: $st');
      rethrow;
    }
  }

  @override
  Future<List<RequestEntity>> getCurrentUserOpenRequests() async {
    debugPrint('[RequestsRepository] Carregando requisições abertas do usuário');
    try {
      final requests = await _remoteDataSource.getCurrentUserOpenRequests();
      debugPrint('[RequestsRepository] ${requests.length} requisições do usuário carregadas');
      return requests;
    } catch (e, st) {
      debugPrint('[RequestsRepository] Erro ao carregar requisições do usuário: $e\nStackTrace: $st');
      rethrow;
    }
  }

  @override
  Future<void> updateCurrentUserRequest({
    required String requestId,
    required String title,
    String? description,
    String? budgetRange,
    required bool isRemote,
  }) async {
    debugPrint('[RequestsRepository] Atualizando requisição: $title');
    try {
      await _remoteDataSource.updateCurrentUserRequest(
        requestId: requestId,
        title: title,
        description: description,
        budgetRange: budgetRange,
        isRemote: isRemote,
      );
      debugPrint('[RequestsRepository] Requisição atualizada com sucesso');
    } catch (e, st) {
      debugPrint('[RequestsRepository] Erro ao atualizar requisição: $e\nStackTrace: $st');
      rethrow;
    }
  }

  @override
  Future<void> createRequest({
    required String title,
    String? description,
    double? budgetRange,
    bool isRemote = false,
    required double lat,
    required double lon,
  }) async {
    debugPrint('[RequestsRepository] Criando requisição: $title');
    try {
      await _remoteDataSource.createRequest(
        title: title,
        description: description,
        budgetRange: budgetRange,
        isRemote: isRemote,
        lat: lat,
        lon: lon,
      );
      debugPrint('[RequestsRepository] Requisição criada com sucesso');
    } catch (e, st) {
      debugPrint('[RequestsRepository] Erro ao criar requisição: $e\nStackTrace: $st');
      rethrow;
    }
  }

  @override
  Future<void> deleteCurrentUserRequest({
    required String requestId,
  }) async {
    debugPrint('[RequestsRepository] Deletando requisição: $requestId');
    try {
      await _remoteDataSource.deleteCurrentUserRequest(requestId: requestId);
      debugPrint('[RequestsRepository] Requisição deletada com sucesso');
    } catch (e, st) {
      debugPrint('[RequestsRepository] Erro ao deletar requisição: $e\nStackTrace: $st');
      rethrow;
    }
  }
}
