local Map = {}

local Center = require("./Graph.Center")
local Corner = require("./Graph.Corner")
local Edge = require("./Graph.Edge")

local cornerLookup = {}
local centerLookup = {}
local edgeLookup = {}

function Map:new (o)
	local o = o or {
	centers = {},
	corners = {},
	edges = {},
	SIZE = 256
	}
    setmetatable(o, self)
	self.__index = self
	return o
end

function pointToKey(point)
	return point.x.."_"..point.y	
end

function Map:generateCenters()
	for xx = 1, self.SIZE do
		for yy = 1, self.SIZE do
			local cntr = Center:new()
			cntr.point = {x = 0.5+xx - 1, y = 0.5+yy - 1}
			self.centers[pointToKey(cntr.point)] = cntr
		end
	end
end

function Map:generateCorners()
	for xx = 0, self.SIZE do
		for yy = 0, self.SIZE do
			local crnr = Corner:new() 
			crnr.point = {x = xx, y = yy}
			crnr.border = crnr.point.x == 0 or crnr.point.x == self.SIZE or crnr.point.y == 0 or crnr.point.y == self.SIZE
			self.corners[pointToKey(crnr.point)] = crnr
		end
	end
end

function Map:generateEdges()
	--since there are 16 edges per row, but 17 rows(since 1 extra edge to close off grid)
	--dir == direction of edge row
	--parr == parrallel edge rows
	for parr = 0, self.SIZE do
		for dir = 0, self.SIZE-1 do
			--edges per column
			local cedge = Edge:new()
			cedge.p0 = {x = parr, y = dir}
			cedge.p1 = {x = parr, y = dir+1}
			cedge.midpoint = {x = cedge.p0.x, y = cedge.p0.y+0.5}
			self.edges[pointToKey(cedge.midpoint)] = cedge
			--edges per row
			local redge = Edge:new()
			redge.p0 = {x = dir, y = parr}
			redge.p1 = {x = dir+1, y = parr}
			redge.midpoint = {x = redge.p0.x+0.5, y = redge.p0.y}
			self.edges[pointToKey(redge.midpoint)] = redge
		end
	end
end

function neighbors(center, centers, size)
	if center.point.y + 1 < size then
		local up = {x = center.point.x, y = center.point.y+1}
		center.neighbors[#center.neighbors+1] = up
	end
	if center.point.y - 1 > 0 then
		local down = {x = center.point.x, y = center.point.y-1}
		center.neighbors[#center.neighbors+1] = down
	end
	if center.point.x - 1 > 0 then
		local left = {x = center.point.x - 1, y = center.point.y}
		center.neighbors[#center.neighbors+1] = left
	end
	if center.point.x + 1 < size then
		local right = {x = center.point.x + 1, y = center.point.y}
		center.neighbors[#center.neighbors+1] = right
	end
end

function corners(center, corners)
	local bottomleft = {x = center.point.x - 0.5, y = center.point.y - 0.5}
	center.corners[1] = bottomleft
	
	local topleft = {x = center.point.x - 0.5, y = center.point.y + 0.5}
	center.corners[2] = topleft

	local bottomright = {x = center.point.x + 0.5, y = center.point.y - 0.5}
	center.corners[3] = bottomright
	
	local topright = {x = center.point.x + 0.5, y = center.point.y + 0.5}
	center.corners[4] = topright
end

function borders(center, edges)
	local leftborder = {x = center.point.x - 0.5, y = center.point.y}
	center.borders[1] = leftborder
	
	local rightborder = {x = center.point.x + 0.5, y = center.point.y}
	center.borders[2] = rightborder
	
	local topborder = {x = center.point.x, y = center.point.y + 0.5}
	center.borders[3] = topborder
	
	local bottomborder = {x = center.point.x, y = center.point.y - 0.5}
	center.borders[4] = bottomborder
end

function touches(corner, centers, size)
	if corner.point.x < size and corner.point.y < size then
		local upright = {x = corner.point.x + 0.5, y = corner.point.y + 0.5}
		corner.touches[#corner.touches+1] = upright
	end
	if corner.point.x < size and corner.point.y > 0 then
		local downright = {x = corner.point.x + 0.5, y = corner.point.y - 0.5}
		corner.touches[#corner.touches+1] = downright
	end
	if corner.point.x > 0 and corner.point.y < size then
		local upleft = {x = corner.point.x - 0.5, y = corner.point.y + 0.5}
		corner.touches[#corner.touches+1] = upleft
	end
	if corner.point.x > 0 and corner.point.y > 0 then
		local downleft = {x = corner.point.x - 0.5, y = corner.point.y - 0.5}
		corner.touches[#corner.touches+1] = downleft
	end
end

function protrudes(corner, edges, size)
	if corner.point.x > 0 then
		local left = {x = corner.point.x - 0.5, y = corner.point.y}
		corner.protrudes[#corner.protrudes+1] = left
	end
	if corner.point.x < size then
		local right = {x = corner.point.x + 0.5, y = corner.point.y}
		corner.protrudes[#corner.protrudes+1] = right
	end
	if corner.point.y < size then
		local up = {x = corner.point.x, y = corner.point.y + 0.5}
		corner.protrudes[#corner.protrudes+1] = up
	end
	if corner.point.y > 0 then
		local down = {x = corner.point.x, y = corner.point.y - 0.5}
		corner.protrudes[#corner.protrudes+1] = down
	end
end

function adjacent(corner, corners, size)
	if corner.point.x > 0 then
		local left = {x = corner.point.x - 1, y = corner.point.y}
		corner.adjacent[#corner.adjacent+1] = left
	end
	if corner.point.x < size then
		local right = {x = corner.point.x + 1, y = corner.point.y}
		corner.adjacent[#corner.adjacent+1] = right
	end
	if corner.point.y < size then
		local up = {x = corner.point.x, y = corner.point.y + 1}
		corner.adjacent[#corner.adjacent+1] = up
	end
	if corner.point.y > 0 then
		local down = {x = corner.point.x, y = corner.point.y - 1}
		corner.adjacent[#corner.adjacent+1] = down
	end
end

function Map:buildGraph()
	for i, c in pairs(self.centers) do
		neighbors(c, self.centers, self.SIZE)
		corners(c, self.corners)
		borders(c, self.edges)
	end
	wait()
	for i, s in pairs(self.corners) do
		touches(s, self.centers, self.SIZE)
		protrudes(s, self.edges, self.SIZE)
		adjacent(s, self.corners, self.SIZE)
	end
end

return Map