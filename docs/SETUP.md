# Configuración

Parámetros configurables de la app y del firmware.

## Configuración de la app (estado del osciloscopio)

| Parámetro | Descripción |
|-----------|-------------|
| `timebaseMs` | Timebase (ms/div), default 10 ms/div. |
| `horizontalDivs` | Divisiones horizontales de la ventana (default 10). |
| `triggerMode` | `off` (roll) / `auto` / `norm`. |
| `triggerChannel` | Canal de disparo (CH1/CH2). |
| `triggerEdge` | `rising` / `falling`. |
| `triggerLevel` | Nivel de disparo. |
| `preTriggerPercent` | % de muestras antes del disparo (default 50 %). |
| `sampleRate` | `500k` / `1M3` / `2M` / `2M5` (pref `"rp2040msr"`). |
| `channels[]` | Volt/div, offset, rango por canal. |

## Configuración del firmware (guardada en la Pico)

Accesible desde la app: *badge de conexión → Connected device → Firmware
settings*.

- **Connection**: Device Name, Wi-Fi Country, Wi-Fi Mode (AP/Station).
- **Channel**: voltage ranges por canal (Min/Max V, Vref 1X/10X).
- **GPIO**: reasignación de GPIO por función.

> El firmware sube sus settings y sobreescribe los de la app al conectar; el
> checkbox "Do not overwrite when device is connected" evita que lo pise.

## Detalle de opciones WiFi

- **Access Point**: SSID, contraseña, autorización.
- **Station/Client**: SSID, contraseña, autorización, **Scoppy Access Code**.
- Métodos de conexión en la app: Auto / Scoppy device name / IP address /
  Access Code.