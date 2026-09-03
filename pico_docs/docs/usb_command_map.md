# Mapa de Comandos USB - Análisis Smali

## Fuente

Análisis del APK decompilado (`apktool_out/smali/`), específicamente:
- `P0/d.smali` - Clase principal de comunicación USB
- `P0/e.smali` - Control transfers y configuración
- `P0/h.smali` - RX thread (bulkTransfer)
- `O0/c.smali` - Detección de dispositivo USB

---

## Arquitectura de Comunicación

### Clases Principales

| Clase Smali | Función |
|-------------|---------|
| `P0/d` | Comunicación USB principal (control + bulk) |
| `P0/e` | Control transfers específicos |
| `P0/h` | Thread RX (lectura bulk) |
| `P0/b` | Detección de dispositivo |
| `O0/c` | Filtrado de dispositivo USB |

### Endpoints Asignados

```smali
# P0/e.smali líneas 455-470
if (endpoint.getDirection() != 0x80) {
    this.j = endpoint;  // EP2 OUT (bulk, host → pico)
} else {
    this.k = endpoint;  // EP2 IN (bulk, pico → host)
}
```

- `j` = EP2 OUT (envío de comandos desde Android)
- `k` = EP2 IN (recepción de datos desde Pico)

---

## Tipos de Transferencia

### 1. Control Transfers (EP0)

**Código:** `P0/e.smali` líneas 2180-2220

```smali
invoke-virtual/range {v1 .. v8}, Landroid/hardware/usb/UsbDeviceConnection;->controlTransfer(IIII[BII)I
```

**Parámetros:**
- `requestType`: `0x40` (VENDOR_TYPE | DEVICE_TO_HOST)
- `request`: variable (0x1312, 0xf2c, etc.)
- `value`: variable
- `index`: 0
- `buffer`: null
- `length`: 0
- `timeout`: 0

**Uso:** Lectura de registros/estado del dispositivo.

### 2. Bulk Transfers (EP2 IN)

**Código:** `P0/h.smali` línea 306

```smali
invoke-virtual {v0, v2, v1, v3, v7}, Landroid/hardware/usb/UsbDeviceConnection;->bulkTransfer(Landroid/hardware/usb/UsbEndpoint;[BII)I
```

**Parámetros:**
- `endpoint`: EP2 IN (`k`)
- `buffer`: byte array
- `offset`: 0
- `length`: hasta 0x4000 (16384) o menor
- `timeout`: 0

**Uso:** Recepción de datos de muestreo continuo.

### 3. Vendor Requests

**Código:** `P0/d.smali` método `o(II)I` línea 3480

```smali
.method public o(II)I
    .locals 2
    const/16 v0, 0x1312
    const/16 v1, 0x9a
    invoke-virtual {p0, v1, v0, p1}, LP0/d;->r(III)I
```

**Mapeo de requests:**

| Request Code | Value | Segundo parámetro | Uso inferido |
|--------------|-------|-------------------|--------------|
| `0x6481` | 0x1312 | 0x76 | Set sample rate range? |
| `0x6482` | 0xf2c | variable | Get sample rate/status? |
| `0x6483` | - | variable | Get device info? |
| `0x9883` | - | variable | Advanced config? |
| `0xcc83` | - | variable | Premium/feature unlock? |

---

## Códigos de Comando Identificados

### Desde `P0/e.smali` array_0 (línea 1785)

```smali
:array_0
    .array-data 1
        0x0t   # 0
        0x3t   # 3
        0x2t   # 2
        0x4t   # 4
        0x1t   # 1
        0x5t   # 5
        0x6t   # 6
        0x7t   # 7
    .end array-data
```

**Interpretación:** Índices de sample rate presets o configuraciones de clock.

### Desde `P0/e.smali` array_1 (línea 1805)

