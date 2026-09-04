# Trigger, ADC y Buffer de Captura - Firmware Scoppy (v18)

## Arquitectura de Adquisición

```
Canal 1 ADC ──► RP2040 ADC ──► DMA Controller ──► Sample Buffer (RAM)
Canal 2 ADC ──► RP2040 ADC ──► DMA Controller ──► Sample Buffer (RAM)
                                                      │
                              Trigger Engine ──────────┤
                              (hardware/software)       │
                                                      ▼
                                              USB EP2 IN Bulk
                                              (streaming al host)
```

---

## RP2040 ADC

### Características del ADC

| Parámetro | Valor |
|-----------|-------|
| **Resolución** | 12-bit nativo, usados **10 bits** en Scoppy |
| **Entradas** | ADC0 (GPIO26), ADC1 (GPIO27) |
| **Sample rate máx. (1 canal)** | 2 MS/s (con DMA, 1 muestras/ciclo) |
| **Sample rate máx. (2 canales)** | 1 MS/s (time-multiplexed) |
| **Referencia** | 3.3V (rango 0-3.3V) |

### Canales ADC en Firmware

```
CH1 ADC   → ADC0 (GPIO26)
CH2 ADC   → ADC1 (GPIO27)
```

### Rangos de Voltaje Soportados

| Rango | Voltaje (aprox.) | Uso |
|-------|-----------------|-----|
| 0 | ±10V | Bajo voltaje, alta sensibilidad |
| 1 | ±5V | |
| 2 | ±2V | |
| 3 | ±1V | Alta señal |
| ... | ... | (depende de attenuación hardware) |

> **Nota:** El firmware muestra: `voltage range for channel %u=%u`

---

## Configuración de Canales

### Parámetros por Canal

```
invalid num channels: %d          ← Error si se solicita >2 canales
voltage range for channel %u=%u   ← Canal 0 o 1, rango
```

### Modos de Operación

| Modo | Canales | Sample Rate | Bits |
|------|---------|-------------|------|
| Mono | 1 | Hasta 2 MS/s | 10 |
| Estéreo | 2 | Hasta 1 MS/s | 10 |
| Logic Analyser | 4-8 | Variable | 1 |

---

## Motor de Trigger

### Modos de Trigger

El firmware reporta estados de trigger:

```
invalid trigger mode: %d
invalid trigger_channel: %d
invalid trigger_type: %d
Trigger. mode=%u, ch=%u, type=%u, level=%d
Trigger LED                            ← LED indicador de trigger
```

### Tipos de Trigger

| Tipo | Valor | Descripción |
|------|-------|-------------|
| Rising | 0 | Flanco de subida |
| Falling | 1 | Flanco de bajada |
| Both | 2 | Cualquier flanco |
| Level | 3 | Nivel (threshold) |

### Canales de Trigger

| Canal | Valor | Fuente |
|-------|-------|--------|
| CH1 | 0 | ADC0 |
| CH2 | 1 | ADC1 |
| LA_CH0 | 2 | Logic Analyser canal 0 |
| LA_CH1 | 3 | Logic Analyser canal 1 |

### Trigger LED

```
Trigger LED    ← GPIO que se activa al detectar trigger
```

### Pre-Trigger

```
incorrect value for pre-trigger samples
pre-trigger samples=%lx
```

El número de muestras pre-trigger se configura en bytes (4 bytes, uint32 LE).

---

## Buffer de Captura

### Estructura del Buffer

```
+─────────────────────────────────────────────────┐
│             Sample Buffer (RAM)                 │
│  (RP2040 SRAM: 264 KB total)                    │
│                                                 │
│  ┌─────────────────────────────────────────┐   │
│  │  Pre-trigger samples (circular)         │   │
│  │  ← buffer se llena circularmente        │   │
│  │     antes del trigger                    │   │
│  └─────────────────────────────────────────┘   │
│                      ▼                          │
│  ┌─────────────────────────────────────────┐   │
│  │  Trigger point                          │   │
│  │  (dirección guardada: trigger_addr)     │   │
│  └─────────────────────────────────────────┘   │
│                      ▼                          │
│  ┌─────────────────────────────────────────┐   │
│  │  Post-trigger samples (DMA directo)     │   │
│  │  → Se envían por USB/WiFi               │   │
│  └─────────────────────────────────────────┘   │
└─────────────────────────────────────────────────┘
```

### Mensajes de Error del Buffer

```
TRIG ADDR NOT IN BUFFER: trigger_addr=%lx, offset=%ld
```

Este error ocurre cuando la dirección del trigger calculada cae fuera del rango del buffer asignado.

