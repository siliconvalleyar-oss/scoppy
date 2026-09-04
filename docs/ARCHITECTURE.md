# Architecture

Alto nivel del proyecto **Scoppy**: cómo se conecta la app con la Pico y cómo
está estructurado el código.

## Visión general

```
+---------------------+        binario Scoppy        +----------------------+
|   App Flutter       |  USB (0x2E8A) o  WiFi        |   Pico / Pico W      |
|  (cliente / scope)  |  <------------------------>  |  firmware v18/v19    |
+---------------------+   TCP 22483/22484            +----------------------+
```

- La app actúa como **cliente**: se conecta a la Pico y esta **toma la
  iniciativa** enviando el mensaje **SYNC (60)** al establecerse la sesión.
- El mismo parser de tramas procesa las conexiones USB y WiFi.

## Estado de la conexión

```
DISCONNECTED → CONNECTED → SYNCHRONISED
```

- **CONNECTED**: transporte establecido (socket/TCP).
- **SYNCHRONISED**: recibido el SYNC con información válida del frontend.

## Capas de la app (`app/lib/`)

1. **core/protocol** — codificación/decodificación de tramas y opcodes.
2. **core/transport** — transporte hacia la Pico (WiFi TCP; USB extensible).
3. **core/logic** — cálculo de mediciones del osciloscopio.
4. **core/scope_client.dart** — orquestación protocolo + transporte + estado.
5. **scope_viewmodel.dart** — ViewModel (`ChangeNotifier`) para la UI.
6. **ui/** — pantalla del osciloscopio, rejilla y controles.

## Flujo de datos

1. El usuario pulsa **RUN**.
2. La app envía: setup de canales (61), RUN (80), trigger (83).
3. La Pico muestrea (ADC/DMA) y envía tramas de datos de muestra (61).
4. El decodificador extrae los waveforms; el ViewModel recalcula medidas y
   notifica a la UI; el `CustomPainter` dibuja la onda en la rejilla 10×8.

## Gestión de estado

- `Provider` + `ChangeNotifier` (`ScopeViewModel`).
- `ScopeViewModel` consume `ScoppyClient` y expone `ScopeConfig`, medidas y
  estado de conexión.
- `ScoppyClient` mantiene los streams de eventos (SYNC, muestras, errores).