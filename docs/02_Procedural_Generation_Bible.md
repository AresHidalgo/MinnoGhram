# MinnoGhram

> Procedural Generation Bible — v1.1 (Revisión: pivote a mundo 3D real)
> Documentos base: `00_Project_Vision.md`, `01_Game_Design_Document.md`

---

## Propósito de este documento

Este documento es la **especificación funcional** del sistema de generación procedural de MinnoGhram. Define **qué debe hacer** cada etapa del generador, qué información produce y qué reglas debe cumplir — no define **cómo** se implementa.

Las decisiones de implementación (algoritmos definitivos, estructuras de datos, optimizaciones, threading) se documentan en `03_Technical_Architecture.md` y en los ADR correspondientes.

---

## 1. Filosofía del sistema procedural

La generación procedural es el corazón de MinnoGhram.

No buscamos únicamente generar un mapa aleatorio.

Buscamos generar una aventura completa.

Cada nueva Seed debe definir un mundo coherente, reproducible y único.

La Seed no solo genera el terreno.

También define la identidad completa de la partida.

Una Run representa la historia que el jugador vive dentro de ese mundo.

---

## 2. Determinismo

La generación es completamente determinista.

Una misma Seed siempre produce exactamente el mismo mundo. Esto incluye absolutamente toda la generación inicial:

- Tamaño del mundo.
- Continentes.
- Relieve.
- Biomas.
- Clima.
- Ríos.
- Cuevas.
- Recursos.
- Dungeons.
- Estructuras.
- Aldeas.
- NPCs.
- Profesiones.
- Economía inicial.
- Misiones iniciales.
- Eventos iniciales.
- Loot inicial.
- Portales.
- Objetos rituales (fijos o seleccionados) y su estado inicial de precolocación.
- Decoración ambiental.

El objetivo es que cualquier jugador pueda compartir una Seed y cualquier otra persona obtenga exactamente el mismo mundo.

---

## 3. Seed vs. Run

### La Seed define

Todo aquello que existe cuando el mundo es creado: geografía, biomas, recursos, NPCs iniciales, dungeons, eventos planificados, misiones disponibles, economía inicial.

### La Run define

Todo aquello que ocurre después: decisiones del jugador, construcciones, combates, muerte de NPCs, comercio, consumo de recursos, IA, clima dinámico, progresión.

**La Seed crea el mundo. La Run crea la historia.**

### Consecuencia para Misiones y Eventos

Algunas entradas de la lista de "La Seed define" (Misiones, Eventos) no son instancias activas, sino **pools deterministas de plantillas disponibles**. Qué misión se activa, en qué momento, y cómo evoluciona un evento depende del estado del jugador — eso pertenece a la Run, no a la Seed. La Seed garantiza *qué es posible* en ese mundo; la Run decide *qué ocurre realmente*.

### Consecuencia para Portales

El mismo principio aplica a los Portales: **la Seed los genera físicamente, la Run hace que el jugador los descubra.** Un portal no aparece por una acción del jugador ni es creado por una misión — ya existe desde el instante en que el mundo se genera. Las misiones solo pueden revelar su ubicación, explicar su funcionamiento, o guiar al jugador hacia él (ver sección 7).

### Nota sobre reutilización de Seed

Esta distinción resuelve la pregunta abierta #1 del GDD (`01_Game_Design_Document.md`, sección 14): dado que una Seed es determinista y no guarda estado de ninguna Run, **nada impide iniciar una Run nueva con una Seed ya usada**. El mundo generado será idéntico en su estado inicial; la nueva Run construirá su propia historia desde cero sobre él, igual que compartir una Seed de Minecraft entre dos jugadores distintos.

### Nota sobre Runs concurrentes

El GDD (sección 4) permite hasta 8 Runs activas simultáneas por jugador. Cada Run ejecuta el pipeline completo de esta sección de forma totalmente independiente — no existe ningún estado compartido entre Runs, ni siquiera si comparten la misma Seed. Solo la Run que el jugador está jugando activamente necesita su mundo materializado en memoria (sección 9); el resto permanece serializado.

---

## 4. Perfiles de Mundo

### Decisión de arquitectura

El sistema de generación procedural es **un único pipeline genérico**, no tres pipelines distintos para Oppervlak, Onderwereld y Voorgeborchte. Cada mundo es una instancia de datos de un **Perfil de Mundo** (`WorldProfile`) que parametriza el comportamiento de cada etapa del pipeline (sección 6).

