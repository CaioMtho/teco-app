import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'features/auth/presentation/pages/auth_screen.dart';
import 'features/auth/presentation/providers/auth_providers.dart';
import 'features/requests/presentation/pages/requests_map_page.dart';
import 'core/services/supabase_service.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  StreamSubscription<AuthState>? _authSubscription;
  bool _recoveryPageVisible = false;

  @override
  void initState() {
    super.initState();
    _authSubscription = SupabaseService.client.auth.onAuthStateChange.listen(
      (data) {
        if (data.event == AuthChangeEvent.passwordRecovery) {
          _openRecoveryPage();
        }
      },
    );
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  void _openRecoveryPage() {
    if (_recoveryPageVisible) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      final navigator = _navigatorKey.currentState;
      if (navigator == null) {
        return;
      }

      _recoveryPageVisible = true;
      navigator.push(
        MaterialPageRoute<void>(
          builder: (_) => ResetPasswordPage(
            onCompleted: _closeRecoveryPage,
          ),
        ),
      );
    });
  }

  void _closeRecoveryPage() {
    if (!mounted) {
      return;
    }

    _recoveryPageVisible = false;
    final navigator = _navigatorKey.currentState;
    if (navigator != null && navigator.canPop()) {
      navigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: 'TECO',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF145CFF),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: const _AuthGate(),
    );
  }
}

class _AuthGate extends ConsumerWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authStateAsync = ref.watch(authControllerProvider);

    return authStateAsync.when(
      loading: () => const Scaffold(
        backgroundColor: Color(0xFF0A0A0A),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFFD4FF00)),
        ),
      ),
      error: (_, _) => const AuthScreen(),
      data: (authState) {
        if (authState.isAuthenticated) {
          return const RequestsMapPage();
        }

        return AuthScreen(initialMessage: authState.message);
      },
    );
  }
}