```smali
:array_1
    .array-data 1
        0x0t    # 0
        0x1t    # 1
        0x0t    # 0
        0x1t    # 1
        0x0t    # 0
        -0x1t   # -1 (0xFF)
        0x2t    # 2
        0x1t    # 1
        0x0t    # 0
        -0x1t   # -1 (0xFF)
        -0x2t   # -2 (0xFE)
        -0x3t   # -3 (0xFD)
        0x4t    # 4
        0x3t    # 3
    .end array-data
```

**Interpretación:** Configuraciones de trigger o channel settings.

---

## Cálculo de Sample Rate

### Código: `P0/e.smali` líneas 1230-1410

El firmware calcula el sample rate así:

```smali
# 1. Obtener divisor base del descriptor USB
aget-byte v7, v8, v5    # byte 5 del descriptor
if-nez v7, :cond_2
    move v7, v13        # divisor = 1 si descriptor[5] == 0
:cond_2

# 2. Calcular divisor de sample rate
shr-int/lit8 v8, v3, 0xe   # v3 = 0x2dc6c0 (3000000?)
if-lt v1, v8, :cond_0      # v1 = sample rate solicitada

# 3. Buscar preset en array_0
aget-byte v4, v4, v7       # v4 = array_0[v7]
shl-int/lit8 v4, v4, 0xe   # v4 <<= 14
or-int/2addr v4, v5        # OR con flags
or-int/2addr v4, v6        # OR con más flags
int-to-short v5, v4
aput-short v5, v2, v14     # Guardar en array de rates
```

**Sample rates presets encontrados:**

| Valor hex | Decimal | Uso |
|-----------|---------|-----|
| `0x1388` | 5000 | Sample rate bajo |
| `0x1a` | 26 | Sample rate medio |
| `0xd` | 13 | Sample rate alto |
| `0x34` | 52 | Muy alto |
| `0x809c` | 32924 | Alto |
| `0xc04e` | 49150 | Máximo |
| `0x9600` | 38400 | Estándar |
| `0x4b00` | 19200 | Estándar |
| `0x2580` | 9600 | Estándar |
| `0x12c0` | 4800 | Estándar |
| `0x258` | 600 | Bajo |
| `0x12c` | 300 | Muy bajo |

---

## Constantes de Tiempo/Timeout

| Constante | Decimal | Uso |
|-----------|---------|-----|
| `0x40` | 64 | Max packet size USB |
| `0x4b0` | 1200 | Buffer size / timeout |
| `0x2710` | 10000 | Timeout 10s |
| `0x1388` | 5000 | Timeout 5s |
| `0x9c4` | 2500 | Timeout 2.5s |
| `0x64` | 100 | Timeout 100ms |

---

## Detección de Dispositivo

### Código: `O0/c.smali` líneas 7702-7829

```smali
.method public static a(Landroid/hardware/usb/UsbDevice;)Z
    # Verifica VID/PID
    invoke-virtual {p0}, Landroid/hardware/usb/UsbDevice;->getVendorId()I
    # ... compara con 0x2E8A
    
    # Verifica Product ID
    invoke-virtual {p0}, Landroid/hardware/usb/UsbDevice;->getProductId()I
    # ... compara con 0x000A
    
    # Verifica interfaces
    invoke-virtual {p0}, Landroid/hardware/usb/UsbDevice;->getInterfaceCount()I
    # ... debe ser >= 2
    
    # Verifica clase de interfaz
    invoke-virtual {v1}, Landroid/hardware/usb/UsbInterface;->getInterfaceClass()I
    # ... debe ser 0x02 (CDC)
```

**Criterios de detección:**
1. `vendorId == 0x2E8A`
2. `productId == 0x000A`
3. `interfaceCount >= 2`
4. Al menos una interfaz con `interfaceClass == 0x02`

---

## Flujo de Inicialización

### Código: `P0/d.smali` constructor

```smali
.method public constructor <init>(Landroid/hardware/usb/UsbDevice;Landroid/hardware/usb/UsbDeviceConnection;I)V
    .locals 0
    iput p3, p0, LP0/d;->g:I
    packed-switch p3, :pswitch_data_0
```

