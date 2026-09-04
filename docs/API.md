# API

Descripción de la API de comunicación App ↔ Pico (protocolo binario Scoppy) y
de la API interna de la app Flutter.

## Protocolo binario (App ↔ Pico)

Ver [PROTOCOLO_SCOPPY.md](PROTOCOLO_SCOPPY.md) para el detalle completo.

### Frame común

```
byte 0 : 0xFF              (sync)
byte 1-2: longitud total (big-endian)
byte 3 : opcode
byte 4 : opcode + 5        (confirmación)
byte 5 : version >= 1
byte 6+: payload
```

Los mensajes App→Pico se cierran con el byte terminador **0x56**.

### Opcodes App → Pico

| OP | Hex | Función |
|----|-----|---------|
| 61 | 0x3D | Setup de canales/captura |
| 62 | 0x3E | Config FRONTEND_TO_APP |
| 80 | 0x50 | RUN / parámetros de captura |
| 81 | 0x51 | Heartbeat/timebase |
| 82 | 0x52 | Listado de canales activos |
| 83 | 0x53 | Trigger settings |
| 84 | 0x54 | Params volts/div |
| 85 | 0x55 | Trigger level |
| 87 | 0x57 | Volt/div por canal |
| 88 | 0x58 | Offset por canal |
| 90 | 0x5A | Request info |
| 91 | 0x5B | Config APP_TO_FRONTEND |
| 92 | 0x5C | Heartbeat con byte de control |

### Opcodes Pico → App

| OP | Hex | Función |
|----|-----|---------|
| 60 | 0x3C | SYNC / info del frontend |
| 61 | 0x3D | Datos de muestra (waveform) |
| 62 | 0x3E | Config del frontend |
| 63 | 0x3F | Params volts/div |

### Transportes

- **USB serial**: VID 0x2E8A (Raspberry Pi), PID variantes.
- **WiFi (Pico W)**: TCP control **22483**, datos **22484**. IP por defecto
  (modo AP): **192.168.4.1**.

## API interna de la app (`app/lib/`)

```
core/
  models/scope_models.dart        // config, run mode, sample rate, trigger
  protocol/scoppy_opcodes.dart    // constantes de opcodes
  protocol/scoppy_frame.dart      // codificador de frames (App->Pico)
  protocol/scoppy_decoder.dart    // decodificador de frames (Pico->App)
  protocol/frontend_info.dart     // parseo del SYNC (opcode 60)
  transport/transport.dart        // interfaz ScoppyTransport
  transport/wifi_transport.dart   // WifiTransport (TCP 22483/22484)
  logic/measurement_calculator.dart // Vmin/Vmax/Vpp/Mean/DC-RMS/AC-RMS/Freq/Duty
  scope_client.dart               // orquesta protocolo + transporte
ui/
  oscilloscope_screen.dart        // pantalla principal
  widgets/scope_painter.dart      // rejilla 10x8 + waveforms
scope_viewmodel.dart              // ViewModel (ChangeNotifier / Provider)
```

### API del cliente (Dart)

| Método | Descripción |
|--------|-------------|
| `sendChannelSetup(config)` | Envía opcode 61 con canales + timebase. |
| `sendRun(runMode, sampleMode, nonce)` | Opcode 80 (RUN). |
| `sendTriggerSettings(config)` | Opcode 83. |
| `sendHeartbeat(timebaseUs)` | Opcode 81. |
| `sendRequestInfo(group)` | Opcode 90. |