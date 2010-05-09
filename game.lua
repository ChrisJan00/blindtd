

-- Blind Tower Defense (temporal name)
-- Copyright 2009 Iwan Gabovitch, Christiaan Janssen, September 2009
--
-- This file is part of Blind Tower Defense
--
--     Blind Tower Defense is free software: you can redistribute it and/or modify
--     it under the terms of the GNU General Public License as published by
--     the Free Software Foundation, either version 3 of the License, or
--     (at your option) any later version.
--
--     Blind Tower Defense is distributed in the hope that it will be useful,
--     but WITHOUT ANY WARRANTY; without even the implied warranty of
--     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
--     GNU General Public License for more details.
--
--     You should have received a copy of the GNU General Public License
--     along with Blind Tower Defense  If not, see <http://www.gnu.org/licenses/>.

Game = class(function(g)
	g:load()
end)

step_counter = 0
step_size = 0.08
tabledelay = 0
listdelay = 0
mytext=""
fps = 0
show_fps = false
enemy_timer = 3
enemy_spawndelay = 3
enemy_launcher = true
touched = 0

self = {}

-- todo:  since the order in which parts of the game are instantiated is a bit random, avoid references in sub-items until necessary
-- (that is, if a class has self.sthref = game.sthref, avoid doing that in the constructor and retrieve the reference in the method that needs it)
-- also:  avoid underscores in method names

function Game:load()
--~ 	love.filesystem.load("map.lua")()
--~ 	love.filesystem.load("routefinder.lua")()

	self.map = generateMapWRooms()
	self.cachedmap = {}



	self.scheduler = Scheduler()
	self.pathcont={ path={} }
	self.path={}

	self.scheduler:addUntimedTask(MapCacher(self.map,self.cachedmap))

	----------- actuators
	self.actuatorList = ActuatorList(self)
	while self.actuatorList.list.n < 0 do
		local pos = {math.random(20),math.random(20)}
		if self.map[pos[1]][pos[2]].corridor then self.actuatorList:addBomb(pos) end
	end

	-- doors
	self:addDoors()

		--~ 	initScent(self.map)
	self.scentTask = ScentTask(self)
	self.scheduler:addTimedTask(self.scentTask,0.08)

	self.player = Player(self)
	currentpos = {self.player.pos[1],self.player.pos[2]}





	--~  	launchEnemy(self.scentTask)
	self.enemyTask = EnemyTask(self)
	self.scheduler:addTimedTask(self.enemyTask,0.18)


	self.actuatorList.actuatorMap:enter(self.player)


end

function Game:addDoors()
	local i,j
	for i=1,self.map.hcells-1 do
		for j=1,self.map.vcells-1 do
			if self.map[i][j].r == 2 or self.map[i][j].r == 3 then
				self.actuatorList:addDoor({i,j}, 4, 3-self.map[i][j].r)
			end
			if self.map[i][j].d == 2 or self.map[i][j].d == 3 then
				self.actuatorList:addDoor({i,j}, 2, 3-self.map[i][j].l)
			end
		end
	end
end

--~ Player = class(function(p)
--~ 	p.pos=currentpos
--~ end)

function Game:update(dt)
	fps = fps*0.99 + 0.01 * 1.0 / dt


		-- 60 FPS
		self.scheduler:iteration(1.0/40.0)

		self.actuatorList:update(dt)
--~ 		self:movePlayer(dt)
		self.player:appendPath( self.pathcont )
		self.player:move(dt)


		if enemy_timer > 0 then enemy_timer = enemy_timer - dt
		if enemy_timer <=0 and enemy_launcher then self.enemyTask:launchEnemy()
		enemy_timer = enemy_spawndelay end end


end

function Game:movePlayer(dt)
	if table.getn(self.pathcont.path)>0 then
			for i,v in ipairs(self.pathcont.path) do
				table.insert(self.path,v)
			end
			self.pathcont.path = {}
		end

		local do_step = false
		local nsteps = 1
		if step_counter>0 then
			step_counter = step_counter - dt
		end
		if step_counter<=0 then
			do_step = true
			nsteps = math.floor(math.abs(step_counter/step_size))+1
			step_counter = step_size
		end

		if self.path and do_step then
			if table.getn(self.path)>0 then
				if nsteps>table.getn(self.path) then nsteps=table.getn(self.path) end
				currentpos = self.path[nsteps]
				local i
				for i=1,nsteps do
					--self.scentTask:markPlayer(self.path[1])
					self.scentTask:mark(self.path[1],Player_scent)
					table.remove(self.path,1)
				end
			end
		end

		if self.player.pos ~= currentpos then
			self.actuatorList.actmap:leave(self.player)
			self.player.pos = currentpos
			self.actuatorList.actmap:enter(self.player)
		end
end



function Game:draw()
--~ 	Map.draw(self.map)
	if self.cachedmap.cached_map then
		self.cachedmap.cached_map:blit()
	end


		self.scentTask:draw()
		self.enemyTask:drawEnemies()
		self.actuatorList:draw()
		self:drawchar(self.player.pos)



	self:drawtext()
	self:drawscanlines()

--~ 	love.graphics.print(touched,482,40)

	if show_fps then
		love.graphics.print(fps, 482, 20)
	end

end

function Game:drawchar( c )

	if not c then return end
	local dx,dy = self.map.side,self.map.side

	love.graphics.setColor(188,168,0)
	love.graphics.rectangle("fill" , (c[1]-1)*dx+1,(c[2]-1)*dy+1,dx-1,dy-1 )
end

function Game:drawpath( p )
	local i,v
	if not p then return end
--~ 	local self.map=self.map
	local dx,dy = self.map.side,self.map.side
	for i,v in ipairs(p) do
		love.graphics.setColor(188,168,i*255/table.getn(p))
		love.graphics.rectangle( "fill" , (v[1]-1)*dx+1,(v[2]-1)*dy+1,dx-1,dy-1 )
	end
end

function Game:drawscanlines()
	if not cached_scanlines then
		cached_scanlines = ImageCache()
		local i
		local shalf = math.floor( screensize[2]/2 )
		for i=1,shalf do
			cached_scanlines:drawStraightLine(0,i*2-1,screensize[1]-1,i*2-1,{0,0,0,128},1)
		end
	end
	cached_scanlines:blit()
end

function myprint(t)
	mytext=mytext..t.."\n"
end

function Game:drawtext()
	love.graphics.setColor(200,200,200)
	love.graphics.print(mytext, 480, 20)
end


function Game:keypressed(key)
	if key == "escape" then
		quit()
	end

end


function Game:keyreleased(key)
end


function Game:mousepressed(x, y, button)

	local dx,dy = self.map.side,self.map.side
	local cx = math.floor(x/dx)+1
	local cy = math.floor(y/dy)+1
	local lx = x%dx
	local ly = y%dy

	if cx>self.map.hcells or cy>self.map.vcells then
		-- outside of map: ignore
		return
	end


--~ 	if self.map[cx][cy].corridor and button == "l" then
--~ 		if not currentpos then currentpos = {cx,cy} end
--~ 		local dest = currentpos
--~ 		if table.getn(self.path)>0 then dest = self.path[table.getn(self.path)] end
--~ 		self.scheduler:addUntimedTask(RouteFinder(dest, {cx,cy}, self.map, self.pathcont, nil, true))
--~ 	end
	if self.map[cx][cy].corridor and button == "l" then
		self.player:moveTo({cx,cy})
	end
end



function Game:mousereleased(x, y, button)
end

