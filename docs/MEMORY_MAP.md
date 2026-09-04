# Mapa de memoria

Detalle de los **buffers** y la **persistencia** implicados en la app y el
protocolo Scoppy.

## Buffer de entrada del frontend

El parser de la app mantiene un buffer de entrada de **64 kB** (`0xFA00`),
con lecturas big-endian de 1, 2, 4 y 8 bytes:

- `read1()` : 1 byte
- `read2()` : 2 bytes BE
- `read4()` : 4 bytes BE
- `read8()` : 8 bytes BE

Los frames completos se extraen según el encabezado; los opcodes fuera de
rango se descartan **consumiendo el frame completo**.

## Persistencia de configuración

| Clave / archivo | Contenido |
|-----------------|-----------|
| Pref `"rp2040msr"` | Sample rate máximo (500k/1M3/2M/2M5). |
| Settings del firmware | Voltage ranges y GPIO (guardados en flash de la Pico). |
| SharedPreferences (app) | `xyz.fhdm.scoppy_preferences` (compra premium, ver PROTOCOLO §8). |

## Bandas del waveform

- **SINGLE capture**: hasta **100k muestras** (menos si el rate tardara >10 s).
- **FFT en single**: **16k muestras**.
- **XY max.**: **1000 muestras** dibujadas.

## Rangos de voltaje (ADC)

| Concepto | Rango |
|----------|-------|
| ADC interno Pico | 12-bit (0–4095) |
| Valor de pico (CH1/CH2) | referido a 0–3.3 V (ADC_VREF) |
| Voltage ranges | ids 0–7 (hasta 8 por canal) |

## Notas

- La Pico guarda su config en flash con un **magic** (rechaza "unmatched
  magic 2"); los strings de GPIO/VR son visibles en el binario del `.uf2`.