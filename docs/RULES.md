# Rules

Reglas de trabajo del proyecto **Scoppy**.

## Versionado y publicación

1. **Todo push lleva su tag.** No se hace `git push` sin asociar un tag de
   versión.
2. **VERSIÓN en `VERSION`** (raíz): valor sin `v` (p. ej. `1.0.0`). El tag
   lleva `v` (`v1.0.0`).
3. **Conventional commits**: `feat:`, `fix:`, `docs:`, `chore:`, `refactor:`,
   `test:`.
4. **Ciclo de patch 0-9**: dentro del mismo minor van `1.0.0 … 1.0.9`; al
   llegar a 9 se promueve el minor (`1.1.0`).
5. **No retroceder versiones.**

## Repositorio

- Rama principal de desarrollo Flutter: **`flutter_for_pico`**.
- `main` solo presenta el README; `scoppy_pico` contiene `pico_docs/`.
- Directorios excluidos que NO se suben: `apk_analysis/`, `tmp/`,
  `scoppy_of_git/`, `pico_docs/`, `firmware_scoppy_for_pico/`,
  `capturar_pico.sh`, `install_tools_roj.sh`.

## Código

- La app Flutter está en `app/`; pasa `flutter analyze`.
- No añadir comentarios innecesarios; seguir el estilo del proyecto.
- No exponer credenciales/tokens (ver `SECURITY.md`).

## Documentación

- Mantener sincronizada la documentación de `docs/` con el comportamiento.
- La doc de protocolo y funcionalidad se basa en la ingeniería inversa real.