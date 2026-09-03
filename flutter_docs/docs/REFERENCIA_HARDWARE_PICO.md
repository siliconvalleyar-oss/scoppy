# Referencia de Hardware — Pico / Pico W / Pico 2 (Scoppy)

Datos oficiales consolidados del repositorio `scoppy_of_git/` (documentación del
proyecto oficial, sin código) para replicar el lado firmware/Pico de Scoppy.
Junto con `PROTOCOLO_SCOPPY.md` (protocolo RE) y `REFERENCIA_FUNCIONALIDAD.md`
(comportamiento de la app).

> Fuente: `scoppy_of_git/docs/wiki/*` (GPIOs, firmware-versions, ReleaseNotes,
> rp2040-max-sample-rate-test-results, Analog-Front-End*).
> AVISO: la documentación oficial NO publica el firmware (binarios `.uf2`) ni el
> protocolo binario. Los `.uf2` v18/v19 están en `firnware_scoppy_for_pico/`.

---

## 1. Firmwares disponibles (urls de descarga oficiales)

Base: `https://github.com/fhdm-dev/scpdl1/raw/master/a/{v18|v19}/`

| Firmware | Placa | Carpeta |
|---|---|---|
| `scoppy-pico-v18.uf2` | Pico | v18 |
| `scoppy-picow-v18.uf2` | Pico W | v18 |
| `scoppy-pico2-v19.uf2` | Pico 2 | v19 |
| `scoppy-pico2w-v19.uf2` | Pico 2 W | v19 |
| `scoppy-fscope-500k-pico-v18.uf2` | FScope-500K (Pico) | v18 |
| `scoppy-fscope-500k-picow-v18.uf2` | FScope-500K (Pico W) | v18 |
| `scoppy-dso-500k-p-v18.uf2` | DSO-500K | v18 |
| `scoppy-dso500k-u-v18.uf2` | DSO500K-U (<2023-06-30) | v18 |
| `scoppy-dso500k-u2-v18.uf2` | DSO500K-U (>2023-06-30) | v18 |

- Pico / Pico 2 → USB only (sin WiFi). Pico W / Pico 2 W → USB + WiFi.
- Builds `-fscope-*` / `-dso*` traen **voltage ranges preconfigurados** para esas
  placas; el firmware base `scoppy-pico` NO trae rangos por defecto.

---

## 2. Pinout oficial del firmware (configuración "Default")

| GPIO | Dir | Función | Descripción |
|---|---|---|---|
| 0, 1 | Out | UART TX/RX | Diagnóstico (errores irrecoverables) |
| 2, 3 | In (pulled-down) | CH1 Voltage Range | Bits 0/1 del "range id" del canal 1 |
| 4, 5 | In (pulled-down) | CH2 Voltage Range | Bits 0/1 del "range id" del canal 2 |
| 6–13 | In | Logic Analyzer | Hasta 8 entradas digitales (0–3.3V) |
| 14 | Out | Wi-Fi Status | LED de estado Wi-Fi |
| 15 | Out | Trigger | LED de disparo |
| 22 | Out | Test signal | PWM 1kHz 50% (conectable a ADC) |
| 26 | In | CH1 ADC | Entrada del AFE CH1 |
| 27 | In | CH2 ADC | Entrada del AFE CH2 |

Nota: existe una config alternativa "FScope" (comentada en el fuente de GPIOs.md)
con test signal en GPIO 16, CH1 range en 18/19, CH2 range en 20/21, y CH2 ADC en
GPIO 28. Las asignaciones de GPIO por función son **configurables desde la app**
(desde v1.022/firmware v14).

### GPIO configurables (Firmware GPIO Settings)
- Signal generator (default 22)
- Voltage range pins (bits de "range id", default CH1=GPIO3(bit0)/GPIO2(bit1),
  CH2=GPIO5(bit0)/GPIO4(bit1), bit2 deshabilitado)
- Status LED (los GPIO 14/15 se pueden poner a "None" para ahorrar corriente)

---

## 3. Muestreo ADC del RP2040 (osciloscopio interno)

| Sample rate | ADC clock | Nota |
|---|---|---|
| 500 kS/s (default) | 48 MHz | 96 ciclos/muestra |
| 1.3 MS/s | 125 MHz | overclock opcional |
| 2.0 MS/s | 192 MHz | overclock opcional |

- **2 canales encendidos → el rate se divide a la mitad** (250k/625k/1M).
- Con 2.0 MS/s el analizador lógico sube de 25 MS/s a 38 MS/s.
- El setting "Max Sample Rate" se guarda en la **APP** (no en el firmware),
  pref `"rp2040msr"` (`V2/G`). Solo afecta al osciloscopio de ADC interno.
- Analizador lógico: máx 25 MS/s (default), 38 MS/s con ADC a 2.0 MS/s.

