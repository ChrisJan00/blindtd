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

-- actuators

ActuatorMap = class( function(acts, refmap)
	acts.refmap = refmap
	acts.map = {}
	acts:init()
end)

function ActuatorMap:init()
	local i,j
	for i=1,self.refmap.hcells do
		self.map[i]={}
		for j=1,self.refmap.vcells do
			self.map[i][j]=List()
		end
	end
end

function ActuatorMap:add(actuator)
	local cell = actuator.cellslist:getFirst()
	while cell do
		self.map[cell[1]][cell[2]]:pushBack(actuator)
		cell = actuator.cellslist:getNext()
	end
end

function ActuatorMap:remove(actuator)
	local cell = actuator.cellslist:getFirst()
	while cell do
		self.map[cell[1]][cell[2]]:remove(actuator)
		cell = actuator.cellslist:getNext()
	end
end

function ActuatorMap:enter( who )
	local ref = self.map[who.pos[1]][who.pos[2]]:getFirst()
	while ref do
		if findRoute( ref.pos, who.pos, self.refmap, ref.radius) then
			ref:activate( who )
		end
		ref = self.map[who.pos[1]][who.pos[2]]:getNext()
	end
end

function ActuatorMap:leave( who )
	local ref = self.map[who.pos[1]][who.pos[2]]:getFirst()
	while ref do
		ref:leave( who )
		ref = self.map[who.pos[1]][who.pos[2]]:getNext()
	end
end

-------------------

