import 'dart:typed_data';

/// Modo de ejecución de la captura (RUN, STOP, SINGLE).
enum RunMode { run, stop, single }

/// Modo de muestreo (deriva del nº de canales / tipo).
enum SampleMode { normal, highSpeed }

/// Tipo de canal: osciloscopio analógico (ADC) o analizador lógico.
enum ChannelType { analog, logic }

/// Estado de conexión con el frontend (Pico).
enum ConnectionState { disconnected, connected, synchronized }

/// Sample rate del ADC del RP2040 (ver REFERENCIA_HARDWARE_PICO.md §3).
enum SampleRate {
  sr500k(500000),
  sr1_3m(1300000),
  sr2m(2000000),
  sr2_5m(2500000);

  const SampleRate(this.hz);
  final int hz;
}

/// Modos de trigger (OFF = roll mode, AUTO, NORM).
enum TriggerMode { off, auto, norm }

/// Tipos de flanco de trigger.
enum TriggerEdge { rising, falling }

/// Un canal del osciloscopio.
class ScopeChannel {
  ScopeChannel({
    required this.index,
    required this.type,
    this.enabled = false,
    this.voltageRange = 0,
    this.voltsPerDiv = 1.0,
    this.offsetDivs = 0.0,
    this.on = false,
  });

  final int index;
  ChannelType type;

  /// Canal activado (participa en la captura).
  bool enabled;

  /// Rango de voltaje seleccionado (0-7).
  int voltageRange;

  /// Volts por división (eje vertical).
  double voltsPerDiv;

  /// Posición vertical en divisiones (desplazamiento del 0V).
  double offsetDivs;

  /// Encendido/apagado desde la UI.
  bool on;

  bool get isAnalog => type == ChannelType.analog;
}

/// Configuración completa enviada/recibida por el frontend.
class ScopeConfig {
  ScopeConfig({
    this.numChannels = 2,
    ChannelType type = ChannelType.analog,
    this.timebaseMs = 10,
    this.horizontalDivs = 10,
    this.triggerMode = TriggerMode.auto,
    this.triggerChannel = 0,
    this.triggerEdge = TriggerEdge.rising,
    this.triggerLevel = 0,
    this.preTriggerPercent = 50,
    this.sampleRate = SampleRate.sr500k,
  }) : type = type {
    for (var i = 0; i < numChannels; i++) {
      channels.add(ScopeChannel(
        index: i,
        type: type,
        voltageRange: 0,
      ));
    }
  }

  /// Número total de canales (2 analógicos / 8 lógicos + ...).
  int numChannels;

  ChannelType type;

  /// Timebase en milisegundos por división.
  double timebaseMs;

  /// Divisiones horizontales de la ventana (típicamente 10).
  double horizontalDivs;

  /// Parámetros de trigger.
  TriggerMode triggerMode;
  int triggerChannel;
  TriggerEdge triggerEdge;
  int triggerLevel;
  int preTriggerPercent;

  /// Sample rate del ADC.
  SampleRate sampleRate;

  List<ScopeChannel> channels = [];

  ScopeChannel channel(int i) => channels[i];

  int get timebaseUs => (timebaseMs * 1000).round();

  /// Sample rate efectivo (se divide a la mitad con 2 canales analógicos).
  int get effectiveSampleRate {
    if (type == ChannelType.logic) return sampleRate.hz;
    final enabledAnalog = channels.where((c) => c.enabled && c.isAnalog).length;
    return enabledAnalog >= 2 ? sampleRate.hz ~/ 2 : sampleRate.hz;
  }

  /// Flags de canal para el opcode 61 (analog:3, logic:19).
  int get channelFlags => type == ChannelType.logic ? 19 : 3;

  ScopeChannel get triggerChannelObj => channels[triggerChannel];
}

/// Una trama Pico -> App con datos de muestra.
class WaveformData {
  WaveformData({
    required this.channel,
    required this.samples,
    required this.sampleRate,
    required this.logic,
  });

  final int channel;
  final Int16List samples;
  final int sampleRate;
  final bool logic;
}
