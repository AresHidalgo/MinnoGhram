# MinnoGhram

> Documento de Visión del Proyecto (Project Vision v0.2 — actualizado: dirección 3D, sandbox aclarado)

---

# Visión

MinnoGhram es un **Open World Survival Roguelike** con generación procedural, exploración, progresión y libertad.

El objetivo es crear un juego donde **cada partida (Run)** genere un mundo completamente nuevo, con NPCs, biomas, dungeons, misiones, eventos y progresión diferentes.

No queremos un juego donde únicamente cambie el mapa.

Queremos que cambie toda la aventura.

Cada partida debe sentirse como una historia distinta.

---

# Inspiraciones

## Gameplay

- Minecraft
- Terraria
- Core Keeper
- Don't Starve
- ARK Survival Evolved
- V Rising

## Dirección artística

Buscamos un estilo:

- 3D
- Perspectiva Isométrica Aérea
- Oscuro
- Medieval/Fantástico
- Iluminación dinámica
- Ambientes inmersivos
- Low Poly estilizado
- Procedural

---



# Filosofía del juego

No buscamos que el jugador complete niveles.

Buscamos que sobreviva.

Que explore.

Que tome decisiones.

Que descubra.

Que improvise.

Que cada partida cuente una historia diferente.

---



# Core Gameplay

El núcleo del juego será:

- Mundo Abierto Procedural
- Survival
- Exploración
- Aventuras
- Riesgo vs Recompensa
- Gestión de Recursos
- Libertad
- Misiones
- Roguelike

---



# Resumen del Gameplay

Cada nueva partida comienza desde cero.

Se genera una Seed.

Esa Seed crea completamente el mundo.

El jugador aparece sin recursos.

Debe comenzar su supervivencia.

Explora el mundo.

Consigue recursos.

Construye.

Mejora su equipo.

Conoce NPCs.

Realiza misiones.

Descubre Dungeons.

Obtiene objetos rituales.

Abre portales.

Viaja entre mundos.

Derrota al Boss Final.

---



# Objetivo del Proyecto

No queremos crear un Sandbox creativo sin propósito (mundo persistente tipo Minecraft/Terraria, construcción libre sin objetivo).

No queremos crear un RPG.

No queremos crear un Roguelike tradicional.

Queremos crear una mezcla de:

- Sandbox (en el sentido de libertad de mundo abierto, no de modo creativo persistente — ver `01_Game_Design_Document.md`)
- Survival
- Roguelike
- Exploración
- RPG ligero

Todo integrado bajo un mismo sistema procedural.

---



# Estructura del Mundo

Actualmente existirán tres mundos.

---



## 1. Oppervlak

Es el mundo inicial.

Representa el mundo "vivo".

Características:

- Día y noche
- Clima
- Fauna
- Recursos básicos
- NPCs
- Comerciantes
- Aldeas
- Dungeons
- Biomas

Actualmente tendrá aproximadamente 7 biomas principales.

Durante este mundo el jugador deberá conseguir los objetos necesarios para abrir un portal hacia Onderwereld.

---



## 2. Onderwereld

Segundo mundo.

La dificultad aumenta considerablemente.

Este mundo rompe muchas reglas del primero.

Ejemplos:

- No existe un ciclo normal de día y noche.
- Ambiente caótico.
- Nuevos recursos.
- Nuevos NPCs.
- Nuevos enemigos.
- Nuevas mecánicas.
- Dungeons exclusivas.

Aquí el jugador deberá conseguir los objetos necesarios para abrir el portal hacia Voorgeborchte.

---



## 3. Voorgeborchte

Último mundo.

Representa la dimensión final.

Mucho más hostil.

Muy pocas zonas seguras.

Contendrá el Boss Final.

---



# Filosofía de los Mundos

Cada mundo debe sentirse completamente diferente.

No solamente deben cambiar los enemigos.

También deben cambiar:

- Recursos
- Música
- Iluminación
- NPCs
- Eventos
- Arquitectura
- Dungeons
- Loot
- Objetos
- Mecánicas

Cada mundo debe tener personalidad propia.

---



# Progresión

La progresión será basada en exploración.

El jugador deberá descubrir cómo avanzar.

No queremos una progresión lineal.

La exploración debe ser la principal herramienta del jugador.

---



# Sistema Roguelike

Cada Run debe ser distinta.

No solamente cambia el mapa.

También cambian:

- NPCs
- Misiones
- Eventos
- Loot
- Dungeons
- Recursos
- Objetos
- Comerciantes
- Enemigos

Cada partida debe sentirse como una aventura diferente.

---



# NPCs

No queremos NPCs completamente estáticos.

Los NPCs deberán ser generados según la Seed.

