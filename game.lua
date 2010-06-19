

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
smooth_fps = true
enemy_timer = 3
enemy_spawndelay = 3
enemy_launcher = true
touched = 0

--~ self = {}

-- todo:  since the order in which parts of the game are instantiated is a bit random, avoid references in sub-items until necessary
-- (that is, if a class has self.sthref = game.sthref, avoid doing that in the constructor and retrieve the reference in the method that needs it)
-- also:  avoid underscores in method names

function Game:load()
	self.map = generateMapWRooms()
	self.cachedmap = {}

	self.scheduler = Scheduler()

--~ 	self.scheduler:addUntimedTask(MapCacher(self.map,self.cachedmap))

	----------- actuators
	self.actuatorList = ActuatorList(self)
	while self.actuatorList.list.n < 0 do
		local pos = {math.random(20),math.random(20)}
		if self.map[pos[1]][pos[2]].corridor then self.actuatorList:addBomb(pos) end
	end

	-- doors
	self:addDoors()

	self.scentTask = ScentTask(self)
	self.scheduler:addTimedTask(self.scentTask,0.08)

	self.player = Player(self)
	currentpos = {self.player.pos[1],self.player.pos[2]}

	self.enemyTask = EnemyTask(self)
	self.scheduler:addTimedTask(self.enemyTask,0.18)

	self.actuatorList.actuatorMap:enter(self.player)

	self.UI = UIList()
	self.messagebox = MessageBox({ 10,410,380,100 })
	self.UI:addElement(self.messagebox)

	self.actionScreen = ActionScreen( {2,2,300,300}, self )
	self.UI:addElement(self.actionScreen)

--~ 	self.radar = Radar({20,20,200,200}, self)
--~ 	self.radar:addElement( self.player )
--~ 	self.UI:addElement(self.radar)

--~ 	self.button = UIButton( { 100,100,100,33 } )
--~ 	self.button:setRadius(6)
--~ 	self.button.text = "Accept"
--~ 	self.UI:addElement(self.button)

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


function Game:update(dt)
	if smooth_fps then
		fps = fps*0.99 + 0.01 * 1.0 / dt
	else
		fps = 1/dt
	end


		-- 60 FPS
		self.scheduler:iteration(1.0/60.0)

		self.actuatorList:update(dt)
		self.player:update(dt)


		if enemy_timer > 0 then enemy_timer = enemy_timer - dt
			if enemy_timer <=0 and enemy_launcher then
				self.enemyTask:launchEnemy()
				if self.radar then
					self.radar:addElement(self.enemyTask.enemies:getLast())
				end
				enemy_timer = enemy_spawndelay
				myprint("New enemy launched")
			end
		end

		self.UI:update(dt)

end

function Game:draw()

	self.UI:draw()

	self:drawtext()
	self:drawscanlines()

	if show_fps then
		love.graphics.setColor(255,255,255)
		love.graphics.print(fps, 2, 20)
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
--~ 	self.messagebox:addText(t)
end

function Game:drawtext()
	if string.len(mytext)>0 then
		self.messagebox:addText(mytext)
		mytext=""
	end
--~ 	love.graphics.setColor(200,200,200)
--~ 	love.graphics.print(mytext, 480, 20)
end


function Game:keypressed(key)
	if key == "escape" then
		quit()
	end

end


function Game:keyreleased(key)
end


function Game:mousepressed(x, y, button)

	self.UI:mousePressed(x,y,button)


end



function Game:mousereleased(x, y, button)
	self.UI:mouseReleased(x,y,button)
end

