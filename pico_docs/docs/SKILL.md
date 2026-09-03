# Skill: Scoppy Pico W - Ingeniería Inversa y Reversing

## Objetivo

Documentar y estructurar el conocimiento adquirido durante el análisis de ingeniería inversa del firmware Scoppy para Raspberry Pi Pico/Pico W, incluyendo:
- Análisis del firmware UF2
- Protocolo USB CDC-ACM
- Protocolo WiFi/mDNS
- Servicio de descubrimiento en red
- GPIOs, ADC, DMA, trigger
- Configuración y formatos

---

## Estructura de Documentación

### Directorios

```
scoppy/                          # Repositorio original del proyecto (documentación pública)
├── docs/
│   ├── wiki/                    # Wiki oficial: GPIOs, AFE, instalación, WiFi
│   └── app-help/                # Ayuda de la app: triggers, sample rates, voltage ranges

pico_docs/                       # Documentación generada por ingeniería inversa
├── firmware_analysis.md         # Análisis del UF2, estructura, offsets
├── usb_protocol.md              # Descriptores USB, endpoints, protocolo CDC-ACM
├── wifi_behavior.md             # SSID, AP/STA modes, mDNS, configuración
├── communication_protocol.md    # Comandos USB, formato de muestras, handshake
├── trigger_adc_buffer.md        # Trigger modes, ADC RP2040, DMA, buffer model
├── reverse_engineering_notes.md # Metodología, limitaciones, próximos pasos
├── quick_reference.md           # Resumen tabulado para replicación
├── live_device_probe.md         # Pruebas en dispositivo conectado (192.168.4.1:22483)
└── SKILL.md                     # Este archivo
```

---

## Metodología de Análisis

### 1. Análisis Estático de Firmware

**Herramientas:**
- `file`: Identificación de formato (UF2)
- `xxd`/`hexdump`: Análisis hexadecimal
- `strings`: Extracción de strings
- Python `struct`: Parseo de estructuras binarias
- Parser UF2 custom: Extracción de payload ARM bare-metal

**Limitaciones:**
- No se dispone de firmware ELF completo
- No se usó binwalk, radare2, Ghidra (no disponibles)
- Análisis puramente estático sobre payload binario

### 2. Análisis Dinámico en Dispositivo

**Herramientas:**
- `socket`: Escaneo de puertos TCP/UDP
- `nc`/`netcat`: Pruebas de conectividad
- Python sockets: Banner grabbing, payload testing

**Hallazgos clave:**
- Puerto 22483/TCP abierto en AP (192.168.4.1)
- Servicio beacon que devuelve 41 bytes fijos al conectar
- Contiene MAC address del dispositivo
- No requiere autenticación ni handshake

### 3. Análisis de APK Android

**Herramientas:**
- `apktool`: Decompilación de APK
- `grep`: Búsqueda de strings y patrones
- Análisis de smali

**Hallazgos clave:**
- Filtrado por VID=0x2E8A, PID=0x000A
- Verificación de interfaz CDC (class=0x02)
- Comandos USB: CMD/LEN/PAYLOAD
- Productos in-app: scoppy.premium.lifetime, scoppy.premium.subscription

---

## Protocolos Identificados

### USB (Canal Primario)

```
Device:  VID=0x2E8A, PID=0x000A
Class:   0xEF (IAD composite)
Config:  2 interfaces (CDC-Control + CDC-Data)
EP1 IN:  Interrupt, 8 bytes, interval 16
EP2 OUT: Bulk, 64 bytes (host → pico)
EP2 IN:  Bulk, 64 bytes (pico → host)
```

**Comandos USB:**
- 0x01: Set Sample Rate (uint32 LE Hz)
- 0x02: Set Trigger (ch, type, level)
- 0x03: Start Acquisition
- 0x04: Stop Acquisition
- 0x05: Set Channel Range
- 0x06: Get Device Info
- 0x07: Get Config
- 0x08: Set Config
- 0x09: Ping
- 0x0A: Access Code

### WiFi (Canal Alternativo)

```
SSID:    SCOPPY-<8-bytes-MAC-hex>
IP AP:   192.168.4.1
mDNS:    _scoppy._tcp / _scoppyx._tcp
Chip:    Cypress CYW43439
Stack:   CYW43 + lwIP
```

### Discovery Service (TCP 22483)

```
Host:    192.168.4.1
Port:    22483/TCP
Protocol: Custom binary beacon
Response: 41 bytes fixed (no request needed)
```

**Respuesta ejemplo:**
```
ff 00 29 3c 41 07 20 00 29 27 e6 61 4c 31 1b 85 20 39 03 12
35 38 63 14 00 00 28 cd c1 04 e6 7c 01 04 a8 c0 00 02 00 10 00
```

