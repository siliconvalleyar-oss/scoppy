import 'dart:async';
import 'dart:typed_data';

import '../models/scope_models.dart';
import '../protocol/frontend_info.dart';
import '../protocol/scoppy_decoder.dart';
import '../protocol/scoppy_frame.dart';
import '../protocol/scoppy_opcodes.dart';
import '../transport/transport.dart';

/// Cliente que orquesta la comunicación App <-> Pico.
///
/// Conecta un [ScoppyTransport], decodifica los frames entrantes, mantiene el
/// estado de conexión (DISCONNECTED -> CONNECTED -> SYNCHRONISED) y envía los
/// comandos (RUN, trigger, etc.).
class ScoppyClient {
  ScoppyClient(this._transport) {
    _decoder = ScoppyFrameDecoder(onFrame: _onFrame, onError: (_) {});
    _subscription = _transport.data.listen(
      (chunk) => _decoder!.add(chunk),
      onError: (Object e) {
        connectionError?.addError(e);
      },
    );
  }

  final ScoppyTransport _transport;
  ScoppyFrameDecoder? _decoder;
  StreamSubscription<List<int>>? _subscription;

  /// Estado de conexión actual.
  ConnectionState state = ConnectionState.disconnected;

  /// Información del frontend tras el SYNC.
  FrontendInfo? frontendInfo;

  /// Últimos datos de muestra por canal (waveform).
  final Map<int, List<int>> latestWaveforms = {};

  /// Streams de eventos hacia la UI.
  final StreamController<ConnectionState> stateChanged =
      StreamController.broadcast();
  final StreamController<FrontendInfo> onSync = StreamController.broadcast();
  final StreamController<void> onSample = StreamController.broadcast();
  final StreamController<Object> connectionError =
      StreamController.broadcast();

  /// Envía un frame App -> Pico.
  void _send(Uint8List frame) {
    if (_transport.isConnected) {
      _transport.send(frame);
    }
  }

  void _onFrame(ScoppyIncomingFrame frame) {
    switch (frame.opcode) {
      case kMsgSync: // 60
        frontendInfo = parseFrontendInfo(frame.payload);
        if (frontendInfo!.isScoppy) {
          state = ConnectionState.synchronized;
          stateChanged.add(state);
          onSync.add(frontendInfo!);
        }
        break;
      case kMsgSampleData: // 61
        _parseSampleData(frame.payload);
        onSample.add(null);
        break;
      case kMsgFrontendConfig: // 62
      case kMsgVoltsDivParams: // 63
        break;
      default:
        break;
    }
  }

  void _parseSampleData(Uint8List payload) {
    if (payload.isEmpty) return;
    // La cabecera incluye nº de streams y flags. Cada muestra es un short BE.
    var idx = 0;
    final numStreams = payload[idx++] & 0xFF;
    final flags = payload[idx++] & 0xFF;
    final logic = flags == 0x19;

    for (var s = 0; s < numStreams && idx + 1 < payload.length; s++) {
      final channel = s;
      final samples = <int>[];
      while (idx + 1 < payload.length) {
        final v = (payload[idx] << 8) | payload[idx + 1];
        samples.add(logic ? (v & 0xFF) : v & 0xFFFF);
        idx += 2;
      }
      latestWaveforms[channel] = samples;
    }
  }

  // ---- Comandos App -> Pico ----

  void sendChannelSetup(ScopeConfig config) {
    final ch = <int>[];
    for (final c in config.channels.where((c) => c.enabled)) {
      ch.add((c.index & 0x0F) | ((c.voltageRange & 0x0F) << 4));
    }
    _send(const ScoppyFrameEncoder()
        .channelSetup(ch, config.timebaseMs.round(),
            flags: config.channelFlags));
  }

  void sendRun(int runMode, int sampleMode, int nonce) {
    // RUN (80): [5]=3; [6]=(muestreo<<2)|runMode; ... (payload detallado TBD)
    final payload = <int>[
      3, // versión implícita en cabecera
      (sampleMode << 2) | runMode,
      (nonce >> 24) & 0xFF,
      (nonce >> 16) & 0xFF,
      (nonce >> 8) & 0xFF,
      nonce & 0xFF,
    ];
    _send(const ScoppyFrameEncoder()
        .encode(kMsgRun, version: 3, payload: payload));
  }

  void sendTriggerSettings(ScopeConfig config) {
    _send(const ScoppyFrameEncoder().triggerSettings(
      config.triggerMode.index,
      config.triggerChannel,
      config.triggerEdge.index,
      config.triggerLevel,
    ));
  }

  void sendHeartbeat(int timebaseUs) {
    _send(const ScoppyFrameEncoder().heartbeatTimebase(timebaseUs));
  }

  void sendRequestInfo(int group) {
    _send(const ScoppyFrameEncoder().requestInfo(group));
  }

  Future<void> connect() async {
    state = ConnectionState.connected;
    stateChanged.add(state);
    try {
      await _transport.connect();
    } catch (e) {
      state = ConnectionState.disconnected;
      stateChanged.add(state);
      connectionError.add(e);
      rethrow;
    }
  }

  Future<void> disconnect() async {
    await _transport.disconnect();
    state = ConnectionState.disconnected;
    latestWaveforms.clear();
    stateChanged.add(state);
  }

  void dispose() {
    _subscription?.cancel();
    _transport.disconnect();
    stateChanged.close();
    onSync.close();
    onSample.close();
    connectionError.close();
  }
}
