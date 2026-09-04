# Troubleshooting

Resolución de problemas comunes de **Scoppy**.

## Conexión

### No conecta por WiFi
- ¿La Pico W está en modo **AP** (LED parpadeando) o esperando una LAN?
  - 4 blinks = AP esperando · 3 blinks = joined LAN · 2 blinks = USB.
- Verifica que el host esté en la misma red (`192.168.4.0/24` en modo AP).
- La Pico **solo atiende UNA sesión de control**: si otra app está conectada,
  cierra la sesión y espera ~30 s.
- IP por defecto: `192.168.4.1` (puerto 22483).

### Conecta pero no aparecen datos
- Tras el handshake la iniciativa la toma la Pico (manda el **SYNC**). Si nada
  se muestra, espera un momento o toca RUN.
- Revisa el puerto de datos 22484 (solo se abre dentro de la sesión).

### USB no detectado
- Requiere **USB host** en el dispositivo y permisos en el manifest.
- Verifica VID 0x2E8A / PID 0x000A.

## Visualización

### Aliasing / señal distorsionada
- Reduce el sample rate o sube el timebase; activa la interpolación Sin(x)/x
  si la señal es >50 kHz.

### Onda recortada verticalmente
- Ajusta el **volts/div** o selecciona el rango de voltaje correcto del canal.

### Pantalla en blanco en NORM
- El trigger NORM espera un flanco antes de dibujar; si no hay señal, cambia a
  AUTO u OFF (roll).

## Performance

### Bajo framerate
- Reducir canales encendidos (2 canales analógicos dividen el sample rate).
- Bajar el nº de muestras por captura (SINGLE usa hasta 100k).

## Firmware

### Firmware no arranca / config corrupta
- Re-Grabar con BOOTSEL y, si hace falta, `flash_nuke.uf2` para limpiar.

### Bug conocido (DSO-500K)
- A veces se cuelga al pasar de Sine(PWM) a Square: reiniciar la Pico.

## Build / pub

- `flutter pub get` falla ⇒ `flutter clean && flutter pub get`.
- Build Android falla ⇒ `cd android && ./gradlew clean` y luego
  `flutter clean`.
- iOS CocoaPods ⇒ `pod deintegrate && pod install` en `ios/`.