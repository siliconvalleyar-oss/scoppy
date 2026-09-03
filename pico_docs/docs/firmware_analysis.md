# Análisis de Ingeniería Inversa - Firmware Scoppy para Raspberry Pi Pico W

## Información General

| Campo | Valor |
|-------|-------|
| **Firmware analizado** | `scoppy-picow-v18.uf2` |
| **Target** | Raspberry Pi Pico / Pico W (RP2040) |
| **Build** | `scoppy-picow-v18` (firmware version 18) |
| **USB Vendor ID** | `0x2E8A` (Raspberry Pi Foundation) |
| **USB Product ID** | `0x000A` |
| **USB Device Class** | `0xEF` (Miscellaneous / IAD composite device) |
| **WiFi** | Sí (Pico W, chip Cypress CYW43439) |
| **Modo USB** | CDC-ACM ( Communications Device Class ) |
| **Modo WiFi** | Access Point + mDNS discovery |

---

## Estructura del Archivo UF2

El archivo `scoppy-picow-v18.uf2` es una imagen UF2 modificada/no-estándar para el RP2040.

### Cabecera UF2

| Campo | Offset | Valor observado |
|-------|--------|-----------------|
| Magic | 0x00 | `UF2\n` (0x5546520A) |
| Flags | 0x04 | `0x9E5D5157` (bit 31: extension, bit 17: non-main) |
| Payload addr | 0x08 | `0x00002000` |
| Length | 0x0C | `0x10000000` (268435456, indicador extendido) |
| Block num | 0x10 | `0x00000100` (= 256, **no usado** en este UF2) |
| Total blocks | 0x14 | `0x00000000` (= 0, **no usado**) |
| Total blocks (alt) | 0x18 | `0x00000600` (= 1536, **valor real**) |
| Family ID | 0x1C | `0xE48BFF56` (RP2040) |

> **Nota:** Este UF2 usa un layout no-estándar donde `total_blocks` está en offset 0x18 (no 0x14) y `block_num` en offset 0x14 (no 0x10). El payload por bloque es 476 bytes (512 - 36).

### Estadísticas del UF2

| Campo | Valor |
|-------|-------|
| Bloques totales | 1536 |
| Tamaño de archivo | 786432 bytes (768 KB) |
| Payload extraído | 731136 bytes (714 KB) |
| Formato del payload | Binario ARM bare-metal (sin ELF header) |

---

## Puntos de Interés en el Binario

| Offset (hex) | Contenido |
|--------------|-----------|
| `0x0000` | Vector de reset / código ARM Thumb de inicio |
| `0x445ED` | Strings: `_scoppyx`, `_scoppy` (nombres mDNS) |
| `0x4509C` | URL del proyecto: `https://github.com/fhdm-dev/scoppy` |
| `0x450D0` | Strings: `scoppy-pico`, `scoppy-picow`, `scoppy-picow-v18` |
| `0x452E4` | **Conjunto completo de descriptores USB** (75 bytes) |
| `0x45330` | USB Device Descriptor (18 bytes) |
| `0x45639` | Strings de configuración y error de magic number |
| `0x4584C` | Patrón de nombre de configuración: `SCOPPY-%02X%02X...` |
| `0x45FE8` | Cadena de nombre de dispositivo: `scoppy` |

---

## Firmware Relacionado en el Repositorio

| Archivo | Target | Versión |
|---------|--------|---------|
| `scoppy-pico-v18.uf2` | Raspberry Pi Pico (sin WiFi) | v18 |
| `scoppy-picow-v18.uf2` | Raspberry Pi Pico W (con WiFi) | v18 |
| `scoppy-pico2-v19.uf2` | Raspberry Pi Pico 2 | v19 |
| `scoppy-pico2w-v19.uf2` | Raspberry Pi Pico 2 W | v19 |
