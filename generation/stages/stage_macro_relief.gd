## Etapa 2: Macro-relieve (Bible 6.2).
## Produce el heightmap 0..1. Tierra vs. agua sale de comparar con sea_level.
@tool
class_name StageMacroRelief
extends GenerationStage


func get_stage_id() -> StringName:
	return &"macro_relief"


func run(state: WorldState, sub_seed: int) -> bool:
	var p := state.profile
	var n := state.size

	var noise := FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	noise.fractal_octaves = p.noise_octaves
	noise.frequency = p.noise_frequency
	# FastNoiseLite usa una seed de 32 bits.
	noise.seed = sub_seed & 0x7FFFFFFF

	var hm := PackedFloat32Array()
	hm.resize(n * n)
	var land := 0
	var center := (n - 1) * 0.5

	for z in n:
		for x in n:
			var v := (noise.get_noise_2d(x, z) + 1.0) * 0.5  # -1..1 -> 0..1
			# Caída hacia los bordes: el mundo es finito y está rodeado de océano.
			var dx := (x - center) / center
			var dz := (z - center) / center
			var d := clampf(sqrt(dx * dx + dz * dz), 0.0, 1.0)
			v = lerpf(v, v * (1.0 - d * d), p.edge_falloff)
			v = clampf(v * 1.25, 0.0, 1.0)
			hm[z * n + x] = v
			if v >= p.sea_level:
				land += 1

	state.heightmap = hm
	state.land_ratio = float(land) / float(n * n)
	# Regla: debe existir suficiente masa continental jugable.
	return state.land_ratio >= p.min_land_ratio
