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

ActuatorMap = class( function(self, game)
	self.game = game
	self.map = {}
	self:init()
end)

function ActuatorMap:init()
	local i,j
	for i=1,self.game.map.hcells do
		self.map[i]={}
		for j=1,self.game.map.vcells do
			self.map[i][j]=List()
		end
	end
end

function ActuatorMap:add(actuator)
	local cell = actuator.cellslist:getFirst()
	while cell do
		if not self.map[cell[1]][cell[2]]:contains(actuator) then
			self.map[cell[1]][cell[2]]:pushBack(actuator)
		end
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

function ActuatorMap:move(who, from, to)
	local cellfrom = self.map[from[1]][from[2]]
	local cellto = self.map[to[1]][to[2]]
	-- check leaves
	local ref = cellfrom:getFirst()
	while ref do
		if not cellto:contains( ref ) then
			ref:deactivate( who )
		end
		ref = cellfrom:getNext()
	end

	-- check enters
	ref = cellto:getFirst()
	while ref do
		if not cellfrom:contains( ref ) then
			ref:activate( who )
		end
		ref = cellto:getNext()
	end
end

function ActuatorMap:enter( who )
	local ref = self.map[who.pos[1]][who.pos[2]]:getFirst()
	while ref do
		ref:activate( who )
		ref = self.map[who.pos[1]][who.pos[2]]:getNext()
	end
end

function ActuatorMap:leave( who )
	local ref = self.map[who.pos[1]][who.pos[2]]:getFirst()
	while ref do
		ref:deactivate( who )
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

Actuator = class(function(self, game, pos, radius)
	self.game = game
	self.radius = radius
	self.pos = {pos[1],pos[2]}
	self:fill()
	self.seen = List()
	self.sensed = List()
end
)

function Actuator:fill()
	self.cellslist = List()
	self.cellslist:pushFront( {self.pos[1],self.pos[2]},0 )
	local elem = self.cellslist:getFirst()
	while elem do
		local newradius = self.cellslist.current.val+1
		if self.game.map[elem[1]][elem[2]].u>0 and newradius<= self.radius
			and not self.cellslist:containsContents({elem[1],elem[2]-1}) then
			self.cellslist:pushBack({elem[1],elem[2]-1},newradius)
		end
		if self.game.map[elem[1]][elem[2]].d>0 and newradius<= self.radius
			and not self.cellslist:containsContents({elem[1],elem[2]+1}) then
			self.cellslist:pushBack({elem[1],elem[2]+1},newradius)
		end
		if self.game.map[elem[1]][elem[2]].l>0 and newradius<= self.radius
			and not self.cellslist:containsContents({elem[1]-1,elem[2]}) then
			self.cellslist:pushBack({elem[1]-1,elem[2]},newradius)
		end
		if self.game.map[elem[1]][elem[2]].r>0 and newradius<= self.radius
			and not self.cellslist:containsContents({elem[1]+1,elem[2]}) then
			self.cellslist:pushBack({elem[1]+1,elem[2]},newradius)
		end
		elem = self.cellslist:getNext()
	end
	self.game.actuatorList.actuatorMap:add(self)
end

function Actuator:activate( who )
	if not self.sensed:contains( who )	then
		self.sensed:pushBack( who )
		if self:canSee( who ) then
			self.seen:pushBack( who )
			self:enter( who )
		end
	end
end

function Actuator:canSee( who )
	if findRoute( self.pos, who.pos, self.game.map, self.radius) then
		return true
	else
		return false
	end
end

function Actuator:deactivate( who )
	if self.sensed:contains( who ) then
		self.sensed:remove( who )
		if self.seen:contains( who ) then
			self.seen:remove( who )
			self:leave( who )
		end
	end
end

function Actuator:updateSeen()
	local who = self.sensed:getFirst()
	while who do
		local wasSeen = self.seen:contains(who)
		local isSeen = self:canSee(who)
		if wasSeen and not isSeen then
			self.seen:remove(who)
			self:leave(who)
		end
		if isSeen and not wasSeen then
			self.seen:pushBack(who)
			self:enter(who)
		end
		who = self.sensed:getNext()
	end
end

function Actuator:update( dt )
end

function Actuator:enter( who )
end

