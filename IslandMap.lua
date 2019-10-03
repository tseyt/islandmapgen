--Lua port of Amit Patel's https://github.com/amitp/mapgen2/blob/master/Map.as

--CLASS INHERITANCE SETUP
local Map = require("./Map")

function inheritsFrom( baseClass )

    local new_class = {}
    local class_mt = { __index = new_class }

    function new_class:new()
        local newinst = {
		centers = {},
		corners = {},
		edges = {},
		SIZE = 256
		}
        setmetatable( newinst, class_mt )
        return newinst
    end

    if nil ~= baseClass then
        setmetatable( new_class, { __index = baseClass } )
    end

    return new_class
end

--ISLAND CLASS
local Island = inheritsFrom(Map)
local islandshape

local sqrt = math.sqrt
local sin = math.sin
local cos = math.cos
local max = math.max
local abs = math.abs
local atan2 = math.atan2
local pi = math.pi
local ceil = math.ceil
local random = math.random
local huge = math.huge
local min = math.min

local needsMoreRandomness = (math.floor(math.random()*100)/100) --pumps in more random elevations
math.randomseed(os.time())

local ISLAND_FACTOR = 1.07 --1.0 means no small islands, 2.0 means a lot
local LAKE_THRESHOLD = 0.3
local FORCE = true --Load first map quickly

function pointToKey(point)
	return point.x.."_"..point.y	
end

--**NEED TO FIX MAKERADIAL FUNCTION***
--makeRadial decides which points are on land or water based on overlapping sine waves (random radial island)
function makeRadial(seed) --factory function to return same randoms for inside(), unless new island is created
	local bumps = random(1, 4)
	math.randomseed(seed)
	local startAngle = random() * (2*pi)
	local dipAngle = random() * (2*pi)
	local dipWidth = random() * 0.5 + 0.2
	
	local inside = function (point)
		if not point then return end
		local angle = atan2(point.y, point.x)
		local length = 0.5 * (max(abs(point.x), abs(point.y) + point.magnitude))

		local r1 = 0.7 + 0.40*sin(startAngle + bumps*angle + cos((bumps+3)*angle))		
		local r2 = 0.5 - 0.20*sin(startAngle + bumps*angle - sin((bumps+2)*angle))
		if abs(angle - dipAngle) < dipWidth
		or abs(angle - dipAngle + 2*pi) < dipWidth
		or abs(angle - dipAngle - 2*pi) < dipWidth then
			r1, r2 = 0.2, 0.2
		end
		return length < r1 or (length > r1*ISLAND_FACTOR and length < r2)
	end
	return {
		inside = inside
	}
end

function inside(point, size)
	local newpoint = Vector2.new((point.x - (size/2))/(size/2), (point.y - (size/2))/(size/2))
	return islandshape.inside(newpoint)
end

function lookupEdgeFromCorner(corner1, corner2, edges)
	for i, ee in pairs(corner1.protrudes) do
		local e = edges[pointToKey(ee)]
		if (e.p0.x == corner2.point.x and e.p0.y == corner2.point.y) or (e.p1.x == corner2.point.x and e.p1.y == corner2.point.y) then
			return e
		end
	end
end

--faster queue implementation

--push value onto last index
function push(list, value)
	local last = list.last + 1
	list.last = last
	list[last] = value
end

--pop first value
function pop(list)
	local first = list.first
	if first > list.last then error("list is empty") end
	local value = list[first]
	list[first] = nil        -- to allow garbage collection
	list.first = first + 1
	return value
end
	
function assignCornerElevations(corners, size)
	local infinity = huge
	local queue = {first = 0, last = -1}	
	table.sort(corners, function(a,b) return a.elevation < b.elevation end)
	for i, q in pairs(corners) do
		q.water = not inside(q.point, size)
	end
	wait()
	for _, q in pairs(corners) do
		if q.border then
			q.elevation = 0.0
			push(queue, q)
		else
			q.elevation = infinity
		end
	end
	wait()
	local count = 0
	while not (queue.first > queue.last) do
		count = count+1
		if FORCE then
			if count % 20 == 0 then wait() end
		else wait() end
		local qq = pop(queue)
		local q = corners[pointToKey(qq.point)]
		for _, ss in pairs(q.adjacent) do
			local s = corners[pointToKey(ss)]
			local newElevation = 0
			newElevation = 0.01 + q.elevation
			if not q.water and not s.water then
				newElevation = newElevation + 1
			end
			if newElevation < s.elevation then
				s.elevation = newElevation
				push(queue, s)
			end
		end
	end
	queue = nil
