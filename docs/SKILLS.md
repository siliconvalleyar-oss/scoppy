# Skills

Habilidades y conocimientos asociados al proyecto **Scoppy**.

## Conocimiento de dominio

El proyecto se apoya en un **skill de ingeniería inversa** documentado en
[SKILL.md](SKILL.md). Cubre:

- Análisis de la app Android `xyz.fhdm.scoppy` v1.031.
- Firmware `scoppy-pico(-w)-v18` y `scoppy-pico2(-w)-v19`.
- Protocolo binario App ↔ Pico (framing `0xFF`, opcodes 60-63/80-92,
  puertos 22483/22484, USB VID 0x2E8A).
- Compra in-app / premium (`scoppy.premium.lifetime` / `subscription`).

## Skills técnicos requeridos

| Área | Conocimiento |
|------|--------------|
| Flutter/Dart | Widgets, `CustomPainter`, `StreamController`, `Provider`/`ChangeNotifier`. |
| Redes | TCP (control/datos), modo AP/station de la Pico W. |
| USB | UsbSerial / USB host (Android), CDC-ACM. |
| Señales | Osciloscopio (trigger, timebase, volt/div, medidas), FFT, math, XY. |
| RE/Android | jadx, apktool, smali, apkanalyzer (para revisar la app real). |

## Flujo recomendado de trabajo

1. `apkanalyzer manifest print base.apk` → paquete/versión/permisos.
2. jadx a `decompiled/sources/`; si no decompila, leer el smali.
3. Localizar transporte activo (`V2/A` WiFi, `V2/J` USB) y verificar bytes.
4. Contrastar contra el firmware real y la red en vivo.
5. Documentar en `docs/`.

## Referencias cruzadas

- Protocolo: [PROTOCOLO_SCOPPY.md](PROTOCOLO_SCOPPY.md)
- Funcionalidad: [REFERENCIA_FUNCIONALIDAD.md](REFERENCIA_FUNCIONALIDAD.md)
- Hardware: [REFERENCIA_HARDWARE_PICO.md](REFERENCIA_HARDWARE_PICO.md)