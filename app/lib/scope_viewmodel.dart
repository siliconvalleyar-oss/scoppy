import 'package:flutter/foundation.dart';

import 'core/logic/measurement_calculator.dart';
import 'core/models/scope_models.dart';
import 'core/protocol/frontend_info.dart';
import 'core/scope_client.dart';

/// ViewModel del osciloscopio. Expone el estado mutable a la UI.
class ScopeViewModel extends ChangeNotifier {
  ScopeViewModel(this.client) {
    client.stateChanged.listen((s) {
      _connectionState = s;
      notifyListeners();
    });
    client.onSync.listen((info) {
      _frontendInfo = info;
      // Ajustar nº de canales según el frontend.
      if (info.numChannels >= 2 && config.numChannels < info.numChannels) {
        config.numChannels = info.numChannels;
        config.channels.clear();
        for (var i = 0; i < config.numChannels; i++) {
          config.channels.add(ScopeChannel(
            index: i,
            type: config.type,
            voltageRange: 0,
          ));
        }
      }
      notifyListeners();
    });
    client.onSample.listen((_) {
      _recalculate();
      notifyListeners();
    });
  }

  final ScoppyClient client;
  ScopeConfig config = ScopeConfig();

  ConnectionState _connectionState = ConnectionState.disconnected;
  Map<int, Measurements> _measurements = {};
  FrontendInfo? _frontendInfo;
  bool _isRunning = false;

  ConnectionState get connectionState => _connectionState;
  Map<int, Measurements> get measurements => _measurements;
  FrontendInfo? get frontendInfo => _frontendInfo;
  bool get isRunning => _isRunning;

  /// Comandos de conexión.
  Future<void> connect() async => client.connect();
  Future<void> disconnect() async => client.disconnect();

  /// Inicia la captura (RUN).
  void run() {
    _isRunning = true;
    client.sendChannelSetup(config);
    client.sendRun(RunMode.run.index, 0, 0);
    client.sendTriggerSettings(config);
    notifyListeners();
  }

  void stop() {
    _isRunning = false;
    client.sendRun(RunMode.stop.index, 0, 0);
    notifyListeners();
  }

  void single() {
    _isRunning = true;
    client.sendChannelSetup(config);
    client.sendRun(RunMode.single.index, 0, 0);
    client.sendTriggerSettings(config);
    notifyListeners();
  }

  /// Cambia el timebase y actualiza el trigger/heartbeat.
  void setTimebase(double ms) {
    config.timebaseMs = ms.clamp(0.02, 1000.0);
    client.sendHeartbeat(config.timebaseUs);
    notifyListeners();
  }

  /// Cambia el canal de trigger.
  void setTriggerChannel(int ch) {
    config.triggerChannel = ch.clamp(0, config.numChannels - 1);
    client.sendTriggerSettings(config);
    notifyListeners();
  }

  void setTriggerMode(TriggerMode mode) {
    config.triggerMode = mode;
    client.sendTriggerSettings(config);
    notifyListeners();
  }

  void setTriggerEdge(TriggerEdge edge) {
    config.triggerEdge = edge;
    client.sendTriggerSettings(config);
    notifyListeners();
  }

  void setTriggerLevel(int level) {
    config.triggerLevel = level;
    client.sendTriggerSettings(config);
    notifyListeners();
  }

  void setChannelOn(int ch, bool on) {
    if (ch < config.channels.length) {
      config.channels[ch].on = on;
      config.channels[ch].enabled = on;
      notifyListeners();
    }
  }

  void _recalculate() {
    final m = <int, Measurements>{};
    for (final entry in client.latestWaveforms.entries) {
      final ch = entry.key < config.channels.length
          ? config.channels[entry.key]
          : null;
      m[entry.key] = MeasurementCalculator.calculate(
        entry.value,
        fullScaleVolts:
            ch != null ? ch.voltsPerDiv * 8 : 3.3,
      );
    }
    _measurements = m;
  }

  /// Obtiene las muestras del canal [ch] para el painter.
  List<int> samplesFor(int ch) =>
      client.latestWaveforms[ch] ?? const [];

  @override
  void dispose() {
    client.dispose();
    super.dispose();
  }
}
