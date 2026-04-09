import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/datasources/requests_remote_datasource.dart';
import '../../data/repositories/requests_repository_impl.dart';
import '../../domain/repositories/requests_repository.dart';
import '../../domain/usecases/delete_current_user_request_usecase.dart';
import '../../domain/usecases/get_current_user_open_requests_usecase.dart';
import '../../domain/entities/request_entity.dart';
import '../../domain/usecases/get_nearby_open_requests_usecase.dart';
import '../../domain/usecases/update_current_user_request_usecase.dart';
import '../../domain/usecases/create_request_usecase.dart';
import '../../../main_page/presentation/pages/profile_page.dart';

class RequestsMapPage extends ConsumerStatefulWidget {
  const RequestsMapPage({super.key});

  @override
  ConsumerState<RequestsMapPage> createState() => _RequestsMapPageState();
}

class _RequestsMapPageState extends ConsumerState<RequestsMapPage> {
  static const LatLng _defaultMapCenter = LatLng(-23.55052, -46.633308);

  final MapController _mapController = MapController();
  final RequestsRepository _requestsRepository = RequestsRepositoryImpl(
    RequestsRemoteDataSource(),
  );

  late final CreateRequestUseCase _createRequestUseCase =
      CreateRequestUseCase(_requestsRepository);
  late final GetNearbyOpenRequestsUseCase _getNearbyOpenRequestsUseCase =
      GetNearbyOpenRequestsUseCase(_requestsRepository);
  late final GetCurrentUserOpenRequestsUseCase
  _getCurrentUserOpenRequestsUseCase = GetCurrentUserOpenRequestsUseCase(
    _requestsRepository,
  );
  late final UpdateCurrentUserRequestUseCase _updateCurrentUserRequestUseCase =
      UpdateCurrentUserRequestUseCase(_requestsRepository);
  late final DeleteCurrentUserRequestUseCase _deleteCurrentUserRequestUseCase =
      DeleteCurrentUserRequestUseCase(_requestsRepository);

  LatLng _mainLocation = const LatLng(0, 0);
  List<RequestEntity> _openRequests = const [];
  List<RequestEntity> _currentUserOpenRequests = const [];
  RequestEntity? _selectedRequest;
  bool _isMyRequestsPanelOpen = false;
  bool _isLoading = true;
  bool _isLoadingMyRequests = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadMapData();
  }

  void _onRequestMarkerTap(RequestEntity request) {
    setState(() {
      _isMyRequestsPanelOpen = false;
      _selectedRequest = request;
    });
  }

  void _onCloseRequestModal() {
    setState(() {
      _selectedRequest = null;
    });
  }

  void _openMyRequestsPanel() {
    setState(() {
      _selectedRequest = null;
      _isMyRequestsPanelOpen = true;
    });
  }

  void _closeMyRequestsPanel() {
    setState(() {
      _isMyRequestsPanelOpen = false;
    });
  }

  Future<void> _refreshMyOpenRequests({bool withLoadingState = false}) async {
    if (withLoadingState) {
      setState(() {
        _isLoadingMyRequests = true;
      });
    }

    try {
      final requests = await _getCurrentUserOpenRequestsUseCase.call();

      if (!mounted) {
        return;
      }

      setState(() {
        _currentUserOpenRequests = requests;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível carregar suas requisições abertas.'),
        ),
      );
    } finally {
      if (withLoadingState && mounted) {
        setState(() {
          _isLoadingMyRequests = false;
        });
      }
    }
  }

