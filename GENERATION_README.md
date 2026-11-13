# Generador procedural — v0

Primera versión del motor de generación de MinnoGhram (Godot 4.3+, probado también en 4.7.2).
Implementa 2 de las 17 etapas del pipeline de `02_Procedural_Generation_Bible.md`.

## Qué incluye

| Archivo | Qué hace |
|---|---|
| `core/seed_hash.gd` | Hash propio FNV-1a versionado. Convierte texto en Seed y deriva una sub-seed por etapa. |
| `generation/world_profile.gd` | `WorldProfile` como Resource (datos del mundo, sin código por mundo). |
| `generation/world_state.gd` | Resultado de la generación: heightmap, sub-seeds, checksum, imagen 2D. |
| `generation/world_generator.gd` | Ejecuta las etapas en orden, con reintentos deterministas si una falla su validación. |
| `generation/stages/` | Etapa 1 (Configuración Global) y Etapa 2 (Macro-relieve). |
| `world/terrain_mesh_builder.gd` | Convierte el heightmap en malla 3D + colisión `HeightMapShape3D`. |
| `scenes/terrain_preview.tscn` | Escena de prueba. La isla aparece en el editor; cambia `Seed Text` en el Inspector. Con F6: **R** = nueva Seed, **P** = guardar PNG. |
| `data/world_profiles/oppervlak.tres` | Perfil de Oppervlak. Edítalo en el Inspector y vuelve a ejecutar. |
| `tests/test_determinism.gd` | Prueba que la misma Seed da siempre el mismo mundo. |
| `tools/seed_visualizer.gd` | Genera PNGs de varias Seeds sin abrir el juego. |

## Cómo usarlo

1. Copia las carpetas `core/ generation/ world/ scenes/ data/ tests/ tools/` a la raíz de tu proyecto.
2. Abre Godot, deja que importe, abre `scenes/terrain_preview.tscn` y pulsa **F6**.
3. Pruebas desde terminal:
   ```
   godot --headless --script res://tests/test_determinism.gd
   godot --headless --script res://tools/seed_visualizer.gd -- 1 42 dragon
   ```

## Reglas de arquitectura que ya aplica

- Ninguna etapa usa `randi()`/`randf()` globales ni la Seed maestra: solo su sub-seed.
- Ninguna etapa pregunta "¿qué mundo es?": todo sale del `WorldProfile`.
- Si una etapa no cumple su regla (ej. poca tierra), se reintenta con `derive(seed, etapa, intento)`.

## Riesgo conocido

`FastNoiseLite` es del motor. Si una versión futura de Godot cambia su implementación,
los mundos de Seeds ya compartidas cambiarían. Las huellas (`GOLDEN`) del test lo detectan.
Si pasa, la solución es implementar nuestro propio ruido (decisión para un ADR).

## Siguiente paso

Etapa 3 (Hidrografía: ríos y lagos) y Etapa 4 (Clima), y después Biomas.
