Lua port of Amit Patel's [Polygonal Map Generation for Games](http://www-cs-students.stanford.edu/~amitp/game-programming/polygon-map-generation/)

See a demo of how it works [here.](http://www-cs-students.stanford.edu/~amitp/game-programming/polygon-map-generation/demo.html)

Amit's algorithm creates an interesting procedurally-generated island map featuring coastlines, various biomes, and rivers (I also added paths which run perpendicular to rivers) through Voronoi polygons and Delaunay triangulation.
I ported this algorithm for generating procedural Island worlds for a massively-multiplayer 3D game I was making called [Voxrealms](https://tseyt.github.io/denseli).

Read more about how the algorithm works [here.](http://www-cs-students.stanford.edu/~amitp/game-programming/polygon-map-generation/)

Create new randomly-generated IslandMap
```
local IslandMap = require(**IslandMap Script Location**)
local island = IslandMap:new()
```

The `island` variable now contains the graph structure of polygons for your procedural Island world, and you may use the data within to construct your new island for your game.

This code is Open Source. Zero Rights Reserved.