### Constant en la app (`V2/G`)
- `SR_0_5` (500 kS/s), `SR_1_3` (1.3 MS/s), `SR_2_0` (2 MS/s), `SR_2_5` (2.5 MS/s).

---

## 4. Voltage ranges (rangos de voltaje)

Un rango = par (min, max) de voltaje de entrada sin clipping (= sensibilidad).

- Hasta **8 rangos por canal** (ids 0–7). Default del firmware base: ninguno (solo
  builds de pared las placas AFE traen los suyos).
- Por cada rango se configuran (valores de pico):
  - **Min. Voltage**: voltaje de entrada que da 0V en el ADC.
  - **Max. Voltage**: voltaje de entrada que da ADC_VREF (3.3V).
  - **Vref 1X y Vref 10X**: voltaje PWM opcional para generar offset (por rango),
    emitido por un GPIO de Vref configurable.
- **GPIOs de rango**: hasta 3 por canal = bits 0–2 del "range id".
  - Como **inputs** (selector mecánico indica el rango; se leen pulled-low →
    nada conectado = rango 0).
  - Como **outputs** (la app controla un mux CD4052 → **Auto Voltage Range**; el
    rango cambia solo según volts/div; en auto los rangos grandes van primero = id 0).
  - "Auto Voltage Range Pins" (1/2/3) controla cuántos bits son outputs → permite
    modo mixto.
  - Para usar >4 rangos hay que **habilitar el bit2**.
- **Inverting AFE**: checkbox por canal para front-ends inversores (3.3V en ADC =
  voltaje de entrada mínimo).
- Almacenamiento: el firmware **sube sus rangos y sobreescribe los de la app** al
  conectar; el checkbox "Do not overwrite when device is connected" evita que lo pise.

---

## 5. Signal generator (salida PWM, GPIO 22 default)

- Basado en **PWM** (GPIO configurable). Al encender = onda cuadrada 1kHz.
- **Square Wave**: 100 Hz – 1.25 MHz, duty 50%.
- **Sine Wave (PWM)**: cuadrada con duty modulado por seno; frecuencia del seno fija
  1kHz. Se obtiene seno real añadiendo filtro paso bajo (1kΩ + 0.1µF).
- **None**: apaga la generación.
- En placas 500K: salidas SIG LP (a través de filtro RC) y DIRECT.

---

## 6. Diseños de Analog Front-End (AFE)

Docs oficiales: `Analog-Front-End.md`, `Analog-Front-End-Examples.md`,
`front-end-design-1..4.md` (en `scoppy_of_git/docs/wiki/`). Esquemas/PNGs en
`flutter_docs/` (`119-sch.png`, `Schematic_Pi-Pico-Scoppy-AFE-Circuit-3*.png`,
`schematic.png`, `schematics_2.png`, `pico.png`, `raspberry_pico.jpeg`).

- Diseño 4 (referencia): switch 4 posiciones × 2 polos → 4 rangos
  (0–6.6V / 0–3.3V / 0–1.8V / 0–0.8V) usando resistor de feedback del opamp +
  GPIO de "Channel voltage range".
- FSCOPE/DSO-500K: 2 canales AFE, jumpers AC/DC coupling (1µF), trimmer, probe
  attenuation 10X. Rangos auto al cambiar volts/div (muestra nº 0–3 en el badge).
- Calibración: con señal 1kHz del signal generator; requiere volts/div >600mV
  (rango 0) para no recortar.

---

## 7. Notas de instalación / comportamiento (wiki)

- **About Scoppy on the Pico W**: al encender, el Pico W **intenta USB primero**;
  si en ~10s no hay respuesta de la app, cambia a Wi-Fi (AP o station según config).
- **Boot LEDs** (WiFi-Troubleshooting): 4 blinks = AP esperando, 3 blinks = joined
  LAN, 2 blinks = USB; pasar ~10s USB antes de cambiar a WiFi.
- **erase-flash**: usar `flash_nuke.uf2` para limpiar (p.ej. config WiFi previa).
- El Pico W como AP: SSID `SCOPPY-<MAC>`, IP 192.168.4.1 (DHCP server). Como
  cliente/station obtiene IP por DHCP (no admite IP fija). Métodos de conexión de la
  app: Auto / Scoppy device name / IP address / Access Code.
- El firmware guarda config en flash con magic (rechaza "unmatched magic 2");
  strings de GPIO/VR ("CH1 ADC", "Trigger LED", ...) visibles en el binario UF2.

---

## 8. Pico 2 (v19) — diferencias conocidas
- v19 es el firmware para Pico 2 / Pico 2 W.
- En el binario v18 el puerto 22483 aparece como literal `d3570000`; en v19 buscar
  variante de codificación/`htons` (ver TODO.md).
