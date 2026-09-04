# Protocolo de Comunicación - Android ↔ Pico W

## Visión General

El protocolo de comunicación entre la aplicación Android y el firmware Scoppy corre sobre:
- **USB**: CDC-ACM (EP2 OUT/IN), conexión directa de alta velocidad
- **WiFi**: TCP/IP sobre Access Point o Station

---

## Detección del Dispositivo

### USB

La aplicación Android detecta el dispositivo USB mediante:

1. Enumeración USB y lectura de descriptores
2. Filtrado por `VID = 0x2E8A` y `PID = 0x000A`
3. Verificación de la estructura IAD (bFunctionClass = 0x02 CDC)

```java
// Pseudocódigo basado en smali
if (device.getVendorId() == 0x2E8A && 
    device.getProductId() == 0x000A) {
    // Verificar interfaces
    for (int i = 0; i < device.getInterfaceCount(); i++) {
        UsbInterface iface = device.getInterface(i);
        if (iface.getInterfaceClass() == 0x02) {
            // Dispositivo Scoppy detectado
        }
    }
}
```

### WiFi

Detección por mDNS (Bonjour/ZeroConf):
- Servicio: `_scoppy._tcp` (o `_scoppyx._tcp`)
- Protocolo: TCP
- Puerto: variable (típicamente 5000-6000)

---

## Protocolo USB (Canal Primario)

### Handshake de Conexión

```
Android                        Pico W
  │                               │
  │─── SetConfiguration(1) ──────►│  Activar interfaces CDC
  │                               │
  │─── SetLineCoding ────────────►│  Configurar parámetros serie
  │─── SetControlLineState ──────►│  DTR/RTS
  │                               │
  │─── CMD_PING (0x09) ──────────►│  Verificar comunicación
  │◄── STATUS_OK ─────────────────│  Respuesta
  │                               │
  │─── CMD_GET_DEVICE_INFO ──────►│  Obtener modelo, versión, etc.
  │◄── DeviceInfo ────────────────│  "scoppy-pico" / "scoppy-picow"
  │                               │
  │─── CMD_GET_CONFIG ───────────►│  Leer configuración actual
  │◄── ConfigBlock ───────────────│
  │                               │
```

### Formato de Comandos USB

Los comandos se envían como tramas binarias por EP2 OUT (bulk, 64 bytes max por transacción):

```
┌─────────┬─────────┬─────────────────────┐
│  CMD    │  LEN    │  PAYLOAD            │
│ (1 byte)│ (1 byte)│ (LEN bytes)         │
├─────────┼─────────┼─────────────────────┤
│ 0x01    │  4      │ sample_rate (u32 LE)│
│ 0x02    │  3      │ trigger config      │
│ 0x03    │  0      │ (start acquisition) │
│ 0x04    │  0      │ (stop acquisition)  │
│ 0x05    │  2      │ channel, range      │
│ 0x06    │  0      │ (get device info)   │
│ 0x07    │  0      │ (get config)        │
│ 0x08    │  N      │ config block        │
│ 0x09    │  0      │ (ping/keepalive)    │
│ 0x0A    │  N      │ access code         │
│ 0x0B    │  N      │ set buffer params   │
└─────────┴─────────┴─────────────────────┘
```

### Formato de Respuestas USB

Las respuestas vienen por EP2 IN (bulk):

```
┌─────────┬─────────┬─────────────────────┐
│  STATUS │  LEN    │  PAYLOAD            │
│ (1 byte)│ (1 byte)│ (LEN bytes)         │
├─────────┼─────────┼─────────────────────┤
│ 0x00    │  N      │ OK + datos          │
│ 0x01    │  N      │ Error + mensaje     │
│ 0x02    │  0      │ ACK (sin datos)     │
└─────────┴─────────┴─────────────────────┘
```

---

## Comandos Identificados

### CMD_START_ACQUISITION (0x03)

Inicia la adquisición de muestras del ADC.

**Request:**
```
CMD=0x03, LEN=0
```

**Behavior:**
- Configura DMA del ADC
- Habilita interrupción de fin de buffer
- Comienza envío continuo de paquetes de datos por EP2 IN
- El trigger puede ser inmediato o por hardware

### CMD_STOP_ACQUISITION (0x04)

Detiene la adquisición.

**Request:**
```
CMD=0x04, LEN=0
```

**Behavior:**
- Deshabilita DMA del ADC
- Detiene envío por EP2 IN

### CMD_SET_SAMPLE_RATE (0x01)

Configura la tasa de muestreo.

**Request:**
```
CMD=0x01, LEN=4
PAYLOAD: sample_rate (uint32 little-endian, Hz)
```

**Ejemplo:**
- `0x00 0x0F 0x00 0x00` = 3840 Hz
- `0x80 0x3E 0x00 0x00` = 16000 Hz
- `0x20 0xA1 0x00 0x00` = 41200 Hz (máximo 1 canal)
- `0x40 0x24 0x01 0x00` = 150000 Hz

