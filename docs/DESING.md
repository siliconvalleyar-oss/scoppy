# Diseño (Design)

Notas de diseño de la app **Scoppy** (réplica Flutter).

## Principios de diseño

1. **Basarse en el protocolo RE** (binario): la app replica el comportamiento
   real de Scoppy, no una invención. Ver `PROTOCOLO_SCOPPY.md`.
2. **Separación de capas**: `core/` (protocolo, transporte, lógica) separado de
   `ui/` (widgets) y del `ViewModel`.
3. **Transporte intercambiable**: la UI depende de una interfaz
   (`ScoppyTransport`), de modo que se pueda cambiar WiFi por USB sin tocar la
   UI.
4. **Estado reactivo**: `Provider` + `ChangeNotifier` mantiene la UI sincronizada
   con el flujo de muestras.
5. **Medidas reales**: el cálculo de mediciones sigue las definiciones de
   `REFERENCIA_FUNCIONALIDAD.md` (Vmin/Vmax/Vpp/Mean/DC-RMS/AC-RMS/Freq/Duty).

## Decisiones clave

- **Rendering**: `CustomPainter` (CPU) para la rejilla 10x8 y las formas de
  onda; suficiente para la mayoría de usos sin GPU.
- **Framing**: se conserva el framing binario `0xFF + len + opcode + ack +
  version` documentado, incluyendo el terminador `0x56` en mensajes App→Pico.
- **Concurrencia**: `ScoppyClient` recolecta tramas desde el socket y emite
  eventos a través de `StreamController`; el ViewModel suscribe y recalcula.

## Alternativas consideradas

- **OpenGL / Impeller**: innecesario para el alcance inicial.
- **WebSocket JSON**: descartado por NO ser el protocolo real de Scoppy (el
  proyecto propio lo definía, pero la app real usa binario).