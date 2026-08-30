import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/request_entity.dart';
import '../../../profile/presentation/pages/profile_page.dart';
import '../../../chat/presentation/widgets/chat_list_panel.dart';
import '../../../chat/presentation/widgets/initial_chat_message_modal.dart';
import '../../../chat/presentation/providers/chat_providers.dart';
import '../providers/requests_map_provider.dart';
import '../widgets/requests_map_bottom_sheets.dart';

class RequestsMapPage extends ConsumerStatefulWidget {
  const RequestsMapPage({super.key});

  @override
  ConsumerState<RequestsMapPage> createState() => _RequestsMapPageState();
}

class _RequestsMapPageState extends ConsumerState<RequestsMapPage> {
  static const LatLng _defaultMapCenter = LatLng(-23.55052, -46.633308);
  final MapController _mapController = MapController();

  RequestEntity? _selectedRequest;
  bool _isMyRequestsPanelOpen = false;
  bool _isMapReady = false;
  bool _hasCenteredMap = false;
  bool _isLoadingMyRequests = false;

  @override
  void initState() {
    super.initState();
    debugPrint('[RequestsMapPage] initState chamado');
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

  Future<void> _onCreateChat() async {
    if (_selectedRequest == null) return;
    final request = _selectedRequest!;

    final authState = ref.read(authControllerProvider).valueOrNull;
    final profile = authState?.profile;
    final currentUserId = authState?.user?.id;

    if (profile == null || currentUserId == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao obter informações do usuário')),
      );
      return;
    }

    if (profile.type != 'provider') {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Somente prestadores de serviço podem iniciar chats com clientes'),
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    final requesterId = request.requesterId;
    if (requesterId == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro: requester não identificado')),
      );
      return;
    }

    final messageContent = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: const Color(0xFF222431),
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => const InitialChatMessageModal(),
    );

    if (messageContent == null || messageContent.isEmpty) return;

    try {
      await ref.read(createChatWithMessageUseCaseProvider).call(
            requestId: request.id,
            requestTitle: request.title,
            requesterId: requesterId,
            providerId: currentUserId,
            participantId: requesterId,
            participantName: '',
            messageContent: messageContent,
          );
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chat criado com sucesso!')),
      );

      setState(() {
        _selectedRequest = null;
      });

