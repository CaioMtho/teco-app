import 'package:latlong2/latlong.dart';

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

    final rpcResponse = await SupabaseService.client.rpc(
      'get_profile_with_location_lat_lng',
      params: {'p_user_id': userId},
    );

    final rpcRow = _asMapOrNull(rpcResponse);
    if (rpcRow != null) {
      return _mapRowToEntity(rpcRow);
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
    final location = _locationFromRow(row);
    final locationLabel = _locationLabelFromRow(
      row: row,
      fallbackLocation: location,
    );

    return ProfileEntity(
      id: _readString(row, const ['id']) ?? '',
      fullName: _readString(row, const ['full_name', 'fullName']) ?? '',
      type: _readString(row, const ['type']) ?? '',
      avatarUrl: row['avatar_url']?.toString(),
      cpfCnpj: row['cpf_cnpj']?.toString(),
      isVerified: _boolFromDynamic(row['is_verified']),
      locationLabel: locationLabel,
      location: location,
      createdAt: _dateFromDynamic(row['created_at']),
      updatedAt: _dateFromDynamic(row['updated_at']),
    );
  }

  Map<String, dynamic>? _asMapOrNull(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }

    if (value is List && value.isNotEmpty && value.first is Map) {
      return Map<String, dynamic>.from(value.first as Map);
    }

    return null;
  }

  String? _readString(Map<String, dynamic> row, List<String> keys) {
    for (final key in keys) {
      final value = row[key];
      if (value != null) {
        final parsed = value.toString().trim();
        if (parsed.isNotEmpty) {
          return parsed;
        }
      }
    }

    return null;
  }

  LatLng? _locationFromRow(Map<String, dynamic> row) {
    final lat = row['location_lat'] ?? row['lat'] ?? row['latitude'];
    final lng = row['location_lng'] ?? row['lng'] ?? row['longitude'];
    if (lat is num && lng is num) {
      return LatLng(lat.toDouble(), lng.toDouble());
    }

    return _locationFromDynamic(row['location']);
  }

  String? _locationLabelFromRow({
    required Map<String, dynamic> row,
    required LatLng? fallbackLocation,
  }) {
    final directLabel = _readString(
      row,
      const ['location_label', 'locationLabel', 'address'],
    );
    if (directLabel != null) {
      return directLabel;
    }

    final fromLocation = _locationLabelFromDynamic(row['location']);
    if (fromLocation != null && fromLocation.trim().isNotEmpty) {
      return fromLocation;
    }

    if (fallbackLocation != null) {
      return '${fallbackLocation.latitude}, ${fallbackLocation.longitude}';
    }

    return null;
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

  LatLng? _locationFromDynamic(dynamic value) {
    if (value is Map<String, dynamic>) {
      final coordinates = value['coordinates'];
      if (coordinates is List && coordinates.length >= 2) {
        final longitude = coordinates[0];
        final latitude = coordinates[1];
        if (longitude is num && latitude is num) {
          return LatLng(latitude.toDouble(), longitude.toDouble());
        }
      }
    }

    if (value is String) {
      final match = RegExp(r'^\s*\(([-\d.]+),\s*([-\d.]+)\)\s*$').firstMatch(value);
      if (match != null) {
        final longitude = double.tryParse(match.group(1)!);
        final latitude = double.tryParse(match.group(2)!);
        if (longitude != null && latitude != null) {
          return LatLng(latitude, longitude);
        }
      }
    }

    return null;
  }
}