---

## DMA (Direct Memory Access)

### Configuración DMA

El RP2040 tiene 12 canales DMA independientes.

```
No DMA channels are available    ← Error si todos los canales están ocupados
```

### Canales DMA Utilizados

| Canal | Uso |
|-------|-----|
| DMA0 | ADC0 → RAM |
| DMA1 | ADC1 → RAM |
| DMA2-DMA11 | Disponibles (buffer circular, etc.) |

### Controlador DMA

```c
Failed to add adc re...    ← Error al registrar recurso ADC DMA
```

---

## Logic Analyser

El firmware también implementa un modo Logic Analyser:

```
Logic Analyser Last Channel    ← Último canal del LA
Logic Analyser First Channel   ← Primer canal del LA
```

### Canales Logic Analyser

| Canal | GPIO RP2040 |
|-------|-------------|
| LA_CH0 | Configurable |
| LA_CH1 | Configurable |
| LA_CH2 | Configurable |
| LA_CH3 | Configurable |
| LA_CH4 | Configurable |
| LA_CH5 | Configurable |
| LA_CH6 | Configurable |
| LA_CH7 | Configurable |

---

## Relación Sample Rate ↔ Tamaño de Buffer

### Cálculo de Tiempo de Captura

```
Tiempo (s) = (Muestras × 2 canales) / Sample Rate
```

| Sample Rate | Canales | Buffer (1 MB) | Tiempo Captura |
|-------------|---------|---------------|----------------|
| 1 kS/s | 1 | 1M muestras | 1000 s |
| 10 kS/s | 1 | 1M muestras | 100 s |
| 100 kS/s | 1 | 1M muestras | 10 s |
| 1 MS/s | 2 | 1M pares | 0.5 s |
| 2 MS/s | 1 | 1M muestras | 0.5 s |

### Configuración de Pre-Trigger

```c
pre-trigger samples=%lx   ← uint32, número de muestras antes del trigger
```

Ejemplo: `pre-trigger samples = 10000` con sample rate 1 MS/s = 10 ms de pre-trigger.

---

## Inicialización del ADC

```
Initialising ADC
CLK: curr_adc_clk_auxsrc=%lu, ctrl=%lX
Fatal error: code=%d
```

### Registros ADC RP2040

| Registro | Dirección | Uso |
|----------|-----------|-----|
| `ADC_CS` | 0x4004C000 | Control/Status |
| `ADC_RESULTS` | 0x4004C00C | Resultado de conversión |
| `ADC_FCS` | 0x4004C050 | FIFO control/status |
| `ADC_DEBUG` | 0x4004C078 | Debug |

---

## Diagrama de Flujo de Adquisición

```
                    ┌──────────────┐
                    │   Host       │
                    │  (Android)   │
                    └──────┬───────┘
                           │ CMD_START (0x03)
                           ▼
┌─────────────────────────────────────────┐
│           PICO W FIRMWARE               │
│                                         │
│  ┌─────────────┐    ┌───────────────┐  │
│  │  ADC HW     │───►│  DMA Channel  │  │
│  │  (12-bit)   │    │  (sample buf) │  │
│  └─────────────┘    └───────┬───────┘  │
│                             │            │
│                    ┌────────▼──────┐    │
│                    │  Trigger HW   │    │
│                    │  comparator   │    │
│                    └───────┬──────┘    │
│                            │            │
│                    Trigger Detect?       │
│                     NO → circular buf   │
│                     YES → freeze +      │
│                           send to USB   │
│                                         │
│  ┌─────────────────────────────────────┐│
│  │  TinyUSB CDC Task                   ││
│  │  - EP2 IN: streaming de muestras    ││
│  │  - EP2 OUT: comandos                ││
│  └─────────────────────────────────────┘│
└─────────────────────────────────────────┘
                           │
                           ▼
                    ┌──────────────┐
                    │   USB Host   │
                    │  (Android)   │
                    └──────────────┘
```

---

## Valores de Configuración Guardados

La configuración del osciloscopio se guarda en flash:

```
------- Configuration settings ------
```

La firma de la configuración guardada usa un magic number:
```
not scoppy config - unmatched magic 2
```

El magic number para configuraciones válidas es `2` (inferido del mensaje de error).

### Formato de Configuración (inferido)

```
[4 bytes] Magic: "SCOP" (0x53434F50)
[1 byte]  Versión de formato
[1 byte]  Modo preferido: 0x01=USB, 0x02=WiFi
[N bytes] Parámetros específicos
```

> **Nota:** El formato exacto del bloque de configuración requiere análisis adicional del código de lectura/escritura.
