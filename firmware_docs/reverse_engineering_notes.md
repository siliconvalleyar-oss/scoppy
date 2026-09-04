# Notas de Ingeniería Inversa - Firmware Scoppy v18

## Metodología

### Herramientas Utilizadas

| Herramienta | Uso |
|-------------|-----|
| `file` | Identificación del formato UF2 |
| `xxd` / `hexdump` | Análisis hexadecimal del UF2 |
| `strings` | Extracción de strings del firmware |
| Python 3 (struct) | Parseo de estructuras binarias |
| UF2 parser custom | Extracción del payload ARM bare-metal |
| APK analysis (apktool) | Análisis del APK Android complementario |

### Limitaciones

- No se dispone de firmware ELF completo (solo raw binary desde UF2)
- No se utilizó `binwalk`, `radare2`, `ghidra` o `GNU objdump` (no disponibles)
- El análisis se realizó estáticamente sobre el payload binario
- No se realizó debugging JTAG/SWD en tiempo de ejecución

---

## Hallazgos del Análisis del UF2

### Estructura No-Estándar

El archivo UF2 tiene desviaciones del formato estándar de Microsoft:

```python
# Layout estándar vs. observado en scoppy-picow-v18.uf2
# offset 0x10 (block_num):   0x00000100 (256)  → No es el número de bloque real
# offset 0x14 (total_blocks): 0x00000000 (0)    → No se usa
# offset 0x18:               0x00000600 (1536) → VERDADERO total de bloques
```

### Payload del Firmware

- **Tamaño**: 731,136 bytes (737,280 bytes brutos del UF2, 476 bytes por bloque útil)
- **Formato**: Binario ARM Thumb-2 (bare-metal)
- **Sin ELF header**: Código cargado en dirección 0x10000000 por el bootROM RP2040
- **Punto de entrada**: Primeras instrucciones ARM en offset 0x0000 del payload

---

## Hallazgos de USB

### Device Descriptor

Offset en firmware: `0x45330`

```
12 01 00 02 EF 02 01 40 8A 2E 0A 00 00 01 01 02 03 01
```

### Configuration Descriptor Set

Offset en firmware: `0x452E4` (75 bytes)

Incluye:
- Configuración con 2 interfaces
- IAD (Interface Association Descriptor) para CDC
- 4 descriptores funcionales CDC (Header, Call Management, ACM, Union)
- 3 endpoints (1 interrupt + 2 bulk)

---

## Hallazgos del APK Android

El APK (`base.apk`) decompilado con apktool revela:

### Información de Versión

| Campo | Valor |
|-------|-------|
| App name | `scoppy-pico` / `scoppy-pico-wireless` |
| Device names | `FSCOPE/DSO-500K (Pico)`, `FSCOPE/DSO-500K (Pico W)` |
| Firmware version | v18 (Pico), v19 (Pico 2) |
| Build config | `default 1` |

### Productos In-App

```
scoppy.premium.lifetime      → Pago único premium
scoppy.premium.subscription  → Suscripción premium
```

### Código Fuente del Proyecto

```
https://github.com/fhdm-dev/scoppy
https://oscilloscope.fhdm.xyz
```

---

## Strings Relevantes del Firmware

### Inicialización

```
Initialising USB
Initialising ADC
Initialising SMPS
Initialising LEDs
Initialising voltage range gpios
build config: default 1
scoppy-picow-v18
Could not find saved scoppy config
```

### WiFi

```
WiFi: Enabling Access Point mode
WiFi: Enabling Client/Station mode
WiFi: Start connecting: auth=%s
WiFi: Connected
WiFi: AP MAC addr=%02X.%02X.%02X.%02X.%02X.%02X
WiFi: AP IP addr=%u.%u.%u.%u
WiFi-CYW43
```

### Configuración

```
scoppy-%.2x%.2x%.2x%.2x%.2x%.2x%.2x%.2x"
SCOPPY-%.2X%02X%02X%02X%02X%02X%02X%02X"
------- Configuration settings ------
WiFi AP Mode SSID: %s
WiFi AP Mode PW is set
WiFi AP Mode Auth Type: %s (%u)
Channels
Access Code: %s
```

### Osciloscopio

```
Trigger LED
Logic Analyser Last Channel
Logic Analyser First Channel
CH2 ADC
CH1 ADC
selected sample rate=%lx
pre-trigger samples=%lx
invalid trigger mode=%d
invalid trigger_channel=%d
invalid trigger type=%d
Trigger. mode=%u, ch=%u, type=%u, level=%d
voltage range for channel %u=%u
TRIG ADDR NOT IN BUFFER: trigger_addr=%lx, offset=%ld
```

---

## Información de Hardware del RP2040

### Pines Utilizados

| Función | GPIO RP2040 |
|---------|-------------|
| ADC0 (CH1) | GPIO26 |
| ADC1 (CH2) | GPIO27 |
| Trigger LED | GPIO (configurable) |
| WiFi Status LED | GPIO (CYW43 controla) |
| SMPS | GPIO23 (control) |

### Memoria RP2040

| Región | Dirección | Tamaño |
|--------|-----------|--------|
| Flash | 0x10000000 | 2 MB |
| SRAM0 | 0x20000000 | 240 KB |
| SRAM1 | 0x21000000 | 24 KB |
| USB | 0x50110000 | USB controller |

---

## Limitaciones del Análisis Actual

1. **No se analizaron** los archivos UF2 para Pico 2 (v19)
2. **No se decodificó** el formato exacto de los comandos USB (requiere tracing dinámico)
3. **No se identificó** el string descriptor del fabricante (podría ser generado en runtime)
4. **No se analizó** la sección de datos del APK (posiblemente protocolo adicional)
5. **No se hizo** dump de memoria del dispositivo conectado

---

## Próximos Pasos para Análisis Avanzado

1. **Debugging JTAG/SWD**: Conectar debugger y tracear comandos USB en vivo
2. **Wireshark + USBPcap**: Capturar tráfico USB entre Android y Pico
3. **Ghidra/radare2**: Análisis binario estático completo del ARM firmware
4. **RP2040 datasheet**: Mapeo de registros exacto de ADC, DMA, USB
5. **TinyUSB source**: Comparar con código fuente de TinyUSB (open source)
6. **fhdm-dev/scoppo GitHub**: Buscar código fuente del proyecto
