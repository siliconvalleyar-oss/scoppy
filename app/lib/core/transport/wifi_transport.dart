import 'dart:async';
import 'dart:io';

import 'transport.dart';

/// Puertos de la comunicación WiFi con la Pico W (ver PROTOCOLO_SCOPPY.md).
const int kControlPort = 22483; // 0x57D3
const int kDataPort = 22484; // 0x57D4

/// IP por defecto de la Pico W en modo Access Point.
const String kDefaultAccessPointIp = '192.168.4.1';

/// Transporte WiFi: se conecta por TCP a la Pico W.
///
/// Usa el puerto de control [kControlPort] para el intercambio de mensajes
/// de control y el de datos [kDataPort] para el canal de forma de onda.
class WifiTransport implements ScoppyTransport {
  WifiTransport({
    required this.host,
    this.controlPort = kControlPort,
    this.dataPort = kDataPort,
  });

  final String host;
  final int controlPort;
  final int dataPort;

  final StreamController<List<int>> _data = StreamController.broadcast();

  Socket? _controlSocket;

  @override
  Stream<List<int>> get data => _data.stream;

  @override
  bool get isConnected => _controlSocket != null && !_controlSocket!.destroyed;

  @override
  Future<void> connect() async {
    await disconnect();
    _controlSocket = await Socket.connect(host, controlPort,
        timeout: const Duration(seconds: 8));
    _controlSocket!.listen(
      (chunk) {
        _data.add(chunk);
      },
      onError: (Object e) {
        _data.addError(e);
      },
      onDone: () async {
        await disconnect();
      },
      cancelOnError: true,
    );
  }

  @override
  Future<void> disconnect() async {
    final s = _controlSocket;
    _controlSocket = null;
    if (s != null) {
      try {
        await s.close();
      } catch (_) {}
    }
    if (!_data.isClosed) {
      await _data.close();
    }
  }

  @override
  Future<void> send(List<int> bytes) async {
    final s = _controlSocket;
    if (s == null || s.destroyed) {
      throw StateError('Transporte WiFi no conectado');
    }
    s.add(bytes);
    await s.flush();
  }
}
