# MinnoGhram

> Technical Architecture — v0.9 (Borrador, pendiente de aprobación final)
> Documentos base: `00_Project_Vision.md`, `01_Game_Design_Document.md`, `02_Procedural_Generation_Bible.md`

---

## Propósito y alcance

Este documento traduce la intención de diseño (`01`) y la especificación funcional de generación (`02`) a una arquitectura concreta sobre Godot 4 / GDScript: estructura de nodos y escenas, esquemas de Resources, límites entre sistemas, mecanismo de determinismo, sistema de guardado, streaming y contrato de integración de assets.

**Fuera de alcance de este documento** (se resuelven en ADRs o en documentos posteriores):

- Selección definitiva de algoritmo por etapa procedural (`02` los deja como candidatos, no vinculantes).
- Valores numéricos de balance.
- Especificación creativa de arte (paleta, estilo, dirección visual) — eso es `05_Art_Direction.md`; aquí solo se define el **contrato técnico** de integración de assets.

---

## 1. Principios arquitectónicos aplicados a Godot

- **Desacoplamiento vía Signals y Groups.** Los sistemas no se referencian directamente entre sí. Combat nunca llama a Inventory; emite una señal (`damage_dealt`, `entity_died`) que Inventory (u otro sistema) puede escuchar. Groups se usan para consultas transversales (ej. "todas las entidades vivas en este chunk") sin acoplar quién pregunta a quién.
- **Data-Driven vía Resources.** Todo contenido (ítems, NPCs, misiones, biomas, temas de dungeon, `WorldProfile`) es una subclase de `Resource`, almacenada como `.tres` y cargada vía `ResourceLoader`. Añadir contenido nuevo no debe requerir tocar código.
- **Autoloads solo para servicios transversales**, nunca para lógica de gameplay. Ejemplos válidos: `EventBus` (bus de señales globales), `RunManager` (qué Run está activa), `GameClock` (tiempo de juego). Un autoload que empieza a contener lógica de combate o inventario es una señal de que el límite se rompió.
- **Composición sobre herencia para entidades.** Cada entidad (NPC, enemigo, estructura interactiva) es una `PackedScene` ensamblada a partir de nodos-componente reutilizables (`Health`, `Hitbox`, `Hurtbox`, `StatusEffects`, `AIController`) — necesario para sostener "cientos de enemigos" sin duplicar lógica por cada uno.

---

## 2. Composición por Nodos/Escenas vs. ECS

**Decisión**: Godot 4 se usa con su modelo nativo de Nodos/Escenas, no con un ECS (Entity Component System) añadido por encima.

- **Ventaja**: el árbol de escenas de Godot ya es, en esencia, un sistema de composición. Signals, Groups y `PackedScene` resuelven exactamente los problemas que un ECS resolvería, usando herramientas que el editor, el depurador y el profiler ya entienden nativamente.
- **Desventaja / riesgo real**: a escalas muy altas de entidades simuladas simultáneamente, el overhead de Nodos (cada uno con su propio `_process`/`_physics_process`) puede superar a un enfoque data-oriented. Esto se mitiga con **LOD de simulación** (sección 8): las entidades lejanas al jugador no existen como Nodo — son un registro de datos ligero (posición, estado) dentro del chunk serializado, y solo se instancian como escena completa cuando el jugador se acerca.
- **Alternativa descartada**: ECS custom o vía addon. Se descarta para V1 porque duplica herramientas que el motor ya resuelve. **Trigger de revisión** (para ADR futuro): si el profiling muestra que el LOD de simulación no es suficiente a la escala real del juego, ahí se reevalúa — no antes.

---

## 3. Mapa de sistemas y límites de módulos

Cada sistema se comunica hacia afuera solo por señales o por una interfaz pública mínima — nunca alcanzando directamente el estado interno de otro sistema.

