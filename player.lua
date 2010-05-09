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

step_size = 0.08

Orders = {
	moveOrder = 1,
	blockOrder = 2,
	grabOrder = 3,
	setOrder = 4,
	dropOrder = 5
}

-- new todo:  since the doors delay you, take that into accound in the routefinder thread! (adding a cost for crossing them)

Player = class ( function (p, game)
	p.gameref = game
	p.refmap = game.map
	p.act = game.actuatorList
	p.scent = game.scentTask
	p.path = {}
	p.step_counter = 0
	p:setStartPos()
	p.waitingOrders = List()
	p.processingOrders = List()
end)

function Player:setStartPos()
	local i,j
	for j=1,self.refmap.vcells do
		for i=1,self.refmap.hcells do
			if self.refmap[i][self.refmap.vcells-j+1].corridor then
				self.pos = {i,self.refmap.vcells-j+1}
				self.newpos = { self.pos[1], self.pos[2] }
				return
			end
		end
	end
end

function Player:die()
end

function Player:appendPath( pathcont )
--~ 	if not self.pathcont.path then
--~ 		self.pathcont.path = path
--~ 	else
--~ 		table.append(self.pathcont.path,path)
--~ 	end
	if table.getn(pathcont.path)>0 then
		for i,v in ipairs(pathcont.path) do
			table.insert(self.path,v)
		end
		pathcont.path = {}
	end
end

function Player:moveTo( newpos )
	self.gameref.scheduler:addUntimedTask(RouteFinder({self.newpos[1],self.newpos[2]},{newpos[1],newpos[2]},self.gameref.map,self.gameref.pathcont, nil, true))
	self.newpos = {newpos[1],newpos[2]}
end

-- moving:
-- set
-- current position is self.pos
-- expected position is self.expectedpos
-- add untimed task (routefind, from self.expectedpos to dest)
-- set new expected pos the destination

-- when finished:  if the path is null, cancel the rest of the queue because orders cannot be applied from there on
-- if it is not null, append to the movement

-- "in place": when arrived to destination do the thing
-- note: the future pathfinding has to take into account the new status (that is, closed doors)

-- there is a "future" map, and we store "diffs" that we can undo if necessary
-- "move" has to be a untimed task again.. that contains the pathfinding

--------------------------------------------------
-- add order: it's a task!
-- 1) make untimed task: copy map
-- 2) when map is copied: push order to the pile, start task performing order, remember what is the change
-- 3) when order is ready: if it was a cancel, flush pile and forget changes
-- 4) when order is ready: if it was successful, apply change, proceed to the next one

-- -> so, architecture could be: push orders immediately
-- -> in the loop, process orders: spawn tasks...
-- -> in the loop, spawn _all_ tasks in parallel, even though some of them will have to wait for the proper condition
--     -> each order first has to copy map from current
--     -> in the new map, apply all the changes in order
--     -> then apply untimed task
--     -> when untimed task is ready, wait for its turn in the order list
--     -> apply changes in the current map

-- possible changes:
--   1- player position is X,Y
--   2- door X,Y,d is in state C (blocked/open)
--   3- object O in X,Y will not be there (grab)
--   4- object O grabbed will be in X,Y
--   5- activating an object will not change anything in the map

--~ function Player:appendDestination( dest )
--~ 	local order = {Orders.moveOrder,{dest[1],dest[2]},{}}
--~ 	self.orders:pushBack(order)
--~ 	self.gameref.scheduler:addUntimedTask(RouteFinder({dest[1],dest[2]}, {self.pos[1],self.pos[2]}, game.map, order[3], nil, true))
--~ end

--~ function Player:update(dt)
--~ 	self:move(dt)
--~ end

function canpass(from,to,map)
	if to[2]<from[2] then
		if map[from[1]][from[2]].u==3 or map[from[1]][from[2]].u==4 then return false else return true end
	end
	if to[2]>from[2] then
		if map[from[1]][from[2]].d==3 or map[from[1]][from[2]].d==4 then return false else return true end
	end
	if to[1]<from[1] then
		if map[from[1]][from[2]].l==3 or map[from[1]][from[2]].l==4 then return false else return true end
	end
	if to[1]>from[1] then
		if map[from[1]][from[2]].r==3 or map[from[1]][from[2]].r==4 then return false else return true end
	end
	return true
