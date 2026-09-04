# Roadmap

Hoja de ruta del proyecto **Scoppy** (réplica Flutter).

## Hito 1 — Núcleo (en curso)

- [x] Prototipo de la rejilla 10x8 + waveform con CustomPainter.
- [x] Codificador/decodificador de tramas binarias (opcodes 60-63/80-92).
- [x] Transporte WiFi (TCP 22483/22484) y ViewModel con Provider.
- [x] Cálculo de mediciones (Vmin/Vmax/Vpp/Mean/DC-RMS/AC-RMS/Freq/Duty).
- [ ] Conexión USB serial (usb_serial) — transporte USB.
- [ ] Pruebas unitarias del protocolo y de las mediciones.

## Hito 2 — Funcionalidad del osciloscopio

- [ ] Trigger completo: tipos rising/falling, niveles, pre-trigger (50 %).
- [ ] Modos RUN/STOP/SINGLE con sample-rate fijo/auto y timebase completo.
- [ ] Interpolación Sin(x)/x para timebases cortas.
- [ ] Voltage ranges por canal (auto/manual).
- [ ] Signal generator screen (square/sine PWM).

## Hito 3 — Analizador lógico y avanzado

- [ ] Modo analizador lógico (8 canales, GPIO 6-13).
- [ ] Cursores XY.
- [ ] FFT (unidades dBm/dBmV/V).
- [ ] Math channels (7 unarias + 4 binarias).
- [ ] Export CSV de muestras.

## Hito 4 — Robustez y distribución

- [ ] Reconexión con backoff, manejo de una sola sesión de control.
- [ ] Pruebas contra hardware real (Pico W v18/v19).
- [ ] AAB para Google Play + versionado con tags (ver LEARNINGS.md).