Un Perfil de Mundo define, entre otros parámetros:

- Si el ciclo día/noche está activo, roto, o ausente.
- Rangos de densidad de biomas, recursos, enemigos, eventos y decoración ambiental.
- El subconjunto de temas de Dungeon disponibles.
- El subconjunto de profesiones de NPC disponibles.
- El modo de comportamiento climático (cíclico normal vs. inestable/caótico).
- El nivel de hostilidad base y la proporción de zonas seguras.
- El modo de selección de objetos rituales de su portal de salida (fijo vs. seleccionado de un pool) y la probabilidad de precolocación (sección 7.5).

### Justificación

- **Ventaja**: añadir un cuarto mundo en el futuro (el proyecto ya lo contempla como plataforma a largo plazo) significa crear un nuevo archivo de datos, no escribir un nuevo generador. Esto es directamente el principio Data-Driven de `00_Project_Vision.md`.
- **Ventaja**: cualquier corrección o mejora a una etapa del pipeline (ej. el algoritmo de Biomas) beneficia a los tres mundos a la vez, sin triplicar el mantenimiento.
- **Desventaja / riesgo**: exige disciplina técnica real. Si una etapa del pipeline necesita una rama de código específica para un mundo ("if world == Onderwereld"), el modelo se rompe silenciosamente. Este riesgo se traslada como restricción explícita a `03_Technical_Architecture.md`.
- **Alternativa descartada**: pipelines especializados por mundo. Se descarta porque viola directamente los pilares de Modularidad y Reutilización del proyecto, y no escala a la ambición de "muchos biomas, muchos NPCs, cientos de enemigos" declarada en la Visión.

Cada etapa de la sección 6 recibe, además de su sub-seed, el `WorldProfile` activo como entrada.

---

## 5. Jerarquía de generación

Construcción por capas: cada etapa consume únicamente la información producida por las etapas anteriores.

Esta versión revisa la jerarquía tras el pivote a mundo 3D real (ver `03_Technical_Architecture.md` para la decisión de arquitectura completa). El pivote **no invalida la jerarquía funcional** — fue escrita deliberadamente como mapas de datos abstractos (elevación, humedad, temperatura, biomas), agnósticos de cómo se renderiza el resultado. Los cambios reales son dos etapas nuevas que faltaban:

- **Aldeas** se separa de **Estructuras** como etapa propia: los asentamientos habitables necesitan reglas de espaciado y cercanía a recursos/agua que las ruinas y otros POIs no necesitan.
- **Decoración ambiental** se añade como etapa final de emplazamiento físico: detalle puramente visual (sin función de gameplay) que debe conocer dónde ya se colocó todo lo demás para no superponerse.

```
Seed
 ↓
1. Configuración Global
 ↓
2. Macro-relieve (terreno + relieve + continentes/islas)
 ↓
3. Hidrografía
 ↓
4. Clima
 ↓
5. Biomas
 ↓
6. Cuevas
 ↓
7. Estructuras (ruinas, POIs no habitables)
 ↓
8. Aldeas (asentamientos habitables)
 ↓
9. Dungeons
 ↓
10. Portales (incluye asignación de Objetos Rituales, sección 7)
 ↓
11. Recursos, Flora y Fauna
 ↓
12. Decoración ambiental
 ↓
13. NPCs
 ↓
14. Economía
 ↓
15. Misiones (pools de plantillas)
 ↓
16. Eventos iniciales (pools de plantillas)
 ↓
17. Estado inicial del mundo
```

---

## 6. Especificación por etapa

Cada etapa responde: qué problema resuelve, qué recibe, qué genera, qué reglas debe cumplir, qué restricciones tiene, y de qué depende.

### 6.1 Configuración Global

- **Problema**: evitar que un cambio futuro en un generador (ej. Fauna) altere accidentalmente la secuencia aleatoria de otro (ej. Relieve), rompiendo la reproducibilidad de mundos ya generados.
- **Entrada**: Seed maestra, `WorldProfile` seleccionado.
- **Salida**: una sub-seed independiente y determinista por cada etapa posterior (derivada por hash de Seed maestra + identificador de etapa), tamaño del mundo, parámetros globales del `WorldProfile` resueltos.
- **Reglas**: la derivación de sub-seeds debe ser determinista y estable entre versiones del generador para una misma Seed maestra.
- **Restricciones**: ninguna etapa posterior puede consumir la Seed maestra directamente — solo su sub-seed asignada.
- **Depende de**: Seed, `WorldProfile`.

