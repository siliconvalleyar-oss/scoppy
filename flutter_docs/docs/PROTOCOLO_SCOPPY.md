# Protocolo de comunicación Scoppy (App Android ↔ Pico)

Ingeniería inversa de la app **xyz.fhdm.scoppy v1.031** (versionCode 1031, minSdk 23,
targetSdk 36), extraída del dispositivo `192.168.1.33:40633` y descompilada con jadx/apktool.

Fuentes de referencia en este workspace:
- `apk_analysis/base.apk` — APK original
- `apk_analysis/decompiled/sources/` — código Java (jadx)
- `apk_analysis/apktool_out/smali/` — smali (apktool)

Docs complementarias (en este mismo directorio):
- `REFERENCIA_HARDWARE_PICO.md` — pinout GPIO, sample rates ADC/overclock, voltage
  ranges, signal generator, firmwares v18/v19 (datos oficiales de `scoppy_of_git/`).
- `REFERENCIA_FUNCIONALIDAD.md` — comportamiento de la app a replicar (trigger,
  timebase, medidas, FFT, math, XY, premium).

---

## 1. Transportes

### USB serial (Pico sin WiFi)
- Clase conectora: `V2/J.java` → `j3/b.java` (USB serial genérico).
- VID/PID buscados por la app (`O0/*.java`):
  - `O0/a` : PL2303 / CH340 → VID 0x4348 (17224) y 0x1A86 (6790)
  - `O0/b` : FTDI → VID 0x0403 (1115)
  - `O0/d` : CP210x (variantes)
  - `O0/c` : CDC genérico (VID 0x0403)
- Selector específico de Pico: `j3/b.java` busca **VID 11914 (0x2E8A, Raspberry Pi) + PID 10 (0x000A)**.

### WiFi (Pico W)
- Clase `V2/A.java`; dos `SocketChannel`:
  - `f2342p` : control → puerto **22483** (`0x57d3`, `smali/V2/A.smali:1804`)
  - `f2343q` : datos   → puerto **22484** (`0x57d4`, `smali/V2/y.smali:450`)
- IPs:
  - Modo AP de la Pico W: `192.168.4.1`
  - Modo cliente (LAN): `10.233.28.172` (IP por defecto encontrada en `V2/A.java`)
- El mismo parser (`V2/w`) procesa las tramas vengan por USB o por WiFi.

---

## 2. Trama común (ambas direcciones)

Encabezado de 6 bytes + payload:

```
byte 0 : 0xFF  (sync)
byte 1 : longitud total del frame, parte alta (big-endian)
byte 2 : longitud total del frame, parte baja
byte 3 : opcode (tipo de mensaje)
byte 4 : opcode + 5  (confirmación: tipo ^ ~opcode invertido, siempre tipo+5)
byte 5 : versión del protocolo (>= 1; los mensajes precisan version>=1, 3 en el RUN)
byte 6+: payload
```

Los mensajes **App→Pico** de ida al frontend (APP_TO_FRONTEND, `V2/t.h`) añaden además un
byte terminador **0x56 (86)** al final (`f1.g.g()`). `V2/w` (parser entrante) aplica estas
reglas y valida: confirmación = `tipo+5`; si no, excepción "Unexpected message type
confirmation"; si `version < 1`, "Firmware version (%d) not supported".

Los mensajes fuera del rango reconocido se descartan consumiendo el frame completo.

---

## 3. Mensajes App → Pico

Constructor de tramas: `f1/g.java` (`t()` fija cabecera; `g()` calcula longitud + terminador).
Listo para reenviar cada 250 ms con deduplicación (`V2/H.a()`).
Clase emisora: `V2/H.handleMessage()`.

