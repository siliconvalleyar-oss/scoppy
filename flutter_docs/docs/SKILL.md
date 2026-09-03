---
name: scoppy-re
description: Ingeniería inversa y protocolo del osciloscopio Scoppy (app Android xyz.fhdm.scoppy + firmware Pico/Pico W). Usar para analizar la comunicación App↔Pico (USB/WiFi), opcodes, transporte, firmwares, compra in-app o replicar clientes/servidores Scoppy.
---

# Skill: Scoppy Reverse-Engineering (app ↔ Pico/Pico W)

Conocimiento acumulado el 2026-09-01: análisis de la app Android **Scoppy**
(`xyz.fhdm.scoppy` v1.031), firmware **scoppy-pico(-w)-v18** (Pico 2: v19) y
protocolo de comunicación verificado en vivo.

Workspace: `/mnt/disk/src/flutter_src/scoppy_pico`
Doc canónica: `flutter_docs/PROTOCOLO_SCOPPY.md` (la fuente real y verificada).

> AVISO: `pico_docs/*.md` contiene documentación previa ESPECULATIVA de un
> firmware antiguo (comandos USB 0x01-0x0B con empaquetado 10-bit). El protocolo
> REAL de la app actual usa el framing/opcodes de abajo — usar siempre lo verificado.

---

## 1. Artefactos y herramientas

| Ruta / utilidad | Descripción |
|---|---|
| `apk_analysis/base.apk` | APK original (3.3 MB) + splits |
| `apk_analysis/decompiled/sources/` | Código Java via jadx (proguard-ofuscado) |
| `apk_analysis/apktool_out/smali/` | Smali via apktool (para lo que jadx no decompila) |
| `firnware_scoppy_for_pico/scoppy-picow-v18.uf2` | Firmware Pico W |
| `capturar_pico.sh` | Captura tcpdump (requiere sudo) |
| `install_tools_roj.sh` | Instala jadx/apktool/dex2jar/cfr (sudo) |
| jadx 1.5.0 (`/opt/jadx`) | Decompilador dex→java |
| apktool 2.7.0 | decompile/recompile APK + smali |
| apkanalyzer (SDK de optimus) | Manifest legible: `apkanalyzer manifest print base.apk` |

Claves del manifest: package `xyz.fhdm.scoppy`, versionName **1.031**/code **1031**,
minSdk 23, targetSdk 36, `uses-feature android.hardware.usb.host`, Activity
principal `ScopeActivity`. App **no debuggable**, `allowBackup=false`
(datos privados inaccesibles sin root).

---

## 2. Transportes

### USB serial (Pico y Pico W vía cable)
- VID/PID del Pico **0x2E8A:0x000A** (Raspberry Pi). También acepta FTDI
  (0x0403), CH340/PL2303 (0x4348, 0x1A86), CP210x, CDC genérico.
- Clases: `V2/J.java` (conector), `j3/b.java` (serial), `O0/*` (VID/PID).
- El firmware v18 usa CDC-ACM: 2 interfaces (control+data), endpoints
  bulk 64 B (EP2 OUT/IN).

### WiFi (Pico W)
- La Pico W es AP/DHCP en **192.168.4.1** (SSID `SCOPPY-<MAC>`), o cliente/station
  de la LAN (IP en `V2/A.java`: `192.168.4.1` AP, `10.233.28.172` LAN).
- Puertos: **control 22483** (0x57D3), **datos 22484** (0x57D4).
- Cliente TCP: `V2/A.java` (f2342p=control, f2343q=datos); escritor `V2/z`.
- La Pico:
  - Acepta **UNA sola sesión de control** a la vez. Con la app activa, otros
    clientes hacen timeout; tras cerrar la app la ventana se agota (~30 s).
  - Toma la iniciativa al conectar: manda el mensaje SYNC (60) y datos.
  - El puerto 22484 solo se abre dentro de la sesión de la app.

---

## 3. Trama común

```
byte0 = 0xFF                    (sync)
byte1-2 = longitud total (BE)
byte3  = opcode
byte4  = opcode + 5             (confirmación; si no: "Unexpected message type confirmation")
byte5  = version >= 1           (el mensaje RUN usa 3)
byte6..payload
```
Los mensajes App→Pico de ida al frontend (APP_TO_FRONTEND) se cierran con un
byte terminador **0x56 (86)**. Mensajes con opcode desconocido se descartan
consumiendo todo el frame. Buffer de entrada: 64 kB; lecturas 1B/2B/4B/8B BE.

---

## 4. Mensajes App → Pico (`f1/g.java`, `V2/H.java`)

| OP | Hex | Payload |
|----|-----|---------|
| 61 | 0x3D | Setup canales (`f1.g.d`): `[6]=flags (analog 3, logic 19)`, `[7]=nº canales`, 1 B/canal `(canal&0xF)\|(rango<<4)`, int timebase ms, int -1, byte 1 |
| 62 | 0x3E | Config FRONTEND_TO_APP (`f1.g.f`): `[6]=0,[7]=1,[8]=1` + config `P2.f` |
| 80 | 0x50 | RUN (`H` case 1): `[5]=3`; `[6]=(muestreo<<2)\|runmode`; `[7..10]=int MD5(str(m)+\"Err[45]:9397\")` con m=i7+693 (anti-fake); nº canales+flags; sample-rate; long timebase; trigger (13 B) + pre/post-trigger (1 B c/uno) |
| 81 | 0x51 | Heartbeat/timebase (`H.c`) |
| 82 | 0x52 | Listado de canales activos |
| 83 | 0x53 | Trigger settings (`f1.g.v`, 13 B): modo, canal, tipo, short nivel, long 0, long 0 |
| 84 | 0x54 | Params volts/div: tipo, 0xFF, long timeout ms, short 50 |
| 85 | 0x55 | Trigger level: 4 B |
| 87 | 0x57 | Volt/div por canal: 1 B |
| 88 | 0x58 | Offset por canal (canales 0-7): canal, nivel |
| 90 | 0x5A | Request info: `[6]=3,[7]=1,[8]=grupo&7` |
| 91 | 0x5B | Config APP_TO_FRONTEND = 62 + terminador |
| 92 | 0x5C | Heartbeat con byte de control |

