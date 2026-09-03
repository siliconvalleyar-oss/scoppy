# Protocolo USB - Firmware Scoppy Pico W (v18)

## Resumen

El firmware Scoppy implementa un dispositivo **CDC-ACM (USB Communications Device Class - Abstract Control Model)** sobre USB 2.0 High-Speed. El dispositivo se presenta como un puerto COM virtual estándar, permitiendo comunicación bidireccional con la aplicación Android (y también con herramientas estándar como `screen`, `minicom`, `PuTTY` en el host).

---

## Device Descriptor

Extraído del firmware en offset `0x45330`:

```c
struct {
    uint8_t  bLength;            // 0x12 = 18
    uint8_t  bDescriptorType;    // 0x01 = Device
    uint16_t bcdUSB;             // 0x0200 = USB 2.0
    uint8_t  bDeviceClass;       // 0xEF = Miscellaneous (IAD)
    uint8_t  bDeviceSubClass;    // 0x02
    uint8_t  bDeviceProtocol;    // 0x01
    uint8_t  bMaxPacketSize0;    // 64 bytes (EP0 max packet)
    uint16_t idVendor;           // 0x2E8A (Raspberry Pi Foundation)
    uint16_t idProduct;          // 0x000A
    uint16_t bcdDevice;          // 0x0100 = 1.0
    uint8_t  iManufacturer;      // 1
    uint8_t  iProduct;           // 2
    uint8_t  iSerialNumber;      // 3
    uint8_t  bNumConfigurations; // 1
} __attribute__((packed));
```

### Campos clave

| Campo | Valor | Nota |
|-------|-------|------|
| `bcdUSB` | `0x0200` | USB 2.0 High-Speed (480 Mbps) |
| `bDeviceClass` | `0xEF` | Clase Miscelánea → requiere IAD |
| `bDeviceSubClass` | `0x02` | Common Class |
| `bDeviceProtocol` | `0x01` | DFU (Device Firmware Upgrade) |
| `idVendor` | `0x2E8A` | Raspberry Pi Foundation |
| `idProduct` | `0x000A` | Scoppy Pico |
| `bMaxPacketSize0` | 64 | Control endpoint EP0 |
| `bNumConfigurations` | 1 | Solo una configuración |

> **Nota:** El campo `bDeviceProtocol=0x01` sugiere soporte DFU, pero la interfaz principal es CDC-ACM.

---

## Configuration Descriptor Set

Extraído del firmware en offset `0x452E4` (75 bytes totales):

### Configuration Descriptor (offset +0)

```
09 02 4B 00 02 01 00 A0 7D
```

| Campo | Valor | Nota |
|-------|-------|------|
| `bLength` | 9 | Tamaño del descriptor |
| `bDescriptorType` | 0x02 | Configuration |
| `wTotalLength` | 0x004B = 75 | Todos los descriptores |
| `bNumInterfaces` | 2 | Interface 0 (CDC-Ctrl) + Interface 1 (CDC-Data) |
| `bConfigurationValue` | 1 | Seleccionar con `SetConfiguration(1)` |
| `iConfiguration` | 0 | Sin string |
| `bmAttributes` | 0xA0 | Bus powered + Remote wakeup |
| `bMaxPower` | 0x7D = 125 | 250 mA requeridos |

### Interface Association Descriptor (IAD) (offset +9)

```
08 0B 00 02 02 02 00 00
```

| Campo | Valor | Nota |
|-------|-------|------|
| `bLength` | 8 | |
| `bDescriptorType` | 0x0B | IAD |
| `bFirstInterface` | 0 | Primera interfaz = 0 |
| `bInterfaceCount` | 2 | Agrupa interfaces 0 y 1 |
| `bFunctionClass` | **0x02** | **CDC — usado por Android para detección** |
| `bFunctionSubClass` | 0x00 | |
| `bFunctionProtocol` | 0x00 | |

> **Importante:** La aplicación Android filtra dispositivos verificando que `getInterfaceCount() >= 2` y que al menos una interfaz tenga `bInterfaceClass == 0x02`. En este dispositivo, la detección la realiza sobre el IAD (`bFunctionClass = 0x02`).

