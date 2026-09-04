# Uso

Cómo usar la aplicación **Scoppy** (réplica Flutter).

## Pantalla principal

Al abrir la app verás: la **rejilla de osciloscopio (10x8)**, la barra de
**estado** (sample rate, time/div, trigger), la de **medidas** (Vpp, Vmax,
Vmin, Mean, Freq, Duty) y el panel de **controles** (RUN/STOP/SINGLE,
timebase, trigger, canales).

## Conectar a la Pico

1. Asegúrate de tener la Pico/W encendida con el firmware Scoppy.
2. Pulsa el botón **Conectar** (esquina superior derecha).
3. Por defecto se conecta por **WiFi** a `192.168.4.1` (puerto 22483).
4. Al conectar, la Pico envía el **SYNC**; el estado pasa a *Conectado*.

## Capturar

- **RUN** : captura continua (polling de muestras desde la Pico).
- **STOP** : detiene la recepción y muestra los últimos datos.
- **SINGLE** : captura un registro y se detiene (hasta 100k muestras).

## Timebase

- Cambia el time/div desde el desplegable del panel de controles.
- Rango típico: 0.02 ms/div … 500 ms/div.

## Trigger

- Elige modo: **OFF** (roll) / **AUTO** / **NORM**.
- Cambia el **canal** de disparo tocando el canal como fuente.
- Flanco: **rising** / **falling**.
- Nivel: ajustable (por defecto al 50 % del midpoint).

## Canales

- Enciende/apaga canales con los chips CH1/CH2.
- Configura Vent/div y offset (posición) por canal.

## Guía rápida de uso de un osciloscopio

1. Conecta una señal (p. ej. la de prueba del GPIO 22, 1 kHz) a CH1.
2. Desactiva CH2.
3. Pulsa RUN.
4. Ajusta el time/div para ver ~1-2 ciclos.
5. Ajusta el volts/div y la posición vertical.
6. Usa STOP o SINGLE para analizar la onda.
7. Lee las medidas en la barra inferior.