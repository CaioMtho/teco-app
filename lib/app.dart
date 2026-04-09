import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'features/requests/presentation/pages/requests_map_page.dart';
import 'features/main_page/presentation/pages/profile_page.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    final GoRouter router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const RequestsMapPage(),
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => const ProfilePage(),
        ),
      ],
    );

    return MaterialApp.router(
      title: 'TECO',
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF145CFF),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
    );
  }
}