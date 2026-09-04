# Report

Informe de estado del proyecto **Scoppy** (réplica Flutter del osciloscopio).

## Resumen

Este proyecto documenta y replica el comportamiento del osciloscopio **Scoppy**
(app Android `xyz.fhdm.scoppy`) acoplado a una Raspberry Pi **Pico/Pico W**.
Incluye la **ingeniería inversa** del protocolo binario App ↔ Pico y una **app
Flutter** que busca replicar la funcionalidad.

## Estado (2026-09)

**Documentación**
- Documentado el protocolo binario: framing `0xFF`, opcodes 60-63 (Pico→App) y
  80-92 (App→Pico), puertos WiFi 22483/22484, USB VID 0x2E8A.
- Documentada la funcionalidad (trigger, timebase, medidas, FFT, math, XY),
  el hardware (GPIO, sample rates, voltage ranges, AFE) y el signal generator.

**Código (app Flutter)**
- Core de protocolo (encoder/decoder), transporte WiFi, ViewModel (Provider),
  painter de rejilla 10x8 y cálculo de mediciones.
- Pendiente: transporte USB, pruebas unitarias y funcionalidad avanzada
  (FFT, math, analizador lógico, cursores).

## Activos de referencia

- Docs RE: `docs/PROTOCOLO_SCOPPY.md`, `docs/REFERENCIA_HARDWARE_PICO.md`,
  `docs/REFERENCIA_FUNCIONALIDAD.md`.
- Esquemas AFE: `docs/*.png`.
- Proyecto: `app/`.

## Bloqueantes / pendientes

1. Decodificar la **trama SYNC de 41 B** (TODO.md) para mapear los campos del
   opcode 60 con la clase `V2/C0078f`.
2. Validar end-to-end contra una Pico real (RUN → stream 61 → render).
3. Transporte USB serial (usb_serial) y pruebas unitarias.

## Riesgos

- La documentación de protocolo USB antigua (`pico_docs/`) es especulativa;
  el protocolo real verificado está en `PROTOCOLO_SCOPPY.md`.
- Los opcodes de muestras (61) dependen de la trama SYNC (aún pendiente).