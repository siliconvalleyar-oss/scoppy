# Compilación (Build)

Cómo compilar la app Flutter y el firmware.

## App Flutter (`app/`)

```bash
cd app
flutter pub get          # resuelve dependencias
flutter analyze          # análisis estático (opcional pero recomendado)
```

### Android (APK)

```bash
flutter build apk --debug          # depuración
flutter build apk --release        # release
# Resultado: build/app/outputs/flutter-apk/app-release.apk
```

### iOS

```bash
flutter build ios --release
```

### Notas

- Requiere Flutter stable + SDK de Android configurado.
- La conexión USB serial requiere dispositivo con USB host y los permisos
  correspondientes en `AndroidManifest.xml`.
- `flutter clean` si algo falla por caché:
  `flutter clean && flutter pub get`.

## Firmware (Pico) — referencia

El firmware oficial se distribuye como `.uf2` (binario cerrado). No se
recompila en este repo; solo se graba con BOOTSEL (ver
[INSTALL.md](INSTALL.md)). Una fuente alternativa (vieja/más completa) está en
https://github.com/mars-low/scoppy-pico.

## Versiones

- Pico / Pico W: **v18** (`scoppy-pico(-w)-v18.uf2`).
- Pico 2 / 2 W: **v19** (`scoppy-pico2(-w)-v19.uf2`).