| Sistema | Responsabilidad | Depende de | Se comunica vía |
|---|---|---|---|
| **Core** | Autoloads transversales (`EventBus`, `RunManager`, `GameClock`) | Nada específico de gameplay | Todo lo demás puede depender de Core |
| **Generation** | Ejecuta el pipeline de `02` (17 etapas) | Core (sub-seeds) | Produce `WorldState`; no conoce Combat/UI |
| **World** | Terreno 3D materializado, streaming de chunks, `NavigationRegion3D` | Generation (`WorldState`), Core | Expone consultas de terreno/navegación; nunca llama a Entities |
| **Combat** | Daño, esquiva, hitboxes/hurtboxes | Entities, World | Señales (`damage_dealt`, `entity_died`) — nunca referencia Inventory/Quest directamente |
| **Entities** | Librería base de componentes (Health, Hitbox, Hurtbox, StatusEffects, Stats) | Nada por encima | Framework reutilizado por Combat/AI/NPC/Dungeon |
| **Inventory** | Ítems del jugador/NPC | Escucha señales de Combat/Crafting/Economía | Nunca alcanza Combat directamente |
| **Crafting** | Recetas, producción de ítems | Inventory, Resources de recetas | Señal al completar crafteo |
| **Survival** | Hambre/sed/refugio | Core (`GameClock`), World (clima) | Señales (`starving`, `exposed`) que UI escucha |
| **NPC** | Existencia/profesión/agenda de NPCs | Generation (placement), Dialogue, Quest | Depende de Dialogue/Quest, nunca al revés |
| **Dialogue** | Árboles de diálogo data-driven | Resources de diálogo | Puede leer estado de Quest (solo lectura) |
| **Quest** | Máquina de estados de misiones (plantilla → activa → completa) | Generation (NPC/Portales/Biomas) | Señal (`quest_updated`) que UI/Dialogue escuchan |
| **AI** | Framework de comportamiento compartido | Entities, World (navegación) | Usado por NPC y por enemigos de Combat; agnóstico de Quest/Dialogue |
| **Dungeon** | Gestión en tiempo real de instancias de dungeon | Generation (layout), World (streaming) | Entrada/salida, disparo de encuentros |
| **SaveSystem** | Serializa/deserializa una Run completa | Core (`RunManager`) únicamente | Cada sistema implementa `get_save_data()`/`load_save_data()`; SaveSystem nunca conoce el interior de otro sistema |
| **UI** | Presenta estado de todos los sistemas | Escucha señales de todos | Dependencia estrictamente unidireccional — nada depende de UI |

---

## 4. Cámara y control

- **Rig de cámara**: `Camera3D` montada sobre un `SpringArm3D` que orbita al jugador (`CharacterBody3D`) a un ángulo de inclinación (pitch) fijo tipo isométrico (~45–60°). El `SpringArm3D` evita clipping contra geometría y controla el zoom (longitud del brazo, con límites min/max).
- **Rotación**: el yaw de la cámara es controlado por el jugador (arrastre de mouse o stick derecho) — libre, sin los saltos discretos que exigiría un enfoque 2D/HD-2D. Esto es directamente lo que la decisión de mundo 3D real habilita.
- **Movimiento relativo a cámara**: el input del jugador se transforma según el yaw actual de la cámara ("adelante" siempre significa "alejarse de la cámara"), el patrón estándar que hace que la rotación libre se sienta bien (V Rising, Diablo).
- **Física**: `CharacterBody3D` con `move_and_slide()`; el movimiento se restringe al plano horizontal (input en X/Z) más gravedad/seguimiento de terreno en Y — sin vuelo libre.
- **Combate agnóstico de cámara**: hitboxes/hurtboxes son `Area3D` (componente de Entities), con detección de colisión en espacio 3D real — el combate nunca depende del ángulo de cámara, satisfaciendo directamente el pilar del GDD ("la cámara nunca debe interponerse en el combate").

---

## 5. Resources como contenedores Data-Driven

- `WorldProfile` es un `Resource` (`class_name WorldProfile extends Resource`) con campos exportados tipados para cada parámetro definido en `02` sección 4: modo día/noche, rangos de densidad, subconjunto de temas de dungeon, subconjunto de profesiones, modo climático, nivel de hostilidad, modo/probabilidad de ritual, densidad de decoración.
- Ítems, NPCs (definiciones de profesión), misiones (plantillas), temas de dungeon y biomas son subclases de `Resource`, organizadas en una jerarquía de carpetas data-driven (ej. `res://data/items/`, `res://data/npcs/professions/`, `res://data/world_profiles/`).
- **Validación de esquema**: cada tipo de Resource implementa una convención `_validate_schema()` verificada al cargar, para detectar datos malformados temprano — candidato directo a herramienta interna (sección 12).

---

## 6. Determinismo técnico: sub-seeding y streams de RNG