### 6.2 Macro-relieve

- **Problema**: definir la forma del mundo — dónde hay tierra y dónde hay océano, y la elevación general.
- **Entrada**: sub-seed, tamaño del mundo, parámetros de rugosidad/escala del `WorldProfile`.
- **Salida**: mapa de elevación (heightmap); continentes y océanos emergen como resultado de un umbral de nivel del mar sobre ese mismo mapa (no son una etapa separada). Este mapa es la base a partir de la cual se construye la malla 3D real del terreno.
- **Reglas**: debe existir suficiente masa continental jugable según el tamaño del mundo declarado en Configuración Global.
- **Restricciones**: el mapa de elevación es la única fuente de verdad para "tierra vs. agua" — ninguna etapa posterior redefine esta frontera.
- **Depende de**: Configuración Global.

### 6.3 Hidrografía

- **Problema**: generar ríos y lagos coherentes con el relieve.
- **Entrada**: mapa de elevación.
- **Salida**: cauces de ríos, cuerpos de agua, mapa de humedad de proximidad al agua.
- **Reglas**: los ríos deben seguir gradientes de descenso reales del mapa de elevación (de zonas altas a zonas bajas, terminando en océano o lago).
- **Restricciones**: no puede generar ríos que asciendan o que terminen sin salida válida (salvo lagos endorreicos intencionales, si el `WorldProfile` lo permite).
- **Depende de**: Macro-relieve.

### 6.4 Clima

- **Problema**: asignar temperatura y humedad a cada punto del mundo.
- **Entrada**: mapa de elevación (altitud), latitud implícita del mundo, mapa de humedad de Hidrografía, modo climático del `WorldProfile` (cíclico vs. inestable/caótico).
- **Salida**: mapas de temperatura y humedad; definición de si existe ciclo día/noche y cómo se comporta.
- **Reglas**: temperatura debe correlacionar inversamente con altitud; humedad debe correlacionar positivamente con proximidad a agua.
- **Restricciones**: en perfiles donde el `WorldProfile` marca el clima como "inestable" (ej. Onderwereld), esta etapa debe seguir produciendo mapas válidos y consumibles por Biomas — "inestable" es un modo de comportamiento, no una ausencia de datos.
- **Depende de**: Macro-relieve, Hidrografía, `WorldProfile`.

### 6.5 Biomas

- **Problema**: clasificar cada región del mundo en un bioma coherente.
- **Entrada**: elevación, temperatura, humedad, subconjunto de biomas permitidos por el `WorldProfile`.
- **Salida**: mapa de biomas, con fronteras y transiciones.
- **Reglas**: la clasificación debe ser una función determinista de elevación + temperatura + humedad (criterio tipo Whittaker); el número de biomas resultantes debe aproximarse al objetivo declarado en el `WorldProfile` (referencia: ~7 para Oppervlak, ver pregunta abierta en sección 12).
- **Restricciones**: ningún bioma puede aparecer en una combinación de clima/elevación incompatible con su definición de datos.
- **Depende de**: Clima, Macro-relieve.

### 6.6 Cuevas

- **Problema**: generar el espacio subterráneo del mundo.
- **Entrada**: sub-seed, mapa de elevación (solo para ubicar entradas coherentes en superficie).
- **Salida**: red de cuevas navegable en volumen 3D real, puntos de entrada válidos desde la superficie.
- **Reglas**: toda cueva debe tener al menos un punto de acceso alcanzable desde superficie.
- **Restricciones**: la generación interna de cuevas es independiente de Biomas/Clima — solo las entradas dependen de la superficie.
- **Depende de**: Macro-relieve.

### 6.7 Estructuras

- **Problema**: ubicar ruinas y otros puntos de interés explorables no habitables en superficie.
- **Entrada**: mapa de biomas, subconjunto de estructuras permitidas por el `WorldProfile`.
- **Salida**: lista de estructuras con ubicación, tipo y bioma anfitrión.
- **Reglas**: cada tipo de estructura solo puede ubicarse en biomas compatibles definidos por datos.
- **Restricciones**: ninguna restricción de habitabilidad se aplica aquí — ver Aldeas (6.8) para asentamientos habitados por NPCs.
- **Depende de**: Biomas.

