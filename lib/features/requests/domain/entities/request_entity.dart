import 'package:latlong2/latlong.dart';

class RequestEntity {
  const RequestEntity({
    required this.id,
    required this.title,
    required this.status,
    required this.location,
  });

  final String id;
  final String title;
  final String status;
  final LatLng location;
}
