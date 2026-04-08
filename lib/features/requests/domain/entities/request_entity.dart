import 'package:latlong2/latlong.dart';

class RequestEntity {
  const RequestEntity({
    required this.id,
    required this.title,
    required this.status,
    required this.description,
    this.requesterId,
    this.budgetRange,
    this.isRemote,
    this.createdAt,
    required this.location,
  });

  final String id;
  final String title;
  final String status;
  final String? description;
  final String? requesterId;
  final String? budgetRange;
  final bool? isRemote;
  final DateTime? createdAt;
  final LatLng location;
}
