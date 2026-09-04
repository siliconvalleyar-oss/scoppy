# TODO - Próximos Pasos

## Firmware C++ (RP2040 / Pico W)

### Proyecto base
- [x] Crear estructura de proyecto C++ para RP2040
- [x] Configurar build system (CMake + Pico SDK)
- [x] Configurar TinyUSB como submódulo/dependencia
- [x] Crear `src/` y `include/` con módulos base

### USB (TinyUSB)
- [ ] Implementar device descriptor idéntico a `0x452E4`
- [ ] Implementar configuración CDC-ACM (IAD + 2 interfaces)
- [ ] Implementar endpoints: EP1 IN Interrupt, EP2 IN/OUT Bulk
- [ ] Implementar handler de vendor requests (`0x9a`, `0x1312`, `0xf2c`)
- [ ] Implementar parser de comandos por EP2 OUT
- [ ] Implementar streaming de muestras por EP2 IN

### ADC + DMA
- [ ] Configurar ADC RP2040 para 2 canales (GPIO26/GPIO27)
- [ ] Implementar buffer circular con DMA
- [ ] Implementar motor de trigger (hardware/software)
- [ ] Soportar sample rates: 500k/1.3M/2.0 MS/s

### WiFi / Red
- [ ] Inicializar CYW43439 en modo AP
- [ ] Generar SSID `SCOPPY-<8-bytes-MAC-hex>`
- [ ] Implementar mDNS (`_scoppy._tcp` / `_scoppyx._tcp`)
- [ ] Implementar servicio TCP en puerto `22483` con respuesta de 41 bytes
- [ ] Implementar modo Station/Client con DHCP

### Aplicación host / herramientas
- [ ] Crear CLI en Python/C++ para descubrimiento de dispositivos
- [ ] Crear parser de la respuesta de 41 bytes del puerto 22483
- [ ] Crear generador de tráfico de prueba para el servicio 22483

## Documentación

### Pendiente
- [ ] Completar tabla de sample rates con valores exactos
- [ ] Documentar formato de muestra ADC (8-bit vs 10-bit packed)
- [ ] Extraer y documentar strings de error del firmware
- [ ] Documentar formato de configuración guardada en flash

## Investigación

### Preguntas abiertas
- [ ] ¿El servicio 22483 acepta comandos o es solo beacon?
- [ ] ¿Cómo se calcula/valida el checksum de la respuesta de 22483?
- [ ] ¿El APK usa EP2 OUT en alguna versión/funcionalidad?
- [ ] ¿El puerto 22/SSH es parte del firmware o un overlay externo?

## Validación

### Tests
- [ ] Verificar descriptor USB contra hardware real
- [ ] Validar GPIOs contra documentación oficial
- [ ] Probar formato de SSID con diferentes MACs
- [ ] Validar cálculo de sample rates
- [ ] Verificar respuesta de 22483 se reproduce correctamente
