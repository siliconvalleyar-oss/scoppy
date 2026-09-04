# Diagramas

Diagramas ASCII del proyecto **Scoppy** (arquitectura, conexión y flujo de
captura). Para esquemas de hardware ver las imágenes en `docs/`.

## 1. Conexión física

```
                    USB (solo datos / alimentación)
        App Flutter  ───────►  Pico (VID 0x2E8A)
               │
               └╌╌ WiFi (Pico W):  TCP 22483 (control) / 22484 (datos) ╌╌►  Pico W
```

Modo AP de la Pico W: SSID `SCOPPY-<MAC>`, IP `192.168.4.1`.

## 2. Estado de la máquina de conexión

```
DISCONNECTED ──connect()──► CONNECTED ──SYNC(60)──► SYNCHRONISED
      ▲                                                     │
      └────────────────feedback de error/desconexión────────┘
```

## 3. Flujo de captura (RUN)

```
[UI] RUN ──► ViewModel ──► ScoppyClient
                              │
                              ├── sendChannelSetup (61)
                              ├── sendRun (80)
                              └── sendTriggerSettings (83)
                                            │
Pico muestrea (ADC/DMA) ◄──┘         ┌──────▼──────┐
      │                                    │  envío
      └────────────► data(61) ──► decoder ──► waveforms ─► painter ─► rejilla
```

## 4. Estructura de un frame

```
┌──────┬──────┬──────┬────────┬─────────┬─────────┬──────────┬────────────┐
│ 0xFF │ lenH │ lenL │ opcode │opcode+5 │ version │ payload  │ 0x56 (App) │
└──────┴──────┴──────┴────────┴─────────┴─────────┴──────────┴────────────┘
  sync      length(BE)   tipo    ack        ≥1
```

## 5. Componentes de la app

```
ScopyApp (MaterialApp)
 └─ ChangeNotifierProvider(ScopeViewModel)
     └─ OscilloscopeScreen
         ├─ _StatusBar        (sample rate, timebase, trigger)
         ├─ _ScopeCanvas      (ScopeGridPainter: rejilla 10x8 + waveforms)
         ├─ _MeasurementBar   (Vpp, Vmax, Vmin, Mean, Freq, Duty)
         └─ _ControlsBar      (RUN/STOP/SINGLE, timebase, trigger, canales)
```