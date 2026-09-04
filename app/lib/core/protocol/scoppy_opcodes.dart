/// Opcodes del protocolo binario Scoppy App <-> Pico.
///
/// Documentado en `flutter_docs/docs/PROTOCOLO_SCOPPY.md`.
library;

/// Byte de sincronización del frame.
const int kSyncByte = 0xFF;

/// Byte terminador para mensajes App -> Pico.
const int kFrameTerminator = 0x56; // 'V' (86)

/// Versión de protocolo exigida por el parser (>= 1).
const int kMinProtocolVersion = 1;

/// Tamaño del buffer de entrada del frontend (bytes).
const int kInputBufferSize = 64000;

/// --- Pico -> App (FRONTEND_TO_APP) ---
const int kMsgSync = 60; // 0x3C  info del frontend
const int kMsgSampleData = 61; // 0x3D  datos de muestra (waveform/trigger)
const int kMsgFrontendConfig = 62; // 0x3E  config del frontend
const int kMsgVoltsDivParams = 63; // 0x3F  params volts/div

/// --- App -> Pico (APP_TO_FRONTEND) ---
const int kMsgChannelSetup = 61; // 0x3D  setup de canales/captura
const int kMsgConfigFrontend = 62; // 0x3E  config FRONTEND_TO_APP
const int kMsgRun = 80; // 0x50  RUN / parámetros de captura
const int kMsgHeartbeatTimebase = 81; // 0x51  heartbeat/timebase
const int kMsgChannelList = 82; // 0x52  listado canales activos
const int kMsgTriggerSettings = 83; // 0x53  trigger settings
const int kMsgVoltsDivParamsReq = 84; // 0x54  params volts/div (req)
const int kMsgTriggerLevel = 85; // 0x55  trigger level
const int kMsgVoltsDivChannel = 87; // 0x57  volt/div por canal
const int kMsgOffsetChannel = 88; // 0x58  offset por canal
const int kMsgRequestInfo = 90; // 0x5A  request info
const int kMsgConfigAppToFrontend = 91; // 0x5B  config APP_TO_FRONTEND
const int kMsgHeartbeatControl = 92; // 0x5C  heartbeat con byte de control

/// Valores de flags de canal para el opcode 61.
const int kChannelFlagsAnalog = 3;
const int kChannelFlagsLogic = 19;
