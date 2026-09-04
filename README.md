# Scoppy — Firmware C++ y Documentación

Repositorio de documentación y firmware para **Scoppy**, el osciloscopio/analizador lógico
que convierte una Raspberry Pi **Pico (W / 2 / 2 W)** en un osciloscopio controlado
por una app Android.

## Estructura

| Ruta | Contenido |
|---|---|
| `src/` | Código fuente C++ del firmware |
| `include/` | Headers públicos del firmware |
| `docs/` | Documentación técnica y TODO del proyecto |
| `pico_firmware_docs/` | Documentación generada por ingeniería inversa |
| `README.md` | Este archivo |

## Firmware C++

El firmware se implementa en C++17 sobre el **RP2040 SDK** con **TinyUSB** y **lwIP**.

### Módulos

| Módulo | Archivo | Función |
|--------|---------|---------|
| USB | `src/usb_descriptors.cpp`, `src/usb_handler.cpp` | Descriptores CDC-ACM, vendor requests, streaming |
| ADC/DMA | `src/adc_dma.cpp` | Sampling, buffer circular, trigger |
| WiFi | `src/wifi.cpp` | CYW43, modo AP/STA, DHCP |
| mDNS | `src/mdns.cpp` | Descubrimiento de dispositivos |
| TCP Server | `src/tcp_server.cpp` | Servicio discovery en puerto 22483 |
| Main | `src/main.cpp` | Punto de entrada y loop principal |

### Build

```bash
# Configurar proyecto
mkdir build && cd build
cmake ..

# Compilar
make -j4

# Generar UF2
make scoppy_firmware.uf2
```

## Documentación

La documentación oficial de referencia está en `pico_firmware_docs/` y proviene del
análisis de ingeniería inversa del firmware original.

### Archivos clave

| Archivo | Contenido |
|---|---|
| `pico_firmware_docs/usb_protocol.md` | Protocolo USB CDC-ACM, descriptores, endpoints |
| `pico_firmware_docs/usb_command_map.md` | Comandos USB, vendor requests, control transfers |
| `pico_firmware_docs/wifi_behavior.md` | SSID, modos AP/STA, mDNS |
| `pico_firmware_docs/communication_protocol.md` | Formato de comandos y muestras |
| `pico_firmware_docs/trigger_adc_buffer.md` | Trigger, ADC, DMA, buffer model |
| `pico_firmware_docs/live_device_probe.md` | Análisis del servicio 22483 en dispositivo real |
| `pico_firmware_docs/official_reference.md` | Documentación oficial cruzada de GPIOs, versiones, sample rates |
| `docs/TODO.md` | Tareas pendientes del proyecto C++ |
