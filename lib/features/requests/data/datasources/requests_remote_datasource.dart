import 'package:latlong2/latlong.dart';

import '../../../../core/services/supabase_service.dart';
import '../../domain/entities/request_entity.dart';

class RequestsRemoteDataSource {
  Future<List<RequestEntity>> getOpenRequests() async {
    final response = await SupabaseService.client
        .from('requests')
        .select('id, title, status, location')
        .eq('status', 'open')
        .not('location', 'is', null)
        .order('created_at', ascending: false);

    final rows = List<Map<String, dynamic>>.from(response as List);

    return rows.map(_mapRowToEntity).toList(growable: false);
  }

  RequestEntity _mapRowToEntity(Map<String, dynamic> row) {
    final id = row['id'] as String;
    final title = row['title'] as String;
    final status = row['status'] as String;
    final locationMap = row['location'] as Map<String, dynamic>;
    final latitude = (locationMap['latitude'] as num).toDouble();
    final longitude = (locationMap['longitude'] as num).toDouble();

    return RequestEntity(
      id: id,
      title: title,
      status: status,
      location: LatLng(latitude, longitude),
    );
  }
}