### 6.8 Aldeas

- **Problema**: ubicar asentamientos habitables donde residirán los NPCs.
- **Entrada**: mapa de biomas, mapa de humedad/proximidad a agua (Hidrografía), distribución preliminar de recursos accesibles, subconjunto de tipos de aldea permitidos por el `WorldProfile`.
- **Salida**: lista de aldeas con ubicación, tamaño, y bioma anfitrión.
- **Reglas**: cada aldea debe ubicarse a una distancia razonable de agua dulce y de recursos básicos — a diferencia de Estructuras (6.7), aquí la habitabilidad real es un requisito, no un detalle estético.
- **Restricciones**: las aldeas deben quedar a una distancia transitable entre sí y de Estructuras/Dungeons cercanos — no aisladas sin ruta razonable.
- **Depende de**: Biomas, Hidrografía.

### 6.9 Dungeons

- **Problema**: generar dungeons temáticos, únicos por mundo.
- **Entrada**: mapa de biomas, subconjunto de temas de dungeon permitidos por el `WorldProfile`, red de Cuevas (algunos dungeons pueden anidarse en cuevas).
- **Salida**: lista de dungeons con ubicación, tema, y estructura interna navegable en volumen 3D (incluyendo verticalidad real: puentes, fosas, salas apiladas), con puntos de interés reservables para loot u objetos especiales.
- **Reglas**: el tema de cada dungeon debe ser coherente con el bioma/mundo anfitrión (ver Non-Goals del GDD: "un dungeon de Onderwereld no debe sentirse como un reskin de uno de Oppervlak").
- **Restricciones**: cada dungeon debe tener al menos una ruta de entrada y salida garantizada (ver Regla de Alcanzabilidad, sección 11).
- **Depende de**: Biomas, Estructuras, Cuevas.

### 6.10 Portales

- **Problema**: ubicar el punto de transición entre mundos y determinar el ritual necesario para activarlo.
- **Entrada**: lista de Dungeons y Estructuras especiales candidatas, `WorldProfile`.
- **Salida**: ubicación exacta del portal de salida del mundo actual; lista de objetos rituales requeridos (fijos o seleccionados según el tipo de portal, sección 7); punto de interés (dentro de un Dungeon o Estructura ya generado) donde se ubica cada objeto ritual; estado inicial de precolocación del ritual (sección 7.5).
- **Reglas**: el portal debe estar ubicado dentro de una estructura o dungeon ya generado, nunca en una posición arbitraria sin contexto narrativo. El sistema de Objetos Rituales (sección 7) rige el comportamiento detallado de esta etapa.
- **Restricciones**: debe existir siempre una ruta alcanzable entre el punto de aparición del jugador, cada ubicación de objeto ritual, y el portal (ver Regla de Alcanzabilidad, sección 11). Esta etapa no existía en el flujo de referencia original y se añade explícitamente porque los portales son el mecanismo central de la macro-progresión (GDD sección 5).
- **Depende de**: Dungeons, Estructuras.

### 6.11 Recursos, Flora y Fauna

- **Problema**: poblar el mundo con recursos recolectables y vida — contenido **funcional**, distinto de la Decoración ambiental (6.12).
- **Entrada**: mapa de biomas, `WorldProfile`.
- **Salida**: distribución de recursos básicos/avanzados, densidad y ubicación de flora, densidad y ubicación de fauna.
- **Reglas**: la Fauna se genera después de la Flora dentro de esta misma etapa, porque la densidad de herbívoros/depredadores debe ser coherente con la disponibilidad de flora (relación trófica) — no son independientes entre sí aunque comparten etapa.
- **Restricciones**: ningún recurso puede aparecer en un bioma que no lo define en sus datos.
- **Depende de**: Biomas.

### 6.12 Decoración ambiental

- **Problema**: poblar el mundo con detalle puramente visual y sin función de gameplay (rocas sueltas, matorrales, escombros, mobiliario ambiental) para que el mundo 3D no se sienta vacío, sin comprometer la lectura funcional del espacio.
- **Entrada**: mapa de biomas, ubicaciones ya ocupadas por Estructuras, Aldeas, Dungeons, Portales, Recursos, Flora y Fauna.
- **Salida**: distribución de props decorativos no interactuables.
- **Reglas**: nunca puede ocupar una celda ya reservada por una etapa funcional anterior — esta etapa se ejecuta al final del emplazamiento físico precisamente para poder validarlo.
- **Restricciones**: la densidad de decoración es un parámetro de `WorldProfile`, no un valor fijo — debe poder reducirse en perfiles con presupuesto de rendimiento más ajustado.
- **Depende de**: todas las etapas de emplazamiento físico anteriores (6.2–6.11).