- Cada etapa del pipeline (`02` sección 6) recibe su propia instancia de `RandomNumberGenerator`, sembrada con una sub-seed derivada de la Seed maestra.
- **Riesgo técnico real a señalar**: la función `hash()` nativa de Godot no está garantizada estable entre versiones del motor. Confiar en ella para derivar sub-seeds significa que una futura actualización de Godot podría invalidar silenciosamente Seeds ya compartidas por jugadores. **Recomendación**: implementar una función de hash propia y versionada (ej. FNV-1a o murmur, con un número de versión explícito en el esquema de guardado) bajo control total del proyecto, en vez de depender de la función genérica del motor.
- Ningún sistema puede llamar a `randi()`/`randf()` globales sin sembrar explícitamente — esto debería aplicarse por convención de código, con un chequeo estático como candidato de herramienta interna.

---

## 7. Streaming de mundo 3D: chunks, malla en hilo, LOD

- El mundo se divide en chunks de tamaño fijo (tamaño exacto: pregunta abierta, sección 14).
- La malla de cada chunk se genera a partir de su porción del heightmap de Macro-relieve (`02` sección 6.2) usando `WorkerThreadPool` de Godot 4 — nunca en el hilo principal.
- **LOD de terreno**: múltiples resoluciones de malla por chunk, intercambiadas según distancia a cámara (`GeometryInstance3D` visibility ranges).
- **LOD de simulación de entidades** (resuelve el riesgo de la sección 2): las entidades lejanas al jugador existen únicamente como registro de datos (posición, estado) dentro del chunk serializado — se promueven a escena completa (Nodo instanciado, con física/animación) solo cuando su chunk entra en el radio de streaming del jugador, y se degradan de vuelta a datos cuando el chunk sale de ese radio.
- **Navegación**: `NavigationRegion3D` horneado por chunk (o grupo de chunks) conforme se materializan — hornear el NavMesh del mundo completo por adelantado es inviable a esta escala. Pregunta abierta: hornear en tiempo de generación y serializar el resultado, vs. hornear en tiempo real al hacer streaming (sección 14).

---

## 8. Sistema de guardado

- **Run activa**: `WorldState` completo + estados de entidades (incluyendo las "simuladas pero no instanciadas") + estado del jugador, serializados vía el contrato `get_save_data()`/`load_save_data()` de cada sistema (sección 3), agregados por SaveSystem en un archivo de Run.
- **Hasta 8 Runs activas concurrentes** por perfil de jugador — solo la Run que se está jugando se deserializa en memoria; las otras 7 permanecen como archivos inertes en disco hasta que el jugador elige reanudar una.
- **Run finalizada**: al morir o derrotar al Boss Final, SaveSystem escribe un registro archivado permanente (estadísticas/resultado, según la lista de persistencia del GDD sección 4) en el perfil del jugador, y retira esa Run del pool de slots activos.
- **Pregunta abierta**: ¿el archivo completo del mundo de una Run finalizada se conserva (para un posible "replay" futuro) o se descarta hasta quedarse solo con estadísticas? El GDD no lo especifica — sección 14.
- **Formato de guardado**: se recomienda un formato binario/JSON propio y versionado, con soporte explícito de migración de esquema — en vez de usar `ResourceSaver` directamente sobre las clases de gameplay. **Ventaja**: resiliente a refactors de código futuro (un save no se rompe porque una clase cambió de forma). **Desventaja**: más trabajo manual de (de)serialización. **Alternativa descartada**: `ResourceSaver` nativo sobre objetos de gameplay — se descarta porque acopla el formato de guardado a la forma exacta de las clases de código, rompiéndose en cualquier refactor.

---

## 9. Objetos rituales — estado por-slot del portal en 3D

- El portal es una escena con una lista ordenada de puntos de anclaje (`Marker3D`), uno por cada objeto ritual requerido.
- El estado del portal (a nivel Resource/save data) incluye un arreglo de estados por slot (vacío / ocupado por ítem X) — usado tanto para el estado inicial de precolocación (`02` sección 7.5) como para el llenado progresivo en tiempo de Run (`02` sección 7.4).
- Al ocupar un slot, se instancia la malla/modelo específico de ese objeto ritual en la posición del `Marker3D` correspondiente.
- **Dependencia cruzada con Arte**: cada objeto ritual necesita dos representaciones — versión de icono de inventario y versión "colocada" en 3D — a documentar en `05_Art_Direction.md`.