---

## Interface 0: CDC Control (Abstract Control Management)

```
09 04 00 00 01 02 02 00 04    (Interface descriptor)
05 24 00 20 01                (CS Header Functional)
05 24 01 00 01                (CS Call Management)
04 24 02 02                   (CS ACM)
05 24 06 00 01                (CS Union)
07 05 81 03 08 00 10          (EP1 IN - Interrupt)
```

### Descriptor de Interfaz

| Campo | Valor | Nota |
|-------|-------|------|
| `bInterfaceNumber` | 0 | Interfaz de control CDC |
| `bNumEndpoints` | 1 | Solo EP1 IN |
| `bInterfaceClass` | 0x02 | CDC-Control |
| `bInterfaceSubClass` | 0x02 | Abstract Control Management |
| `bInterfaceProtocol` | 0x00 | No hay protocolo específico |
| `iInterface` | 4 | String descriptor 4 |

### CS Functional Descriptors

| Subtipo | bLength | Datos | Significado |
|---------|---------|-------|-------------|
| `HEADER` (0x00) | 5 | `24 00 20 01` | CDC versión 1.2 |
| `CALL_MGMT` (0x01) | 5 | `24 01 00 01` | No hay gestión de llamadas, DataInterface=1 |
| `ACM` (0x02) | 4 | `24 02 02` | Capacidades ACM: soporta `Set_Line_Coding`, `Set_Control_Line_State` |
| `UNION` (0x06) | 5 | `24 06 00 01` | Control=IF0, Subordinada=IF1 |

### Endpoint EP1 IN (Interrupt)

| Campo | Valor |
|-------|-------|
| `bEndpointAddress` | `0x81` (EP1, dirección IN) |
| `bmAttributes` | `0x03` = Interrupt |
| `wMaxPacketSize` | 8 bytes |
| `bInterval` | 16 (frames = 16 × 125 µs = 2 ms en High-Speed) |

> EP1 IN se usa para **notificaciones de estado de línea serie** (sería el `SerialState` en CDC-ACM).

---

## Interface 1: CDC Data

```
09 04 01 00 02 0A 00 00 00    (Interface descriptor)
07 05 02 02 40 00 00          (EP2 OUT - Bulk)
07 05 82 02 40 00 00          (EP2 IN - Bulk)
```

### Descriptor de Interfaz

| Campo | Valor | Nota |
|-------|-------|------|
| `bInterfaceNumber` | 1 | Interfaz de datos CDC |
| `bNumEndpoints` | 2 | EP2 OUT + EP2 IN |
| `bInterfaceClass` | **0x0A** | CDC-Data |
| `bInterfaceSubClass` | 0x00 | |
| `bInterfaceProtocol` | 0x00 | |
| `iInterface` | 0 | Sin string |

### Endpoint EP2 OUT (Bulk - Host → Pico)

| Campo | Valor |
|-------|-------|
| `bEndpointAddress` | `0x02` (EP2, dirección OUT) |
| `bmAttributes` | `0x02` = Bulk |
| `wMaxPacketSize` | `0x0040` = **64 bytes** |
| `bInterval` | 0 (no aplica para bulk en High-Speed) |

### Endpoint EP2 IN (Bulk - Pico → Host)

| Campo | Valor |
|-------|-------|
| `bEndpointAddress` | `0x82` (EP2, dirección IN) |
| `bmAttributes` | `0x02` = Bulk |
| `wMaxPacketSize` | `0x0040` = **64 bytes** |
| `bInterval` | 0 |

> **Nota:** EP2 OUT e EP2 IN tienen `wMaxPacketSize = 64` bytes, lo que indica **USB High-Speed** (480 Mbps). En Full-Speed (12 Mbps) el máximo para bulk es 64 bytes igual, pero el contexto del RP2040 con estos endpoints es High-Speed.

---

## Flujo de Comunicación USB

