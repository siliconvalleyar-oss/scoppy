# Live Device Probe - 192.168.4.1:22483

## Resumen

El dispositivo Scoppy Pico W en modo Access Point (`192.168.4.1`) expone un servicio TCP en el puerto **22483** que devuelve información del dispositivo de forma pasiva.

---

## Descubrimiento

### Escaneo de Puertos

**IP objetivo:** `192.168.4.1` (AP WiFi del Pico W)

| Puerto | Estado | Servicio |
|--------|--------|----------|
| 22/tcp | Abierto | SSH (OpenSSH 9.6p1 Ubuntu) - **No es el servicio Scoppy** |
| 22483/tcp | **Abierto** | **Servicio discovery Scoppy** |
| Todos los demás | Cerrados | — |

> **Nota:** El puerto 22 SSH parece ser un servicio adicional no documentado en el firmware Scoppy. Requiere investigación adicional.

---

## Análisis del Puerto 22483

### Comportamiento

- **Protocolo:** TCP
- **Handshake:** No requiere handshake especial
- **Respuesta:** Devuelve 41 bytes inmediatamente al conectar
- **Input:** Ignora cualquier dato enviado por el cliente
- **Respuesta:** Siempre la misma trama de 41 bytes (estática)

### Pruebas Realizadas

| Prueba | Resultado |
|--------|-----------|
| Conexión sin enviar datos | 41 bytes recibidos |
| Enviar `\r\n` | Mismo paquete de 41 bytes |
| Enviar `HELLO` | Mismo paquete de 41 bytes |
| Enviar `GET / HTTP/1.0` | Mismo paquete de 41 bytes |
| Enviar bytes aleatorios | Mismo paquete de 41 bytes |
| UDP al mismo puerto | Timeout (no responde) |

### Formato de Respuesta

**Hexdump (41 bytes):**
```
ff 00 29 3c 41 07 20 00 29 27 e6 61 4c 31 1b 85
20 39 03 12 35 38 63 14 00 00 28 cd c1 04 e6 7c
01 04 a8 c0 00 02 00 10 00
```

**Análisis de campos:**

| Offset | Bytes | Valor | Interpretación |
|--------|-------|-------|----------------|
| 0-1 | `ff 00` | — | Magic/versión del protocolo |
| 2-3 | `29 3c` | — | Tipo/longitud de mensaje |
| 4-5 | `41 07` | — | Device ID / timestamp |
| 6-7 | `20 00` | — | Flags / capabilities |
| 8-9 | `29 27` | — | Firmware version? |
| 10-15 | `e6 61 4c 31 1b 85` | **MAC** | **MAC address del dispositivo** (e6:61:4c:31:1b:85) |
| 16-19 | `20 39 03 12` | — | Timestamp / build date |
| 20-23 | `35 38 63 14` | — | Unknown (posible IP o ID) |
| 24-25 | `00 00` | — | Padding |
| 26-29 | `28 cd c1 04` | — | Unknown |
| 30-31 | `e6 7c` | — | Unknown |
| 32-33 | `01 04` | — | Unknown |
| 34-37 | `a8 c0 00 02` | — | Posible IP (formato big-endian: 168.192.0.2) |
| 38-39 | `00 10` | 16 | Unknown |
| 40 | `00` | — | Terminador |

### Campos Confirmados

- **MAC Address:** `e6:61:4c:31:1b:85` (bytes 10-15)
  - Coincide con el prefijo del SSID: `SCOPPY-E6614C311B852039`
  - Primeros 6 bytes de la MAC de 8 bytes del CYW43

### Campos Presumidos

- **Bytes 16-19:** `20 39 03 12` → Podría ser fecha de compilación (2024?) o timestamp
- **Bytes 34-37:** `a8 c0 00 02` → Podría ser dirección IP en formato big-endian

---

## Comparación con Firmware

El valor del puerto **22483 (0x57f3)** aparece 2 veces en el firmware extraído:
- Offset `0x7d7c`: En tabla de datos/structs
- Offset `0x8670`: En otra tabla de datos

Ambas apariciones son en little-endian: `d3 57 00 00` = 0x000057d3 = 22483

Esto confirma que el puerto está hardcodeado en el firmware.

La respuesta de 41 bytes **no aparece como texto** en el firmware, lo que sugiere que se construye dinámicamente en runtime a partir de:
- MAC address (leída del CYW43)
- Timestamp de compilación
- Dirección IP actual
- Capacidades del firmware

---

## Hipótesis del Protocolo

Este es un **servicio de descubrimiento/identificación** que:

1. La app Android usa para descubrir dispositivos Scoppy en la red WiFi
2. Devuelve información estática del dispositivo al establecer conexión TCP
3. No requiere autenticación ni handshake
4. Es de solo lectura (no acepta comandos)

**Flujo probable:**
```
App Android                    Pico W (192.168.4.1:22483)
    │                               │
    │──── TCP SYN ──────────────────►│
    │◄─── TCP SYN+ACK ──────────────│
    │──── TCP ACK ──────────────────│
    │                               │
    │◄─── 41 bytes (device info) ───│  Respuesta automática
    │                               │
    │──── FIN ──────────────────────►│
```

---

## Aplicación en Ingeniería Inversa

Este servicio es útil para:

1. **Fingerprinting**: Identificar dispositivos Scoppy en la red
2. **Extracción de MAC**: Obtener la dirección MAC sin acceso físico
3. **Detección de firmware**: La respuesta podría variar entre versiones
4. **Debugging**: Punto de entrada para análisis dinámico

---

## Próximos Pasos

1. **Capturar tráfico real**: Usar Wireshark o tcpdump para ver cómo interactúa la app Android con este puerto
2. **Analizar variaciones**: Ver si la respuesta cambia entre diferentes firmware/versiones
3. **Buscar en APK**: Analizar el código smali que parsee esta respuesta de 41 bytes
4. **Probar con diferentes dispositivos**: Comparar respuestas entre Pico, Pico W, Pico 2
5. **Ingeniería inversa del parser**: Determinar el formato exacto de cada campo
