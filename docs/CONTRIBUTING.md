# Contributing

Guía para contribuir al proyecto **Scoppy**.

## Flujo de trabajo

Este repo sigue el flujo definido en [WORKFLOW.md](WORKFLOW.md) y las reglas de
versionado de [LEARNINGS.md](LEARNINGS.md):

1. Trabaja en una rama (p. ej. `flutter_for_pico`).
2. Haz cambios de código/documentación **localmente** (`$PWD`).
3. Commit con **conventional commits**:
   - `feat:` nueva funcionalidad
   - `fix:` corrección
   - `docs:` documentación
   - `chore:` mantenimiento
   - `refactor:` refactorización
   - `test:` pruebas
4. **Todo push lleva su tag** (ver versionado).
5. Pushea la rama y el tag.

## Estructura

- `docs/` — documentación.
- `app/` — aplicación Flutter.

## Estándares de código

- La app está en `app/` con Dart/Flutter; ejecuta `flutter analyze` antes de
  contribuir.
- No escribas comentarios innecesarios; sigue el estilo del archivo.
- Mantén la documentación actualizada cuando cambies comportamiento.

## Pull requests

- Describe el cambio y por qué.
- Verifica que `flutter analyze` y `flutter test` pasan.
- Asocia el cambio a su versión/tag cuando aplique.