El parámetro `g:I` es un modo de operación:
- `0x1` = Modo normal (Pico/Pico W)
- Otros valores = Modos especiales (FScope, DSO-500K)

### Secuencia de Setup

1. **Claim Interface 0** (CDC-Control)
   - `claimInterface(iface0, true)`
   - Configura EP1 IN (Interrupt) para notificaciones

2. **Claim Interface 1** (CDC-Data)
   - `claimInterface(iface1, true)`
   - Configura EP2 OUT y EP2 IN (Bulk)

3. **Inicializar UsbRequest**
   - TX: UsbRequest en EP2 OUT (`j`)
   - RX: UsbRequest en EP2 IN (`k`)

4. **Control Transfers Iniciales**
   - `controlTransfer(0x40, request, value, 0, null, 0, 0)`
   - Lectura de configuración del dispositivo

---

## Comandos de Control Identificados

### Vendor Requests (método `r(III)I`)

| Request | Value | Interpretación |
|---------|-------|----------------|
| `0x9a` | `0x1312` | Set sample rate |
| `0x9a` | `0xf2c` | Get sample rate |
| `0x9a` | `0x1311` | Set trigger |
| `0x9a` | `0x9f` | Set channel range |
| `0x9a` | `0xee` | Get device info |
| Otros | Variables | Configuración avanzada |

### Nota sobre 0x9a

`0x9a` = 154 decimal = `0b10011010`
- Bit 7 = 1 (DEVICE_TO_HOST)
- Bit 6-5 = 01 (VENDOR_TYPE)
- Bits 4-0 = 01010 (recipient = device?)

---

## Timeouts de Transferencia

| Contexto | Timeout |
|----------|---------|
| Control transfer | 0 ms |
| Bulk transfer RX | 0 ms (blocking) |
| Espera de datos | 10 segundos (0x2710) |
| Reintento WiFi | 10 segundos |

---

## Thread de Recepción (RX)

### Código: `P0/h.smali` método `a()V`

```smali
.method public final a()V
    .locals 8
    # Esperar en monitor hasta haber datos
    invoke-virtual {v0}, Ljava/lang/Object;->wait()V
    
    # Leer hasta 0x4000 (16384) bytes
    const-wide/16 v4, 0x4000
    invoke-virtual {v1, v4, v5}, LI2/a;->a(J)[B
    
    # Enviar por bulkTransfer
    invoke-virtual {v0, v2, v1, v3, v7}, Landroid/hardware/usb/UsbDeviceConnection;->bulkTransfer(...)
```

**Comportamiento:**
- Espera en un monitor hasta que hay datos disponibles
- Lee bloques de hasta 16KB
- Envía por EP2 IN usando bulkTransfer síncrono

---

## Campos de Configuración

### Desde `P0/d.smali` array_0

```smali
:array_0
    .array-data 1
        0x1t    # 1
        0x0t    # 0
        0x0t    # 0
        0x0t    # 0
        0x40t   # 64
        0x0t    # 0
        0x0t    # 0
        0x0t    # 0
        0x0t    # 0
        -0x80t  # -128 (0x80)
        0x0t    # 0
        0x0t    # 0
        0x0t    # 0
        0x20t   # 32
        0x0t    # 0
        0x0t    # 0
    .end array-data
```

**Interpretación:** Configuración de endpoints:
- Byte 0: 1 = número de interfaz?
- Byte 4: 64 = max packet size
- Byte 9: -128 (0x80) = dirección IN
- Byte 13: 32 = intervalo?

---

## Métodos de Control Transfer

### method q([B)I - Lectura de datos (IN)
```smali
const/16 v1, 0xc0    # requestType
const/16 v2, 0x95    # request
const/16 v3, 0x706   # value
controlTransfer(0xc0, 0x95, 0x706, iface, buffer, len, 0)
```
**Uso:** Lectura de datos del dispositivo (ej: respuesta a comandos)