-- actuator class
-- add in single position
-- add in radius "absolute" (manhattan distance)
-- add in radius "absolute" (euclidean distance)
-- add in walking distance ( what happens with the doors?
  -- when a door is found, mark the next cells specially (with a reference to the offending door)...
  -- but what if
  --  A
  --  d d
  --  x
  -- "x" will be active if at least one of the doors is open.
-- well, we can add the actuator in these cells no matter what, and then in the activate method check if there is a valid way actually, using A*

Actuator = class(function(act, pos, radius, actuatormap)
	act.actmap = actuatormap
	act.radius = radius
	act.pos = {pos[1],pos[2]}
	act:fill()
end
)

function Actuator:fill()
	self.cellslist = List()
	self.cellslist:pushFront( {self.pos[1],self.pos[2]},0 )
	local elem = self.cellslist:getFirst()
	while elem do
		local newradius = self.cellslist.current.val+1
		if self.actmap.refmap[elem[1]][elem[2]].u>0 and newradius<= self.radius
			and not self.cellslist:containsContents({elem[1],elem[2]-1}) then
			self.cellslist:pushBack({elem[1],elem[2]-1},newradius)
		end
		if self.actmap.refmap[elem[1]][elem[2]].d>0 and newradius<= self.radius
			and not self.cellslist:containsContents({elem[1],elem[2]+1}) then
			self.cellslist:pushBack({elem[1],elem[2]+1},newradius)
		end
		if self.actmap.refmap[elem[1]][elem[2]].l>0 and newradius<= self.radius
			and not self.cellslist:containsContents({elem[1]-1,elem[2]}) then
			self.cellslist:pushBack({elem[1]-1,elem[2]},newradius)
		end
		if self.actmap.refmap[elem[1]][elem[2]].r>0 and newradius<= self.radius
			and not self.cellslist:containsContents({elem[1]+1,elem[2]}) then
			self.cellslist:pushBack({elem[1]+1,elem[2]},newradius)
		end
		elem = self.cellslist:getNext()
	end
	self.actmap:add(self)
end

function Actuator:activate( who )
end

function Actuator:leave( who )
end

function Actuator:update( dt )
end

--------------------------
ActuatorList = class( function (self, refmap)
	self.list = List()
	self.actmap = ActuatorMap(refmap)
	self.refmap = refmap
end)

function ActuatorList:draw()
	local elem = self.list:getFirst()
	while elem do
		elem:draw()
		elem = self.list:getNext()
	end
end

function ActuatorList:update(dt)
	local elem = self.list:getFirst()
	while elem do
		elem:update(dt)
		elem = self.list:getNext()
	end
end

function ActuatorList:addBomb(pos)
	self.list:pushBack( DeathPoint( pos, self.actmap ) )
end

function ActuatorList:addDoor(pos, orientation, open_percent)
	self.list:pushBack( Door( pos, orientation, open_percent, self.actmap) )
end

--------------------------
MachineGun = class(Actuator,function(act, pos, radius, actuatormap)
end)

--------------------------
-- orientation:
-- 1-up
-- 2-down
-- 3-left
-- 4-right
Door = class(Actuator,function(door, pos, orientation, open_percent, actuatormap)
	--act._base.init(act, pos, 3, actuatormap)
	door.actmap = actuatormap
	door.orientation = orientation
	door.radius = 2
	door.pos = {pos[1],pos[2]}
	door.detected = 0
	-- it takes 0.5 seconds to open
	door.open_velocity = 1/0.5
	door.open_percent = open_percent
	door:fill()
end)

-- the door needs a special fill method because it lies between two cells
function Door:fill()
	self.cellslist = List()
	self.cellslist:pushFront( {self.pos[1],self.pos[2]},0 )

	-- add the other side
	if self.orientation == 1 and self.actmap.refmap[self.pos[1]][self.pos[2]].u>0 then
		self.cellslist:pushBack( {self.pos[1], self.pos[2]-1}, 0)
	end
	if self.orientation == 2 and self.actmap.refmap[self.pos[1]][self.pos[2]].d>0 then
		self.cellslist:pushBack( {self.pos[1], self.pos[2]+1}, 0)
	end
	if self.orientation == 3 and self.actmap.refmap[self.pos[1]][self.pos[2]].l>0 then
		self.cellslist:pushBack( {self.pos[1]-1, self.pos[2]}, 0)
	end
	if self.orientation == 4 and self.actmap.refmap[self.pos[1]][self.pos[2]].r>0 then
		self.cellslist:pushBack( {self.pos[1]+1, self.pos[2]}, 0)
	end

	local elem = self.cellslist:getFirst()
	while elem do
		local newradius = self.cellslist.current.val+1
		if self.actmap.refmap[elem[1]][elem[2]].u>0 and newradius< self.radius
			and not self.cellslist:containsContents({elem[1],elem[2]-1}) then
			self.cellslist:pushBack({elem[1],elem[2]-1},newradius)
		end
		if self.actmap.refmap[elem[1]][elem[2]].d>0 and newradius< self.radius
			and not self.cellslist:containsContents({elem[1],elem[2]+1}) then
			self.cellslist:pushBack({elem[1],elem[2]+1},newradius)
		end
		if self.actmap.refmap[elem[1]][elem[2]].l>0 and newradius< self.radius
			and not self.cellslist:containsContents({elem[1]-1,elem[2]}) then
			self.cellslist:pushBack({elem[1]-1,elem[2]},newradius)
		end
		if self.actmap.refmap[elem[1]][elem[2]].r>0 and newradius< self.radius
			and not self.cellslist:containsContents({elem[1]+1,elem[2]}) then
			self.cellslist:pushBack({elem[1]+1,elem[2]},newradius)
		end
		elem = self.cellslist:getNext()
	end
	self.actmap:add(self)
end

function Door:activate( who )
	self.detected = self.detected + 1
end

function Door:leave(who)
	self.detected = self.detected - 1
end

function Door:draw()
	local dx,dy = self.actmap.refmap.side,self.actmap.refmap.side
	local i,j = self.pos[1],self.pos[2]
	local sp = 0.5 - self.open_percent*0.5
	if self.orientation == 1 then
		love.graphics.setColor(160,0,160)
		love.graphics.line((i-1)*dx,(j-1)*dy,(i-1+sp)*dx,(j-1)*dy)
		love.graphics.line((i-sp)*dx,(j-1)*dy,i*dx,(j-1)*dy)
	end
		if self.orientation == 2 then
		love.graphics.setColor(160,0,160)
		love.graphics.line((i-1)*dx,j*dy,(i-1+sp)*dx,j*dy)
		love.graphics.line((i-sp)*dx,j*dy,i*dx,j*dy)
	end
		if self.orientation == 3 then
		love.graphics.setColor(160,0,160)
		love.graphics.line((i-1)*dx,(j-1)*dy,(i-1)*dx,(j-1+sp)*dy)
		love.graphics.line((i-1)*dx,(j-sp)*dy,(i-1)*dx,j*dy)
	end
		if self.orientation == 4 then
		love.graphics.setColor(160,0,160)
		love.graphics.line(i*dx,(j-1)*dy,i*dx,(j-1+sp)*dy)
		love.graphics.line(i*dx,(j-sp)*dy,i*dx,j*dy)
	end
end

function Door:update(dt)
	if self.detected > 0 and self.open_percent < 1 then
		self.open_percent = self.open_percent + dt * self.open_velocity
		if self.open_percent >=1 then
		self:setInMap( 2 )
		self.open_percent = 1
		end
	elseif self.detected == 0 and self.open_percent > 0 then
		self.open_percent = self.open_percent - dt * self.open_velocity
		if self.open_percent <=0 then
		self:setInMap( 3 )
		self.open_percent = 0
		end
	end
end

function Door:block()
	-- todo
end

function Door:setInMap( newcode )
	if self.orientation == 1 then
		self.actmap.refmap[self.pos[1]][self.pos[2]].u = newcode
		self.actmap.refmap[self.pos[1]][self.pos[2]-1].d = newcode
	end
	if self.orientation == 2 then
		self.actmap.refmap[self.pos[1]][self.pos[2]].d = newcode
		self.actmap.refmap[self.pos[1]][self.pos[2]+1].u = newcode
	end
	if self.orientation == 3 then
		self.actmap.refmap[self.pos[1]][self.pos[2]].l = newcode
		self.actmap.refmap[self.pos[1]-1][self.pos[2]].r = newcode
	end
	if self.orientation == 4 then
		self.actmap.refmap[self.pos[1]][self.pos[2]].r = newcode
		self.actmap.refmap[self.pos[1]+1][self.pos[2]].l = newcode
	end
end

--------------------------
DeathPoint = class(Actuator, function(act, pos, actuatormap)
	-- todo: there is some bug at the filling algorithm that makes the thing hang
	act._base.init(act, pos, 3, actuatormap)
	end)

function DeathPoint:activate( who )
	who:die()
end

function DeathPoint:draw()
	local dx,dy =  self.actmap.refmap.side, self.actmap.refmap.side
	local i,j = self.pos[1],self.pos[2]

	love.graphics.setColor(0,255,255)
	love.graphics.rectangle("fill" , (i-1)*dx+1,(j-1)*dy+1,dx-1,dy-1 )
end


--------------------------
-- there is a map where each cell is a list of references to an actuator instance
-- when an entity steps in the cell, all referenced actuators are called

-- the actuator has a list of cells in which it is present, so when it has to be erased it nows who to call
-- it has a callback method that applies the effect of the actuator when it is called
-- examples:  door -> open
-- gun -> fire bullet
-- mine -> explode
-- bomb -> this has a timer, does not react to presence of the entity but explodes after certain time
-- electronic blast -> stuns the enemies, disables doors nearby
-- laser blast -> kills one enemy, but then it has to be activated again
