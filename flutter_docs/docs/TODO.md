# TODO — Trabajo futuro (Scoppy RE)

Checklist de tareas pendientes. Las `*.md` se guardan en `flutter_docs/`.

## Consolidación de documentación oficial (hecho 2026-09-03)
- [x] Leída íntegramente `scoppy_of_git/` (wiki + app-help + productos).
- [x] Creados `REFERENCIA_HARDWARE_PICO.md` y `REFERENCIA_FUNCIONALIDAD.md`.
- [x] Actualizado `PROTOCOLO_SCOPPY.md` con referencias cruzadas a los docs nuevos.

## Alta prioridad
- [ ] **Decodificar la trama SYNC de 41 B** de `192.168.4.1:22483`. Pasar el hex del usuario y mapear campo a campo con `V2/C0078f` (firmware type, versión, board ID, chip ID, MAC/IP WiFi, hardware DSO-500K/DSO20M, rangos).
- [ ] **Cliente Python mínimo contra la Pico**: conectar a `22483`, recibir SYNC (60/0x3C), enviar RUN (80/0x50) con MD5 `Err[45]:9397`, recibir stream 61/0x3D (samples shorts) y mostrarlo gráficamente. Confirma el protocolo end-to-end sin teléfono.

## Media prioridad
- [ ] **Capturar app↔Pico en vivo con PCAPdroid** (VPN local, sin root) en el teléfono conectado al AP Scoppy (192.168.4.16): validar mensajes reales de scope en el aire.
- [ ] **Analizar v19 (Pico 2)**: el puerto 22483 no aparece como literal `d3570000`; buscar variante de codificación/`htons` y dif marrones vs v18.
- [ ] **Buscar 22484 (0x57d4) en el firmware Pico-W v18** (solo 1 match solitario `57 d4` en `0x34e85`); confirmar uso de datos junto a control.
- [ ] **Revisar `pico_docs/*.md`** (protocolo USB 0x01-0x0B, empaquetado 10-bit) → verificarlas/descartarlas frente al protocolo real decodificado; actualizar o marcar como obsoletas.

## Baja prioridad
- [ ] Verificar si la Pico consume/requiere el **término 0x56** en respuestas SYNC y detallarlo en `PROTOCOLO_SCOPPY.md`.
- [ ] Documentar **`V2/A.d()` completo** (1673 líneas smali): resolución de IP AP vs LAN, mDNS `_scoppy._tcp`/`_scoppyx._tcp`, DHCP server → 192.168.4.1.
- [ ] Mapear **payload completo de RUN (80/0x50)** byte a byte (campos timebase, trigger 13 B, pre/post trigger) con pruebas en vivo.
- [ ] Analizar la **verificación de licencia cloud** (`config.txt`/`sync.txt`) y si las prefs `AEX01Z0HRA5492FG.3` pueden enumerarse.
- [ ] Probar **modo monitor** en la interfaz WiFi de la PC (compatibilidad tarjeta) como alternativa a PCAPdroid para capturar el payload en el aire.