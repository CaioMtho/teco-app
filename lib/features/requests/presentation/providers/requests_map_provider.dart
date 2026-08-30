import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/request_entity.dart';
import 'requests_providers.dart';

class RequestsMapState {
  final List<RequestEntity> openRequests;
  final List<RequestEntity> currentUserOpenRequests;
  final LatLng mainLocation;
  final bool hasResolvedMainLocation;

  RequestsMapState({
    required this.openRequests,
    required this.currentUserOpenRequests,
    required this.mainLocation,
    required this.hasResolvedMainLocation,
  });
}

class RequestsMapNotifier extends AsyncNotifier<RequestsMapState> {
  static const LatLng _defaultMapCenter = LatLng(-23.55052, -46.633308);

  @override
  Future<RequestsMapState> build() async {
    return _loadData();
  }

  Future<RequestsMapState> _loadData() async {
    final mainLocation = await _resolveMainLocation();

    List<RequestEntity> openRequests = const [];
    try {
      openRequests = await ref.read(getNearbyOpenRequestsUseCaseProvider).call(
        center: mainLocation,
        radiusKm: AppConstants.openRequestsRadiusKm,
      );
    } catch (e) {
      // Ignora erro para não quebrar a página toda
    }

    List<RequestEntity> currentUserOpenRequests = const [];
    try {
      currentUserOpenRequests = await ref.read(getCurrentUserOpenRequestsUseCaseProvider).call();
    } catch (e) {
      // Ignora erro
    }

    return RequestsMapState(
      openRequests: openRequests,
      currentUserOpenRequests: currentUserOpenRequests,
      mainLocation: mainLocation,
      hasResolvedMainLocation: true,
    );
  }

  Future<void> reload() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _loadData());
  }

  Future<void> refreshMyOpenRequests() async {
    final current = state.valueOrNull;
    if (current == null) return;
    try {
      final requests = await ref.read(getCurrentUserOpenRequestsUseCaseProvider).call();
      state = AsyncValue.data(RequestsMapState(
        openRequests: current.openRequests,
        currentUserOpenRequests: requests,
        mainLocation: current.mainLocation,
        hasResolvedMainLocation: current.hasResolvedMainLocation,
      ));
    } catch (e) {
      // Ignora
    }
  }

  Future<void> createRequest({
    required String title,
    String? description,
    double? budgetRange,
    required bool isRemote,
    required double lat,
    required double lon,
  }) async {
    await ref.read(createRequestUseCaseProvider).call(
      title: title,
      description: description,
      budgetRange: budgetRange,
      isRemote: isRemote,
      lat: lat,
      lon: lon,
    );
    await reload();
  }

  Future<void> updateRequest({
    required String requestId,
    required String title,
    String? description,
    double? budgetRange,
    required bool isRemote,
  }) async {
    await ref.read(updateCurrentUserRequestUseCaseProvider).call(
      requestId: requestId,
      title: title,
      description: description,
      budgetRange: budgetRange,
      isRemote: isRemote,
    );
    await reload();
  }

  Future<void> deleteRequest(String requestId) async {
    await ref.read(deleteCurrentUserRequestUseCaseProvider).call(requestId: requestId);
    await reload();
  }

  Future<LatLng> _resolveMainLocation() async {
    final deviceLocation = await _resolveDeviceLocation();
    if (deviceLocation != null && _isValidLatLng(deviceLocation)) {
      return deviceLocation;
    }

    final profileLocation = ref.read(authControllerProvider).valueOrNull?.profile?.location;
    if (profileLocation != null && _isValidLatLng(profileLocation)) {
      return profileLocation;
    }

    return _defaultMapCenter;
  }

  Future<LatLng?> _resolveDeviceLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return null;
    }

    var permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return null;
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      return LatLng(position.latitude, position.longitude);
    } catch (_) {
      return null;
    }
  }

  bool _isValidLatLng(LatLng point) {
    return point.latitude.isFinite &&
        point.longitude.isFinite &&
        point.latitude >= -90 &&
        point.latitude <= 90 &&
        point.longitude >= -180 &&
        point.longitude <= 180;
  }
}

final requestsMapProvider = AsyncNotifierProvider<RequestsMapNotifier, RequestsMapState>(
  RequestsMapNotifier.new,
);
