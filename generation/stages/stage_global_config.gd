## Etapa 1: Configuración Global (Bible 6.1).
class_name StageGlobalConfig
extends GenerationStage


func get_stage_id() -> StringName:
	return &"global_config"


func run(state: WorldState, _sub_seed: int) -> bool:
	var errors := state.profile.validate_schema()
	if not errors.is_empty():
		push_error("WorldProfile inválido: %s" % ", ".join(errors))
		return false
	state.size = state.profile.world_size_cells
	return true
