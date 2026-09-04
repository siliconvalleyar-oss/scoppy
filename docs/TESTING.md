# Testing

Estrategia de pruebas del proyecto **Scoppy** (app Flutter).

## Niveles

1. **Unitarias** — lógica pura: codificador/decodificador de tramas y cálculo
   de mediciones. No requieren hardware.
2. **Widget** — pantalla del osciloscopio y widgets (con un transporte
   *fake*).
3. **Integración / manual** — contra una Pico real por USB o WiFi.

## Tests unitarios recomendados

```bash
cd app
flutter test                           # todos
flutter test test/measurement_test.dart  # de mediciones
flutter test test/protocol_test.dart     # de protocolo
```

### Casos clave

- **measurement_calculator**: Vmin/Vmax/Vpp sobre una onda conocida
  (p. ej. seno entre 1000 y 3000 ⇒ Volmax≈…, Vpp≈…); frecuencia y duty sobre
  una cuadrada sintética.
- **scoppy_decoder**: un frame completo `FF len opcode opcode+5 version
  payload` se extrae en un solo evento; un frame partido en dos chunks se
  ensambla; un opcode con confirmación inválida se descarta consumiendo el
  frame.
- **scoppy_frame_encoder**: el frame App→Pico termina en `0x56` y tiene el
  opcode+5 como confirmación.

## Pruebas manuales (contra la Pico)

- Conectar por WiFi a `192.168.4.1`, recibir SYNC, pulsar RUN y ver la onda.
- Cambiar timebase y trigger; verificar que las medidas se actualizan.
- Desconectar y reconectar.

## CI sugerida

- `flutter analyze`
- `flutter test`
- `flutter build apk --debug` (verificar build Android)