function Actuator:leave( who )
end
--------------------------
ActuatorList = class( function (self, game)
	self.list = List()
	self.game = game
	self.actuatorMap = ActuatorMap(game)
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
	self.list:pushBack( DeathPoint( self.game, pos ) )
end

function ActuatorList:addDoor(pos, orientation, open_percent)
	self.list:pushBack( Door( self.game, pos, orientation, open_percent) )
end


--------------------------
MachineGun = class(Actuator,function(act, game, pos, radius)
end)

--------------------------
-- orientation:
-- 1-up
-- 2-down
-- 3-left
-- 4-right
Door = class(Actuator,function(self, game, pos, orientation, open_percent)
--~ 	self.game = game
	self.radius = 2
	self._base.init(self, game, pos, self.radius)
	--act._base.init(act, pos, 3, actuatormap)
	self.orientation = orientation

	self.pos = {pos[1],pos[2]}
	-- it takes 0.5 seconds to open
	self.open_velocity = 1/0.8
	self.open_percent = open_percent
	self.status = 0
	self:fill()
end)

-- the door needs a special fill method because it lies between two cells
function Door:fill()
	self.cellslist = List()
	self.cellslist:pushFront( {self.pos[1],self.pos[2]},0 )

	-- add the other side
	if self.orientation == 1 and self.game.map[self.pos[1]][self.pos[2]].u>0 then
		self.backpos = {self.pos[1], self.pos[2]-1}
		self.cellslist:pushBack( {self.pos[1], self.pos[2]-1}, 0)
	end
	if self.orientation == 2 and self.game.map[self.pos[1]][self.pos[2]].d>0 then
		self.backpos = {self.pos[1], self.pos[2]+1}
		self.cellslist:pushBack( {self.pos[1], self.pos[2]+1}, 0)
	end
	if self.orientation == 3 and self.game.map[self.pos[1]][self.pos[2]].l>0 then
		self.backpos = {self.pos[1]-1, self.pos[2]}
		self.cellslist:pushBack( {self.pos[1]-1, self.pos[2]}, 0)
	end
	if self.orientation == 4 and self.game.map[self.pos[1]][self.pos[2]].r>0 then
		self.backpos = {self.pos[1]+1, self.pos[2]}
		self.cellslist:pushBack( {self.pos[1]+1, self.pos[2]}, 0)
	end

	local elem = self.cellslist:getFirst()
	while elem do
		local newradius = self.cellslist.current.val+1
		if self.game.map[elem[1]][elem[2]].u>0 and newradius<= self.radius
			and not self.cellslist:containsContents({elem[1],elem[2]-1}) then
			self.cellslist:pushBack({elem[1],elem[2]-1},newradius)
		end
		if self.game.map[elem[1]][elem[2]].d>0 and newradius<= self.radius
			and not self.cellslist:containsContents({elem[1],elem[2]+1}) then
			self.cellslist:pushBack({elem[1],elem[2]+1},newradius)
		end
		if self.game.map[elem[1]][elem[2]].l>0 and newradius<= self.radius
			and not self.cellslist:containsContents({elem[1]-1,elem[2]}) then
			self.cellslist:pushBack({elem[1]-1,elem[2]},newradius)
		end
		if self.game.map[elem[1]][elem[2]].r>0 and newradius<= self.radius
			and not self.cellslist:containsContents({elem[1]+1,elem[2]}) then
			self.cellslist:pushBack({elem[1]+1,elem[2]},newradius)
		end
		elem = self.cellslist:getNext()
	end
	self.game.actuatorList.actuatorMap:add(self)
end

function Door:canSee( who )
	if findRoute( self.pos, who.pos, self.game.map, self.radius) or findRoute(self.backpos, who.pos, self.game.map, self.radius) then
		return true
	else
		return false
	end
end

function Door:draw()
	local dx,dy = self.game.map.side,self.game.map.side
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
	if self.seen.n > 0 and self.open_percent < 1 then
		self.open_percent = self.open_percent + dt * self.open_velocity
	elseif self.seen.n == 0 and self.open_percent > 0 then
		self.open_percent = self.open_percent - dt * self.open_velocity
		self:setInMap( 3 )
	end

	if self.open_percent > 1 then
		self:setInMap( 2 )
		self.open_percent = 1
	end

	if self.open_percent <0 then
		self.open_percent = 0
	end
end

function Door:block()
	-- todo
end

function Door:setInMap( newcode )
	if self.status == newCode then return end

	if self.orientation == 1 then
		self.game.map[self.pos[1]][self.pos[2]].u = newcode
		self.game.map[self.pos[1]][self.pos[2]-1].d = newcode
	end
	if self.orientation == 2 then
		self.game.map[self.pos[1]][self.pos[2]].d = newcode
		self.game.map[self.pos[1]][self.pos[2]+1].u = newcode
	end
	if self.orientation == 3 then
		self.game.map[self.pos[1]][self.pos[2]].l = newcode
		self.game.map[self.pos[1]-1][self.pos[2]].r = newcode
	end
	if self.orientation == 4 then
		self.game.map[self.pos[1]][self.pos[2]].r = newcode
		self.game.map[self.pos[1]+1][self.pos[2]].l = newcode
	end

	self.status = newcode
	-- notify all the actuators
	self:notifySeenChanged()
end

function Door:notifySeenChanged()

	local mappos = self.game.actuatorList.actuatorMap.map[self.pos[1]][self.pos[2]]
	local current = mappos.current
	local affected = mappos:getFirst()
	while affected do
		affected:updateSeen()
		affected = mappos:getNext()
	end
	mappos.current = current
	mappos = self.game.actuatorList.actuatorMap.map[self.backpos[1]][self.backpos[2]]
	current = mappos.current
	affected = mappos:getFirst()
	while affected do
		affected:updateSeen()
		affected = mappos:getNext()
	end
	mappos.current = current
end


--------------------------
DeathPoint = class(Actuator, function(act, game, pos)
	-- todo: there is some bug at the filling algorithm that makes the thing hang
	act._base.init(act, game, pos, 3)
	end)

function DeathPoint:enter( who )
	if findRoute( self.pos, who.pos, self.game.map, self.radius) then
		who:die()
	end
end

function DeathPoint:draw()
	local dx,dy =  self.game.map.side, self.game.map.side
	local i,j = self.pos[1],self.pos[2]

	love.graphics.setColor(0,255,255)
	love.graphics.rectangle("fill" , (i-1)*dx+1,(j-1)*dy+1,dx-1,dy-1 )
end


--------------------------
-- examples:  door -> open
-- gun -> fire bullet
-- mine -> explode
-- bomb -> this has a timer, does not react to presence of the entity but explodes after certain time
-- electronic blast -> stuns the enemies, disables doors nearby
-- laser blast -> kills one enemy, but then it has to be activated again
