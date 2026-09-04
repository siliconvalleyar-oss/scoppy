#!/usr/bin/env bash
# Captura el trafico WiFi hacia/desde la Pico Scoppy (192.168.4.1 / celular 192.168.4.x)
# 1) ANTES de ejecutar: abre la app Scoppy en el telefono, conectate al WiFi
#    SCOPPY-E6614C311B852039 y pulsa RUN hasta que diga "WiFi OK".
# 2) Ejecuta:   sudo bash capturar_pico.sh
# 3) Mientras corre (30 s), mueve ajustes en pantalla (volt/div, canales, RUN/Stop).
# Requisito: la PC debe estar conectada al mismo WiFi de la Pico.

IFACE=wlx00e0388fb154
OUT=/tmp/opencode/scoppy2.pcap

echo "Capturando en $IFACE durante 30 segundos -> $OUT"
echo "La app debe estar ABIERTA y SINCRONIZADA. Mueve controles de la app ahora."
sudo timeout 30 tcpdump -i "$IFACE" -nn -s0 -w "$OUT"
echo "=== Resultado ==="
ls -la "$OUT"