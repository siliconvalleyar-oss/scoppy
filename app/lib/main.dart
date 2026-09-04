import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/scope_client.dart';
import 'core/transport/wifi_transport.dart';
import 'scope_viewmodel.dart';
import 'ui/oscilloscope_screen.dart';

void main() {
  runApp(const ScoppyApp());
}

class ScoppyApp extends StatelessWidget {
  const ScoppyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ScopeViewModel(
        ScoppyClient(
          WifiTransport(host: kDefaultAccessPointIp),
        ),
      ),
      child: MaterialApp(
        title: 'Scoppy',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF2E7D32),
            brightness: Brightness.dark,
          ),
          scaffoldBackgroundColor: const Color(0xFF101010),
          useMaterial3: true,
        ),
        home: const OscilloscopeScreen(),
      ),
    );
  }
}
