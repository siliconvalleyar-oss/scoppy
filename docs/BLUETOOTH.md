# Bluetooth

Nota sobre **Bluetooth** en el proyecto **Scoppy**.

## Estado

**Scoppy NO usa Bluetooth.** La comunicación entre la app y la Pico se realiza
exclusivamente mediante:

- **USB serial** (Pico / Pico W por cable): VID 0x2E8A (Raspberry Pi).
- **Wi-Fi** (solo Pico W / Pico 2 W): TCP a los puertos **22483** (control) y
  **22484** (datos).

## Explicación

El protocolo binario documentado (`docs/PROTOCOLO_SCOPPY.md`) viaja por USB o
por sockets TCP sobre Wi-Fi. No existe transporte BLE/Bluetooth clásico ni en
el firmware ni en la app original.

## Si quisieras Bluetooth (extensión)

Aunque no forma parte del proyecto, una extensión futura podría exponer el
mismo protocolo sobre BLE (p. ej. un servicio GATT que emula el canal de
control 22483). No está implementado ni planificado en el `ROADMAP` actual.