El `V2/H` reenvía mensajes cada 250 ms con deduplicación (`a()`), alternando
token si pasa >1 s.

### Campo anti-fake (importante para replicar el cliente)
El RUN (80) incluye un int calculado como `MD5(<m>\|"Err[45]:9397")` con
`m = nonce + 693` (4 primeros/últimos bytes del digest sin firmar). El firmware
v18 contiene la MISMA cadena `Err[45]:9397` (verificado en el binario del .uf2).

---

## 5. Mensajes Pico → App (`V2/w.a()`)

| OP | Hex | Descripción |
|----|-----|-------------|
| 60 | 0x3C | SYNC / info del frontend → `V2/C0078f` (firmware version, canales, rangos de voltaje); marca estado SYNCHRONISED |
| 61 | 0x3D | Datos de waveform/trigger → shorts[][] para OpenGL; nº de streams con flags (xor 0xFF en modo lógico) |
| 62 | 0x3E | Config del frontend (`P2.f`, máx 0x800 B) |
| 63 | 0x3F | Params volts/div: lista de ints; 1º ∈ {0,10,20,30,40} selecciona estado `V2/a` |

Estados (`V2/r`): DISCONNECTED → CONNECTED → SYNCHRONISED.

---

## 6. Constantes

- Sample rates (`V2/G`): SR_0_5 (500 kS/s), SR_1_3 (1.3 MS/s), SR_2_0 (2 MS/s),
  SR_2_5 (2.5 MS/s); pref `"rp2040msr"`.
- FDMC: `V2/t` APP_TO_FRONTEND / FRONTEND_TO_APP.
- Firmwares: Pico **v18**, Pico 2 **v19** (los descargan de fhdm-dev/scpdl1).
- El .uf2 v18 responde al SSID AP `SCOPPY-<MAC>`; guarda config en flash con
  magic (rechaza "unmatched magic 2"); strings de GPIO/VR ("CH1 ADC", "Trigger
  LED", etc.).

---

## 7. Verificación en vivo (lecciones)

- El SSID AP `SCOPPY-<MAC>`: la Pico W es 192.168.4.1; el teléfono/cliente
  obtiene p.ej. 192.168.4.16 y la PC 192.168.4.17.
- EVIDENCIA de que la Pico responde: con la app sincronizada, `/proc/net/tcp6`
  del teléfono muestra `192.168.4.16 → 192.168.4.1:22483` ESTABLISHED con datos
  entrantes (ej. 1460 B pendientes).
- **Captura tcpdump limitada**: en modo managed la tarjeta WiFi no ve frames
  WPA2 de otras estaciones → para ver el payload app↔Pico hace falta modo
  monitor + claves, o capturar en el propio host o vía USB.
- Pruebas de puerto útiles (sin root): `nc -zvw2 192.168.4.1 22483`,
  `cat /proc/net/tcp6` del teléfono via adb.

---

## 8. Compra in-app / premium

- SKUs: `scoppy.premium.lifetime` (pago único) y `scoppy.premium.subscription`.
- Activity: `xyz.fhdm.billing.InAppPurchaseActivity`, NO exportada, con hook
  `debug=true` interno (solo alcanzable desde dentro de la app).
- Estado persistido: SharedPreferences `xyz.fhdm.scoppy_preferences`, clave
  **`AEX01Z0HRA5492FG.3`** (StringSet con los SKUs comprados). Se re-valida
  periódicamente (`L2.k.f()`) y puede revertirse.
- Gates: `S1.e.g()` = `L2.k.b() || trialActivo` (libera 2º canal / sin anuncios);
  `L2/q.java` pide suscripción para algunas features.
- Cloud: la app consulta `config.txt`/`sync.txt` de fhdm (URL ofuscada con xor)
  con `app=1031`, `ppp=<esPremium>`, `ec=<nivel>`; comandos remotos BIBLNP/BIBLE/
  MBLNP/MBLE y AVNP/AVSE/AVSS/AVMM/AVEE.

---

## 9. Flujo recomendado para nuevos análisis

1. `apkanalyzer manifest print base.apk` → paquete/versión/permisos/activities.
2. jadx a `decompiled/sources/`; si algo no decompila, leer el smali de
   `apktool_out/` (ej. `smali/V2/w.smali` para el parser entrante).
3. Localizar el transporte activo (`V2/A` WiFi, `V2/J` USB) y los bytes que
   camino por el bus.
4. Verificar contra el firmware real (strings del binario UF2 extraído, no los
   docs especulativos) y contra la red en vivo.
5. Documentar en `flutter_docs/` (toda `*.md` generada va ahí).