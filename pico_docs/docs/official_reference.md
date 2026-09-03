# Documentación Oficial de Referencia - Scoppy Pico W

Esta carpeta contiene documentación generada por ingeniería inversa del firmware Scoppy para Raspberry Pi Pico W.
La documentación oficial de referencia se encuentra en la carpeta `scoppy_of_git/` del repositorio.

## Fuentes Oficiales

### Documentación del Proyecto
- **Repositorio oficial**: `scoppy_of_git/` (clonado de https://github.com/fhdm-dev/scoppy)
- **Wiki**: `scoppy_of_git/docs/wiki/`
- **Ayuda de la app**: `scoppy_of_git/docs/app-help/`
- **Sitio web**: https://oscilloscope.fhdm.xyz

### Archivos de Referencia Clave

#### GPIOs y Hardware
- `scoppy_of_git/docs/wiki/GPIOs.md` - Pinout completo del Pico W
- `scoppy_of_git/docs/wiki/Analog-Front-End.md` - Diseño de front-end analógico
- `scoppy_of_git/docs/wiki/front-end-design-1.md` - Diseño de front-end 1
- `scoppy_of_git/docs/wiki/front-end-design-2.md` - Diseño de front-end 2
- `scoppy_of_git/docs/wiki/front-end-design-3.md` - Diseño de front-end 3
- `scoppy_of_git/docs/wiki/front-end-design-4.md` - Diseño de front-end 4

#### Firmware y Versiones
- `scoppy_of_git/docs/wiki/firmware-versions.md` - URLs de descarga de firmware
- `scoppy_of_git/docs/wiki/ReleaseNotes.md` - Historial de versiones
- `scoppy_of_git/docs/wiki/Installation-&-Getting-Started.md` - Guía de instalación

#### Conexión WiFi
- `scoppy_of_git/docs/wiki/Getting-started-with-the-Pico-W.md` - Introducción al Pico W
- `scoppy_of_git/docs/wiki/WiFi-How-To.md` - Guía de conexión WiFi
- `scoppy_of_git/docs/wiki/WiFi-Troubleshooting.md` - Solución de problemas WiFi
- `scoppy_of_git/docs/app-help/WiFi-Connection-Settings.md` - Configuración de conexión WiFi

#### Configuración
- `scoppy_of_git/docs/app-help/firmware-connection-settings.md` - Configuración de conexión del firmware
- `scoppy_of_git/docs/app-help/firmware-gpio-settings.md` - Configuración de GPIOs del firmware
- `scoppy_of_git/docs/app-help/firmware-channel-settings.md` - Configuración de canales
- `scoppy_of_git/docs/app-help/rp2040-settings.md` - Configuración del RP2040
- `scoppy_of_git/docs/app-help/rp2040-max-sample-rate-setting.md` - Configuración de sample rate máximo

#### Uso de la App
- `scoppy_of_git/docs/app-help/index.md` - Índice de ayuda
- `scoppy_of_git/docs/app-help/Trigger-Oscilloscope.md` - Trigger en modo osciloscopio
- `scoppy_of_git/docs/app-help/Trigger-Logic-Analyzer.md` - Trigger en modo analizador lógico
- `scoppy_of_git/docs/app-help/Sample-Rate.md` - Configuración de sample rate
- `scoppy_of_git/docs/app-help/Voltage-Ranges.md` - Rango de voltajes
- `scoppy_of_git/docs/app-help/Cursors.md` - Uso de cursores
- `scoppy_of_git/docs/app-help/FFT.md` - Análisis FFT
- `scoppy_of_git/docs/app-help/Signal-Generator.md` - Generador de señales
- `scoppy_of_git/docs/app-help/Measurements.md` - Medidas en pantalla

## Información Relevante Extraída

### GPIOs del Firmware (Default)

| GPIO | Dirección | Función | Descripción |
|------|-----------|---------|-------------|
| 0, 1 | Output | UART TX/RX | Información de diagnóstico y errores |
| 2, 3 | Input - pulled down | CH1 Voltage Range | Rango de voltaje canal 1 (bits 0-1) |
| 4, 5 | Input - pulled down | CH2 Voltage Range | Rango de voltaje canal 2 (bits 0-1) |
| 6-13 | Input | Logic Analyzer | Entradas digitales (0V a 3.3V) |
| 14 | Output | WiFi Status LED | Estado de conexión WiFi |
| 15 | Output | Trigger LED | Indicador de trigger disparado |
| 22 | Output | Test Signal | PWM 1kHz 50% duty cycle |
| 26 | Input | CH1 ADC | Entrada analógica canal 1 |
| 27 | Input | CH2 ADC | Entrada analógica canal 2 |

### Modos de Operación

1. **Access Point (AP)**
   - SSID: `SCOPPY-<8-bytes-MAC-hex>` (ej: `SCOPPY-A1234BC5678DE12A`)
   - IP: `192.168.4.1`
   - Puerto discovery: `22483/TCP`
   - Sin internet para el cliente

2. **Station/Client (STA)**
   - Se conecta a red WiFi existente
   - Obtiene IP por DHCP
   - Usa mDNS para descubrimiento (`_scoppy._tcp` / `_scoppyx._tcp`)

### Sample Rate Máximo

| Configuración | Clock ADC | 1 Canal | 2 Canales |
|---------------|-----------|---------|-----------|
| 500 kS/s | 48 MHz | 500 kS/s | 250 kS/s |
| 1.3 MS/s | 125 MHz | 1.3 MS/s | 625 kS/s |
| 2.0 MS/s | 192 MHz | 2.0 MS/s | 1.0 MS/s |

> Nota: Los valores > 500 kS/s están fuera de especificación del RP2040 pero funcionan con impacto mínimo.

### Firmware Versiones

| Dispositivo | Firmware | URL |
|-------------|----------|-----|
| Pico | v18 | `scoppy-pico-v18.uf2` |
| Pico W | v18 | `scoppy-picow-v18.uf2` |
| Pico 2 | v19 | `scoppy-pico2-v19.uf2` |
| Pico 2 W | v19 | `scoppy-pico2w-v19.uf2` |

### Características por Versión

- **v7**: Falling edge trigger, Signal Generator, Run/Stop/Single buttons
- **v8**: On-screen measurements, Measurement Snapshot, CSV export
- **v9**: XY Mode, exact frequency in Signal Generator
- **v10**: FFT, Probe Settings, Cursor button moved
- **v11**: WiFi support (Pico W), Trigger swipe, picotool binary info
- **v14**: Sin(x)/x interpolation, GPIO mappings configurable, Voltage ranges stored on Pico, Reference voltage per range
- **v17+**: Max sample rate setting (500k/1.3M/2.0M)
- **v18**: Current version analyzed

### Configuración de Voltage Ranges

- Hasta 8 rangos por canal (0-7)
- Configuración almacenable en firmware o app
- GPIOs de rango: 2 bits por canal (GPIO 2-3 para CH1, GPIO 4-5 para CH2)
- Soporte para front-end inversor
- Vref configurable por rango (PWM)

### Conexión a la App

#### Métodos de Conexión (Station Mode)
1. **Auto**: Conecta al primer Pico W encontrado
2. **Scoppy device name**: Selecciona dispositivo específico
3. **IP address**: Conexión directa por IP conocida
4. **Access Code**: Control de acceso por código

#### Modo USB
- CDC-ACM (puerto COM virtual)
- Timeout de conexión: 10 segundos
- Si no hay conexión USB en 10s, pasa a modo WiFi

### Características de la App

- Modo Osciloscopio (YT)
- Modo Analizador Lógico (LA)
- Modo XY
- FFT
- Generador de señales
- Cursores
- Medidas en pantalla
- Exportación CSV
- Cursor rápido en LA (25 MS/s default, 38 MS/s con 2.0 MS/s)

## Notas de Ingeniería Inversa

### Hallazgos del Análisis Estático

1. **USB**: VID=0x2E8A, PID=0x000A, CDC-ACM composite
2. **Comandos**: Usa vendor requests (0x9a) en lugar de bulk transfers para comandos
3. **Datos**: Bulk transfers solo para recepción de muestras (EP2 IN)
4. **Discovery**: Servicio TCP en puerto 22483 con respuesta estática de 41 bytes
5. **WiFi**: CYW43439, stack lwIP, mDNS
6. **SSID**: Formato `SCOPPY-<8-bytes-MAC-hex>` con MAC completa de 8 bytes del CYW43

### Limitaciones del Análisis

- No se dispone de firmware ELF, solo payload binario
- No se usó Ghidra/radare2 para análisis profundo
- Protocolo binario requiere tracing dinámico para completar
- Servicio 22483 es solo beacon (no acepta comandos según análisis actual)
