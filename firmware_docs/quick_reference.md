# Referencia Rápida - Firmware Scoppy Pico W v18

## Datos del Dispositivo

| Campo | Valor |
|-------|-------|
| **Firmware** | scoppy-picow-v18.uf2 |
| **Target** | Raspberry Pi Pico W (RP2040 + CYW43439) |
| **VID** | 0x2E8A (Raspberry Pi Foundation) |
| **PID** | 0x000A |
| **Device Class** | 0xEF (IAD composite) |
| **Configuración** | 1 configuración, 2 interfaces (CDC) |
| **Potencia** | 250 mA (bus powered) |

---

## Configuración USB

```
IAD:       class=0x02 (CDC), first_iface=0, count=2
Interface 0:  CDC-Control (class=0x02, subclass=0x02)
               EP1 IN (Interrupt, max 8 bytes, interval 16)
Interface 1:  CDC-Data (class=0x0A)
               EP2 OUT (Bulk, max 64 bytes)
               EP2 IN  (Bulk, max 64 bytes)
```

---

## WiFi

| Parámetro | Valor |
|-----------|-------|
| **SSID** | `SCOPPY-<8-bytes-MAC>` |
| **Modo AP IP** | `192.168.4.1` |
| **mDNS** | `_scoppy._tcp` o `_scoppyx._tcp` |
| **Chip** | Cypress CYW43439 |
| **Stack** | CYW43 + lwIP |

---

## Comandos USB (EP2 OUT)

| CMD | Nombre | Payload |
|-----|--------|---------|
| 0x01 | Set Sample Rate | uint32 LE (Hz) |
| 0x02 | Set Trigger | 3 bytes: ch, type, level |
| 0x03 | Start Acquisition | — |
| 0x04 | Stop Acquisition | — |
| 0x05 | Set Channel Range | 2 bytes: ch, range |
| 0x06 | Get Device Info | — |
| 0x07 | Get Config | — |
| 0x08 | Set Config | N bytes |
| 0x09 | Ping | — |
| 0x0A | Access Code | N bytes |

---

## Puntos Clave para Replicar el Firmware

### Mínimo Viable

1. **USB CDC-ACM**: Implementar en RP2040 usando TinyUSB
2. **Descriptor USB**: Igual que el analizado (VID=0x2E8A, PID=0x000A)
3. **ADC**: RP2040 ADC0/ADC1, 12-bit, 10-bit usable
4. **DMA**: Transferir muestras de ADC a buffer en RAM
5. **EP2 IN**: Streaming de 64 bytes bulk hacia host
6. **Comandos**: Parsear CMD/LEN/PAYLOAD desde EP2 OUT

### Fuente de Referencia

- TinyUSB (open source, soporta RP2040 CDC-ACM)
- Proyecto original: https://github.com/fhdm-dev/scoppy
- Wiki: https://oscilloscope.fhdm.xyz

### Limitaciones de Hardware RP2040

- SRAM limitada: 264 KB total
- 2 canales DMA para ADC (máximo 2 canales simultáneos)
- Sample rate máx ~2 MS/s (1 canal)
