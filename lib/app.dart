import 'package:flutter/material.dart';

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
      home: const RequestsMapPage(),
    );
  }
}
