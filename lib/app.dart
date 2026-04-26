import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/auth/presentation/pages/auth_screen.dart';
import 'features/auth/presentation/providers/auth_providers.dart';
import 'features/requests/presentation/pages/requests_map_page.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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
