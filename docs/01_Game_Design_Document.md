# MinnoGhram

> Game Design Document — v1.1 (Revisión: pivote a mundo 3D real, cámara isométrica rotable)
> Documento base: `00_Project_Vision.md`

---

## 1. Resumen Ejecutivo

MinnoGhram es un **Action Survival Roguelike** de mundo abierto y generación procedural, donde cada Run genera una historia completa y cerrada a partir de una Seed: un mundo distinto, NPCs distintos, misiones distintas, y un mismo objetivo final — sobrevivir, explorar, y derrotar al Boss Final antes de que la Run termine.

El combate es en tiempo real, rápido y preciso (referencia jugable: **Hades**). El mundo es completamente 3D, presentado con una cámara isométrica de libertad de rotación y zoom (referencia: **V Rising**); la dirección artística es 3D estilizado low-poly con materiales hand-painted e iluminación dinámica (referencias parciales, sin copiar ninguna: **Tunic** en claridad visual, **Valheim** en filosofía de supervivencia, **Albion Online** en legibilidad, **No Rest for the Wicked** en calidad ambiental). La generación procedural (referencia de estructura: **Shattered Pixel Dungeon**) y la supervivencia de mundo abierto (referencia de sistemas: **Minecraft, Terraria, Core Keeper, Don't Starve, ARK**) se combinan bajo un único sistema: todo lo que existe en una Run — mapa, NPCs, misiones, loot, dungeons, eventos — nace de la misma Seed.

### Pilares de diseño

1. **La Seed lo es todo.** Ninguna Run se parece a otra. Si dos elementos son idénticos entre dos Runs, algo falló en el diseño procedural.
2. **Cada Run es una historia cerrada.** Tiene principio (Seed) y final (muerte o Boss Final). Cuando termina, termina para siempre.
3. **Combate preciso por encima de la presentación.** La cámara es un sistema de presentación (isométrica, con libertad de rotación estilo V Rising); nunca debe condicionar la arquitectura ni interponerse entre el jugador y un combate fluido tipo Hades.
4. **Riesgo vs Recompensa como motor de decisiones.** Cada sistema (noche, dungeons, mundos) debe presentar una decisión real, no un obstáculo gratuito.
5. **Supervivencia con propósito.** Los sistemas de survival (recursos, refugio, crafting) existen para sostener la exploración y el combate, no como fin en sí mismos.

### Qué NO es MinnoGhram

- No es un sandbox creativo (no hay construcción libre sin objetivo), aunque el jugador puede decidir crearse una base si lo desea.
- No es un mundo persistente al estilo Minecraft/Terraria (el mundo muere con la Run).
- No es un roguelike de combate por turnos o en grilla.
- No es, en su V1, un juego multijugador.

---

## 2. Alcance de este documento

Este GDD documenta la **visión de diseño completa** del proyecto, pero **el nivel de detalle es intencionalmente asimétrico**:

- **Oppervlak** se documenta con detalle jugable completo — es el contenido de la V1 (vertical slice).
- **Onderwereld** y **Voorgeborchte** se documentan únicamente a nivel conceptual (identidad, propósito, diferencias). Su diseño detallado ocurrirá en fases posteriores del proyecto, cuando Oppervlak esté validado.

Explícitamente **fuera de este documento** (se resuelven en documentos posteriores):


| Tema                                                            | Documento destino                        |
| ----------------------------------------------------------------- | ------------------------------------------ |
| Algoritmos de generación (ruido, biomas, seeds)                | `02_Procedural_Generation_Bible.md`      |
| Nodos, Resources, Autoloads, patrones de Godot                  | `03_Technical_Architecture.md`           |
| Lore, historia del mundo, facciones                             | `04_World_Lore.md`                       |
| Paletas, resoluciones, sprites, naming de assets                | `05_Art_Direction.md`                    |
| Layout de menús, HUD, flujos de UI                             | `06_UI_UX.md`                            |
| Fases de desarrollo, milestones                                 | `08_Roadmap.md`                          |
| Valores numéricos de balance (daño, drop rates, hambre/turno) | Tablas de datos, fuera del GDD narrativo |

---

## 3. Core Loop

### Loop de sesión (minuto a minuto)

```
Explorar → Encontrar recurso/amenaza/secreto
   ↓
Combate en tiempo real (esquivar, atacar, gestionar recursos de combate)
   ↓
Recolectar / Craftear / Mejorar equipo
   ↓
Decisión de Riesgo vs Recompensa (¿avanzo, exploro de noche, entro al dungeon?)
   ↓
(vuelve a Explorar)
```

### Loop de Run (macro)

```
Inicio de Run → Seed (aleatoria o manual)
   ↓
Oppervlak: sobrevivir, explorar, conseguir objetos rituales
   ↓
Portal → Onderwereld: reglas rotas, mayor dificultad, nuevos objetos rituales
   ↓
Portal → Voorgeborchte: hostil, pocas zonas seguras
   ↓
Boss Final
   ↓
Run finalizada (victoria o muerte) → Estadísticas y resultados guardados permanentemente
```

---

## 4. Modelo de partida y muerte

### Ciclo de vida de una Run

- Una Run comienza al elegir una Seed (aleatoria o especificada por el jugador).
- La Seed genera un mundo completo e independiente de cualquier otra Run.
- Durante la Run, el jugador puede **guardar y cargar libremente** (modelo tipo *The Binding of Isaac*: comodidad de sesión, no permadeath por sesión).
- La Run **termina permanentemente** cuando:
  - el jugador muere, o
  - el jugador derrota al Boss Final.

### Run activa vs. Run finalizada


| Estado             | Mundo              | Guardado                      | Reingreso                 |
| -------------------- | -------------------- | ------------------------------- | --------------------------- |
| **Run activa**     | Existe, es jugable | Guardable/cargable libremente | Sí, mientras siga activa |
| **Run finalizada** | Archivado          | No aplica                     | No — permanente          |

Esta distinción es un requisito de arquitectura (`03_Technical_Architecture.md` deberá definir cómo se archiva una Run finalizada sin mantenerla cargada en memoria ni ocupando slots de guardado activo).

### Runs activas concurrentes

El jugador puede mantener **hasta 8 Runs activas simultáneamente**. Cada una es completamente independiente: Seed, mundo, progreso, NPCs, construcciones, economía, inventario, objetos rituales y estado del mundo propios. Morir o finalizar una Run únicamente afecta a esa Run — el resto permanece intacto.

Solo la Run que el jugador está jugando activamente permanece cargada en memoria; las demás quedan serializadas en disco (consecuencia directa del modelo de streaming ya establecido en `02_Procedural_Generation_Bible.md`, no una decisión nueva de por sí).

### Qué persiste entre Runs (meta-nivel, no dentro del mundo)

- Estadísticas y récords.
- Logros.
- Historial de Runs (incluida la Seed usada, para poder revisitar el registro aunque no el mundo).
- Perfil del jugador.
- Posiblemente, semillas favoritas guardadas para volver a intentarlas (**pendiente de definir si esto significa poder *iniciar una Run nueva* con una Seed ya usada — ver sección 12**).

**Importante**: no existe (en V1) ninguna forma de meta-progresión que afecte el poder o las opciones de la *siguiente* Run (sin desbloqueos permanentes de items, habilidades o ventajas). Esto es una decisión de diseño real con consecuencias — ver sección 12.

---

## 5. Estructura de progresión

MinnoGhram tiene **dos capas de progresión que no deben confundirse**:

- **Macro-progresión: secuencial e intencional.** Oppervlak → Onderwereld → Voorgeborchte → Boss Final es un orden fijo de 3 actos, cada uno desbloqueado por objetos rituales obtenidos en el anterior. Esto es lineal por diseño y no debe describirse como "no lineal" (corrige una imprecisión del documento de Visión).
- **Micro-progresión: libre y no lineal.** Dentro de cada mundo/acto, el jugador decide el orden de exploración, qué biomas visitar, qué dungeons intentar, y cuánto tiempo invertir antes de buscar el siguiente portal.

La libertad del juego vive en la micro-progresión; la estructura y el ritmo narrativo viven en la macro-progresión.

---

## 6. Sistemas de gameplay

### 6.1 Supervivencia

Sistemas base (detalle numérico fuera de alcance de este documento):

- Recursos vitales: comida, agua, refugio.
- Ciclo día/noche con impacto directo en riesgo/recompensa (sección 12).
- Clima y su efecto en exploración y supervivencia.
- Herramientas, armas y armaduras como resultado de crafting, no como drops garantizados.

### 6.2 Combate

- **Tiempo real, movimiento libre en 360°.** Sin turnos, sin grilla.
- **Mundo completamente 3D**, presentado con cámara isométrica de libertad de rotación y zoom controlado (referencia: V Rising) — la cámara es un sistema de presentación, **nunca** una limitación de diseño de combate.
- **Modelo jugable de referencia: Hades.** Esquiva (dash), ataque cuerpo a cuerpo y a distancia, combate fluido y de alta respuesta.
- **Variedad de builds (referencia: Soul Knight).** Múltiples armas, rarezas, estilos de combate distintos entre sí (no solo distinto daño — distinto *feel*).
- **Física 3D real** (movimiento sobre el plano del terreno con gravedad, sin vuelo libre): el combate ocurre en un espacio 3D consistente, independientemente del ángulo de cámara (detalle de implementación a resolver en `03_Technical_Architecture.md`).
- La dificultad depende de habilidad del jugador, preparación previa, gestión de recursos y conocimiento del mundo — no de números de dificultad artificiales.

### 6.3 Crafting

- Data-driven: recetas, materiales y resultados viven fuera del código (`02_Procedural_Generation_Bible.md` / recursos de Godot).
- Alimenta tanto supervivencia (herramientas, refugio) como combate (armas, armaduras, consumibles).

### 6.4 Construcción

- **No es un sistema creativo.** Es una herramienta de supervivencia, temporal y funcional a la Run activa.
- Ejemplos: refugios, estaciones de crafteo, almacenamiento, cocinas, hornos, defensas, estructuras temporales.
- Toda construcción desaparece cuando la Run termina (coherente con el modelo de partida de la sección 4).
- No compite con el pilar central del juego: exploración → supervivencia → progresión → rituales → cambio de mundo → boss final.

---

## 7. Mundos

Cada mundo representa una etapa distinta del viaje del jugador.

No son únicamente mapas diferentes; cada uno modifica las reglas de supervivencia, la exploración, la economía, los enemigos y el ritmo de la partida.

Cada transición entre mundos debe sentirse como un cambio importante tanto en la narrativa como en la jugabilidad.

---

## 7.1 Oppervlak (detalle completo — V1)

### Identidad

Es el mundo donde comienza toda Run.

Representa la naturaleza, la vida y el equilibrio antes del caos.

Aunque es el mundo más "seguro", nunca deja de ser un entorno de supervivencia.

El jugador aprende aquí las mecánicas principales del juego y construye las bases de su progresión.

### Características principales

- Ciclo completo de día y noche.
- Sistema climático.
- Ecosistemas vivos.
- Fauna y flora abundantes.
- Recursos básicos y materiales iniciales.
- NPCs de progresión.
- Comerciantes.
- Aldeas.
- Ruinas antiguas.
- Dungeons procedurales temáticas.
- Secretos repartidos por el mundo.
- Actualmente tendrá aproximadamente 7 biomas principales (valor sujeto a validación durante el diseño procedural).
### Filosofía
  Durante el día el mundo invita a explorar.
  Durante la noche recuerda constantemente al jugador que sigue siendo un juego de supervivencia.
  La exploración debe sentirse relativamente casi segura, pero nunca completamente libre de peligro.
### Objetivo
  Explorar el mundo.
  Fortalecer al personaje.
  Descubrir la historia del mundo.
  Encontrar los artefactos rituales necesarios para abrir el portal hacia Onderwereld.

## 7.2 Onderwereld (conceptual)

### Identidad

  Representa el colapso del equilibrio.
  Es un mundo donde las reglas conocidas dejan de existir.
  Todo debe transmitir la sensación de que el jugador ha abandonado el mundo natural para entrar en un lugar hostil e impredecible.
  La supervivencia deja de depender únicamente de los recursos y comienza a depender del conocimiento, fuerza y la adaptación.

### Características principales

- No existe un ciclo tradicional de día y noche.
- Ambiente permanentemente inestable.
- Biomas extremos.
- Recursos únicos.
- Materiales avanzados.
- Nuevos NPCs.
- Comerciantes especializados.
- Enemigos mucho más agresivos.
- Dungeons exclusivas.
- Eventos ambientales peligrosos.
- La exploración debe sentirse mucho más tensa.
- Cada expedición representa un riesgo importante.
### Filosofía
  El jugador ya no está aprendiendo.
  Ahora debe demostrar que domina las mecánicas del juego.
  Las decisiones comienzan a tener consecuencias mucho mayores.
### Objetivo
  Descubrir los secretos de Onderwereld.
  Obtener los artefactos rituales necesarios para acceder a Voorgeborchte.

### Estado del diseño

El desarrollo detallado de este mundo queda diferido hasta validar completamente Oppervlak y las mecánicas base del juego.

## 7.3 Voorgeborchte (conceptual)

### Identidad

Representa el último desafío de una Run.

Es una dimensión donde la supervivencia deja de ser el objetivo principal y pasa a ser la culminación de todo el aprendizaje del jugador.

Debe sentirse completamente distinta a los mundos anteriores.

No pretende ser extensa.

Pretende ser intensa.

### Características principales

- Ambiente extremadamente hostil.
- Muy pocas zonas seguras.
- Recursos nuevos, unicos y limitados.
- Alta presión constante.
- Enemigos de élite.
- Eventos especiales.
- Últimos desafíos de exploración.
- Acceso al Boss Final.

La progresión ya no consiste en expandirse.

Consiste en sobrevivir el tiempo suficiente para completar el objetivo final.

### Filosofía

Todo lo aprendido durante la Run debe ponerse a prueba.

Cada decisión importa.

Cada recurso cuenta.

Cada enfrentamiento puede definir el resultado de la partida.

### Objetivo

Superar los últimos desafíos.

Derrotar al Boss Final.

Completar la Run.

### Estado del diseño

Este mundo permanece únicamente definido a nivel conceptual.

Su desarrollo detallado será abordado durante etapas posteriores del proyecto.

### Filosofía compartida entre mundos

Cada mundo debe cambiar en identidad completa, no solo en dificultad: recursos, música, iluminación, NPCs, eventos, arquitectura, dungeons, loot y mecánicas propias.

---

## 8. NPCs y profesiones

- Los NPCs y sus profesiones se determinan por la Seed: una Run puede generar un Herrero donde otra genera una Alquimista, y una tercera ninguno de los dos.
- El **pool de profesiones disponibles** (Herrero, Comerciante, Alquimista, Sacerdote, Cazador, Cartógrafo, Constructor, Explorador, Coleccionista, y futuras) debe vivir como datos, no como código — añadir una profesión nueva no debería requerir tocar lógica de generación (principio Data Driven, ver `00_Project_Vision.md`).
- El detalle algorítmico de "cómo" se decide qué NPCs aparecen pertenece a `02_Procedural_Generation_Bible.md`; este documento solo fija la regla de diseño: **existencia y rol de cada NPC son productos de la Seed, no de un guion fijo.**

---

## 9. Sistema de misiones

- Generadas proceduralmente, no fijas.
- Dependen de: mundo, NPC, bioma, eventos activos, Seed, y estado del jugador.
- Regla de diseño (el algoritmo va en `02_Procedural_Generation_Bible.md`): una misión debe poder no existir en otra Run con condiciones distintas — la ausencia de contenido es tan válida como su presencia.

---

## 10. Dungeons

- Generadas proceduralmente, pero basadas en temas reconocibles: minas, templos, ruinas, bibliotecas, cementerios, fortalezas, laboratorios, colmenas, catacumbas.
- Cada mundo tiene sus propias variantes temáticas — un dungeon de Onderwereld no debe sentirse como un reskin de uno de Oppervlak.

---

## 11. Boss Final

- Para V1: **único, fijo, diseñado manualmente.** No procedural.
- Representa el cierre intencional de una Run — el único punto del juego donde el diseño de autor prevalece sobre la generación procedural.
- Variantes, fases alternativas o modificadores por Seed quedan explícitamente fuera de alcance de V1 (ver sección 13), evaluables en el Roadmap.

---

## 12. Riesgo vs Recompensa

Mecánicas concretas que materializan este pilar (no solo el concepto):

- **Ciclo día/noche**: de noche aparecen enemigos peligrosos, eventos especiales, comerciantes nocturnos y recursos/objetos exclusivos — el riesgo nocturno debe estar balanceado con recompensas que no existen de día.
- **Profundidad de dungeon**: mayor progreso dentro de un dungeon temático implica mayor amenaza y mejor loot potencial.
- **Cruce de bioma hostil**: decisión explícita de gestión de recursos antes de entrar.
- **Onderwereld como escalón de riesgo**: al romper las reglas de Oppervlak (sin día/noche normal), todo el mundo se convierte en una decisión de riesgo sostenido, no puntual.
- **Gasto de recursos**: usar ahora vs. reservar para el bioma/dungeon siguiente.

---

## 13. Fuera de alcance (Non-Goals de V1)

- Multiplayer / networking (la arquitectura no debe impedirlo a futuro, pero no se implementa ahora).
- Mundo persistente estilo Minecraft/Terraria.
- Construcción creativa sin propósito de supervivencia.
- Boss Final procedural o con variantes.
- Diseño detallado de Onderwereld y Voorgeborchte.
- Meta-progresión que afecte el poder o las opciones de Runs futuras (ver sección 14 — es una omisión deliberada a validar, no un descarte definitivo).
- Balance numérico (tasas de hambre, daño, drop rates) — pertenece a tablas de datos, no a este documento.

---

## 14. Preguntas abiertas y dependencias

Estas preguntas no bloquean la aprobación de este GDD, pero deben resolverse antes o durante `02_Procedural_Generation_Bible.md` y `03_Technical_Architecture.md`:

1. **Reutilización de Seed**: si un jugador guarda una "Seed favorita", ¿puede iniciar una Run *nueva* con esa misma Seed (generando el mismo mundo desde cero), o la Seed queda retirada permanentemente tras usarse una vez? Esto afecta el diseño del historial de Runs.
2. **Ausencia total de meta-progresión de poder**: confirmado que no hay desbloqueos permanentes que afecten Runs futuras. Vale la pena revisitar esto en el Roadmap — el riesgo de diseño es que toda la sensación de "progreso a largo plazo" del jugador dependa exclusivamente de estadísticas/logros cosméticos, sin ningún refuerzo jugable entre Runs (a diferencia de Hades, cuyo enganche depende en parte de la progresión de Mirror/recursos entre runs). No se pide cambiar nada ahora — se deja registrado para decisión consciente futura.
3. **Cifra de biomas de Oppervlak** ("aproximadamente 7"): a confirmar como objetivo firme o estimado en `02_Procedural_Generation_Bible.md`.
4. **Implementación de física 3D y cámara isométrica rotable**: el mecanismo exacto (nodos de Godot, control de cámara, límites de rotación/zoom) se define en `03_Technical_Architecture.md`, no aquí.
5. **Pipeline artístico 3D**: contrato de integración (formato de importación, convención de rig/esqueleto) para que el pipeline de modelado/animación sea agnóstico de herramienta — se define en `03_Technical_Architecture.md` y `05_Art_Direction.md`.

---

*Fin del documento v1.1.*