// Novo método _onCreateRequest:
Future<void> _onCreateRequest() async {
  final payload = await showModalBottomSheet<_RequestCreatePayload>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => _CreateRequestSheet(
      initialLat: _mainLocation.latitude,
      initialLon: _mainLocation.longitude,
    ),
  );

  if (payload == null) return;

  try {
    await _createRequestUseCase.call(
      title: payload.title,
      description: payload.description,
      budgetRange: payload.budgetRange,
      isRemote: payload.isRemote,
      lat: payload.lat,
      lon: payload.lon,
    );

    await _loadMapData();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Requisição criada com sucesso.')),
    );
  } catch (_) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Não foi possível criar a requisição.')),
      );
    }
  }

  Future<void> _onEditRequest(RequestEntity request) async {
    final payload = await showModalBottomSheet<_RequestEditPayload>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => _EditRequestSheet(request: request),
    );

    if (payload == null) {
      return;
    }

    try {
      await _updateCurrentUserRequestUseCase.call(
        requestId: request.id,
        title: payload.title,
        description: payload.description,
        budgetRange: payload.budgetRange,
        isRemote: payload.isRemote,
      );

      await _loadMapData();

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Requisição atualizada com sucesso.')),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível atualizar a requisição.'),
        ),
      );
    }
  }

  Future<void> _onDeleteRequest(RequestEntity request) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Excluir requisição'),
          content: Text(
            'Tem certeza de que deseja excluir "${request.title}"? Essa ação não pode ser desfeita.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: Theme.of(context).colorScheme.onError,
              ),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Excluir'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) {
      return;
    }

    try {
      await _deleteCurrentUserRequestUseCase.call(requestId: request.id);
      await _loadMapData();

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Requisição excluída com sucesso.')),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível excluir a requisição.')),
      );
    }
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
      String? nonBlockingErrorMessage;

      List<RequestEntity> openRequests = const [];
      try {
        openRequests = await _getNearbyOpenRequestsUseCase.call(
          center: mainLocation,
          radiusKm: AppConstants.openRequestsRadiusKm,
        );
      } catch (_) {
        nonBlockingErrorMessage =
            'Nao foi possível carregar requisições próximas no momento.';
      }

      List<RequestEntity> currentUserOpenRequests = const [];
      try {
        currentUserOpenRequests = await _getCurrentUserOpenRequestsUseCase
            .call();
      } catch (_) {
        currentUserOpenRequests = const [];
      }

      final selectedRequestId = _selectedRequest?.id;
      RequestEntity? refreshedSelectedRequest;
      if (selectedRequestId != null) {
        for (final request in openRequests) {
          if (request.id == selectedRequestId) {
            refreshedSelectedRequest = request;
            break;
          }
        }
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _mainLocation = mainLocation;
        _openRequests = openRequests;
        _currentUserOpenRequests = currentUserOpenRequests;
        _selectedRequest = refreshedSelectedRequest;
        _errorMessage = nonBlockingErrorMessage;
      });

      _mapController.move(_mainLocation, 12.5);
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage =
            'Não foi possível carregar os dados do mapa. Tente novamente.';
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
    final profileLocation =
        ref.read(authControllerProvider).valueOrNull?.profile?.location;
    if (profileLocation != null) {
      return profileLocation;
    }

    final deviceLocation = await _resolveDeviceLocation();
    if (deviceLocation != null) {
      return deviceLocation;
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

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider).valueOrNull;
    final profileName = (authState?.profile?.fullName ?? '').trim();
    final avatarInitial =
        profileName.isNotEmpty ? profileName.substring(0, 1).toUpperCase() : 'U';

    final colorScheme = Theme.of(context).colorScheme;
    final errorBottomPadding = _isMyRequestsPanelOpen
        ? 448.0
        : (_selectedRequest != null ? 234.0 : 86.0);
    final fabBottomPadding = _isMyRequestsPanelOpen
        ? 452.0
        : (_selectedRequest != null ? 238.0 : 86.0);

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
                child: _TopBar(
                  colorScheme: colorScheme,
                  avatarInitial: avatarInitial,
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              minimum: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 240),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                child: _isMyRequestsPanelOpen
                    ? _MyRequestsModal(
                        key: const ValueKey('my-requests-modal'),
                        requests: _currentUserOpenRequests,
                        isLoading: _isLoadingMyRequests,
                        onClose: _closeMyRequestsPanel,
                        onRefresh: () {
                          _refreshMyOpenRequests(withLoadingState: true);
                        },
                        onEdit: _onEditRequest,
                        onDelete: _onDeleteRequest,
                        onCreateRequest: _onCreateRequest,
                      )
                    : _selectedRequest == null
                    ? _BottomBar(
                        key: const ValueKey('bottom-bar'),
                        onHomeTap: () {
                          setState(() {
                            _selectedRequest = null;
                            _isMyRequestsPanelOpen = false;
                          });
                        },
                        onRequestsTap: _openMyRequestsPanel,
                      )
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
              bottom: errorBottomPadding,
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
        padding: EdgeInsets.only(bottom: fabBottomPadding),
        child: Tooltip(
          message: 'Voltar para sua localização',
          child: FloatingActionButton.small(
            hoverElevation: 10,
            onPressed: () {
              _mapController.move(_mainLocation, 13.5);
            },
            child: const Icon(Icons.my_location_rounded),
          ),
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
            boxShadow: const [
              BoxShadow(
                color: Color(0x55000000),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
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
  const _TopBar({
    required this.colorScheme,
    required this.avatarInitial,
  });

  final ColorScheme colorScheme;
  final String avatarInitial;

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
              icon: Icons.chat_bubble_outline_rounded,
              tooltip: 'Chat',
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
            const SizedBox(width: 10),
            _TopBarAction(
              tooltip: 'Perfil',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const ProfilePage()),
                );
              },
              color: colorScheme.onPrimary,
              child: CircleAvatar(
                radius: 12,
                backgroundColor: const Color(0xFF9A7BFF),
                child: Text(
                  avatarInitial,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
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
  const _BottomBar({
    super.key,
    required this.onHomeTap,
    required this.onRequestsTap,
  });

  final VoidCallback onHomeTap;
  final VoidCallback onRequestsTap;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF222431),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: _BottomIcon(
                icon: Icons.home_rounded,
                label: 'início',
                selected: true,
                onTap: onHomeTap,
              ),
            ),
            Expanded(
              child: _BottomIcon(
                icon: Icons.radio_button_checked,
                label: 'requisições',
                onTap: onRequestsTap,
              ),
            ),
            const Expanded(
              child: _BottomIcon(
                icon: Icons.settings_outlined,
                label: 'configuração',
              ),
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
    this.onTap,
    this.selected = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final iconColor = selected ? const Color(0xFF9A7BFF) : Colors.white70;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        hoverColor: Colors.white10,
        splashColor: Colors.white12,
        child: SizedBox(
          height: 54,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: iconColor, size: 20),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: iconColor,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
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
    this.child,
  }) : assert(icon != null || child != null);

  final String tooltip;
  final VoidCallback onTap;
  final Color color;
  final IconData? icon;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final button = InkResponse(
      onTap: onTap,
      radius: 20,
      hoverColor: Colors.white10,
      highlightShape: BoxShape.circle,
      child: SizedBox(
        width: 32,
        height: 32,
        child: Center(child: child ?? Icon(icon, color: color)),
      ),
    );

    return Tooltip(
      message: tooltip,
      child: Material(color: Colors.transparent, child: button),
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
    final colorScheme = Theme.of(context).colorScheme;
    final description = request.description?.trim();

    return Material(
      elevation: 10,
      color: const Color(0xFF222431),
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    request.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Tooltip(
                  message: 'Fechar',
                  child: IconButton(
                    onPressed: onClose,
                    icon: const Icon(Icons.close_rounded),
                    color: Colors.white,
                    hoverColor: Colors.white10,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              description != null && description.isNotEmpty
                  ? description
                  : 'Sem descrição para esta requisição.',
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
            ),
            const SizedBox(height: 14),
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.chat_bubble_outline_rounded),
                label: const Text('Criar chat'),
                style: FilledButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MyRequestsModal extends StatelessWidget {
  const _MyRequestsModal({
    super.key,
    required this.requests,
    required this.isLoading,
    required this.onClose,
    required this.onRefresh,
    required this.onEdit,
    required this.onDelete,
    required this.onCreateRequest,
  });

  final List<RequestEntity> requests;
  final bool isLoading;
  final VoidCallback onClose;
  final VoidCallback onRefresh;
  final ValueChanged<RequestEntity> onEdit;
  final ValueChanged<RequestEntity> onDelete;
  final VoidCallback onCreateRequest;

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height * 0.62;
    final textTheme = Theme.of(context).textTheme;

    return Material(
      elevation: 10,
      color: const Color(0xFF222431),
      borderRadius: BorderRadius.circular(24),
      child: SizedBox(
        height: height,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Suas requisicoes abertas',
                      style: textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Tooltip(
                    message: 'Nova requisição',
                    child: IconButton(
                      onPressed: onCreateRequest,
                      icon: const Icon(Icons.add_circle_outline_rounded),
                      color: Colors.white,
                      hoverColor: Colors.white10,
                      ),
                  ),
                  Tooltip(
                    message: 'Atualizar lista',
                    child: IconButton(
                      onPressed: onRefresh,
                      icon: const Icon(Icons.refresh_rounded),
                      color: Colors.white,
                      hoverColor: Colors.white10,
                    ),
                  ),
                  Tooltip(
                    message: 'Fechar',
                    child: IconButton(
                      onPressed: onClose,
                      icon: const Icon(Icons.close_rounded),
                      color: Colors.white,
                      hoverColor: Colors.white10,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                requests.length == 1
                    ? '1 requisição aberta'
                    : '${requests.length} requisições abertas',
                style: textTheme.bodySmall?.copyWith(color: Colors.white70),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : requests.isEmpty
                    ? Center(
                        child: Text(
                          'Você não possui requisições abertas no momento.',
                          style: textTheme.bodyMedium?.copyWith(
                            color: Colors.white70,
                          ),
                        ),
                      )
                    : ListView.separated(
                        itemCount: requests.length,
                        separatorBuilder: (_, index) =>
                            const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final request = requests[index];
                          return _MyRequestCard(
                            request: request,
                            onEdit: () => onEdit(request),
                            onDelete: () => onDelete(request),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MyRequestCard extends StatelessWidget {
  const _MyRequestCard({
    required this.request,
    required this.onEdit,
    required this.onDelete,
  });

  final RequestEntity request;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final description = request.description?.trim();

    return Card(
      margin: EdgeInsets.zero,
      color: const Color(0xFF2A2D3B),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    request.title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Chip(
                  label: const Text('Aberta'),
                  visualDensity: VisualDensity.compact,
                  backgroundColor: colorScheme.primary.withValues(alpha: 0.20),
                  labelStyle: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colorScheme.onPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              description != null && description.isNotEmpty
                  ? description
                  : 'Sem descricao.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.white70),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _RequestMetaChip(
                  icon: Icons.attach_money_rounded,
                  text: request.budgetRange?.isNotEmpty == true
                      ? request.budgetRange!
                      : 'Sem faixa de orçamento',
                ),
                _RequestMetaChip(
                  icon: request.isRemote == true
                      ? Icons.wifi_rounded
                      : Icons.location_on_outlined,
                  text: request.isRemote == true ? 'Remoto' : 'Presencial',
                ),
                _RequestMetaChip(
                  icon: Icons.schedule_rounded,
                  text: _formatDate(request.createdAt),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_rounded),
                    label: const Text('Editar'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white30),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline_rounded),
                    label: const Text('Excluir'),
                    style: FilledButton.styleFrom(
                      foregroundColor: colorScheme.onErrorContainer,
                      backgroundColor: colorScheme.errorContainer,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime? value) {
    if (value == null) {
      return 'Sem data';
    }

    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    final year = value.year.toString();
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');

    return '$day/$month/$year $hour:$minute';
  }
}

class _RequestMetaChip extends StatelessWidget {
  const _RequestMetaChip({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0x1AFFFFFF),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: Colors.white70),
            const SizedBox(width: 6),
            Text(
              text,
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}

class _RequestEditPayload {
  const _RequestEditPayload({
    required this.title,
    required this.description,
    required this.budgetRange,
    required this.isRemote,
  });

  final String title;
  final String? description;
  final String? budgetRange;
  final bool isRemote;
}

class _EditRequestSheet extends StatefulWidget {
  const _EditRequestSheet({required this.request});

  final RequestEntity request;

  @override
  State<_EditRequestSheet> createState() => _EditRequestSheetState();
}

class _EditRequestSheetState extends State<_EditRequestSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _budgetRangeController;
  late bool _isRemote;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.request.title);
    _descriptionController = TextEditingController(
      text: widget.request.description,
    );
    _budgetRangeController = TextEditingController(
      text: widget.request.budgetRange,
    );
    _isRemote = widget.request.isRemote ?? false;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _budgetRangeController.dispose();
    super.dispose();
  }

  void _submit() {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe um título para a requisição.')),
      );
      return;
    }

    final description = _descriptionController.text.trim();
    final budgetRange = _budgetRangeController.text.trim();

    setState(() {
      _isSaving = true;
    });

    Navigator.of(context).pop(
      _RequestEditPayload(
        title: title,
        description: description.isEmpty ? null : description,
        budgetRange: budgetRange.isEmpty ? null : budgetRange,
        isRemote: _isRemote,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 10, 16, bottomInset + 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Editar requisição',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _titleController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Título',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _descriptionController,
              textInputAction: TextInputAction.newline,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Descrição',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _budgetRangeController,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(
                labelText: 'Faixa de orçamento',
                border: OutlineInputBorder(),
                hintText: 'Ex.: R\$ 500 - R\$ 1000',
              ),
            ),
            const SizedBox(height: 8),
            SwitchListTile.adaptive(
              value: _isRemote,
              onChanged: (value) {
                setState(() {
                  _isRemote = value;
                });
              },
              contentPadding: EdgeInsets.zero,
              title: const Text('Aceita trabalho remoto'),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _isSaving ? null : _submit,
                icon: const Icon(Icons.save_outlined),
                label: const Text('Salvar alteracoes'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RequestCreatePayload {
  const _RequestCreatePayload({
    required this.title,
    required this.description,
    required this.budgetRange,
    required this.isRemote,
    required this.lat,
    required this.lon,
  });

  final String title;
  final String? description;
  final double? budgetRange;
  final bool isRemote;
  final double lat;
  final double lon;
}

class _CreateRequestSheet extends StatefulWidget {
  const _CreateRequestSheet({
    required this.initialLat,
    required this.initialLon,
  });

  final double initialLat;
  final double initialLon;

  @override
  State<_CreateRequestSheet> createState() => _CreateRequestSheetState();
}

class _CreateRequestSheetState extends State<_CreateRequestSheet> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _budgetController = TextEditingController();
  bool _isRemote = false;
  bool _isSaving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  void _submit() {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe um título para a requisição.')),
      );
      return;
    }

    final description = _descriptionController.text.trim();
    final budgetText = _budgetController.text.trim().replaceAll(',', '.');
    final budgetRange = budgetText.isNotEmpty ? double.tryParse(budgetText) : null;

    if (budgetText.isNotEmpty && budgetRange == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe um valor numérico válido para o orçamento.')),
      );
      return;
    }

    setState(() => _isSaving = true);

    Navigator.of(context).pop(
      _RequestCreatePayload(
        title: title,
        description: description.isEmpty ? null : description,
        budgetRange: budgetRange,
        isRemote: _isRemote,
        lat: widget.initialLat,
        lon: widget.initialLon,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 10, 16, bottomInset + 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Nova requisição',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _titleController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Título *',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _descriptionController,
              textInputAction: TextInputAction.newline,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Descrição',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _budgetController,
              textInputAction: TextInputAction.done,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Orçamento (R\$)',
                border: OutlineInputBorder(),
                hintText: 'Ex.: 500.00',
              ),
            ),
            const SizedBox(height: 8),
            SwitchListTile.adaptive(
              value: _isRemote,
              onChanged: (value) => setState(() => _isRemote = value),
              contentPadding: EdgeInsets.zero,
              title: const Text('Aceita trabalho remoto'),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 14, color: Colors.white38),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Localização: ${widget.initialLat.toStringAsFixed(5)}, '
                    '${widget.initialLon.toStringAsFixed(5)}',
                    style: Theme.of(context)
                        .textTheme
                        .labelSmall
                        ?.copyWith(color: Colors.white38),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _isSaving ? null : _submit,
                icon: const Icon(Icons.add_circle_outline_rounded),
                label: const Text('Criar requisição'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}