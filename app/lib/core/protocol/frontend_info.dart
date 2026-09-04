import 'dart:typed_data';

/// Información del frontend parseada del mensaje SYNC (opcode 60 / 0x3C).
///
/// Corresponde a la clase `V2/C0078f` de la app original: firmware version,
/// nº de canales, rangos de voltaje e identificadores de hardware.
class FrontendInfo {
  FrontendInfo({
    this.firmwareVersion = 0,
    this.numChannels = 0,
    this.hardwareId = 0,
    this.deviceType = '',
    this.voltageRanges = const [],
  });

  final int firmwareVersion;
  final int numChannels;
  final int hardwareId;
  final String deviceType;
  final List<int> voltageRanges;

  bool get isScoppy => firmwareVersion >= 1;

  @override
  String toString() =>
      'FrontendInfo(v$firmwareVersion, channels=$numChannels, '
      'hw=$hardwareId, type=$deviceType, ranges=$voltageRanges)';
}

/// Parsea el payload del mensaje SYNC (60) en [FrontendInfo].
///
/// El formato exacto no está documentado al 100% (tarea pendiente del
/// TODO.md: "decodificar la trama SYNC de 41B"). Esta implementación extrae
/// los campos conservadoramente según `V2/C0078f`.
FrontendInfo parseFrontendInfo(Uint8List payload) {
  if (payload.isEmpty) return FrontendInfo();

  final data = Uint8List.fromList(payload);
  int version = 0;
  int channels = 0;
  int hwId = 0;

  var i = 0;
  // Slot 0 de la intro: normalmente el firmware version.
  if (data.length > 0) version = data[0] & 0xFF;
  if (data.length > 1) channels = data[1] & 0x0F;
  if (data.length > 3) {
    hwId = ((data[2] & 0xFF) << 8) | (data[3] & 0xFF);
  }

  final ranges = <int>[];
  // Los rangos suelen venir como shorts tras la cabecera.
  for (i = 4; i + 1 < data.length; i += 2) {
    ranges.add(((data[i] & 0xFF) << 8) | (data[i + 1] & 0xFF));
  }

  return FrontendInfo(
    firmwareVersion: version,
    numChannels: channels,
    hardwareId: hwId,
    voltageRanges: ranges,
  );
}
