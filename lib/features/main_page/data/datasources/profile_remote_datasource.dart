import '../../../../core/services/supabase_service.dart';
import '../../domain/entities/profile_entity.dart';

class ProfileAuthRequiredException implements Exception {
  const ProfileAuthRequiredException();
}

class ProfileNotFoundException implements Exception {
  const ProfileNotFoundException();
}

class ProfileAccessDeniedException implements Exception {
  const ProfileAccessDeniedException();
}

class ProfileRemoteDataSource {
  Future<ProfileEntity> getCurrentUserProfile() async {
    final userId = SupabaseService.client.auth.currentUser?.id;
    if (userId == null || userId.isEmpty) {
      throw const ProfileAuthRequiredException();
    }

    final response = await SupabaseService.client
        .from('profiles')
        .select(
          'id, full_name, avatar_url, type, cpf_cnpj, is_verified, location, created_at, updated_at',
        )
        .eq('id', userId)
        .maybeSingle();

    if (response == null) {
      throw const ProfileNotFoundException();
    }

    return _mapRowToEntity(Map<String, dynamic>.from(response as Map));
  }

  Future<ProfileEntity> updateCurrentUserProfile({
    required String fullName,
    String? cpfCnpj,
  }) async {
    final userId = SupabaseService.client.auth.currentUser?.id;
    if (userId == null || userId.isEmpty) {
      throw const ProfileAuthRequiredException();
    }

    final response = await SupabaseService.client
        .from('profiles')
        .update({
          'full_name': fullName,
          'cpf_cnpj': cpfCnpj,
        })
        .eq('id', userId)
        .select(
          'id, full_name, avatar_url, type, cpf_cnpj, is_verified, location, created_at, updated_at',
        )
        .maybeSingle();

    if (response == null) {
      throw const ProfileNotFoundException();
    }

    return _mapRowToEntity(Map<String, dynamic>.from(response as Map));
  }

  ProfileEntity _mapRowToEntity(Map<String, dynamic> row) {
    final locationLabel = _locationLabelFromDynamic(row['location']);

    return ProfileEntity(
      id: row['id'].toString(),
      fullName: row['full_name'].toString(),
      type: row['type'].toString(),
      avatarUrl: row['avatar_url']?.toString(),
      cpfCnpj: row['cpf_cnpj']?.toString(),
      isVerified: _boolFromDynamic(row['is_verified']),
      locationLabel: locationLabel,
      createdAt: _dateFromDynamic(row['created_at']),
      updatedAt: _dateFromDynamic(row['updated_at']),
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

  String? _locationLabelFromDynamic(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }

    if (value is Map<String, dynamic>) {
      final coordinates = value['coordinates'];
      if (coordinates is List && coordinates.length >= 2) {
        final longitude = coordinates[0];
        final latitude = coordinates[1];
        if (longitude is num && latitude is num) {
          return '${latitude.toDouble()}, ${longitude.toDouble()}';
        }
      }
    }

    return value.toString();
  }
}