| Opcode | Hex | Función / contenido del payload |
|-------|-----|-------------------------------|
| 61 | 0x3D | **Setup de canales/captura** (`f1.g.d()`): `[6]=flags canal (analog:3, logic:19)`, `[7]=nº de canales & 0x0F`, luego 1 byte/canal `(canal&0x0F)|(rangoVolt<<4)`, luego `int` timebase ms, `int` -1, y al final byte 1 |
| 62 | 0x3E | **Config FRONTEND_TO_APP** (`f1.g.f()`): `[6]=0`, `[7]=1`, `[8]=1`, + `P2.f.l()` |
| 80 | 0x50 | **RUN / parámetros de captura** (`H` case 1): `[5]=3`; `[6]=(modoMuestreo<<2)|modoRun`; `[7..10]=int MD5(str(m)||"Err[45]:9397")` con m=i7+693 (campo anti-fake/sesión); `[11]=nº canales+byte/canal`; byte sample-rate (`V2.G.h`); 0; long timebase (div/10000, clamp 1..2³²-1); + trigger (13 B, ver 83) + byte pre-trigger + byte post-trigger |
| 81 | 0x51 | **Heartbeat/timebase** (`H.c()`): `[6..9]=int BE` con `min(div/10000)` |
| 82 | 0x52 | **Listado de canales activos** (`H` case 3): nº canales + byte/canal (flags) |
| 83 | 0x53 | **Trigger settings** (`f1.g.v()`, 13 B): byte modo trig, byte canal, byte tipo trig, short nivel, long 0, long 0 |
| 84 | 0x54 | **Volts/div parameters** (`H` case 5 arg2=12): byte tipo params, byte 0xFF, long timeout ms, short 50 |
| 85 | 0x55 | **Trigger level** (`H` case 5 arg2=10): `[6..9]` nivel (4 B) |
| 87 | 0x57 | **Volt/div por canal** (`H` case 5 arg2=11): `[6]=i4&0xFF` |
| 88 | 0x58 | **Offset por canal** (solo canales ADC 0-7): `[6]=canal`, `[7]=nivel` |
| 90 | 0x5A | **Request info** (`H` case 8): `[6]=3`, `[7]=1`, `[8]=grupo&7` |
| 91 | 0x5B | **Config APP_TO_FRONTEND** = opcode 62 pero con `t.h` (terminador) |
| 92 | 0x5C | **Heartbeat con byte de control**: `[6]=arg1&0xFF` (opcode por `arg2`) |

Nota: el opcode 61 no se envía por el Handler retry; se construye vía `f1.g.d()` (lista de
canales + rangos + timebase). El 62/91 lleva la configuración completa actualizada
(voltaje/div, muestreo, etc.).

---

## 4. Mensajes Pico → App

Parser: `V2/w.java` (méodo `a()Z`, dispatch en `smali/V2/w.smali`).

| Opcode | Hex | Función / contenido |
|-------|-----|--------------------|
| 60 | 0x3C | **SYNC / info del frontend** → clase `V2/C0078f` (firmware version, nº canales, rangos de voltaje, hardware id). Marca el estado SYNCHRONISED |
| 61 | 0x3D | **Datos de muestra** (waveform/trigger data) → se convierten a shorts[][] `[[S` para rendering OpenGL; cabecera con nº de streams y flags (xor 0xFF en modo lógico) |
| 62 | 0x3E | **Config del frontend** → `P2.f` (máx 0x800 B leídos del buffer); respuesta de la app con 0x62/0x5B |
| 63 | 0x3F | **Params volts/div** → lista de ints (4 B c/u); primer valor ∈ {0,10,20,30,40} selecciona `V2.a`; la app responde con 84/0x54 |

Estados de la máquina (`V2/r.java`): `DISCONNECTED → CONNECTED → SYNCHRONISED`.

Mensajes de respuesta entrantes clave:
- `V2/H` recibe `message.what` 8 (request info) y reenvía la configuración local.
- `V2/H` recibe `message.what` 4/11 → reenvía trigger settings (83).

---

## 5. Constantes / enums

- `V2/t` : transporte del mensaje — `APP_TO_FRONTEND` (h), `FRONTEND_TO_APP` (i).
- `V2/G` : sample rates — `SR_0_5` (500 kS/s), `SR_1_3` (1.3 MS/s), `SR_2_0` (2 MS/s), `SR_2_5` (2.5 MS/s). Pref: `"rp2040msr"`.
  - Estos rates son la escala *declarada por la app* para el ADC del RP2040. El detalle
    hardware (ADC@48/125/192MHz, división por nº de canales, LA 25→38 MS/s) está en
    `REFERENCIA_HARDWARE_PICO.md` §3.
- `V2/s` : buffer de entrada — `byte[64000]` (0xFA00); lecturas: `d()`=1B, `f()`=2B BE, `g()`=4B BE, `i()`/`h()`=4B/8B BE.
- Firmware compatible: versiones 1xx (el check exige `>=1`). Firmware actual Pico: v18, Pico 2: v19. WiFi = Pico W.

---

## 6. Links útiles
- Docs: https://oscilloscope.fhdm.xyz/ · Repo docs: https://github.com/fhdm-dev/scoppy
- Firmware `.uf2`: https://github.com/fhdm-dev/scpdl1 (v18/v19)
- Fuente firmware (viejo/más completo): https://github.com/mars-low/scoppy-pico

