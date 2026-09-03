# Referencia de Funcionalidad — App Android Scoppy (a replicar)

Comportamiento completo de la app `xyz.fhdm.scoppy` extraído de la documentación
oficial (`scoppy_of_git/docs/app-help/*` y `wiki/*`). Objetivo: servir de
especificación para replicar el comportamiento del cliente (UI + lógica de
captura), complementando el protocolo binario de `PROTOCOLO_SCOPPY.md`.

> Fuente: `scoppy_of_git/docs/app-help/*.md` y `wiki/*.md` (leídos íntegros).
> Version de referencia de RE: app v1.031, firmware v18 (Pico W) / v19 (Pico 2).

---

## 1. Modos de funcionamiento

- **Osciloscopio** : captura ADC GPIO **26 (CH1) y 27 (CH2)** (sample rates de la
  tabla de RP2040). El fallback de 2.ª entrada: FScope usa GPIO 28.
- **Analizador lógico (LA)** : captura GPIO **6–13** (8 canales digitales 0–3.3V),
  max 25 MS/s (38 MS/s con ADC 2.0MS/s). Sin nivel de trigger (solo flanco).
- Modos **mutuamente excluyentes** (botón Mode en el menú principal).

### Pantalla del osciloscopio (elementos UI a replicar)
- **Top status bar**: Sample Rate (tappable → fijar/auto), Sample Count, Sample
  Record View (vista general del record con rectángulo gris del área visible +
  línea vertical en el punto de trigger), Time/Div (tappable popup), Horizontal
  Position (en divs).
- **Panel RHS (CONTROLS)**: Run Mode, Single Shot, navegación, controles
  Horizontal (Time/Div, Position), Vertical (selección de canal, VOLTS/DIV,
  POSITION), Trigger (LEVEL; long-press = set 50%), Cursors.
- **Bottom bar**: Signal Source (USB/WiFi + badge de conexión), Channel Badges
  (Volts/Div, Position, Voltage Range), Trigger Badge (Channel, Level).
- **Grid del waveform**: Channel Ground Levels (posición vertical del 0V, flecha
  izquierda), Run Status, grosor de grid configurable.

### Display modes (MENU → DISPLAY)
- **YT** (default), **FFT**, **FFT + YT**, **XY**, **XY + YT** (con checkboxes
  para mostrar/ocultar YT).

---

## 2. Trigger (disparo)

### Osciloscopio
- **Canal**: CH1 o CH2 (botones del panel o TRIG badge → Channel). El trigger **NO
  dispara si ese canal está apagado**.
- **Nivel**: botones +/− del panel, tap LEVEL (diálogo valor exacto), TRIG badge →
  Level, o swipe sobre el indicador de nivel. **Long-press LEVEL = "set 50%"**
  (midpoint de la onda mostrada). Indicador indica si el nivel está fuera de
  pantalla.
- **Tipos**: solo **RISING EDGE** y **FALLING EDGE** (v1.014+). No hay edge normal
  con holdoff, ni trigger de pulso/video.
- **Modos**:
  - **OFF** = "Roll Mode": muestra las muestras más recientes del record (útil en
    timebases lentas).
  - **AUTO**: busca trigger pero si no dispara en un rato muestra igualmente.
  - **NORM**: espera trigger antes de dibujar; con RUN/SINGLE la pantalla queda en
    blanco y el estado es RUNNING hasta disparar.
- **Pre-trigger samples**: % del record que queda antes del punto de trigger
  (default 50%; otro valor se muestra en el TRIG badge). Configurable (v1.014+:
  "trigger position within the sample record").
- El punto de trigger se dibuja como línea vertical en el Sample Record View.

### Analizador lógico
- Mismo comportamiento salvo: (1) se configura desde el icono de engranaje de
  trigger en el control panel (no badge), y (2) **NO hay nivel de trigger**.

---

## 3. Sample rate y timebase