### 6.13 NPCs

- **Problema**: determinar qué NPCs existen en esta Seed y qué profesión ejercen.
- **Entrada**: lista de Aldeas, subconjunto de profesiones permitidas por el `WorldProfile`.
- **Salida**: lista de NPCs con identidad, profesión asignada (o ausencia deliberada de una profesión, ver GDD sección 8), y ubicación.
- **Reglas**: la existencia y el rol de cada NPC son producto de la Seed, no de un guion fijo (GDD sección 8).
- **Restricciones**: cada NPC debe asociarse a una Aldea válida.
- **Depende de**: Aldeas.

### 6.14 Economía

- **Problema**: definir precios y disponibilidad inicial de comercio.
- **Entrada**: NPCs con profesión de comerciante, Recursos disponibles regionalmente.
- **Salida**: tablas de precios y stock inicial por comerciante.
- **Reglas**: la oferta de un comerciante debe ser coherente con los recursos de su región y su profesión.
- **Restricciones**: ninguna.
- **Depende de**: NPCs, Recursos.

### 6.15 Misiones (pools de plantillas)

- **Problema**: definir qué misiones son *posibles* en esta Seed, incluyendo aquellas que revelan información sobre los rituales de portal.
- **Entrada**: NPCs, Biomas, Portales (incluyendo ubicación de objetos rituales), Eventos planificados.
- **Salida**: pool determinista de plantillas de misión disponibles, asociadas a NPC/bioma/portal — incluye qué NPC(s) conocen información sobre cada ritual.
- **Reglas**: la ausencia de una misión en una Seed es tan válida como su presencia (GDD sección 9). La activación real de una misión concreta depende del estado del jugador y ocurre en tiempo de Run, no aquí (sección 3).
- **Restricciones**: ninguna.
- **Depende de**: NPCs, Biomas, Portales.

### 6.16 Eventos iniciales (pools de plantillas)

- **Problema**: definir qué eventos ambientales/especiales son posibles en esta Seed.
- **Entrada**: Biomas, `WorldProfile`, Clima.
- **Salida**: pool determinista de eventos planificados y sus condiciones de disparo.
- **Reglas**: mismo principio que Misiones — esto es un catálogo de posibilidades, no una línea de tiempo fija.
- **Restricciones**: ninguna.
- **Depende de**: Biomas, Clima.

### 6.17 Estado inicial del mundo

- **Problema**: componer el resultado final de todas las etapas anteriores en un estado consistente y serializable.
- **Entrada**: salida de todas las etapas 1–16.
- **Salida**: el mundo completo tal como existe en el instante en que la Seed termina de generarse — la base sobre la cual la Run comenzará a construir su historia.
- **Reglas**: debe pasar la validación de Completabilidad (sección 11) antes de considerarse válido.
- **Restricciones**: ninguna etapa posterior a esta pertenece a la Seed — todo lo que ocurra después es responsabilidad de la Run.
- **Depende de**: todas las etapas anteriores.

---

## 7. Sistema de Objetos Rituales

### 7.1 Principio general

Los objetos rituales **no son loot especial**. Son un sistema propio: representan la llave de progresión entre mundos. Cada portal posee su propio ritual, y cada ritual tiene sus propias reglas de generación — no existe un único comportamiento genérico para "todos los rituales".

### 7.2 Ritual del portal Oppervlak → Onderwereld

- La **lista de objetos requeridos es fija** — es la misma en toda Seed.
- Lo que cambia entre Seeds:
  - dónde aparecen (qué Dungeon/Estructura los aloja);
  - qué NPC conoce información sobre ellos;
  - qué desafíos hay que superar para conseguirlos.
- El jugador siempre aprende el mismo ritual, pero nunca lo consigue de la misma forma.

### 7.3 Ritual del portal Onderwereld → Voorgeborchte

- Los **objetos rituales cambian en cada Seed**, seleccionados de un pool exclusivo de objetos de Onderwereld.
- El generador selecciona una combinación válida para esa partida en la etapa Portales (6.10).
- **Restricción de validez**: ninguna combinación seleccionada puede violar la Regla de Alcanzabilidad Garantizada (sección 11) — todo objeto elegido debe quedar en una ubicación alcanzable con lo disponible en esa misma Seed.
- Objetivo de diseño: obligar al jugador a explorar realmente ese mundo y evitar que memorice una ruta fija entre Runs.