      ref.read(chatListNotifierProvider.notifier).load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível criar o chat')),
      );
    }
  }

  Future<void> _onCreateRequest(LatLng mainLocation) async {
    final payload = await showModalBottomSheet<RequestCreatePayload>(
      context: context,
      backgroundColor: const Color(0xFF222431),
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => CreateRequestSheet(
        initialLat: mainLocation.latitude,
        initialLon: mainLocation.longitude,
      ),
    );

    if (payload == null) return;

    try {
      await ref.read(requestsMapProvider.notifier).createRequest(
            title: payload.title,
            description: payload.description,
            budgetRange: payload.budgetRange,
            isRemote: payload.isRemote,
            lat: payload.lat,
            lon: payload.lon,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Requisição criada com sucesso.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível criar a requisição.')),
      );
    }
  }

  Future<void> _onEditRequest(RequestEntity request) async {
    final payload = await showModalBottomSheet<RequestEditPayload>(
      context: context,
      backgroundColor: const Color(0xFF222431),
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => EditRequestSheet(request: request),
    );

    if (payload == null) return;

    try {
      await ref.read(requestsMapProvider.notifier).updateRequest(
            requestId: request.id,
            title: payload.title,
            description: payload.description,
            budgetRange: payload.budgetRange,
            isRemote: payload.isRemote,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Requisição atualizada com sucesso.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível atualizar a requisição.')),
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

    if (shouldDelete != true) return;

    try {
      await ref.read(requestsMapProvider.notifier).deleteRequest(request.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Requisição excluída com sucesso.')),
      );
    } catch (e) {
      if (!mounted) return;
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

  bool _isValidLatLng(LatLng point) {
    return point.latitude.isFinite &&
        point.longitude.isFinite &&
        point.latitude >= -90 &&
        point.latitude <= 90 &&
        point.longitude >= -180 &&
        point.longitude <= 180;
  }

  void _focusMapOnMainLocationIfNeeded(LatLng mainLocation, bool hasResolved) {
    if (!_isMapReady || _hasCenteredMap || !hasResolved || !mounted) return;
    final mapCenter = _isValidLatLng(mainLocation) ? mainLocation : _defaultMapCenter;
    if (!_isValidLatLng(mapCenter)) return;
    _mapController.move(mapCenter, 12.5);
    _hasCenteredMap = true;
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider).valueOrNull;
    final profileType = authState?.profile?.type ?? '';
    final isProvider = profileType == 'provider';
    final profileName = (authState?.profile?.fullName ?? '').trim();
    final avatarInitial = profileName.isNotEmpty
        ? profileName.substring(0, 1).toUpperCase()
        : 'U';
    final colorScheme = Theme.of(context).colorScheme;
    final errorBottomPadding = _isMyRequestsPanelOpen
        ? 448.0
        : (_selectedRequest != null ? 234.0 : 86.0);
    final fabBottomPadding = _isMyRequestsPanelOpen
        ? 452.0
        : (_selectedRequest != null ? 238.0 : 86.0);

    final requestsMapStateAsync = ref.watch(requestsMapProvider);

    return Scaffold(
      body: requestsMapStateAsync.when(
        data: (state) {
          final mainLocation = state.mainLocation;
          final mapCenter = _isValidLatLng(mainLocation) ? mainLocation : _defaultMapCenter;
          
          if (_selectedRequest != null) {
            final exists = state.openRequests.any((r) => r.id == _selectedRequest!.id);
            if (!exists) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) setState(() => _selectedRequest = null);
              });
            } else {
              _selectedRequest = state.openRequests.firstWhere((r) => r.id == _selectedRequest!.id);
            }
          }

          WidgetsBinding.instance.addPostFrameCallback((_) {
            _focusMapOnMainLocationIfNeeded(mainLocation, state.hasResolvedMainLocation);
          });

          return Stack(
            children: [
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: mapCenter,
                  initialZoom: 12,
                  minZoom: 5,
                  maxZoom: 18,
                  onMapReady: () {
                    _isMapReady = true;
                    _focusMapOnMainLocationIfNeeded(mainLocation, state.hasResolvedMainLocation);
                  },
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.caiomtho.teco',
                  ),
                  CircleLayer(
                    circles: [
                      CircleMarker(
                        point: mapCenter,
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
                      _buildMainMarker(colorScheme, mapCenter),
                      ..._buildRequestMarkers(colorScheme, state.openRequests),
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
                        ? MyRequestsModal(
                            key: const ValueKey('my-requests-modal'),
                            requests: state.currentUserOpenRequests,
                            isLoading: _isLoadingMyRequests,
                            onClose: _closeMyRequestsPanel,
                            onRefresh: () async {
                              setState(() => _isLoadingMyRequests = true);
                              await ref.read(requestsMapProvider.notifier).refreshMyOpenRequests();
                              if (mounted) setState(() => _isLoadingMyRequests = false);
                            },
                            onEdit: _onEditRequest,
                            onDelete: _onDeleteRequest,
                            onCreateRequest: () => _onCreateRequest(mainLocation),
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
                        : RequestDetailsModal(
                            key: ValueKey(_selectedRequest!.id),
                            request: _selectedRequest!,
                            onClose: _onCloseRequestModal,
                            isProvider: isProvider,
                            onCreateChat: _onCreateChat,
                          ),
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const ColoredBox(
          color: Color(0x22000000),
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (error, stack) => Stack(
          children: [
            Positioned(
              left: 16,
              right: 16,
              bottom: errorBottomPadding,
              child: Material(
                borderRadius: BorderRadius.circular(12),
                color: const Color(0xCCB00020),
                child: const Padding(
                  padding: EdgeInsets.all(12),
                  child: Text(
                    'Não foi possível carregar os dados do mapa. Tente novamente.',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _isMyRequestsPanelOpen
          ? null
          : Padding(
              padding: EdgeInsets.only(bottom: fabBottomPadding),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Tooltip(
                    message: 'Atualizar mapa',
                    child: FloatingActionButton.small(
                      heroTag: 'requests-map-refresh',
                      hoverElevation: 10,
                      onPressed: requestsMapStateAsync.isLoading
                          ? null
                          : () => ref.read(requestsMapProvider.notifier).reload(),
                      child: const Icon(Icons.refresh_rounded),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Tooltip(
                    message: 'Voltar para sua localização',
                    child: FloatingActionButton.small(
                      heroTag: 'requests-map-location',
                      hoverElevation: 10,
                      onPressed: () {
                        final state = ref.read(requestsMapProvider).valueOrNull;
                        if (state != null) {
                          final mapCenter = _isValidLatLng(state.mainLocation)
                              ? state.mainLocation
                              : _defaultMapCenter;
                          if (_isValidLatLng(mapCenter)) {
                            _mapController.move(mapCenter, 13.5);
                          }
                        }
                      },
                      child: const Icon(Icons.my_location_rounded),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Marker _buildMainMarker(ColorScheme colorScheme, LatLng center) {
    return Marker(
      point: center,
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

  List<Marker> _buildRequestMarkers(ColorScheme colorScheme, List<RequestEntity> openRequests) {
    return openRequests
        .where((request) => _isValidLatLng(request.location))
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
  const _TopBar({required this.colorScheme, required this.avatarInitial});

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
              onTap: () {
                Navigator.of(context).push(
                  PageRouteBuilder(
                    opaque: false,
                    pageBuilder: (context, animation, secondaryAnimation) =>
                        const ChatListPanel(),
                    transitionsBuilder: (context, animation, secondaryAnimation, child) {
                      final slide = Tween<Offset>(
                        begin: const Offset(-1, 0),
                        end: Offset.zero,
                      ).animate(animation);
                      return SlideTransition(position: slide, child: child);
                    },
                  ),
                );
              },
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
    super.key, // ignore: unused_element
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