- **Auto**: Scoppy cambia el sample rate automáticamente al cambiar Time/Div.
- **Fixed**: tap al valor de sample rate (arriba-izquierda) → menú desplegable;
  tap-and-hold alterna auto↔fixed; en fixed se muestra una **"F"** junto al valor.
- El valor mostrado es el del **record actual** (puede diferir del fijo si está
  STOPPED).
- Time/Div default / reset: **10 ms/div** (long-press TIME/DIV).
- Captura **SINGLE**: hasta **100k muestras** (menos si a ese rate tardaría >10 s).
  FFT en single usa **16k muestras**.
- RUN = polling continuo de muestras desde el Pico (pide permiso USB en Android).

### Interpolación
- **Sin(x)/x interpolation** para timebases cortas (mejora display de señales
  >50 kHz). Desactivable en Settings → Display (v1.022/v14+).

---

## 4. Medidas (Measurements)

Dos vistas: **On-screen** (config por checkbox + show/hide por canal, tap en la
medición abre config) y **Snapshot** (todas a la vez; intervalo = "whole record" u
"on-screen"; incluye medidas que no están on-screen como Mean, AC RMS, DC RMS).

| Medida | Definición |
|---|---|
| **Min / Vmin** | Valor de voltaje más bajo del intervalo |
| **Max / Vmax** | Valor más alto |
| **Pk-Pk / Vpp** | Max − Min |
| **Mean / Average** | Suma de voltajes / nº de muestras |
| **DC RMS** | RMS de todas las muestras |
| **AC RMS** | RMS sin componente DC (= desviación estándar de las muestras) |
| **Time / Period** | Tiempo entre thresholds medios de dos rising edges consecutivos; threshold medio = punto medio Vmin–Vmax |
| **Freq** | 1/Period |
| **Duty** | Ratio de muestras > punto medio Vmin–Vmax / total, en % |

- **Export CSV** de las muestras capturadas (botón Export del panel MENU, v1.016+).
- Acceso: tap-and-hold en una medida on-screen (o en LA, a la izquierda de la
  pantalla) abre la configuración/snapshot.

---

## 5. Cursors

- Botón CURSORS en el panel CONTROLS. Cursor **Y no existe en modo LA** (solo X).
- Info del cursor en top-left; badge extra para ocultar cursores sin perder
  posición y para cambiar el canal del cursor Y.
- Movimiento: tap-and-hold hasta que el cursor cambia de rojo a naranja.
- **No se limitan a la pantalla visible** (se mueven con el waveform).
- Hay cursores separados para YT y para FFT (v1.018+).

---

## 6. FFT

- Habilita desde MENU → DISPLAY → "FFT" o "FFT + YT".
- **RBW = sample rate / nº puntos FFT** (16k en single); se mejora bajando el
  sample rate (los puntos aún no son configurables).
- Muestra hasta **sample rate/2** de frecuencia.
- Control horizontal: **SPAN** (touch-hold = auto-fit, 0Hz a la izquierda) y
  **CENTER** (touch-hold = pico más alto al centro).
- Vertical: **SCALE** (amplitud/div) y **POSITION**.
- Unidades verticales: **dBm** (RMS vs 1mW, log, asume 50Ω), **dBmV** (RMS vs 1mV,
  log), **V** (amplitud pico = 50% de Vpp, lineal).
- Canales: CH1, CH2 o ambos (deben estar encendidos). Default = primer canal
  habilitado.

---

## 7. Math channels (canales matemáticos)

- Hasta **2 math channels**; cada uno combina hasta **5 funciones y 3 fuentes**.
- **Unarias**: ABS=abs(y), INV=y*-1, LOG=log10(y), LN=ln(y), SQUARE=y*y,
  SQRT=√y, RECIP=1/y.
- **Binarias**: ADD=y1+y2, SUBTRACT, MULTIPLY, DIVIDE.

---

## 8. XY mode

