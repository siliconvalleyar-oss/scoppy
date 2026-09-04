import 'dart:typed_data';

import 'scoppy_frame.dart';
import 'scoppy_opcodes.dart';

/// Un frame decodificado Pico -> App.
class ScoppyIncomingFrame {
  ScoppyIncomingFrame({
    required this.opcode,
    required this.version,
    required this.payload,
  });

  final int opcode;
  final int version;
  final Uint8List payload;
}

/// Descodifica el flujo de bytes del frontend en frames completos.
///
/// Trae un acumulador interno: le pasas chunks con [add] y te entrega frames
/// completos por [onFrame] a medida que los reconoce, descartando frames
/// fuera de rango (consumiendo el frame completo).
class ScoppyFrameDecoder {
  ScoppyFrameDecoder({this.onFrame, this.onError});

  final void Function(ScoppyIncomingFrame frame)? onFrame;
  final void Function(Object error)? onError;

  final BytesBuilder _buffer = BytesBuilder();

  void add(List<int> data) {
    _buffer.add(data);
    _parse();
  }

  void _parse() {
    final buf = _buffer.toBytes();
    var offset = 0;
    while (true) {
      if (offset + 6 > buf.length) break;

      // Buscar byte de sincronización.
      if (buf[offset] != kSyncByte) {
        offset++;
        continue;
      }

      final length = (buf[offset + 1] << 8) | buf[offset + 2];
      // La longitud incluye el header de 6 bytes.
      if (length < 6) {
        offset += 3;
        continue;
      }
      if (offset + length > buf.length) break; // frame incompleto

      final opcode = buf[offset + 3];
      final confirmation = buf[offset + 4];
      final version = buf[offset + 5];

      // Validación de confirmación (opcode + 5).
      if (confirmation != ((opcode + 5) & 0xFF)) {
        offset += length;
        continue;
      }
      // Validación de versión mínima.
      if (version < kMinProtocolVersion) {
        final e = ScoppyFrameException('Firmware version ($version) not supported');
        onError?.call(e);
        offset += length;
        continue;
      }

      final payload = Uint8List.sublistView(buf, offset + 6, offset + length);
      onFrame?.call(ScoppyIncomingFrame(
        opcode: opcode,
        version: version,
        payload: payload,
      ));
      offset += length;
    }

    if (offset > 0) {
      final remaining = buf.sublist(offset);
      _buffer.clear();
      _buffer.add(remaining);
    }
  }

  void clear() => _buffer.clear();
}
