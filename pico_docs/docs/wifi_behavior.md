# Comportamiento WiFi - Firmware Scoppy Pico W (v18)

## Resumen

El firmware Scoppy v18 para Pico W implementa dos modos de conectividad WiFi usando el chip **Cypress CYW43439** integrado en la Pico W, controlado a través del stack **CYW43** de Raspberry Pi.

---

## Modos de Operación WiFi

| Modo | Descripción | Uso |
|------|-------------|-----|
| **Access Point (AP)** | La Pico W crea su propia red WiFi | Modo por defecto / standalone |
| **Station (STA)** | La Pico W se conecta a un router existente | Integración en red local |

### Selección de Modo

El usuario puede elegir el modo desde la app Android. La secuencia configurada se guarda en la flash de la Pico W.

---

## Access Point (Modo por Defecto)

### SSID

El SSID del Access Point sigue el patrón:

```
SCOPPY-<MAC_HEX>
```

Donde `<MAC_HEX>` son los **6 bytes de la dirección MAC** de la interfaz WiFi en formato hexadecimal minúsculas (sin separadores).

**Ejemplo:** Si la MAC WiFi es `E6:61:4C:31:1B:85:20:39`, el SSID sería:
```
SCOPPY-e6614c311b852039
```

> **Nota:** El `lsusb` muestra `Bus 001 Device 006: ID 2e8a:000a Raspberry Pi Pico` pero el SSID WiFi es generado por el firmware, no por USB. La MAC del AP WiFi es diferente de la MAC USB.

### Código Fuente (extraído del firmware)

```c
// Formato del SSID (encontrado en el firmware):
"scoppy-%.2x%.2x%.2x%.2x%.2x%.2x%.2x%.2x"
"SCOPPY-%.2X%.2X%.2X%02X%02X%02X%02X%02X"
// Usa 8 bytes de MAC en hex (CYW43 tiene MAC de 8 bytes con OUI)
```

### Parámetros del AP

| Parámetro | Valor / Descripción |
|-----------|---------------------|
| **SSID** | `SCOPPY-<8-bytes-MAC-hex>` |
| **Seguridad** | Configurable (Open, WPA2, WPA3) |
| **Contraseña** | Configurable por el usuario |
| **Modo auth** | Auto-detecta (WPA2/WPA3 si hay password) |
| **IP del AP** | `192.168.4.1` (estándar en SoftAP de CYW43) |
| **Canal** | Auto-seleccionado |
| ** País WiFi** | Configurable (afecta canales permitidos) |

### Indicadores LED

- **WiFi Status LED**: Indica estado de conexión WiFi
- **Trigger LED**: Indica detección de trigger del osciloscopio

---

## Station Mode (Cliente WiFi)

La Pico W puede conectarse a un router WiFi existente para:
- Ser accesible desde la red local
- Compartir datos con otros dispositivos en la LAN
- Usar mDNS en la red local

### Parámetros STA

| Parámetro | Descripción |
|-----------|-------------|
| **SSID** | Nombre de la red a conectar |
| **Password** | Contraseña WPA2/WPA3 |
| **Auto-auth** | Detecta automáticamente tipo de autenticación |

### Estados de Conexión

El firmware reporta:
```
WiFi: Start connecting: auth=%s
WiFi: Connection pending, link status=%s (%d)
WiFi: Connected
WiFi: AP MAC addr=%02X.%02X.%02X.%02X.%02X.%02X
WiFi: AP IP addr=%u.%u.%u.%u
```

---

## Descubrimiento mDNS

### Servicio Anunciado

La Pico W anuncia un servicio mDNS para ser descubierta automáticamente por la app Android.

| Campo | Valor |
|-------|-------|
| **Nombre del servicio** | `_scoppy` o `_scoppyx` |
| **Protocolo** | TCP |
| **Puerto** | Configurable |

### Strings del Firmware Relacionadas

```
_scoppyx    (nombre mDNS primario, encontrado en firmware)
_scoppy     (nombre mDNS alternativo)
SCOPPY      (nombre base para display)
```

### Funciones mDNS Utilizadas