- CH1 = eje X, CH2 = eje Y. MENU → DISPLAY → "XY" o "XY + YT".
- Volts/Div y Position funcionan normal (CH1 afecta X, CH2 afecta Y).
- Solo los samples visibles en la ventana YT se usan para XY.
- Máximo **1000 samples** dibujados. Puntos como dots o líneas conectadas.

---

## 9. Controles (patrón común de interacción)

Todos los controles de scala/posición siguen un patrón de 4 vías:
1. **Gesto** (swipe = posición; pinch = escala).
2. **Botones +/−** (tap o hold).
3. **Tap único** al valor → diálogo de valor exacto.
4. **Tap-and-hold** → reset al default (10 ms/div en timebase; 0 div en posición;
   volts/div default según voltage range del canal).

Selección de canal vertical: botones CH1/CH2 o tocando el GND indicator (flecha
del borde izquierdo).

---

## 10. Configuración de firmware desde la app

Acceso: badge de conexión (abajo-izquierda) → "Connected device" → "Firmware
settings". Tres subsecciones:

### Connection (Wi-Fi, Pico W)
- **Device Name**: identificador usado por el método de conexión "Scoppy device name".
- **Wi-Fi Country**.
- **Wi-Fi Mode**:
  - **Access Point**: AP SSID, AP Password, AP Authorization Type.
  - **Station/Client**: SSID, Password, Authorization Type, **Scoppy Access Code**.
- Métodos de conexión (lado app): Auto (primer Pico W encontrado; falla si otro ya
  se conectó), Scoppy device name, IP address (el Pico W solo DHCP), Access Code
  (controla acceso si hay varios Pico W; bloquea Auto y device-name pero IP/USB siguen
  funcionando). En modo AP la app conecta automáticamente.

### Channel
- **Voltage ranges por canal** guardados en el dispositivo (ver
  `REFERENCIA_HARDWARE_PICO.md` §4). Al conectar, el firmware sube sus settings y
  sobreescribe los de la app; checkbox "Do not overwrite..." evita que lo pise.

### GPIO
- Reasignación de GPIO por función (signal gen, voltage range pins, status LEDs).
- Deshabilitar funciones con "None".

### RP2040 settings (SÓLO app, no firmware)
- **Max Sample Rate** (500k / 1.3M / 2.0M), guardado en la app (pref `"rp2040msr"`),
  aplica al ADC interno del osciloscopio.

---

## 11. Premium / compra in-app

- Premium = desbloquea features + **quita publicidad**. Vía MENU → "Upgrade to
  Premium". Si no aparece el botón: ya está activado o el hardware (p. ej. DSO-500K)
  lo desbloquea automáticamente.
- SKUs Play: `scoppy.premium.lifetime`, `scoppy.premium.subscription`
  (ver PROTOCOLO_SCOPPY.md §8 para los detalles de billing/prefs).
- Negocio: comprar DSO-500K (email upgrade@fhdm.xyz con nº de tracking) o Elecrow
  (código canjeable en Play Store, compras ≥2024-03-28) incluye premium gratis.
- Nota de RE: no se documentan públicamente *qué* features concretas son premium
  (solo que algunas lo requieren); en la app el gate global `S1.e.g()` libera el 2º
  canal y quita anuncios.

---

## 12. Notas varias

- **Signal generator**: ver REFERENCIA_HARDWARE_PICO.md §5 (cuadrada 100Hz–1.25MHz; seno
  PWM fijo 1kHz via GPIO PWM).
- **Sonda / probe attenuation**: configurable por canal (CH badge → Settings →
  Probe). Si ≠ 1X se muestra en el badge.
- **Bug conocido** (DSO-500K): a veces el firmware se cuelga al pasar de Sine(PWM) a
  square (reiniciar).
- Aviso de la app si el Time/Div produce un waveform no visible (v1.017+).
- Firmware configurable por función desde v1.022 (v14); Wi-Fi desde v1.020 (v11);
  triggering envuelve "set 50%" y flanco caída desde v1.014 (v7).
