## Hash propio, estable y versionado para derivar Seeds.
##
## No usamos hash() de Godot porque su resultado no está garantizado entre
## versiones del motor: una actualización podría cambiar todos los mundos ya
## compartidos por jugadores (ver 03_Technical_Architecture.md, sección 6).
##
## Si alguna vez cambias este algoritmo, sube HASH_VERSION y guarda la versión
## junto con la Seed en los archivos de guardado.
class_name SeedHash
extends RefCounted

const HASH_VERSION := 1

const _FNV_OFFSET := 2166136261
const _FNV_PRIME := 16777619
const _MASK_32 := 0xFFFFFFFF


## FNV-1a de 32 bits sobre los bytes UTF-8 del texto.
static func fnv1a_32(text: String) -> int:
	var h := _FNV_OFFSET
	for b in text.to_utf8_buffer():
		h = ((h ^ b) * _FNV_PRIME) & _MASK_32
	return h


## Convierte lo que escribe el jugador ("dragon", "12345") en una Seed maestra.
## Si el texto es un número entero, se usa tal cual para que sea fácil compartirlo.
static func seed_from_text(text: String) -> int:
	var t := text.strip_edges()
	if t.is_valid_int():
		return t.to_int()
	return fnv1a_32(t)


## Deriva la sub-seed de una etapa del pipeline.
## `attempt` permite reintentos deterministas cuando una etapa falla su validación
## (Regla de Alcanzabilidad / masa continental mínima).
static func derive(master_seed: int, stage_id: StringName, attempt: int = 0) -> int:
	var key := "v%d|%d|%s|%d" % [HASH_VERSION, master_seed, stage_id, attempt]
	# Dos hashes de 32 bits combinados en uno de 63 bits (positivo).
	var hi := fnv1a_32(key + "#hi")
	var lo := fnv1a_32(key + "#lo")
	return ((hi & 0x7FFFFFFF) << 32) | lo
