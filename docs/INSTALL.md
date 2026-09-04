# Instalación

Pasos para instalar la app y los entornos de desarrollo del proyecto **Scoppy**.

## 1. Firmware en la Pico

1. Pones la **Pico en modo BOOTSEL** (mantén BOOTSEL + conecta USB).
2. Copia el `.uf2` correspondiente al dispositivo (aparece como unidad USB):
   - Pico / Pico W: `scoppy-pico-v18.uf2` / `scoppy-picow-v18.uf2`
   - Pico 2 / 2 W: `scoppy-pico2-v19.uf2` / `scoppy-pico2w-v19.uf2`
3. Se reinicia y queda lista.

> Descargas: https://github.com/fhdm-dev/scpdl1 (carpetas `a/v18` y `a/v19`).

## 2. App Flutter (`app/`)

Requisitos:
- Flutter SDK (stable).
- Dispositivo Android con **soporte USB host** (para conexión por cable) o
  cliente WiFi para usar con la Pico W.

```bash
cd app
flutter pub get
flutter run
```

## 3. Conexión

- **USB**: conecta la Pico por cable al host. La app busca el dispositivo
  OTOH de serie (VID 0x2E8A).
- **WiFi (Pico W)**: conecta el dispositivo a la red `SCOPPY-<MAC>` (modo AP,
  IP `192.168.4.1`) o únete desde la app por *IP / device name / access code*.

## 4. Verificación rápida

1. Inicia la app y pulsa *Conectar*.
2. La Pico envía el mensaje **SYNC (opcode 60)** al conectar.
3. Pulsa **RUN** para capturar; la señal de prueba (GPIO 22, 1 kHz) debe verse
   si se conecta al canal 1.