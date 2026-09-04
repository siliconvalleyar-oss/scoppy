# Despliegue (Deploy)

Cómo generar y distribuir la app **Scoppy**.

## Google Play (Android)

1. **Aumenta la versión** en `app/pubspec.yaml`:
   ```yaml
   version: 1.0.0+1   # → 1.0.1+2 (versionName+versionCode)
   ```
2. Construye el APK/AAB de release:
   ```bash
   cd app
   flutter build appbundle --release   # .aab para Play
   # build/app/outputs/bundle/release/app-release.aab
   ```
3. Sube el `.aab` a la consola de Google Play (Internal/Closed/Production
   track) y publica.

## Instalación directa (APK)

Comparte el APK generado:
```bash
flutter build apk --release
# build/app/outputs/flutter-apk/app-release.apk
```
El dispositivo debe permitir instalación de orígenes desconocidos.

## iOS (App Store)

1. `flutter build ios --release`.
2. Sube con Xcode / Transporter y configura el App Store Connect.

## Firmware

El firmware de la Pico se distribuye como `.uf2`; el usuario lo graba por
BOOTSEL (ver [INSTALL.md](INSTALL.md)).

## Versionado

Todo **push debe llevar su tag**. La versión vive en el archivo `VERSION`
(raíz) y el tag lleva `v` (`VERSION` = `1.x.y`, tag = `v1.x.y`). Ver
[LEARNINGS.md](LEARNINGS.md) y [WORKFLOW.md](WORKFLOW.md).