### 7.4 Progresión física del ritual

- El ritual se siente como un proceso físico, no como un contador abstracto.
- El jugador encuentra el portal **incompleto**.
- Cada objeto requerido se inserta manualmente en el portal.
- Cada objeto colocado permanece **visible** dentro del portal — el portal refleja visualmente su progreso.
- El jugador debe poder entender de un vistazo cuánto le falta para completar el ritual, sin necesidad de un contador de UI separado.

*(Nota: el estado por-slot del portal —qué objeto va en qué posición visible sobre el modelo 3D del portal— es un requisito funcional para `03_Technical_Architecture.md` y para `05_Art_Direction.md`, no una decisión de implementación de este documento.)*

### 7.5 Precolocación procedural (variación narrativa)

Existe una probabilidad baja de que el portal ya tenga uno o más objetos rituales colocados en el momento en que el mundo es generado — representando intentos anteriores de activarlo.

Reglas generales:

- El portal **nunca** aparece completamente activado por precolocación.
- Puede tener uno o varios (no todos) los objetos ya colocados.
- La probabilidad de precolocación es un parámetro del `WorldProfile` de cada mundo (sección 4) — no un valor fijo global.
- La cantidad máxima de objetos precolocados está limitada para no reducir significativamente el desafío de progresión.

El objetivo **no** es facilitar la partida. Es que cada Run cuente una historia distinta desde el primer instante — el jugador puede preguntarse "¿quién intentó abrir este portal antes que yo?". Es narrativa ambiental sin cinemáticas.

*(Los valores exactos de probabilidad y cantidad máxima por mundo son parámetros de balance — se definen en tablas de datos, no en este documento, siguiendo el mismo criterio que el resto de valores numéricos del proyecto.)*

---

## 8. Técnicas de referencia (no vinculantes)

Estas técnicas se mencionan únicamente para dar contexto de qué tipo de problema resuelve cada etapa. Ninguna queda seleccionada como definitiva — esa decisión pertenece a `03_Technical_Architecture.md`.

- Simplex Noise / Perlin Noise
- Voronoi
- BSP (Binary Space Partitioning)
- Cellular Automata
- Poisson Disk Sampling
- Wave Function Collapse
- Prefabs modulares
- Gramáticas procedurales

### 8.1 Mapeo orientativo por etapa (no vinculante)

| Etapa | Técnica candidata | Por qué |
|---|---|---|
| Macro-relieve | Simplex/Perlin Noise | Estándar de facto para heightmaps que se convierten en malla 3D |
| Biomas / Continentes | Voronoi | Fronteras orgánicas, evita transiciones perfectamente suaves |
| Cuevas | Cellular Automata | Técnica estándar para cuevas orgánicas; extiende bien a volumen 3D |
| Dungeons (layout interno) | BSP + Gramáticas procedurales | BSP para salas/pasillos; gramáticas para el orden de progresión interna |
| Aldeas | Prefabs modulares + Gramáticas procedurales | Edificios como piezas ensamblables; la gramática define el plano del asentamiento |
| Recursos, Flora y Fauna | Poisson Disk Sampling | Distribución natural sin amontonamientos |
| Decoración ambiental | Wave Function Collapse | Ensamblaje local con reglas de adyacencia — no como generador global del mundo |

---

## 9. Tamaño del mundo y streaming

Los mundos no son infinitos. Son finitos, pero extremadamente grandes.

- El terreno se genera dinámicamente conforme el jugador explora.
- El mundo se carga y descarga por regiones (chunks o sistema equivalente).
- El jugador nunca percibe que el mundo completo está cargado en memoria.

Sin embargo, los mundos poseen un límite perfectamente definido desde el momento en que la Seed es creada. La generación dinámica (streaming) es únicamente una optimización de memoria y rendimiento — conceptualmente, los mundos completos ya existen desde el instante en que la Seed es generada. El streaming decide *cuándo se materializa* cada región, no *si* existe.

### Consecuencia del mundo 3D real

A diferencia de un TileMap 2D (donde un chunk es una instancia barata de tiles ya dibujados), en un mundo 3D real cada chunk requiere **generar geometría** (una malla) a partir de su porción del mapa de elevación. Esto introduce dos requisitos que no existían en la versión 2D de este documento:

