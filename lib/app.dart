import 'package:flutter/material.dart';

import 'features/requests/presentation/pages/requests_map_page.dart';

class App extends StatelessWidget {
  const App({super.key});
  

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TECO',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: ThemeMode.dark,
      home: const RequestsMapPage(),
    );
  }
}
