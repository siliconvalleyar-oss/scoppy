# TODO - Próximos Pasos

## Análisis Estático del Firmware

### Firmware UF2
- [ ] Extraer el payload ARM y mapear secciones de código vs datos
- [ ] Localizar el stack USB (TinyUSB/Cypress) y el handler de vendor requests
- [ ] Correlacionar códigos `0x9a / 0x1312 / 0xf2c` con la lógica interna
- [ ] Identificar el formato exacto de empaquetado de muestras ADC en EP2 IN
- [ ] Buscar la inicialización del servicio TCP 22483 en el firmware

### APK Android
- [ ] Revisar `P0/d`, `P0/e`, `P0/f`, `P0/g`, `P0/h` para encontrar más comandos
- [ ] Buscar en el APK el parser de la respuesta de 41 bytes del puerto 22483
- [ ] Extraer todos los strings de comando/errores relevantes
- [ ] Analizar la clase `LI2/a` (buffer circular) y su interacción con USB
- [ ] Buscar referencias a `set_sample_rate`, `set_trigger`, `start`, `stop`

### Correlación APK ↔ Firmware
- [ ] Cruzar los command codes del APK con constantes en el firmware
- [ ] Buscar `0x9a`, `0x1312`, `0xf2c` en el código ARM del firmware
- [ ] Verificar si el comando `q([B)` (`0xC0, 0x95, 0x706`) tiene respuesta documentada
- [ ] Confirmar si EP2 OUT realmente se usa o solo es para compatibilidad CDC

## Análisis Dinámico

### Captura de Tráfico USB
- [ ] Capturar tráfico USB con Wireshark + USBPcap (Windows) o `tshark` (Linux)
- [ ] Identificar los comandos exactos enviados por la app Android
- [ ] Capturar el formato de los paquetes de muestras en EP2 IN
- [ ] Documentar el handshake completo de inicialización

### Análisis del Servicio 22483
- [ ] Capturar tráfico TCP en `192.168.4.1:22483` con tcpdump/wireshark
- [ ] Enviar payloads variados y comparar respuestas
- [ ] Buscar en el APK el código que parsea la respuesta de 41 bytes
- [ ] Determinar si el servicio acepta comandos o es solo beacon
- [ ] Analizar si la respuesta cambia entre versiones de firmware

### SSH en 192.168.4.1:22
- [ ] Verificar si el SSH es parte del firmware o un overlay externo
- [ ] Intentar acceso con credenciales por defecto
- [ ] Si es accesible, extraer información del sistema

## Reimplementación

### Firmware Clon (RP2040)
- [ ] Configurar proyecto con TinyUSB + RP2040 SDK
- [ ] Implementar descriptor USB idéntico al de `0x452E4`
- [ ] Implementar CDC-ACM + endpoints bulk (EP2 IN/OUT)
- [ ] Implementar handler de vendor requests (`0x9a`)
- [ ] Configurar ADC + DMA para sampling
- [ ] Implementar buffer circular para pre-trigger
- [ ] Implementar motor de trigger (hardware/software)
- [ ] Implementar streaming por EP2 IN en bloques de 64 bytes
- [ ] Integrar WiFi (CYW43) en modo AP con SSID `SCOPPY-<MAC>`
- [ ] Implementar servicio TCP en puerto 22483 con respuesta de 41 bytes
- [ ] Implementar mDNS (_scoppy._tcp / _scoppyx._tcp)

### Herramientas de Análisis
- [ ] Crear parser de la respuesta de 41 bytes del puerto 22483
- [ ] Crear generador de tráfico de prueba para el servicio 22483
- [ ] Crear script de captura y análisis de protocolo USB
- [ ] Implementar fuzzer básico para el servicio 22483

## Documentación

### Mejoras Pendientes
- [ ] Completar tabla de sample rates con valores exactos del firmware
- [ ] Documentar el formato de muestra ADC (8-bit vs 10-bit packed)
- [ ] Extraer y documentar todos los strings de error del firmware
- [ ] Documentar el formato de configuración guardada en flash
- [ ] Crear diagrama de estados del protocolo USB
- [ ] Documentar el proceso de descubrimiento mDNS completo

### Análisis de Versiones
- [ ] Comparar v18 con v19 (si está disponible)
- [ ] Analizar diferencias entre Pico, Pico W y Pico 2
- [ ] Documentar cambios en el protocolo entre versiones

## Investigación

### Preguntas Abiertas
- [ ] ¿El servicio 22483 es solo para discovery o también para control?
- [ ] ¿Qué contiene exactamente el byte 0xFF al inicio de la respuesta de 22483?
- [ ] ¿Cómo se calcula/valida el checksum de la respuesta de 22483?
- [ ] ¿El APK usa EP2 OUT en alguna versión/funcionalidad?
- [ ] ¿Qué hace el comando `0x95` (lectura específica)?
- [ ] ¿El puerto 22/SSH es parte del firmware o un overlay del sistema?

### Fuentes Adicionales
- [ ] Buscar si hay código fuente abierto de Scoppy en GitHub
- [ ] Revisar el wiki oficial para documentación del protocolo
- [ ] Buscar proyectos alternativos que implementen protocolos similares
- [ ] Analizar el bootloader UF2 para entender el formato completo

## Validación

### Tests
- [ ] Verificar que el descriptor USB extraído es correcto
- [ ] Validar el mapeo de GPIOs contra el hardware real
- [ ] Probar el formato de SSID con diferentes MACs
- [ ] Validar el cálculo de sample rates contra la app Android
- [ ] Verificar que la respuesta de 22483 se reproduce correctamente

### Hardware
- [ ] Probar el firmware original en Pico W real
- [ ] Medir consumo de corriente en diferentes modos
- [ ] Verificar latencia de respuesta USB
- [ ] Medir precisión del ADC a diferentes sample rates