end

function Player:move(dt)
	--if not self.pathcont.path then return end
	-- todo: this assumes that all steps take the same time but... the doors delay you!
		local do_step = false
		local nsteps = 1
		local currentpos = self.pos
		if self.step_counter>0 then
			self.step_counter = self.step_counter - dt
		end
		if self.step_counter<=0 then
			do_step = true
			nsteps = math.floor(math.abs(step_counter/step_size))+1
			self.step_counter = step_size
		end

		if self.path and do_step then
			if table.getn(self.path)>0 then
				if nsteps>table.getn(self.path) then nsteps=table.getn(self.path) end
--~ 				local nextcurrentpos = self.path[nsteps]
--~ 					currentpos = self.pos
				local i
				for i=1,nsteps do
					local nextcurrentpos = {self.path[1][1],self.path[1][2]}
					if not canpass(currentpos,nextcurrentpos,self.gameref.map) then
						break
					else
						currentpos = {nextcurrentpos[1],nextcurrentpos[2]}
					end
					--scentTask:markPlayer(self.path[1])
					self.scent:mark(self.path[1],Player_scent)
					table.remove(self.path,1)
				end
			end
		end

		if self.pos[1] ~= currentpos[1] or self.pos[2]~=currentpos[2] then
--~ 			self.act.actmap:leave(self)
			local oldpos = {self.pos[1],self.pos[2]}
			self.pos = {currentpos[1],currentpos[2]}
			self.act.actmap:move( self, oldpos, currentpos )
--~ 			self.act.actmap:enter(self)
		else
			if not self.scent.playerMarked then
				self.scent:mark(self.pos,Player_scent)
				self.scent.playerMarked = true
			end
		end
end

-------------------------------------------------------------------------

--------------------------------------------------
-- add order: it's a task!
-- 1) make untimed task: copy map
-- 2) when map is copied: push order to the pile, start task performing order, remember what is the change
-- 3) when order is ready: if it was a cancel, flush pile and forget changes
-- 4) when order is ready: if it was successful, apply change, proceed to the next one

-- -> so, architecture could be: push orders immediately
-- -> in the loop, process orders: spawn tasks...
-- -> in the loop, spawn _all_ tasks in parallel, even though some of them will have to wait for the proper condition
--     -> each order first has to copy map from current
--     -> in the new map, apply all the changes in order
--     -> then apply untimed task
--     -> when untimed task is ready, wait for its turn in the order list
--     -> apply changes in the current map

-- possible changes:
--   1- player position is X,Y
--   2- door X,Y,d is in state C (blocked/open)
--   3- object O in X,Y will not be there (grab)
--   4- object O grabbed will be in X,Y
--   5- activating an object will not change anything in the map

function Player:processOrders(dt)
	-- spawn waiting orders
	local neworder = self.waitingOrders:getFirst()
	while neworder do
		self.processingOrders:pushBack(neworder)
		self:spawn(neworder)
		self.waitingOrders:removeCurrent()
		neworder = self.waitingOrders:getNext()
	end

	-- apply finished orders
	neworder = self.processingOrders:getFirst()
	while neworder and neworder:hasFinished() do
		if neworder:successful() then
			neworder:applyOrder()
			self.processingOrders:removeCurrent()
		else
			self.processingOrders:discard()
		end
		neworder = self.processingOrders:getNext()
	end
end

-- todos here:
function Player:spawn( order )
end


Order = class( function(o)
end)

function Order:hasFinished()
	return false
end

function Order:successful()
	return false
end

function Order:applyOrder( order )
end


GameChangesType = {
	playerMove = 1,
	doorChange = 2,
	objectGrab = 3,
	objectLeave = 4,
}

GameChanges = class(function (c)
	c.type = 0
	c.pos = {0,0}
	c.orientation = 0
	c.result = 0 -- new door type
	c.ref = 0 -- reference to object
end)

OrderTask = class(GenericVisitor,function(vis)
end)

function OrderTask:reset_loop()
end

function OrderTask:iteration(dt)
	return true
end

function OrderTask:finish_loop()
end
