import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/constants/app_constants.dart';
import '../../data/datasources/requests_remote_datasource.dart';
import '../../data/repositories/requests_repository_impl.dart';
import '../../domain/entities/request_entity.dart';
import '../../domain/usecases/get_nearby_open_requests_usecase.dart';

class RequestsMapPage extends StatefulWidget {
  const RequestsMapPage({super.key});

  @override
  State<RequestsMapPage> createState() => _RequestsMapPageState();
}

class _RequestsMapPageState extends State<RequestsMapPage> {
  final MapController _mapController = MapController();
  final GetNearbyOpenRequestsUseCase _getNearbyOpenRequestsUseCase =
      GetNearbyOpenRequestsUseCase(
    RequestsRepositoryImpl(RequestsRemoteDataSource()),
  );

  LatLng _mainLocation = AppConstants.testUserFallbackLocation;
  List<RequestEntity> _openRequests = const [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadMapData();
  }

  Future<void> _loadMapData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final mainLocation = await _resolveMainLocation();
      final openRequests = await _getNearbyOpenRequestsUseCase.call(
        center: mainLocation,
        radiusKm: AppConstants.openRequestsRadiusKm,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _mainLocation = mainLocation;
        _openRequests = openRequests;
      });

      _mapController.move(_mainLocation, 12.5);
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage =
            'Nao foi possivel carregar os dados do mapa. Tente novamente.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<LatLng> _resolveMainLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return AppConstants.testUserFallbackLocation;
    }

    var permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return AppConstants.testUserFallbackLocation;
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      return LatLng(position.latitude, position.longitude);
    } catch (_) {
      return AppConstants.testUserFallbackLocation;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _mainLocation,
              initialZoom: 12,
              minZoom: 5,
              maxZoom: 18,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.caiomtho.teco',
              ),
              CircleLayer(
                circles: [
                  CircleMarker(
                    point: _mainLocation,
                    radius: AppConstants.openRequestsRadiusKm * 1000,
                    useRadiusInMeter: true,
                    color: colorScheme.primary.withValues(alpha: 0.14),
                    borderColor: colorScheme.primary,
                    borderStrokeWidth: 1,
                  ),
                ],
              ),
              MarkerLayer(
                markers: [
                  _buildMainMarker(colorScheme),
                  ..._buildRequestMarkers(colorScheme),
                ],
              ),
            ],
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                child: _TopBar(colorScheme: colorScheme),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              minimum: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: const _BottomBar(),
            ),
          ),
          if (_isLoading)
            const Positioned.fill(
              child: ColoredBox(
                color: Color(0x22000000),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
          if (_errorMessage != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: 86,
              child: Material(
                borderRadius: BorderRadius.circular(12),
                color: const Color(0xCCB00020),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.small(
        onPressed: () {
          _mapController.move(_mainLocation, 13.5);
        },
        child: const Icon(Icons.my_location_rounded),
      ),
    );
  }

  Marker _buildMainMarker(ColorScheme colorScheme) {
    return Marker(
      point: _mainLocation,
      width: 52,
      height: 52,
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.primary,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: const [
            BoxShadow(
              color: Color(0x55000000),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(Icons.person_pin_circle_rounded, color: Colors.white),
      ),
    );
  }

  List<Marker> _buildRequestMarkers(ColorScheme colorScheme) {
    return _openRequests
        .map(
          (request) => Marker(
            point: request.location,
            width: 42,
            height: 42,
            child: Container(
              decoration: BoxDecoration(
                color: colorScheme.error,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Icon(
                Icons.build_circle_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
        )
        .toList(growable: false);
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.colorScheme});

  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xDD222431),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Icon(Icons.menu_rounded, color: colorScheme.onPrimary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Praca da Se',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: colorScheme.onPrimary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
            Icon(Icons.search_rounded, color: colorScheme.onPrimary),
            const SizedBox(width: 10),
            CircleAvatar(
              radius: 12,
              backgroundColor: const Color(0xFF9A7BFF),
              child: Text(
                'A',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF222431),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: const [
            _BottomIcon(icon: Icons.home_rounded, label: 'inicio', selected: true),
            _BottomIcon(icon: Icons.radio_button_checked, label: 'requisicoes'),
            _BottomIcon(icon: Icons.person_outline_rounded, label: 'perfil'),
            _BottomIcon(icon: Icons.settings_outlined, label: 'configuracao'),
          ],
        ),
      ),
    );
  }
}

class _BottomIcon extends StatelessWidget {
  const _BottomIcon({
    required this.icon,
    required this.label,
    this.selected = false,
  });

  final IconData icon;
  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final iconColor = selected ? const Color(0xFF9A7BFF) : Colors.white70;

    return SizedBox(
      width: 72,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(height: 3),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: iconColor,
                ),
          ),
        ],
      ),
    );
  }
}
