local Edge = {}

function Edge:new (o)
	local o = o or {
	p0 = nil, p1 = nil, --edge points
	midpoint = nil, --halfway between v0, v1
	river = 0 --volume of water, or 0
	}
	return o
end

return Edge
