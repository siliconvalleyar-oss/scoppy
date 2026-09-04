# Activity

Registro de actividad del proyecto **Scoppy**.

## Sesión 2026-09-03

- Creado el repositorio `siliconvalleyar-oss/scoppy` (público).
- Ramas:
  - `main` — README de presentación.
  - `flutter_for_pico` — documentación Flutter y app.
  - `scoppy_pico` — documentación del firmware (`pico_docs/`).
- Movida la documentación de `flutter_docs/docs/` a `docs/`.
- Completada la documentación de `docs/` (todos los `*.md`).
- Iniciada la **app Flutter** de réplica en `app/`:
  - Core de protocolo binario (encoder/decoder).
  - Transporte WiFi (TCP 22483/22484).
  - ViewModel (Provider), painter de rejilla 10x8, mediciones.

## Notas

- Todo **push** debe llevar su **tag** (ver `LEARNINGS.md`).
- Trabajo local en `app/`; documentación en `docs/`.

## Pendiente

- Decodificar la trama SYNC de 41 B (`TODO.md`).
- Conexión USB serial y pruebas unitarias.
- Validación end-to-end contra una Pico real.