### method p([BII)I - Escritura de datos (OUT)
```smali
const/16 v2, 0x41    # requestType
controlTransfer(0x41, request, value, iface, buffer, len, 0)
```
**Uso:** Envío de datos al dispositivo

### method n()S - Lectura de estado
```smali
const/16 v1, 0xc1    # requestType
const/4 v2, 0x4      # request (GET_LINE_CODING)
controlTransfer(0xc1, 0x4, 0, iface, buffer, 2, 0)
```
**Retorna:** short = (buffer[1] << 8) | buffer[0]

**Uso:** Leer estado actual de line coding (CDC-ACM)

### method m(String, int[]) - Wrapper con logging
```smali
# Convierte int[] a byte[]
# Llama a q() para enviar
# Compara longitud de respuesta
# Loggea resultado con tag "d"
```

---

## Manipulación de Line Coding (CDC-ACM)

### Código: `P0/d.smali` método k() y métodos relacionados

```smali
# 1. Leer estado actual
invoke-virtual {p0}, LP0/d;->n()S
move-result v0

# 2. Modificar bits (ej: establecer baud rate)
and-int/lit16 v0, v0, -0xf01    # Limpiar bits 8-12
or-int/lit16 v0, v0, 0x800      # Establecer bit 11
int-to-short v0, v0

# 3. Escribir de vuelta
const/4 v1, 0x3                 # length = 3
const/4 v2, 0x0                 # offset = 0
invoke-virtual {p0, v2, v1, v0}, LP0/d;->p([BII)I
```

**Patrón:**
- Leer 2 bytes de estado
- Modificar bits específicos (máscaras variables)
- Escribir 3 bytes de vuelta (¿incluye algo más?)

---

## Comandos Vendor Específicos (Scoppy)

### Formato de comando
```smali
# Todos los comandos usan method o(II)
invoke-virtual {p0, command_code, value}, LP0/d;->o(II)I
```

### Traducción a USB
```smali
# method o(II) hace:
1. controlTransfer(0x40, 0x9a, 0x1312, command_code, null, 0, 0)
2. controlTransfer(0x40, 0x9a, 0xf2c, value, null, 0, 0)
```

### Códigos de comando identificados

| Código (hex) | Value | Segundo param | Contexto | Uso inferido |
|--------------|-------|---------------|----------|--------------|
| `0x6481` | 0x76 | - | Sample rate 600-1200 | Set sample rate bajo |
| `0x6482` | variable | - | Get sample rate | Obtener sample rate actual |
| `0x6483` | - | - | Get device info | Obtener información del dispositivo |
| `0x9883` | variable | - | Config avanzada | Configuración avanzada |
| `0xcc83` | variable | - | Premium features | Funciones premium/unlock |
| `0xb281` | 0x3b | - | Sample rate alta | Set sample rate alto (0xb281) |
| `0xd980` | 0xeb | - | Sample rate media | Set sample rate medio |
| `0xd981` | variable | - | Sample rate | Set sample rate específico |
| `0xd982` | variable | - | Sample rate | Set sample rate específico |

### Patrón de detección de sample rate

El código muestra que el APK detecta automáticamente el rango de sample rate soportado:

```smali
if-le p1, v5, :cond_1
if-gt p1, v6, :cond_1
    const p1, 0xd980    # Command for this rate range
    const/16 v1, 0xeb
    invoke-virtual {p0, p1, v1}, LP0/d;->o(II)I
```

**Rangos detectados:**
- 600-1200: 0x6481
- 1200-3000: 0xb281
- 3000-5000: 0xd980
- 5000-10000: 0xd981
- 10000-50000: 0xd982
- 50000-100000: 0x9883
- 100000-200000: 0xcc83
- >200000: ?

---

## Estructura de Paquetes Bulk

### RX (EP2 IN) - P0/h.smali

