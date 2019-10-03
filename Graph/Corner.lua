local Corner = {}

function Corner:new (o)
	local o = o or {
	point = {x = 0, y = 0}, --location
	water = false, --lake or ocean
	ocean = false, --ocean
	coast = false, --touches land and ocean polygons
	shore = false, --water touching beach
	border = false, --at edge of map
	biome = Enum.Material.Water, --Terrain material
	elevation = 0, --0.0 - 1.0
	moisture = 0, --0.0 - 1.0
	touches = {},
	protrudes = {},
	adjacent = {},
	river = 0, --0 if no river, or volume of water in river
	downslope = nil, --pointer to adjacent corner most downhill
	watershed = nil, --pointer to coastal corner, or nil
	watershed_size = 0}
	return o
end

return Corner