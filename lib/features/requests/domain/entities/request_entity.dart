import 'package:latlong2/latlong.dart';

class RequestEntity {
  const RequestEntity({
    required this.id,
    required this.title,
    required this.status,
    required this.description,
    required this.location,
  });

  final String id;
  final String title;
  final String status;
  final String? description;
  final LatLng location;
}