```smali
# Leer hasta 16KB por transferencia
const-wide/16 v4, 0x4000
invoke-virtual {v1, v4, v5}, LI2/a;->a(J)[B

# Enviar por bulkTransfer
invoke-virtual {v0, v2, v1, v3, v7}, Landroid/hardware/usb/UsbDeviceConnection;->bulkTransfer(
    endpoint, buffer, length, 0)
```

**Tamaño máximo:** 16384 bytes (0x4000)
**Timeout:** 0 (blocking)

### TX (EP2 OUT) - No implementado en P0/h

Las escrituras se hacen via control transfers, no bulk.

---

## Formato de Datos de Muestreo

### Inferido desde buffers y constantes

| Parámetro | Valor | Observaciones |
|-----------|-------|---------------|
| Max TX/RX bulk | 16384 bytes | 0x4000 |
| Buffer de cola | variable | LI2/a es un buffer circular |
| Muestras por paquete | 8192 (12-bit) | 8192 × 2 bytes = 16384 |
| Muestras por paquete | 16384 (8-bit) | 16384 × 1 byte = 16384 |
| Resolución ADC | 12-bit | Según documentación oficial |

### Estructura de muestra (12-bit)

```
Byte 0: [sample7..sample0]  (8 bits)
Byte 1: [sample11..sample8] (4 bits) + [next sample bits]
```

O alternativamente:
```
Byte 0: Sample N (low byte)
Byte 1: Sample N (high 4 bits) + Sample N+1 (low 4 bits)
Byte 2: Sample N+1 (high 4 bits) + ...
```

---

## Flujo de Inicialización USB

### Secuencia completa

1. **Detección de dispositivo**
   - O0/c verifica VID=0x2E8A, PID=0x000A
   - Verifica interfaceCount >= 2
   - Verifica interfaceClass == 0x02 (CDC)

2. **Claim Interface 0** (CDC Control)
   - Configura EP1 IN (Interrupt, 8 bytes, intervalo 16ms)
   - Notificaciones de estado

3. **Claim Interface 1** (CDC Data)
   - Configura EP2 OUT (Bulk, 64 bytes)
   - Configura EP2 IN (Bulk, 64 bytes)

4. **Inicialización de endpoints**
   - TX: UsbRequest en EP2 OUT (j)
   - RX: UsbRequest en EP2 IN (k)

5. **Control transfers iniciales**
   - SET_LINE_CODING (si es necesario)
   - SET_CONTROL_LINE_STATE
   - Comando de inicialización específico de Scoppy

6. **Inicio de recepción**
   - Thread RX espera en monitor
   - bulkTransfer bloqueante en EP2 IN

---

## Constantes de Configuración

### Line Coding (CDC-ACM)

| Parámetro | Valor típico | Observaciones |
|-----------|--------------|---------------|
| Baud rate | 0x1388 (5000) | Variable según sample rate |
| Stop bits | 1 | 0=1, 1=1.5, 2=2 |
| Parity | None | 0=None, 1=Odd, 2=Even |
| Data bits | 8 | 5-8 |

### Timeouts

| Contexto | Timeout |
|----------|---------|
| Control transfer | 0 ms |
| Bulk transfer RX | 0 ms (blocking) |
| Espera de datos | 10 segundos |
| Reintento WiFi | 10 segundos |

---

## Correlación Firmware ↔ APK

### Request codes que probablemente implementa el firmware

| APK Request | Firmware probable | Función |
|-------------|-------------------|---------|
| 0x9a (bRequest) | Handler vendor | Dispatch de comandos |
| 0x1312 (wValue) | - | Set command |
| 0xf2c (wValue) | - | Get command |
| 0x95 (bRequest) | - | Lectura específica |
| 0x4 (bRequest) | GET_LINE_CODING | Estado CDC |

### Próximos pasos de análisis

1. Buscar en firmware `0x9a`, `0x1312`, `0xf2c` en código ARM
2. Analizar handler de vendor requests en USB stack
3. Correlacionar con handler de control transfers
4. Extraer formato de muestras desde firmware

