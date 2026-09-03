# Scoppy — Documentación

Repositorio de documentación sobre **Scoppy**, el osciloscopio/analizador lógico
que convierte una Raspberry Pi **Pico (W / 2 / 2 W)** en un osciloscopio controlado
por una app Android.

Este repositorio contiene la documentación de ingeniería inversa generada en
`flutter_docs/`, con el objetivo de **replicar** la aplicación.

## Rama `flutter_for_pico`

La documentación está alojada en la rama **[`flutter_for_pico`](../../tree/flutter_for_pico)**,
bajo `flutter_docs/docs/`:

| Archivo | Contenido |
|---|---|
| `PROTOCOLO_SCOPPY.md` | Protocolo binario App↔Pico verificado por RE (opcodes 60–63/80–92, framing 0xFF, puertos 22483/22484) |
| `REFERENCIA_HARDWARE_PICO.md` | Pinout GPIO, sample rates ADC/overclock, voltage ranges, signal generator, firmwares v18/v19 |
| `REFERENCIA_FUNCIONALIDAD.md` | Comportamiento de la app a replicar (trigger, timebase, medidas, FFT, math, XY, premium) |
| `SKILL.md` | Resumen del skill de RE (transportes, trama, opcodes, verificación en vivo) |
| `TODO.md` | Tareas pendientes de RE |
| `*.png / *.webp / *.jpeg` | Esquemas e imágenes del Analog Front-End |

> Nota: `flutter_docs/apk_analysis/` (APK y código descompilado de la app original)
> **no** se publica en este repositorio.