```
┌──────────────────────────────────────────────────────────────────┐
│  Host Android / Linux                                            │
├──────────────────────────────────────────────────────────────────┤
│                                                                  │
│  Control (EP0)                                                   │
│  ┌─────────────────┐                                             │
│  │ SetConfiguration │ → Interface 0 + Interface 1 activas       │
│  │ GetDescriptor    │ → Lee Device/Config/String descriptors     │
│  └─────────────────┘                                             │
│                                                                  │
│  EP1 IN (Interrupt) ← Notificaciones de estado CDC-ACM          │
│                                                                  │
│  EP2 OUT (Bulk) ──────→ Comandos desde Android hacia Pico       │
│                         (set_sample_rate, set_trigger, start,   │
│                          set_channel_range, etc.)               │
│                                                                  │
│  EP2 IN (Bulk) ←────── Datos de muestra desde Pico hacia Android│
│                         (paquetes de 64 bytes con muestras ADC)  │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘
```

---

## Detección del Dispositivo por la Aplicación Android

La aplicación Scoppy (analizada vía smali) identifica el dispositivo con:

1. `getVendorId() == 0x2E8A` (Raspberry Pi)
2. `getProductId() == 0x000A`
3. `getInterfaceCount() >= 2`
4. Al menos una interfaz con `getInterfaceClass() == 0x02` (CDC, del IAD)
5. Verifica la presencia de interface CDC con `getInterfaceSubclass() == 0x02`

---

## Métodos de Comunicación USB (APK Smali Analysis)

### Arquitectura de Comunicación

El APK de Scoppy usa **control transfers** para comandos y **bulk transfers** solo para recepción de datos:

```
┌──────────────────────────────────────────────────────────────────┐
│  Host Android                                                    │
├──────────────────────────────────────────────────────────────────┤
│                                                                  │
│  Control (EP0) - Comandos y configuración                       │
│  ├─ Vendor requests: controlTransfer(0x40, 0x9a, val, idx, ...) │
│  ├─ Data IN:       controlTransfer(0xC0, 0x95, 0x706, ...)      │
│  ├─ Data OUT:      controlTransfer(0x41, req, val, ...)          │
│  └─ CDC-ACM:       controlTransfer(0xC1, 0x4, ...) [GET_LINE]   │
│                                                                  │
│  EP2 IN (Bulk) ←────── Datos de muestra desde Pico              │
│                         (hasta 16384 bytes por transferencia)   │
│                                                                  │
│  EP2 OUT (Bulk) - NO USADO por el APK actual                    │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘
```

### Clases Smali Principales

| Clase | Función |
|-------|---------|
| `P0/d` | Comunicación USB principal (control + bulk) |
| `P0/e` | Control transfers específicos y CDC-ACM |
| `P0/h` | Thread RX (lectura bulk EP2 IN) |
| `P0/b` | Detección de dispositivo USB |
| `O0/c` | Filtrado de dispositivo USB |

### Endpoints Asignados por la Aplicación

```smali
# P0/e.smali - Asignación de endpoints
if (endpoint.getDirection() != 0x80) {
    this.j = endpoint;  // EP2 OUT (bulk, host → pico)
} else {
    this.k = endpoint;  // EP2 IN (bulk, pico → host)
}
```

- `j` = EP2 OUT (envío de comandos desde Android)
- `k` = EP2 IN (recepción de datos desde Pico)

---

## Protocolo de Comandos via Control Transfers

### Formato de Comando Vendor

Los comandos se envían como **vendor requests** de dos etapas:

```smali
# Paso 1: Enviar comando
controlTransfer(0x40, 0x9a, 0x1312, command_code, null, 0, 0)

# Paso 2: Enviar valor
controlTransfer(0x40, 0x9a, 0xf2c, value, null, 0, 0)
```

Donde:
- `0x40` = `VENDOR_TYPE | DEVICE_TO_HOST | RECIPIENT_DEVICE`
- `0x9a` = Código de vendor request personalizado
- `0x1312` = wValue para "set command"
- `0xf2c` = wValue para "get command"
- `command_code` = Código específico del comando (wIndex)
- `value` = Valor del comando

### Métodos de Transferencia

