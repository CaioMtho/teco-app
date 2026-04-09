import 'package:latlong2/latlong.dart';

class AuthSignUpPayload {
  const AuthSignUpPayload({
    required this.fullName,
    required this.email,
    required this.password,
    required this.userType,
    required this.cpfCnpj,
    required this.location,
  });

  final String fullName;
  final String email;
  final String password;
  final String userType;
  final String cpfCnpj;
  final LatLng location;
}