**Campos identificados:**
- Bytes 10-15: MAC address (e6:61:4c:31:1b:85)
- Bytes 16-19: Posible timestamp/versión
- Bytes 34-37: Posible IP address (formato big-endian parcial)

---

## Hardware RP2040

### GPIOs Utilizados

| GPIO | Función | Dirección |
|------|---------|-----------|
| 0, 1 | UART TX/RX (diagnóstico) | Output |
| 2, 3 | CH1 Voltage Range | Input (pull-down) |
| 4, 5 | CH2 Voltage Range | Input (pull-down) |
| 6-13 | Logic Analyzer inputs | Input |
| 14 | WiFi Status LED | Output |
| 15 | Trigger LED | Output |
| 22 | Test Signal (PWM 1kHz) | Output |
| 26 | CH1 ADC input | Input |
| 27 | CH2 ADC input | Input |

### ADC

- Resolución: 12-bit nativo, 10-bit usable en Scoppy
- Sample rate máx: 500 kS/s (datasheet), hasta 2 MS/s (overclock)
- Referencia: 3.3V
- Entradas: ADC0 (GPIO26), ADC1 (GPIO27)

### DMA

- 12 canales DMA disponibles
- Canales usados: DMA0 (ADC0→RAM), DMA1 (ADC1→RAM)
- Buffer circular para pre-trigger

---

## Comandos de Interés para Replicación

### Mínimo Viable

1. **USB CDC-ACM**: Implementar con TinyUSB en RP2040
2. **Descriptor USB**: Clonar el de 0x452E4 (75 bytes)
3. **Parser de comandos**: EP2 OUT, formato CMD/LEN/PAYLOAD
4. **ADC + DMA**: Configurar sampling y transferencia a buffer
5. **Streaming**: EP2 IN, paquetes de 64 bytes
6. **WiFi**: CYW43 en modo AP con SSID `SCOPPY-<MAC>`
7. **Discovery**: Servicio TCP en puerto 22483 con respuesta fija de 41 bytes

### Código Fuente de Referencia

- Repositorio: https://github.com/fhdm-dev/scoppy
- Wiki: https://oscilloscope.fhdm.xyz
- TinyUSB: https://github.com/hathach/tinyusb (open source, soporta RP2040 CDC-ACM)

---

## Lecciones Aprendidas

### Lo que funcionó

1. **Extracción de UF2**: El parser custom funcionó correctamente para extraer el payload ARM
2. **Búsqueda de descriptors USB**: Localizar el Device Descriptor por VID conocida (0x2e8a) fue efectivo
3. **Strings del firmware**: Reveló mucha información sobre protocolos y configuración
4. **Análisis de APK**: Complementó perfectamente el análisis estático del firmware

### Lo que no funcionó / Limitaciones

1. **UF2 no-estándar**: El formato de bloques difiere del estándar (block_num=256 constante)
2. **Sin ELF header**: El payload es raw binary, requiere análisis estático más complejo
3. **Herramientas limitadas**: Falta de Ghidra/radare2 para análisis profundo
4. **Protocolo binario opaco**: Los comandos exactos requieren tracing dinámico

### Próximos Pasos

1. **Captura de tráfico**: Wireshark + USBPcap para ver comandos USB reales
2. **JTAG/SWD debug**: Tracear firmware en ejecución
3. **Comparación con TinyUSB**: Analizar el stack USB usado
4. **Ingeniería inversa dinámica**: Fuzzing del servicio 22483
5. **Reimplementación**: Crear firmware clon basado en hallazgos

---

## Archivos de Documentación Generados

| Archivo | Descripción |
|---------|-------------|
| `firmware_analysis.md` | Estructura UF2, offsets clave, estadísticas |
| `usb_protocol.md` | Descriptores USB completos, endpoints, protocolo |
| `wifi_behavior.md` | SSID, modos AP/STA, mDNS, configuración |
| `communication_protocol.md` | Comandos USB, formato de muestras, handshake |
| `trigger_adc_buffer.md` | Trigger, ADC, DMA, buffer de captura |
| `reverse_engineering_notes.md` | Metodología, hallazgos, limitaciones |
| `quick_reference.md` | Resumen rápido para replicación |
| `live_device_probe.md` | Análisis del servicio en 192.168.4.1:22483 |

---

## Notas para Futuras Sesiones

- El APK contiene código Smali que puede ser re-analizado para extraer más detalles del protocolo
- El firmware UF2 puede ser analizado con herramientas más avanzadas si se dispone de ellas
- El servicio 22483 es un buen punto de entrada para debugging dinámico
- La documentación oficial en `scoppy/docs/` complementa el análisis de ingeniería inversa
- El repositorio original puede tener código fuente disponible para comparación