```c
mdns_resp_add_netif()      // Registrar interfaz de red
mdns_resp_add_service()    // Anunciar servicio _scoppy
mdns_build_host_domain()   // Construir dominio del host
mdns_build_service_domain() // Construir dominio del servicio
```

> **Nota:** El firmware también registra paquetes mDNS almacenados: `Stored mDNS packets`.

---

## Formato de Nombre de Configuración

La configuración guardada en flash tiene formato:

```
scoppy-<8-bytes-MAC-hex>
```

Ejemplo: `scoppy-e6614c311b852039`

El firmware lee/guarda esta configuración con:
```c
scoppy-%.2x%.2x%.2x%.2x%.2x%.2x%.2x%.2x"
SCOPPY-%.2X%.02X%02X%02X%02X%02X%02X%02X"
```

### Parámetros de Configuración Guardados

| Parámetro | Descripción |
|-----------|-------------|
| `WiFi,USB` o `USB,WiFi` | Orden de preferencia de conexión |
| `WiFi Country` | Código de país WiFi (ISO 3166 alpha-2) |
| `WiFi AP Mode SSID` | Nombre de red en modo AP |
| `WiFi AP Mode PW` | Contraseña en modo AP |
| `WiFi AP Mode Auth Type` | Tipo de autenticación (open, WPA2, WPA3) |
| `WiFi STA Mode SSID` | SSID de red en modo cliente |
| `WiFi STA Mode PW` | Contraseña en modo cliente |
| `WiFi STA Mode Auth Type` | Tipo de autenticación |

---

## Stack TCP/IP

El firmware usa el stack TCP/IP de lwIP integrado en el SDK de Raspberry Pi Pico.

### Funciones TCP utilizadas

```c
tcp_write()    // Envío de datos
pbuf_copy_partial_pbuf()  // Copia de datos desde pbufs
```

### Limitaciones

- `pbuf_copy_partial_pbuf() does not allow packet queues!` → advertencia en firmware cuando se excede límite de colas

---

## Inicialización de CYW43

```c
cyw43_arch_init_with_country()  // Inicialización con país WiFi
cyw43_wifi_pm()                 // Gestión de energía WiFi
cyw43_read_bytes()              // Lectura de registros del chip
cyw43_kso_set()                 // Control de KSO (keep-alive)
```

### Firmware del Chip CYW43

```
43439a0-roml/sdio-g-pool-p2p-idsup-idauth-pktfilter-keepalive-aoe-lpc-swdiv-srfast-fuart-btcx-noclminc-clm_min-fbt-mfp-sae-wowlpf-tko
Version: 7.95.49
Date: Mon 2021-11-29 22:50:27 PST
Ucode Ver: 1043.2162 FWID 01-c51d9400
```

---

## Diagrama de Conectividad

```
┌─────────────────────────────────────────────────────────────────────┐
│                     Dispositivo Android                             │
│  App Scoppy                                                         │
│  ┌────────────┐    USB Bulk     ┌──────────────────────────────┐    │
│  │ EP2 OUT ──────────────────────►│        PICO W                │    │
│  │ EP2 IN ◄──────────────────────│                              │    │
│  └────────────┘                   │  ┌──────────────────────┐  │    │
│                                   │  │ TinyUSB (CDC-ACM)    │  │    │
│                                   │  └──────────┬───────────┘  │    │
│  ┌────────────┐    WiFi TCP       │             │              │    │
│  │ mDNS query ─────────────────►  │  ┌──────────▼───────────┐  │    │
│  │ TCP data  ◄───────────────────│  │ CYW43 WiFi Stack     │  │    │
│  └────────────┘                   │  └──────────────────────┘  │    │
│                                   │        ┌────────────┐      │    │
│                                   │        │ lwIP TCP/IP│      │    │
│                                   │        └────────────┘      │    │
└───────────────────────────────────┘                            ─┘
                                      │
                    ┌─────────────────┘
                    │
        ┌───────────▼──────────────────────┐
        │  Access Point: SCOPPY-<MAC>      │
        │  IP: 192.168.4.1                 │
        │  Servicio mDNS: _scoppy._tcp     │
        └──────────────────────────────────┘
```
