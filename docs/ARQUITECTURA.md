# Arquitectura

Vista de alto nivel del proyecto **Scoppy** (versión en español; ver también
[ARCHITECTURE.md](ARCHITECTURE.md)).

## Visión general

```
+---------------------+        protocolo binario     +----------------------+
|   App Flutter       |  USB (0x2E8A) o  WiFi        |   Pico / Pico W      |
|  (cliente / scope)  |  <------------------------>  |  firmware v18/v19    |
+---------------------+   TCP 22483/22484            +----------------------+
```

- La app es el **cliente**; la Pico envía el **SYNC (opcode 60)** al conectar.
- El mismo parser procesa USB y WiFi.

## Estados de conexión

```
DISCONNECTED → CONNECTED → SYNCHRONISED
```

- **CONNECTED**: transporte establecido.
- **SYNCHRONISED**: recibido el SYNC (frontend válido).

## Capas de la app (`app/lib/`)

1. **core/protocol** — construcción y parseo de tramas (opcodes 60-63/80-92).
2. **core/transport** — transporte hacia la Pico (WiFi TCP; USB extensible).
3. **core/logic** — mediciones (Vmin/Vmax/Vpp/Mean/DC-RMS/AC-RMS/Freq/Duty).
4. **core/scope_client.dart** — orquesta protocolo + transporte + estado.
5. **scope_viewmodel.dart** — ViewModel (`ChangeNotifier`) para la UI.
6. **ui/** — pantalla del osciloscopio (rejilla 10x8, controles, medidas).

## Flujo de datos

1. Usuario pulsa **RUN**.
2. App envía: setup canales (61), RUN (80), trigger (83).
3. Pico muestrea (ADC) y envía tramas de muestra (61).
4. El decodificador produce waveforms; el ViewModel recalcula medidas y
   notifica; el `CustomPainter` dibuja en la rejilla.

## Gestión de estado

- `Provider` + `ChangeNotifier` (`ScopeViewModel`).
- `ScopeViewModel` consume `ScoppyClient` y expone config, medidas y estado.
- `ScoppyClient` mantiene streams de eventos (SYNC, muestras, errores).