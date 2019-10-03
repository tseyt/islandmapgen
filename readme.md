Lua port of Amit Patel's [Polygonal Map Generation for Games](http://www-cs-students.stanford.edu/~amitp/game-programming/polygon-map-generation/)

See a demo of how it works [here.](http://www-cs-students.stanford.edu/~amitp/game-programming/polygon-map-generation/demo.html)

Amit's algorithm creates an interesting procedurally-generated island map featuring coastlines, various biomes, and rivers through Voronoi polygons and Delaunay triangulation (I also added roads, which run perpendicular to rivers along certain elevations).
I ported this algorithm for generating procedural Island worlds for a massively-multiplayer 3D game I was making called [Voxrealms](https://tseyt.github.io/denseli). The game is no longer maintained by me, and I am releasing this code so other developers using Lua can generate maps for their games.

Read more about how the algorithm works [here.](http://www-cs-students.stanford.edu/~amitp/game-programming/polygon-map-generation/)

Create a new randomly-generated IslandMap:
```lua
local IslandMap = require(**IslandMap Script Location**)
local island = IslandMap:new() --Creates a new IslandMap
island:go() --Starts the procedural generation (if IslandMap:go() is called again, it will generate a completely new map)
```

The `island` variable now contains the graph structure of polygons for your procedural Island world, and you may use the data within to construct your new island for your game.

This code is Open Source. Zero Rights Reserved.