- La generación de malla por chunk debe ejecutarse en un **hilo separado** del hilo principal, para no bloquear el juego mientras el jugador explora.
- El terreno lejano necesita **nivel de detalle variable (LOD)** — mallas simplificadas a mayor distancia — para mantener el rendimiento cuando hay más chunks visibles simultáneamente que en una vista 2D equivalente.

El mecanismo exacto (tamaño de chunk, estrategia de LOD, presupuesto de hilos) se define en `03_Technical_Architecture.md`.

---

## 10. Objetivo arquitectónico: ecosistema completo

Este documento no describe únicamente cómo generar terreno. Describe cómo generar un ecosistema completo: mundo, exploración, progresión, economía, misiones, NPCs, recursos, dungeons, portales y objetos rituales, todos como parte de un único pipeline procedural (sección 5).

La meta final es que cada Seed genere una aventura diferente, pero siempre coherente y reproducible.

---

## 11. Principios de calidad del generador

El sistema procedural nunca debe priorizar únicamente la aleatoriedad. Toda generación debe cumplir cinco principios:

- Coherencia.
- Rejugabilidad.
- Balance.
- Exploración significativa.
- Completabilidad.

### Regla de Alcanzabilidad Garantizada (consecuencia directa de Completabilidad)

El jugador nunca debe sentir que un mundo es imposible de terminar por culpa de la generación procedural. Esto se traduce en una restricción dura, no una aspiración:

- Debe existir siempre al menos una ruta transitable entre el punto de aparición del jugador y cada Portal (etapa 6.10).
- Todo objeto ritual requerido para progresar —fijo (7.2) o seleccionado de un pool (7.3)— debe generarse en una ubicación alcanzable sin herramientas que el jugador no pueda obtener antes en esa misma Seed.
- Toda Dungeon debe tener al menos una ruta de entrada y salida garantizada (etapa 6.9).

Si la validación de alcanzabilidad falla durante la generación, la sub-estructura afectada (no el mundo completo) debe regenerarse con una variación derivada de su propia sub-seed, hasta cumplir la regla — y si aplica a una selección de objetos rituales (7.3), el generador debe descartar esa combinación y elegir otra válida. El mecanismo exacto de esta validación/reintento se define en `03_Technical_Architecture.md`.

**La Seed puede cambiar completamente la aventura, pero nunca debe impedir que la partida pueda completarse. Toda Run debe ser potencialmente finalizable.**

---

## 12. Preguntas abiertas y dependencias hacia `03_Technical_Architecture.md`

1. **Función de derivación de sub-seeds**: qué algoritmo de hash concreto se usa para derivar sub-seeds por etapa a partir de la Seed maestra.
2. **Mecanismo de validación/reintento de Alcanzabilidad**: cuántos reintentos, y qué ocurre si una sub-estructura (o una combinación de objetos rituales) nunca pasa la validación (fallback determinista).
3. **Selección de algoritmo definitivo** por etapa, entre las técnicas listadas en la sección 8 (o una combinación).
4. **Estructura de datos del `WorldProfile`**: cómo se modela como Resource de Godot, y qué validación de esquema tiene — incluyendo los nuevos parámetros de ritual (modo fijo/variable, probabilidad de precolocación) y de decoración ambiental.
5. **Cifra objetivo de biomas de Oppervlak** ("~7", heredada del GDD): confirmar como parámetro firme del `WorldProfile` de Oppervlak o dejarlo como rango.
6. **Diseño de streaming/chunks 3D en Godot**: tamaño de chunk, estrategia de LOD, generación de malla en hilo separado, y presupuesto de rendimiento con hasta 8 Runs activas (aunque solo una cargada en memoria a la vez).
7. **Representación por-slot del portal**: cómo se modela en datos el estado visual de "qué objeto ritual ocupa qué posición visible" sobre el modelo 3D del portal, para que Arte (`05_Art_Direction.md`) pueda diseñarlo en función de sus estados posibles.
8. **Contrato de integración de assets 3D**: formato de importación (ej. glTF), convención de esqueleto/rig estándar para que animaciones sean reutilizables entre iteraciones de arte generadas por distintas herramientas de IA (ver pipeline artístico tool-agnostic solicitado por el usuario).

---

*Fin del documento v1.1.*
