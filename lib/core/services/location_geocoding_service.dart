import 'package:geocoding/geocoding.dart';
import 'package:latlong2/latlong.dart';

class AddressSuggestion {
  const AddressSuggestion({
    required this.location,
    required this.label,
  });

  final LatLng location;
  final String label;
}

class LocationGeocodingService {
  const LocationGeocodingService();

  Future<String?> reverseGeocodeLabel(LatLng location) async {
    try {
      final placemarks = await placemarkFromCoordinates(
        location.latitude,
        location.longitude,
      );
      if (placemarks.isEmpty) {
        return null;
      }

      return formatPlacemark(placemarks.first);
    } catch (_) {
      return null;
    }
  }

  Future<List<AddressSuggestion>> searchAddress(
    String query, {
    int limit = 3,
  }) async {
    final normalized = query.trim();
    if (normalized.isEmpty) {
      return const [];
    }

    try {
      final locations = await locationFromAddress(normalized);
      if (locations.isEmpty) {
        return const [];
      }

      final limited = locations.take(limit).toList(growable: false);

      final futures = limited.map((item) async {
        final currentLocation = LatLng(item.latitude, item.longitude);
        final label = await reverseGeocodeLabel(currentLocation);
        return AddressSuggestion(
          location: currentLocation,
          label: label ??
              '${item.latitude.toStringAsFixed(4)}, ${item.longitude.toStringAsFixed(4)}',
        );
      });

      return await Future.wait(futures);
    } catch (_) {
      return const [];
    }
  }

  String? formatPlacemark(Placemark placemark) {
    final parts = <String>[
      if (placemark.street != null && placemark.street!.trim().isNotEmpty)
        placemark.street!.trim(),
      if (placemark.subLocality != null &&
          placemark.subLocality!.trim().isNotEmpty)
        placemark.subLocality!.trim(),
      if (placemark.locality != null && placemark.locality!.trim().isNotEmpty)
        placemark.locality!.trim(),
      if (placemark.administrativeArea != null &&
          placemark.administrativeArea!.trim().isNotEmpty)
        placemark.administrativeArea!.trim(),
    ];

    if (parts.isEmpty) {
      return null;
    }

    return parts.join(', ');
  }
}
