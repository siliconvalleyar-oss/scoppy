# Seguridad

Aspectos de seguridad relevantes para el proyecto **Scoppy**.

## Comunicación App ↔ Pico

- **USB**: conexión por cable, acceso local (no expuesto a la red).
- **WiFi**:
  - Modo **AP**: la Pico expone una red propia (SSID `SCOPPY-<MAC>`); la
    comunicación TCP a los puertos 22483/22484 **no está cifrada** por
    defecto. Usa en entornos de confianza.
  - Modo **Station/Client**: protege el **Scoppy Access Code**; este bloquea
    los métodos Auto y device-name, aunque IP y USB siguen funcionando.

## Recomendaciones

- Cambia el SSID/contraseña del AP por defecto.
- En despliegues semipúblicos, prefiere conexión **USB** o red WiFi cifrada
  (WPA2/3).
- El `Access Code` controla acceso cuando hay varios Pico W.

## Código y dependencias

- Revisa periódicamente dependencias de Flutter (`flutter pub outdated`) por
  CVEs.
- No expongas credenciales ni tokens en el código ni en los logs (ver
  [LEARNINGS.md](LEARNINGS.md) sobre gestión de tokens en git).

## Hardening de la app

- Aplica la política de seguridad de Android de forma estándar
  (`networkSecurityConfig` si hiciera falta para traficar por WiFi local).
- Limita los permisos del manifest a lo mínimo necesario (USB host, red).