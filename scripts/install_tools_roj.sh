#!/bin/bash
# Script para instalar herramientas de ingenieria inversa de Android
# Ejecutar como: sudo bash install_tools_roj.sh

set -e

echo "========== Actualizando repositorios =========="
# Ignorar errores de repositorios rotos (p.ej. Cloudflare) sin bloquear la instalacion
# Temporalmente se desactiva el repo roto, se actualiza y se restaura
CF_LIST=/etc/apt/sources.list.d/cloudflare-client.list
if [ -f "$CF_LIST" ]; then
    mv "$CF_LIST" "$CF_LIST.bak"
fi
apt-get update -qq || true
if [ -f "$CF_LIST.bak" ]; then
    mv "$CF_LIST.bak" "$CF_LIST"
fi

echo "========== Instalando herramientas de analisis de APK =========="
# Herramientas basicas
apt-get install -y -qq unzip zip file binutils openjdk-17-jdk-headless apktool

echo "========== Instalando jadx (desde GitHub, no esta en apt) =========="
# jadx: descompilador de APK/DEX a codigo Java
if ! command -v jadx &> /dev/null; then
    JADX_VERSION="1.5.0"
    wget -q -O /tmp/jadx.zip "https://github.com/skylot/jadx/releases/download/v${JADX_VERSION}/jadx-${JADX_VERSION}.zip"
    mkdir -p /opt/jadx
    unzip -q -o /tmp/jadx.zip -d /opt/jadx
    ln -sf /opt/jadx/bin/jadx /usr/local/bin/jadx
    ln -sf /opt/jadx/bin/jadx-gui /usr/local/bin/jadx-gui
    chmod +x /opt/jadx/bin/jadx /opt/jadx/bin/jadx-gui
    rm -f /tmp/jadx.zip
    echo "jadx instalado en /opt/jadx (via symlink /usr/local/bin/jadx)"
else
    echo "jadx ya esta instalado"
fi

echo "========== Instalando dex2jar (desde GitHub, no esta en apt) =========="
# dex2jar: convierte dex a jar para descompilar
if ! command -v d2j-dex2jar &> /dev/null; then
    wget -q -O /tmp/dex2jar.zip "https://github.com/pxb1988/dex2jar/releases/download/v2.4/dex-tools-v2.4.zip"
    mkdir -p /opt/dex2jar
    unzip -q -o /tmp/dex2jar.zip -d /opt/dex2jar
    chmod +x /opt/dex2jar/*/d2j-*.sh
    for tool in /opt/dex2jar/*/d2j-*.sh; do
        name=$(basename "$tool" .sh)
        ln -sf "$tool" "/usr/local/bin/$name"
    done
    rm -f /tmp/dex2jar.zip
    echo "dex2jar instalado en /opt/dex2jar"
else
    echo "dex2jar ya esta instalado"
fi

echo "========== Instalando Fernflower (Java decompiler) =========="
# fernflower viene con IntelliJ, usaremos CFR como alternativa
apt-get install -y -qq unzip
wget -q -O /usr/local/bin/cfr.jar https://github.com/leibnitz27/cfr/releases/download/0.152/cfr-0.152.jar
cat > /usr/local/bin/cfr << 'EOF'
#!/bin/bash
exec java -jar /usr/local/bin/cfr.jar "$@"
EOF
chmod +x /usr/local/bin/cfr
echo "CFR decompiler instalado en /usr/local/bin/cfr"

echo "========== Instalando androguard (Python) =========="
pip3 install --break-system-packages androguard 2>/dev/null || pip3 install androguard

echo "========== Resumen de herramientas =========="
echo "jadx      -> $(command -v jadx || echo 'NO ENCONTRADO')"
echo "apktool   -> $(command -v apktool || echo 'NO ENCONTRADO')"
echo "d2j-dex2jar -> $(command -v d2j-dex2jar || echo 'NO ENCONTRADO')"
echo "cfr       -> $(command -v cfr || echo 'NO ENCONTRADO')"
echo "androguard -> $(command -v androguard || echo 'NO ENCONTRADO')"

echo ""
echo "========== INSTALACION COMPLETA =========="
echo "Ya puedes descomprimir y analizar el APK en:"
echo "  /mnt/disk/src/flutter_src/scoppy_pico/apk_analysis/"
