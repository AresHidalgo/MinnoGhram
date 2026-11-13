## Etapa base del pipeline (02_Procedural_Generation_Bible.md, sección 5).
## Reglas:
##  - Solo usa el RandomNumberGenerator / noise que recibe con su sub-seed.
##  - Nunca llama a randi()/randf() globales.
##  - Nunca pregunta "¿qué mundo es?": todo lo específico viene del WorldProfile.
class_name GenerationStage
extends RefCounted


func get_stage_id() -> StringName:
	push_error("GenerationStage.get_stage_id() no implementado")
	return &""


## Ejecuta la etapa con la sub-seed dada. Devuelve true si el resultado es válido.
## Si devuelve false, el generador reintenta con otra sub-seed derivada.
func run(_state: WorldState, _sub_seed: int) -> bool:
	push_error("GenerationStage.run() no implementado")
	return false
