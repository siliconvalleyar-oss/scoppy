import 'dart:typed_data';

import 'scoppy_opcodes.dart';

/// Error lanzado cuando un frame entrante es inválido.
class ScoppyFrameException implements Exception {
  ScoppyFrameException(this.message);
  final String message;
  @override
  String toString() => 'ScoppyFrameException: $message';
}

/// Codifica mensajes App -> Pico con el framing binario Scoppy.
///
/// Frame: `FF | len_hi | len_lo | opcode | opcode+5 | version | payload [0x56]`
class ScoppyFrameEncoder {
  const ScoppyFrameEncoder();

  /// Construye un frame App -> Pico con [opcode], [version] y [payload].
  /// Añade el byte terminador 0x56 al final (APP_TO_FRONTEND).
  Uint8List encode(int opcode, {required int version, List<int>? payload}) {
    final body = [
      opcode & 0xFF,
      (opcode + 5) & 0xFF, // confirmación = opcode + 5
      version & 0xFF,
      ...?payload,
    ];
    final length = body.length + 2 + 1; // body + [FF,len] + terminator
    final out = BytesBuilder();
    out.addByte(kSyncByte);
    out.addByte((length >> 8) & 0xFF);
    out.addByte(length & 0xFF);
    out.add(body);
    out.addByte(kFrameTerminator);
    return out.toBytes();
  }

  /// Opcode 61: setup de canales/captura.
  /// payload: [6]=flags, [7]=nº canales&0x0F, 1B/canal (canal|rango<<4),
  ///          int timebase_ms, int -1, byte 1
  Uint8List channelSetup(List<int> channelsWithRange, int timebaseMs,
      {int flags = kChannelFlagsAnalog, int version = 1}) {
    final payload = <int>[
      flags & 0xFF,
      channelsWithRange.length & 0x0F,
      ...channelsWithRange,
    ];
    _pushInt(payload, timebaseMs);
    _pushInt(payload, -1);
    payload.add(1);
    return encode(kMsgChannelSetup, version: version, payload: payload);
  }

  /// Opcode 81: heartbeat/timebase.
  Uint8List heartbeatTimebase(int minDivUs,
      {int version = 1}) {
    final payload = <int>[];
    _pushInt(payload, minDivUs);
    return encode(kMsgHeartbeatTimebase, version: version, payload: payload);
  }

  /// Opcode 82: listado de canales activos. [channels] = lista de flags.
  Uint8List channelList(List<int> channelFlags, {int version = 1}) {
    final payload = <int>[channelFlags.length & 0x0F, ...channelFlags];
    return encode(kMsgChannelList, version: version, payload: payload);
  }

  /// Opcode 83: trigger settings (13 B).
  Uint8List triggerSettings(
    int mode,
    int channel,
    int edgeType,
    int level, {
    int version = 1,
  }) {
    final payload = <int>[
      mode & 0xFF,
      channel & 0xFF,
      edgeType & 0xFF,
      (level >> 8) & 0xFF,
      level & 0xFF,
      0, 0, 0, 0, // long 0
      0, 0, 0, 0, // long 0
    ];
    return encode(kMsgTriggerSettings, version: version, payload: payload);
  }

  /// Opcode 85: trigger level (4 B).
  Uint8List triggerLevel(int level, {int version = 1}) {
    final payload = <int>[];
    _pushInt(payload, level);
    return encode(kMsgTriggerLevel, version: version, payload: payload);
  }

  /// Opcode 87: volt/div por canal.
  Uint8List voltsDiv(int value, {int version = 1}) {
    final payload = <int>[value & 0xFF];
    return encode(kMsgVoltsDivChannel, version: version, payload: payload);
  }

  /// Opcode 88: offset por canal.
  Uint8List offset(int channel, int level, {int version = 1}) {
    final payload = <int>[channel & 0xFF, level & 0xFF];
    return encode(kMsgOffsetChannel, version: version, payload: payload);
  }

  /// Opcode 90: request info.
  Uint8List requestInfo(int group, {int version = 1}) {
    final payload = <int>[3, 1, group & 7];
    return encode(kMsgRequestInfo, version: version, payload: payload);
  }

  /// Opcode 92: heartbeat con byte de control.
  Uint8List heartbeatControl(int arg1, int arg2, {int version = 1}) {
    final payload = <int>[arg1 & 0xFF];
    return encode(
      arg2 & 0xFF, // el opcode depende de arg2
      version: version,
      payload: payload,
    );
  }

  static void _pushInt(List<int> out, int value) {
    out.add((value >> 24) & 0xFF);
    out.add((value >> 16) & 0xFF);
    out.add((value >> 8) & 0xFF);
    out.add(value & 0xFF);
  }
}
