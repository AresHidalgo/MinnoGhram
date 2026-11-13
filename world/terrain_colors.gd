## Colores provisionales por altura, hasta que existan biomas reales (etapa 5).
class_name TerrainColors
extends RefCounted

const DEEP := Color(0.08, 0.16, 0.32)
const SHALLOW := Color(0.18, 0.36, 0.55)
const SAND := Color(0.76, 0.70, 0.50)
const GRASS := Color(0.30, 0.48, 0.24)
const FOREST := Color(0.18, 0.34, 0.18)
const ROCK := Color(0.42, 0.40, 0.38)
const SNOW := Color(0.92, 0.92, 0.95)


static func color_for(h: float, sea: float) -> Color:
	if h < sea * 0.7:
		return DEEP
	if h < sea:
		return SHALLOW
	var t := (h - sea) / maxf(1.0 - sea, 0.0001)
	if t < 0.05:
		return SAND
	if t < 0.35:
		return GRASS
	if t < 0.6:
		return FOREST
	if t < 0.85:
		return ROCK
	return SNOW
