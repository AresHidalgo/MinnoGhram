## Perfil de Mundo: los datos que diferencian Oppervlak, Onderwereld y
## Voorgeborchte. El pipeline es uno solo; cada mundo es un archivo .tres.
## (02_Procedural_Generation_Bible.md, sección 4)
##
## v0: solo los campos que usan las etapas 1 y 2. Se irán añadiendo campos
## a medida que se implementen más etapas (clima, biomas, dungeons...).
@tool
class_name WorldProfile
extends Resource

@export var profile_id: StringName = &"oppervlak"
@export var display_name: String = "Oppervlak"

@export_group("Tamaño")
## Celdas por lado del heightmap. El mundo tiene (world_size_cells x world_size_cells).
@export_range(32, 4096, 1) var world_size_cells: int = 256
## Metros por celda en el mundo 3D.
@export_range(0.25, 16.0, 0.25) var cell_size_m: float = 2.0

@export_group("Macro-relieve")
## Altura máxima del terreno en metros.
@export_range(1.0, 500.0, 1.0) var height_scale_m: float = 60.0
## Por debajo de este valor (0..1) el terreno es océano.
@export_range(0.0, 1.0, 0.01) var sea_level: float = 0.35
@export_range(0.0001, 0.1, 0.0001) var noise_frequency: float = 0.008
@export_range(1, 10, 1) var noise_octaves: int = 5
## Cuánto se hunden los bordes del mapa para formar océano alrededor (mundo finito).
@export_range(0.0, 1.0, 0.01) var edge_falloff: float = 0.6
## Proporción mínima de tierra; si no se alcanza, la etapa se reintenta.
@export_range(0.0, 1.0, 0.01) var min_land_ratio: float = 0.4
@export_range(1, 64, 1) var max_attempts: int = 16


## Validación de esquema (03_Technical_Architecture.md, sección 5).
func validate_schema() -> PackedStringArray:
	var errors := PackedStringArray()
	if profile_id == &"":
		errors.append("profile_id vacío")
	if world_size_cells < 32:
		errors.append("world_size_cells debe ser >= 32")
	if min_land_ratio >= 1.0:
		errors.append("min_land_ratio debe ser < 1.0")
	return errors