end

function assignOceanCoastAndLand(centers, corners) 
	local queue = {first = 0, last = -1}
	for _, p in pairs(centers) do
		local numWater = 0
		for _, qq in pairs(p.corners) do
			local q = corners[pointToKey(qq)]
			if q.border then
				p.border = true
				p.ocean = true
				q.water = true
				push(queue, p)
			end
			if q.water then
				numWater = numWater + 1
			end
		end
		p.water = p.ocean or numWater >= #p.corners * LAKE_THRESHOLD
	end
	wait()
	local count = 0
	while not (queue.first > queue.last) do
		count = count+1
		if FORCE then
			if count % 20 == 0 then wait() end
		else wait() end
		local pp = pop(queue)
		local p = centers[pointToKey(pp.point)]
		for _, rr in pairs(p.neighbors) do
			local r = centers[pointToKey(rr)]
			if r.water and not r.ocean then
				r.ocean = true
				push(queue, r)
			end
		end
	end
	queue = nil
	wait()
	for _, p in pairs(centers) do
		local numOcean = 0
		local numLand = 0
		for _, rr in pairs(p.neighbors) do
			local r = centers[pointToKey(rr)]
			local ro = 0
			local rw = 1
			if r.ocean then ro = 1 end
			if r.water then rw = 0 end
			numOcean = numOcean + ro 
			numLand = numLand + rw
		end
		p.coast	= numOcean > 0 and numLand > 0
	end
	wait()
	for _, q in pairs(corners) do
		local numOcean = 0
		local numLand = 0
		for _, pp in pairs(q.touches) do
			local p = centers[pointToKey(pp)]
			local po = 0
			local pw = 1
			if p.ocean then po=1 end
			if p.water then pw=0 end
			numOcean = numOcean + po
			numLand = numLand + pw
		end
		q.ocean = numOcean == #q.touches
		q.coast = numOcean > 0 and numLand > 0
		q.water = q.border or ((numLand ~= #q.touches) and not q.coast)
	end
	wait()
	--Add in water only right next to beach
	for _, p in pairs(centers) do
		local numCoast = 0
		local numWater = 0
		for _, rr in pairs(p.neighbors) do
			local r = centers[pointToKey(rr)]
			local rc = 0
			local rw = 0
			if r.coast then rc = 1 end
			if r.water then rw = 1 end
			numWater = numWater + rw
			numCoast = numCoast + rc
		end
		p.shore	= numCoast > 0 and numWater < 4 and numWater > 0
	end
end

function landCorners(corners_)
	local locations = {}
	for _, q in pairs(corners_) do
		if not q.ocean and not q.coast then
			locations[#locations+1] = q
		end
	end	
	return locations
end

function redistributeElevations(locations)
	local SCALE_FACTOR = 1.1
	table.sort(locations, function(a, b) return a.elevation < b.elevation end)
	for i, l in pairs (locations) do
		local y = i/(#locations-1)
		local x = sqrt(SCALE_FACTOR) - sqrt(SCALE_FACTOR*(1-y))
		if x > 1.0 then x = 1.0 end
		locations[i].elevation = x
	end
end

function assignPolygonElevations(centers, corners)
	for i, c in pairs(centers) do
		local sumElevation = 0.0
		for i, ss in pairs(c.corners) do
			local s = corners[pointToKey(ss)]
			sumElevation = sumElevation + (ceil(s.elevation*100))/100
		end
		c.elevation = sumElevation / #c.corners
	end
end

function calculateDownslopes(corners)
	for i, q in pairs(corners) do
		local r = q
		for j, ss in pairs(q.adjacent) do
			local s = corners[pointToKey(ss)]
			if s.elevation < r.elevation then
				r = s
			end
		end
		q.downslope = r
	end
end

function calculateWatersheds(corners)
	for i, q in pairs(corners) do
		q.watershed = q
		if not q.ocean and not q.coast then
			q.watershed = q.downslope
		end
	end
	wait()
	local count = 0
	for i = 1, 100 do
		count = count+1
		local changed = false
		for j, q in pairs(corners) do
			count = count+1
			if count % 300 == 0 then wait() end
			if not q.ocean and not q.coast and not q.watershed.coast then
				local r = q.downslope.watershed
				if not r.ocean then
					q.watershed = r
					changed = true
				end
			end
		end
		if not changed then break end
	end
	wait()
	for i, q in pairs(corners) do
		local r = q.watershed
		r.watershed_size = 1 + (r.watershed_size or 0)
	end
end

function createRivers(size, corners, edges)
	for i = 1, size / 2 do
		local point = {x = random(1, size - 1), y = random(1, size - 1)}
		local q = corners[pointToKey(point)]
		if q.ocean or q.elevation < 0.3 or q.elevation > 0.9 then
			--do nothing
		else
			local count = 0
			while not q.coast do
				count = count+1
				if FORCE then
					if count % 20 == 0 then wait() end
				else wait() end
				if q == q.downslope then
					break
				end
				local edge = lookupEdgeFromCorner(q, q.downslope, edges)
				if edge ~= nil then edge.river = edge.river + 1 end
				q.river = (q.river or 0) + 1
				q.downslope.river = (q.downslope.river or 0) + 1
				q = q.downslope
			end
		end
	end
end

function assignCornerMoisture(corners)
	local queue = {first = 0, last = -1}
	for i, q in pairs(corners) do
		if (q.water or q.river > 0) and not q.ocean then
			if q.river > 0 then
				q.moisture = min(3.0, (0.2 * q.river))
			else q.moisture = 1.0 end
			push(queue, q)
		else
			q.moisture = 0.0
		end
	end
	wait()
	local count = 0
	while not (queue.first > queue.last) do
		count = count+1
		if FORCE then
			if count % 20 == 0 then wait() end
		else wait() end
		local qq = pop(queue)
		local q = corners[pointToKey(qq.point)]
		for i, rr in pairs(q.adjacent) do
			local r = corners[pointToKey(rr)]
			local newMoisture = q.moisture * 0.9
			if newMoisture > r.moisture then
				r.moisture = newMoisture
				push(queue, r)
			end
		end
	end
	queue = nil
	wait()
	for i, q in pairs(corners) do
		if q.ocean or q.coast then
			q.moisture = 1.0
		end
	end
end

function redistributeMoisture(locations)
	table.sort(locations, function(a, b) return a.moisture > b.moisture end) 
	for i = 1, #locations do
		locations[i].moisture = i/(#locations-1)
	end
end

function assignPolygonMoisture(centers, corners)
	for i, p in pairs(centers) do
		local sumMoisture = 0.0
		for j, qq in pairs(p.corners) do
			local q = corners[pointToKey(qq)]
			if q.moisture > 1.0 then q.moisture = 1.0 end
			sumMoisture = sumMoisture + q.moisture
		end
		p.moisture = sumMoisture / #p.corners
	end
end

function getBiome(p)
	if p.ocean then
		if p.shore then return Enum.Material.Water
		else return Enum.Material.Air end
	elseif p.water then
		if p.elevation < 0.1 then return Enum.Material.Mud
		elseif p.elevation > 0.8 then return Enum.Material.Ice end
		return Enum.Material.Water
	elseif p.coast then
		return Enum.Material.Sand
	elseif p.elevation > 0.8 then
		if p.moisture > 0.66 then return Enum.Material.Glacier
		elseif p.moisture > 0.33 then return Enum.Material.Basalt
		else return Enum.Material.Glacier end
	elseif p.elevation > 0.6 then
		if p.moisture > 0.52 then return Enum.Material.Slate
		elseif p.moisture > 0.33 then return Enum.Material.Salt
		else return Enum.Material.Concrete end
	elseif p.elevation > 0.36 then
		if p.moisture > 0.75 then return Enum.Material.Pavement
		elseif p.moisture > 0.52 then return Enum.Material.Mud
		elseif p.moisture > 0.33 then return Enum.Material.Rock
		else return Enum.Material.Ground end
	else
		if p.moisture > 0.83 then return Enum.Material.Limestone
		elseif p.moisture > 0.66 then return Enum.Material.Sandstone
		elseif p.moisture > 0.33 then return Enum.Material.LeafyGrass
		else return Enum.Material.Grass end
	end
end

function assignBiomes(centers, size)
	local count = 0
	for i, p in pairs(centers) do
		count = count+1
		if FORCE then
			if count % 20 == 0 then wait() end
		else wait() end
		p.biome = getBiome(p)
--		if p.x == size/2-.5 and p.y == size/2-.5 then
--			p.biome = Enum.Material.Basalt.Value
--		end
	end
end

---------------------------------------------------------------
--ROADS
--Could be made as a module

local function createRoads(centers, corners, edges, road, roadConnections)
	-- Oceans and coastal polygons are the lowest contour zone
	local queue = {first = 0, last = -1}
	local elevationThresholds = {0, 0.1, 0.4, 0.7}
	local cornerContour = {}
	local centerContour = {}
	
	for _, p in pairs (centers) do
		if (p.coast or p.ocean) then
			centerContour[pointToKey(p.point)] = 1
			push(queue, p)
		end
	end
	wait()
	while #queue > 0 do
		local p = pop(queue)
		for _, rr in pairs (p.neighbors) do
			local r = centers[pointToKey(rr)]
			local newLevel = centerContour[pointToKey(p.point)] or 0
			while (r.elevation > elevationThresholds[newLevel] and not r.water) do
				-- extend contour lines past bodies of water so that roads don't terminate inside lakes
				newLevel = newLevel + 1
			end
			if newLevel < (centerContour[pointToKey(r.point)] or 999) then
				centerContour[pointToKey(r.point)] = newLevel
				push(queue, r)
			end
		end
		wait()
	end
	wait()
	--A corner's contour level is the MIN of its polygons
	for _, p in pairs (centers) do
		for _, qq in pairs (p.corners) do
			local q = corners[pointToKey(qq)]
			cornerContour[pointToKey(q.point)] = math.min(cornerContour[pointToKey(q.point)] or 999, centerContour[pointToKey(p.point)] or 999)
		end
	end
	wait()
	--Roads go between polygons that have different contour levels
	for _, p in pairs (centers) do
		for _, ee in pairs (p.borders) do
			local edge = edges[pointToKey(ee)]
			if edge.p0 ~= nil and edge.p1 ~= nil and cornerContour[pointToKey(edge.p0)] ~= cornerContour[pointToKey(edge.p1)] then
				road[pointToKey(edge.midpoint)] = math.min(cornerContour[pointToKey(edge.p0)], cornerContour[pointToKey(edge.p1)])
				if roadConnections[pointToKey(p.point)] == nil then
					roadConnections[pointToKey(p.point)] = {}
				end
				table.insert(roadConnections[pointToKey(p.point)], 1, edge)
			end
		end
	end
end

---------------------------------------------------------------

function Island:go(size, seed)
	self.SIZE = size
	self.centers = {}
	self.corners = {}
	self.edges = {}
	--Modules
	self.road = {}
	self.roadConnections = {}
	--
	
	islandshape = makeRadial(seed)
	
	local stages = {}
	
	local push = function (list, value)
		table.insert(list, #list+1, value)
	end
	
	local startTime = elapsedTime()
	
	local timeIt = function (name, fn)
		print(name..', Loading: '..math.ceil(elapsedTime()-startTime)..' seconds')
		fn()
	end
	
	push(stages, {
		"Place points",
		function()
			self:generateCenters()
			wait()
			self:generateCorners()
			wait()
			self:generateEdges()
			wait()
		end
	})
	
	push(stages, {
		"Build graph",
		function()
			wait()
			self:buildGraph()
		end
	})
	
	push(stages, {
		"Assign elevations",
		function()
			assignCornerElevations(self.corners, self.SIZE)
			wait()
			assignOceanCoastAndLand(self.centers, self.corners)
			wait()
			redistributeElevations(landCorners(self.corners))
			wait()
			for i, c in pairs (self.corners) do
				if c.ocean or c.coast then
					c.elevation = 0.0
				end
			end
			wait()
			assignPolygonElevations(self.centers, self.corners)
			wait()
		end
	})
	
	push(stages, {
		"Assign moisture",
		function()
			calculateDownslopes(self.corners)
			wait()
			calculateWatersheds(self.corners)
			wait()
			createRivers(self.SIZE, self.corners, self.edges)
			wait()
			
			assignCornerMoisture(self.corners)
			wait()
			redistributeMoisture(landCorners(self.corners))
			wait()
			assignPolygonMoisture(self.centers, self.corners)
			wait()
		end
	})

	push(stages, {
		"Decorate map",
		function()
			assignBiomes(self.centers, self.SIZE)
			wait()
		end
	})
	
	push(stages, {
		"Modules",
		function()
			createRoads(self.centers, self.corners, self.edges, self.road, self.roadConnections)
			wait()
		end
	})
	
	for i = 1, #stages do
		wait()
		timeIt(stages[i][1], stages[i][2])
	end
	
	print("Island Created!")
	FORCE = false
end

return Island
