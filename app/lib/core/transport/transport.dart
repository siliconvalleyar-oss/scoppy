import 'dart:typed_data';

/// Transporte abstracto hacia el frontend (Pico).
///
/// Implementaciones: [WifiTransport] (TCP 22483/22484), y USB serial
/// (extensible). Los bytes recibidos se entregan vía [onData].
abstract class ScoppyTransport {
  Stream<List<int>> get data;

  Future<void> connect();
  Future<void> disconnect();
  Future<void> send(List<int> bytes);
  bool get isConnected;
}
