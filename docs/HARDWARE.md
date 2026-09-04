# Hardware

Documentación de hardware del proyecto **Scoppy**. Consolida la información de
[REFERENCIA_HARDWARE_PICO.md](REFERENCIA_HARDWARE_PICO.md) para el lado
firmware/Pico y describe el **front-end analógico (AFE)** necesario.

## Placas soportadas

| Placa | ADC | Firmware | Conexión |
|-------|-----|----------|----------|
| Raspberry Pi Pico | RP2040 (2× ADC, 12-bit) | `scoppy-pico-v18.uf2` | USB |
| Raspberry Pi Pico W | RP2040 (2× ADC, 12-bit) + WiFi | `scoppy-picow-v18.uf2` | USB / WiFi |
| Raspberry Pi Pico 2 | RP2350 (2× ADC, 12-bit) | `scoppy-pico2-v19.uf2` | USB |
| Raspberry Pi Pico 2 W | RP2350 + WiFi | `scoppy-pico2w-v19.uf2` | USB / WiFi |

## GPIO del firmware (config "Default")

| GPIO | Dir | Función |
|------|-----|---------|
| 0, 1 | Out | UART TX/RX (diagnóstico) |
| 2, 3 | In (pulled-down) | CH1 Voltage Range (bits 0/1) |
| 4, 5 | In (pulled-down) | CH2 Voltage Range (bits 0/1) |
| 6–13 | In | Analizador lógico (8 canales, 0–3.3V) |
| 14 | Out | Wi-Fi Status LED |
| 15 | Out | Trigger LED |
| 22 | Out | Test signal (PWM 1 kHz 50 %) |
| 26 | In | CH1 ADC |
| 27 | In | CH2 ADC |

Los GPIO son reasignables desde la app (Firmware GPIO Settings).

## Muestreo ADC del RP2040

| Sample rate | ADC clock |
|-------------|-----------|
| 500 kS/s (default) | 48 MHz |
| 1.3 MS/s | 125 MHz (overclock) |
| 2.0 MS/s | 192 MHz (overclock) |

- 2 canales encendidos ⇒ rate a la mitad.
- Analizador lógico: 25 MS/s (default), 38 MS/s con ADC a 2.0 MS/s.

## Front-end analógico (AFE)

La práctica de entrada 0–3.3 V solo sirve para señales de bajo voltaje. Para
medir otros rangos se usa un AFE con:

- **Divisor de voltaje** (10 V, 20 V, 50 V máx. según resistencias).
- **Filtro anti-aliasing RC** (pasa-bajos).
- **Buffer de alta impedancia** con opamp (p. ej. TLV9062, MCP6002, LM358).
- **Level shift** para señales bipolares (offset a ~1.65 V).
- **Selección automática de rango** con los GPIO de Voltage Range.

Esquemas de referencia en `docs/` (`119-sch.png`, `schematic.png`,
`schematics_2.png`, `Schematic_Pi-Pico-Scoppy-AFE-Circuit-3*.png`).

## Voltage ranges

- Hasta **8 rangos por canal** (ids 0–7).
- Por rango se configuran: **Min. Voltage**, **Max. Voltage**, **Vref 1X** y
  **Vref 10X** (offset PWM).
- GPIOs de rango: hasta 3 por canal (bits 0–2 del "range id"). Default
  CH1=GPIO3/GPIO2, CH2=GPIO5/GPIO4.
- Modo **inputs** (selector mecánico) u **outputs** (la app controla un mux
  CD4052 → Auto Voltage Range).
- **Inverting AFE** para front-ends inversores.

## Signal generator

- PWM por GPIO 22 (configurable).
- Cuadrada: 100 Hz – 1.25 MHz (duty 50 %).
- Seno (PWM): duty modulado; frecuencia fija 1 kHz.