---

## 10. Pipeline de assets 3D — contrato de integración

- **Formato de importación**: glTF 2.0 como formato estándar de intercambio (la vía nativa/recomendada de Godot 4 para 3D), independientemente de qué herramienta —actual o futura, de IA o manual— produzca el modelo fuente. Esto es lo que hace el pipeline agnóstico de herramienta, como pediste.
- **Convención de esqueleto/rig**: se define una convención única de nombrado de huesos (incluso para criaturas no humanoides, con un mapeo documentado), de forma que los `AnimationLibrary` de Godot 4 (animaciones compartidas entre esqueletos) puedan reutilizarse entre distintos modelos sin re-animar cada uno desde cero — esto es lo que hace viable "cientos de enemigos" sin cientos de sets de animación hechos a mano.
- **Materiales**: un contrato de shader/material estandarizado (una familia reducida de shaders "MinnoGhram Standard") para que materiales hand-painted generados por herramientas distintas se compongan de forma consistente bajo la iluminación del juego.
- La especificación creativa (paleta, estilo, requisitos de concept art) queda en `05_Art_Direction.md` — esta sección solo fija el contrato técnico de integración.

---

## 11. Herramientas internas

| Herramienta | Base arquitectónica |
|---|---|
| Editor de NPC / Loot / Dungeons / Eventos / Misiones | Plugins de editor de Godot (`@tool` + inspectores custom) operando directamente sobre los Resources de la sección 5 — no requieren UI propia separada |
| Debug Console | Autoload ligero de comandos en tiempo de ejecución (spawnear NPC, saltar a bioma, forzar clima), complementario al depurador remoto nativo de Godot |
| Visualizador de Seeds | Ejecuta el pipeline de Generation en modo headless/preview y renderiza los mapas resultantes (elevación/bioma/etc.) como imágenes 2D top-down — permite validar el layout macro de una Seed sin esperar la generación de malla 3D completa |
| Inspector Procedural | Herramienta runtime/editor: clic sobre cualquier entidad generada y ver qué etapa + sub-seed la produjo — crítico para depurar problemas de determinismo |
| Generador de Mundos | Batch-runner sobre Generation para probar muchas Seeds contra la Regla de Alcanzabilidad (`02` sección 11) de forma offline, atrapando bugs de generación antes de que lleguen a jugadores |

---

## 12. Constraints de plataforma y multiplayer-readiness

- **Plataforma principal**: Steam, en Windows y Linux, con **Steam Deck como objetivo explícito** — implica soporte de control desde el día uno y un presupuesto de rendimiento realista para el tuning de chunks/LOD (sección 7).
- No se diseña alrededor de consolas u otras tiendas todavía, pero se evita cualquier cosa que bloquee estructuralmente una exportación futura: rutas de archivo no atadas a un SO específico, input abstraído vía `InputMap` de Godot en vez de chequeos de teclado/mouse hardcodeados.
- **Multiplayer-readiness sin implementar networking ahora**: los cambios de estado de gameplay deben fluir por señales/métodos bien definidos en cada sistema (sección 3) en vez de mutación directa dispersa — así, una capa de multiplayer futura podría interceptar/replicar esas mismas llamadas sin una reescritura. Es una disciplina de diseño, no un andamiaje de red — no se escribe código de RPC/networking ahora.

---

## 13. Preguntas abiertas hacia ADRs

1. **Trigger de revisión Node/Scene vs. ECS**: ¿a qué escala de entidades simultáneas se activa la reevaluación (sección 2)?
2. **Función de hash para sub-seeds**: propia y versionada — confirmar diseño exacto (sección 6).
3. **Tamaño de chunk y estrategia exacta de LOD** (sección 7).
4. **Estrategia de NavMesh**: hornear en tiempo de generación (serializado) vs. en tiempo real al streamear (sección 7).
5. **Formato de guardado**: confirmar el diseño binario/JSON versionado propio recomendado en la sección 8.
6. **Política de retención de Runs finalizadas**: ¿se conserva el mundo completo archivado, o solo estadísticas/resultado? (sección 8)
7. **Selección de algoritmo definitivo por etapa procedural** (heredado de `02` sección 12).
8. **Convención exacta de esqueleto/rig compartido** entre criaturas (sección 10).

---

*Fin del borrador v0.9.*
