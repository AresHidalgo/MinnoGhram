## Resultado de la generación: el mundo tal como existe al terminar la Seed.
## No conoce nodos, escenas ni rendering — solo datos.
class_name WorldState
extends RefCounted

var master_seed: int
var profile: WorldProfile
var hash_version: int = SeedHash.HASH_VERSION

## Sub-seed usada por cada etapa (StringName -> int). Útil para el Inspector Procedural.
var sub_seeds: Dictionary = {}
## Intentos que necesitó cada etapa (StringName -> int).
var attempts: Dictionary = {}

var size: int = 0
## Elevación normalizada 0..1, fila por fila (índice = z * size + x).
var heightmap: PackedFloat32Array = PackedFloat32Array()
var land_ratio: float = 0.0


func get_height01(x: int, z: int) -> float:
	x = clampi(x, 0, size - 1)
	z = clampi(z, 0, size - 1)
	return heightmap[z * size + x]


func is_land(x: int, z: int) -> bool:
	return get_height01(x, z) >= profile.sea_level


## Huella del mundo: dos generaciones con la misma Seed deben dar el mismo valor.
func checksum() -> int:
	var h := SeedHash.fnv1a_32("%d|%d" % [master_seed, size])
	for v in heightmap:
		# Cuantizamos para que la huella no dependa del último bit de un float.
		var q := int(roundf(v * 1000000.0))
		h = ((h ^ (q & 0xFFFFFFFF)) * 16777619) & 0xFFFFFFFF
	return h


## Imagen 2D en escala de colores (base del Visualizador de Seeds).
func to_image() -> Image:
	var img := Image.create(size, size, false, Image.FORMAT_RGB8)
	for z in size:
		for x in size:
			img.set_pixel(x, z, TerrainColors.color_for(get_height01(x, z), profile.sea_level))
	return img
