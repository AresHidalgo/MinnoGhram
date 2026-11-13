## Ejecuta el pipeline de generación en orden.
## Hoy tiene 2 de las 17 etapas; las siguientes se añaden a la lista _stages.
@tool
class_name WorldGenerator
extends RefCounted

var _stages: Array[GenerationStage] = [
	StageGlobalConfig.new(),
	StageMacroRelief.new(),
]


func generate(master_seed: int, profile: WorldProfile) -> WorldState:
	var state := WorldState.new()
	state.master_seed = master_seed
	state.profile = profile

	for stage in _stages:
		var id := stage.get_stage_id()
		var ok := false
		var attempt := 0
		while attempt < profile.max_attempts:
			var sub_seed := SeedHash.derive(master_seed, id, attempt)
			state.sub_seeds[id] = sub_seed
			state.attempts[id] = attempt + 1
			if stage.run(state, sub_seed):
				ok = true
				break
			attempt += 1
		if not ok:
			# El último intento se conserva: determinista aunque no cumpla la regla.
			push_warning("Etapa %s no pasó su validación tras %d intentos" % [id, profile.max_attempts])
	return state