---

## 7. Notas de licencia / cloud (hallazgos colaterales `f1/g.java`)
- La app consulta un servidor de config remoto (`config.txt` y `sync.txt`, host ofuscado
  en formato xored) con `app=1031` y varios campos de hardware.
- Preferencias de licencia: `"biblnp"`, `"bible"`, `"mblnp"` con formato
  `CLAVE:listaDispositivos:hashDispositivo[:ids]`; `f1.g` fija `C0078f.f2390l` a 1 o 2 según
  la clave → nivel de "compra/extras".

## 8. Sistema de compra in-app / premium
- Productos Google Play: **`scoppy.premium.lifetime`** (pago único) y
  **`scoppy.premium.subscription`** (suscripción). Billing Library 8.0.0;
  `com.android.billingclient.api`.
- Activity: `xyz.fhdm.billing.InAppPurchaseActivity` — **NO exportada**, y con
  `getIntent().getBooleanExtra("debug",false)` activa un panel de debug (forzar
  compra/consumo/dumps) solo alcanzable desde dentro de la app.
- Estado en memoria: `L2.k.f1174a` (sku→Boolean), `f1175b` (sku→Purchase),
  `f1176c/f1177d` (sets pendientes/no-ack).
- Verificación/persistencia `L2.k.a()/e()`: al confirmar la compra de Play se persiste el
  SKU en **SharedPreferences `xyz.fhdm.scoppy_preferences`, clave `AEX01Z0HRA5492FG.3`**
  (StringSet). Se re-valida de forma periódica (`L2.k.f()`) y puede revertirse.
  Gate global: `S1.e.g()` = `L2.k.b() || trialActivo` (libera 2º canal / sin anuncios).
  Gate por suscripción en `L2/q.java:225` (dialog "please upgrade to use this feature").
- `L2.c.f1163c/f1164d` = estado "trial" (publicidad antes de upgrade).
- `f1.g` informa al servidor cloud: `config.txt?...&ppp=<esPremium>` y `sync.txt?...&ec=<nivel>`.

## 9. Accesibilidad de datos en el dispositivo (ADB)
- APK: `pm path xyz.fhdm.scoppy` (base.apk + split_config.es/xxhdpi).
- Datos privados en `/data/user/0/xyz.fhdm.scoppy` — **no accesibles sin root**:
  - app NO `android:debuggable` (falla `run-as`)
  - `android:allowBackup="false"` (falla `adb backup`)
  - sin datos en `/sdcard/Android/data/xyz.fhdm.scoppy`
- Forma de liberar extra del firmware: `.uf2` → no descompila de datos del usuario.

## 10. Verificación en vivo (pruebas de red con la Pico W)
Configuración observada (WiFi AP de la Pico, SSID `SCOPPY-E6614C311B852039`):
- La Pico W actúa como AP/DHCP en **192.168.4.1** (gateway). El teléfono obtiene IP
  **192.168.4.16**; la PC conectada al mismo AP obtiene p.ej. 192.168.4.17.
- **Puerto de control 22483**:
  - Con la app Scoppy abierta y sincronizada, `/proc/net/tcp6` del teléfono muestra la
    conexión `192.168.4.16 → 192.168.4.1:22483` **ESTABLISHED** (st=01), con datos
    entrantes pendientes (ej. 1460 bytes = SYNC/datos esperando lectura).
  - El puerto responde al TCP handshake (SYN-ACK) mientras la app mantiene su sesión.
  - La Pico **solo atiende UNA sesión de control**: con la app activa, un segundo cliente
    hace timeout en `connect`; con la app cerrada, pasada la ventana (~30 s) deja de
    aceptar conexiones.
  - No envío nada más al conectar: la iniciativa es de la Pico (manda SYNC msg 60/0x3C).
- **Puerto de datos 22484**: no visible como servicio escuchando para un tercero; solo se
  abre dentro de la sesión establecida de la app (es el canal de datos de forma de onda).
- Todas las tramas confirmadas por la app en el smali (opcodes 60-63 Pico→App, 80-92
  App→Pico) son coherentes con estos flujos.
- **Límite de captura**: en modo managed una tarjeta WiFi NO ve los frames encriptados
  (WPA2) dirigidos a otras estaciones, por lo que la PC no puede capturar el payload de la
  comunicación teléfono↔Pico sin modo monitor + claves del handshake.