### CMD_SET_TRIGGER (0x02)

Configura el trigger del osciloscopio.

**Request:**
```
CMD=0x02, LEN=3
PAYLOAD[0] = trigger_channel (0=Ch1, 1=Ch2, 2=Logic, etc.)
PAYLOAD[1] = trigger_type    (0=Rising, 1=Falling, 2=Both, 3=Level)
PAYLOAD[2] = trigger_level   (8-bit: 0-255, mapeado a voltaje)
```

**Trigger types (inferidos):**
- `0x00`: Rising edge
- `1x00`: Falling edge
- `0x02`: Either edge
- `0x03`: Level (threshold)

### CMD_SET_CHANNEL_RANGE (0x05)

Configura el rango de voltaje de un canal.

**Request:**
```
CMD=0x05, LEN=2
PAYLOAD[0] = channel (0=CH1, 1=CH2)
PAYLOAD[1] = range   (0=±10V, 1=±5V, 2=±2V, 3=±1V, etc.)
```

---

## Formato de Datos de Adquisición

### Encapsulación USB

Los datos de muestras se envían en paquetes de **64 bytes** por EP2 IN:

```
┌────────────────────────────────────────────────────┐
│              Paquete EP2 IN (64 bytes)              │
├──────────┬──────────┬──────────────────────────────┤
│ Header   │ Samples  │ Trailer (opcional)           │
│ (4 bytes)│ (N bytes)│ (0 bytes)                    │
├──────────┼──────────┼──────────────────────────────┤
│ 0xAA     │ Muestras │                              │
│ 0xBB     │ ADC      │                              │
│ 0xCC     │ packed   │                              │
│ 0xDD     │ 10-bit   │                              │
└──────────┴──────────┴──────────────────────────────┘
```

### Formato de Muestra por Canal

#### Modo 1 Canal (mono)

```
Cada muestra = 10 bits (0-1023)
Empaquetado: 5 bytes = 4 muestras (5×8 = 40 bits = 4×10)

Byte 0: [S3(2)|S2(8)]       S3 bits 9-8, S2 bits 7-0
Byte 1: [S1(8)|S0(2)]       S1 bits 7-0, S0 bits 9-8
Byte 2: [S7(2)|S6(8)]       ...
...
```

#### Modo 2 Canales (interleaved)

```
Cada par de muestras (Ch1, Ch2) = 20 bits
Empaquetado: 5 bytes = 2 pares (Ch1_0, Ch2_0, Ch1_1, Ch2_1)

Byte 0: [Ch2_0(2)|Ch1_0(8)]   Ch2_0 bits 9-8, Ch1_0 bits 7-0
Byte 1: [Ch1_1(8)|Ch1_0(2)]   Ch1_1 bits 7-0, Ch1_0 bits 9-8 (cont.)
Byte 2: [Ch2_1(2)|Ch2_0(8)]   ...
```

### Muestras por Paquete de 64 bytes

| Modo | Bits por muestra | Muestras/payload | Muestras/paquete |
|------|-----------------|-----------------|-----------------|
| 1 canal, 10-bit packed | 10 | 50 bytes → 40 muestras | ~40 |
| 2 canales, 10-bit packed | 20 por par | 50 bytes → 4 pares | ~4 pares (8 total) |
| Raw 8-bit (debug) | 8 | 60 bytes → 60 muestras | ~60 |

---

## Protocolo WiFi (Canal Alternativo)

### Conexión TCP

```
Android                        Pico W (AP)
  │                               │
  │──── TCP SYN ──────────────────►│  Puerto: servicio mDNS
  │◄─── TCP SYN+ACK ──────────────│
  │──── TCP ACK ──────────────────│
  │                               │
  │──── Comando (mismo formato) ──►│  Igual que USB
  │◄─── Respuesta ────────────────│
  │                               │
  │◄─── Datos continuos ──────────│  Streaming de muestras
```

### mDNS Discovery

```
Android                        Pico W
  │                               │
  │──── mDNS query _scoppy._tcp ──►│
  │◄─── mDNS response ────────────│
  │     (IP: 192.168.4.1, port:N) │
  │                               │
  │──── TCP connect ──────────────►│
```

---

## Acceso Code (Protección de Cuenta)

El firmware soporta un "Access Code" para vincular cuentas de usuario:

```
scoppy-%.2x%.2x%.2x%.2x%.2x%.2x%.2x%.2x"  (formato de código)
```

```
Access Code: %s   (string en firmware)
```

> El Access Code se usa para funciones premium (ver `scoppy.premium.lifetime` y `scoppy.premium.subscription` en el APK).

---

## Flujo de Diagnóstico USB

La app Android incluye una actividad de diagnóstico USB:

```
UsbDiagnosticsActivity
  - Mide throughput de transferencia
  - Verifica: "Data transferred: X bytes"
  - Detecta errores: "Data transfer errors were detected"
  - Prueba de bucle (echo test)
```
