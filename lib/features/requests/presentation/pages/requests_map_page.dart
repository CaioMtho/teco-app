import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:go_router/go_router.dart';

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
  RequestEntity? _selectedRequest;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadMapData();
  }

  void _onRequestMarkerTap(RequestEntity request) {
    setState(() {
      _selectedRequest = request;
    });
  }

  void _onCloseRequestModal() {
    setState(() {
      _selectedRequest = null;
    });
  }

  Future<void> _showUserMarkerModal() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
            child: Text(
              'Esse é você',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
          ),
        );
      },
    );
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

      if (!mounted) return;

      setState(() {
        _mainLocation = mainLocation;
        _openRequests = openRequests;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _mapController.move(_mainLocation, 12.5);
      });
    } catch (_) {
      if (!mounted) return;

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
                    color: colorScheme.primary.withOpacity(0.14),
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
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 240),
                child: _selectedRequest == null
                    ? const _BottomBar(key: ValueKey('bottom-bar'))
                    : _RequestDetailsModal(
                        key: ValueKey(_selectedRequest!.id),
                        request: _selectedRequest!,
                        onClose: _onCloseRequestModal,
                      ),
              ),
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
              bottom: _selectedRequest != null ? 234 : 86,
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
      floatingActionButton: Padding(
        padding: EdgeInsets.only(bottom: _selectedRequest != null ? 238 : 86),
        child: FloatingActionButton.small(
          onPressed: () {
            _mapController.move(_mainLocation, 13.5);
          },
          child: const Icon(Icons.my_location_rounded),
        ),
      ),
    );
  }

  Marker _buildMainMarker(ColorScheme colorScheme) {
    return Marker(
      point: _mainLocation,
      width: 52,
      height: 52,
      child: GestureDetector(
        onTap: _showUserMarkerModal,
        child: Container(
          decoration: BoxDecoration(
            color: colorScheme.primary,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
          ),
          child: const Icon(
            Icons.person_pin_circle_rounded,
            color: Colors.white,
          ),
        ),
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
            child: GestureDetector(
              onTap: () => _onRequestMarkerTap(request),
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
            _TopBarAction(
              icon: Icons.menu_rounded,
              tooltip: 'Menu',
              onTap: () {},
              color: colorScheme.onPrimary,
            ),
            const Spacer(),
            _TopBarAction(
              icon: Icons.search_rounded,
              tooltip: 'Buscar',
              onTap: () {},
              color: colorScheme.onPrimary,
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({super.key});

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
          children: [
            _BottomIcon(
              icon: Icons.add_outlined,
              label: 'suporte',
              onTap: () {
                // futuro
              },
            ),
            _BottomIcon(
              icon: Icons.home_rounded,
              label: 'inicio',
              selected: true,
              onTap: () => context.go('/'),
            ),
            _BottomIcon(
              icon: Icons.radio_button_checked,
              label: 'requisicoes',
              onTap: () {
                // já está aqui
              },
            ),
            _BottomIcon(
              icon: Icons.person_outline_rounded,
              label: 'perfil',
              onTap: () => context.push('/profile'),
            ),
            _BottomIcon(
              icon: Icons.settings_outlined,
              label: 'configuracao',
              onTap: () {
                // futuro
              },
            ),
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
    this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final iconColor = selected ? const Color(0xFF9A7BFF) : Colors.white70;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(height: 3),
          Text(
            label,
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(color: iconColor),
          ),
        ],
      ),
    );
  }
}

class _TopBarAction extends StatelessWidget {
  const _TopBarAction({
    required this.tooltip,
    required this.onTap,
    required this.color,
    this.icon,
  });

  final String tooltip;
  final VoidCallback onTap;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkResponse(
        onTap: onTap,
        child: Icon(icon, color: color),
      ),
    );
  }
}

class _RequestDetailsModal extends StatelessWidget {
  const _RequestDetailsModal({
    super.key,
    required this.request,
    required this.onClose,
  });

  final RequestEntity request;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final description = request.description?.trim();

    return Material(
      color: const Color(0xFF222431),
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(request.title),
            Text(
              description?.isNotEmpty == true
                  ? description!
                  : 'Sem descricao',
            ),
            IconButton(
              onPressed: onClose,
              icon: const Icon(Icons.close),
            ),
          ],
        ),
      ),
    );
  }
}