| Método | requestType | request | Uso |
|--------|-------------|---------|-----|
| `r(III)` | `0x40` | `0x9a` | Vendor request principal |
| `q([B)` | `0xC0` | `0x95` | Lectura de datos (IN) |
| `p([BII)` | `0x41` | variable | Escritura de datos (OUT) |
| `n()S` | `0xC1` | `0x04` | GET_LINE_CODING (CDC-ACM) |

### Códigos de Comando Identificados

| Código (hex) | Value | Segundo param | Contexto | Uso inferido |
|--------------|-------|---------------|----------|--------------|
| `0x6481` | 0x76 | - | Sample rate 600-1200 | Set sample rate bajo |
| `0x6482` | variable | - | Get sample rate | Obtener sample rate actual |
| `0x6483` | - | - | Get device info | Obtener información del dispositivo |
| `0x9883` | variable | - | Config avanzada | Configuración avanzada |
| `0xcc83` | variable | - | Premium features | Funciones premium/unlock |
| `0xb281` | 0x3b | - | Sample rate alta | Set sample rate alto |
| `0xd980` | 0xeb | - | Sample rate media | Set sample rate medio |
| `0xd981` | variable | - | Sample rate | Set sample rate específico |
| `0xd982` | variable | - | Sample rate | Set sample rate específico |

### Comandos CDC-ACM Estándar

El APK también usa control transfers estándar de CDC-ACM:

```smali
# GET_LINE_CODING - Leer configuración de línea
controlTransfer(0xC1, 0x04, 0, iface, buffer, 2, 0)

# SET_LINE_CODING - Establecer configuración de línea
controlTransfer(0x41, 0x03, 0, iface, buffer, len, 0)

# SET_CONTROL_LINE_STATE
controlTransfer(0x41, 0x22, value, iface, null, 0, 0)
```

**Manipulación de Line Coding:**

```smali
# 1. Leer estado actual (2 bytes)
invoke-virtual {p0}, LP0/d;->n()S
move-result v0

# 2. Modificar bits (ej: establecer baud rate)
and-int/lit16 v0, v0, -0xf01    # Limpiar bits 8-12
or-int/lit16 v0, v0, 0x800      # Establecer bit 11
int-to-short v0, v0

# 3. Escribir de vuelta (3 bytes)
invoke-virtual {p0, v2, v1, v0}, LP0/d;->p([BII)I
```

---

## Formato de Datos de Muestra (EP2 IN)

Las muestras del ADC se envían por **EP2 IN (Bulk)** durante la adquisición.

### Características de Transferencia

| Parámetro | Valor |
|-----------|-------|
| Máximo por transferencia | 16384 bytes (0x4000) |
| Timeout | 0 ms (blocking) |
| Thread | RX thread dedicado (P0/h) |

### Thread de Recepción

```smali
.method public final a()V
    .locals 8
    # Esperar en monitor hasta haber datos
    invoke-virtual {v0}, Ljava/lang/Object;->wait()V
    
    # Leer bloques de hasta 16KB
    const-wide/16 v4, 0x4000
    invoke-virtual {v1, v4, v5}, LI2/a;->a(J)[B
    
    # Enviar por bulkTransfer
    invoke-virtual {v0, v2, v1, v3, v7}, Landroid/hardware/usb/UsbDeviceConnection;->bulkTransfer(...)
```

---

## Flujo de Inicialización USB (Corregido)

1. Pico W arranca desde bootROM RP2040
2. Carga el firmware desde flash (UF2 blocks a `0x10000000`)
3. Inicializa USB: `Initialising USB` (0x43a54)
4. Inicializa CYW43 (WiFi): `Initialising SMPS`, `Initialising LEDs`
5. Enumeración USB: Device descriptor enviado al host
6. Host envía `SetConfiguration(1)` → se activan Interface 0 e Interface 1
7. **APK envía control transfers CDC-ACM:**
   - `GET_LINE_CODING` (0xC1, 0x04) para leer estado
   - `SET_LINE_CODING` (0x41, 0x03) para configurar
   - Vendor requests (0x40, 0x9a, ...) para comandos específicos
8. Firmware queda listo para comandos y streaming de datos
