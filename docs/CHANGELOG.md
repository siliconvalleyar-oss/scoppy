# Changelog

Historial de cambios del proyecto **Scoppy**.

La versión vive en el archivo `VERSION` (raíz) y los tags llevan `v`
(`VERSION` = `1.x.y`, tag = `v1.x.y`). El ciclo de patches es 0-9 (ver
[LEARNINGS.md](LEARNINGS.md)).

## [1.0.0] — 2026-09-03

### Añadido
- Repositorio `scoppy` con documentación de ingeniería inversa.
- Docs RE: `PROTOCOLO_SCOPPY.md`, `REFERENCIA_HARDWARE_PICO.md`,
  `REFERENCIA_FUNCIONALIDAD.md`, `SKILL.md`, `TODO.md`.
- Documentación completa del proyecto en `docs/`.
- App Flutter de réplica en `app/`:
  - Core de protocolo binario (encoder/decoder, opcodes 60-63/80-92).
  - Transporte WiFi (TCP 22483/22484).
  - ViewModel (Provider/ChangeNotifier).
  - Painter de rejilla 10x8 + waveform.
  - Cálculo de mediciones (Vmin/Vmax/Vpp/Mean/DC-RMS/AC-RMS/Freq/Duty).
- Rama `flutter_for_pico` como rama principal de trabajo del Flutter.