Cada partida podrá generar distintos personajes.

Ejemplo:

Run 1

Existe un Herrero.

Run 2

No existe el Herrero.

Existe una Alquimista.

Run 3

Existe un Comerciante Nómada.

Run 4

Existe un Cartógrafo.

Las profesiones disponibles también pueden variar.

Ejemplos:

- Herrero
- Comerciante
- Alquimista
- Sacerdote
- Cazador
- Cartógrafo
- Constructor
- Explorador
- Coleccionista

---



# Sistema de Misiones

Las misiones deberán ser generadas proceduralmente.

No queremos misiones completamente fijas.

Las misiones deberán depender de:

- Mundo
- NPC
- Bioma
- Eventos
- Seed
- Estado del jugador

Cada partida contará una historia distinta.

---



# Ciclo Día y Noche

Durante el día:

- Fauna
- Comerciantes
- NPCs normales
- Recursos visibles

Durante la noche:

- Enemigos peligrosos
- Eventos especiales
- Comerciantes nocturnos
- Objetos únicos
- Recursos exclusivos
- Apariciones especiales

La noche no debe ser únicamente más difícil.

También debe ofrecer mejores recompensas.

---



# Dungeons

Las Dungeons serán generadas proceduralmente.

Pero estarán basadas en temas.

Ejemplos:

- Minas
- Templos
- Ruinas
- Bibliotecas
- Cementerios
- Fortalezas
- Laboratorios
- Colmenas
- Catacumbas

Cada mundo tendrá sus propias variantes.

---



# Generación Procedural

La generación procedural será el corazón del proyecto.

Toda la experiencia deberá construirse a partir de una Seed.

La Seed generará:

- Continentes
- Biomas
- Ríos
- Montañas
- Cuevas
- Dungeons
- NPCs
- Misiones
- Loot
- Recursos
- Eventos
- Fauna
- Flora
- Estructuras
- Portales
- Secretos

No queremos un simple mapa aleatorio.

Queremos un ecosistema procedural.

---



# Riesgo vs Recompensa

Este será uno de los pilares del juego.

El jugador siempre deberá tomar decisiones.

Ejemplos:

¿Exploro una Dungeon peligrosa?

¿Salgo durante la noche?

¿Cruzo un bioma hostil?

¿Gasto recursos ahora o más adelante?

Las mejores recompensas siempre implicarán mayores riesgos.

---



# Supervivencia

El jugador comenzará sin nada.

Deberá obtener:

- Comida
- Agua
- Refugio
- Herramientas
- Armas
- Armaduras
- Recursos

La supervivencia será importante durante toda la partida.

---



# Exploración

La exploración debe sentirse recompensada.

El jugador debe querer perderse.

Debe encontrar constantemente:

- Secretos
- Eventos
- NPCs
- Dungeons
- Objetos
- Biomas
- Recursos
- Misterios

---



# Arquitectura del Proyecto

No queremos construir solamente un videojuego.

Queremos construir una plataforma procedural.

Todo deberá ser modular.

Los sistemas principales serán independientes.

Ejemplo:

Core

↓

Generation

↓

World

↓

Combat

↓

Entities

↓

Inventory

↓

Crafting

↓

Survival

↓

NPC

↓

Dialogue

↓

Quest

↓

AI

↓

Dungeon

↓

Save System

↓

UI

---



# Filosofía Técnica

Todo deberá ser Data Driven.

Evitar lógica fija.

Evitar objetos hardcodeados.

Los datos deberán vivir fuera del código siempre que sea posible.

Ejemplos:

- Objetos
- NPCs
- Enemigos
- Misiones
- Loot
- Biomas
- Dungeons
- Eventos

Todo debe ser configurable.

---



# Documento Más Importante

Antes de comenzar el desarrollo debemos crear el documento llamado:

# Procedural Generation Bible

Este documento definirá:

- Cómo se genera el mundo.
- Cómo funcionan las Seeds.
- Cómo se generan NPCs.
- Cómo funcionan las Misiones.
- Cómo se generan Dungeons.
- Cómo funciona el Loot.
- Cómo funcionan los Eventos.
- Cómo se construye la progresión.

Este documento será la base de toda la arquitectura del juego.

---



# Objetivo para Claude

Quiero que Claude actúe como Arquitecto Principal del proyecto.

No quiero únicamente generación de código.

Necesito que cuestione decisiones.

Que proponga arquitecturas escalables.

Que detecte problemas de diseño.

Que proponga patrones de software.

Que diseñe sistemas modulares.

Que piense como un Lead Game Engineer.

Debe priorizar escalabilidad, mantenibilidad y reutilización por encima de soluciones rápidas.