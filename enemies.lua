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

-- enemy list
Scent = {}

Player_scent = 10
Enemy_scent = -1
Blow_scent = -100
Scent_diffusion = 0.95
Center_weight = 1
Prob_move = 0.98

-- todo: each enemy can have its own speed, that can change dynamically depending on status
-- (for example, how strong is the scent)
-- that is done with an internal timer

-- also todo: enemies are stopped in front of closed doors.. if the door is blocked, they "hit" it
-- to check: if they bounce or not... they should bounce after a while, not stay there eternally, but also
-- not bounce automatically... maybe the scent can do that


--------------------------------------------------
ScentTask=class(GenericVisitor,function(scent, game)
	scent.hcells = game.map.hcells
	scent.vcells = game.map.vcells
	scent.current_map = {}
	scent.next_map = {}
	scent.ref_map = game.map
	local i,j
	for j=1,scent.hcells do
		scent.current_map[j]={}
		scent.next_map[j]={}
		for i=1,scent.vcells do
			scent.current_map[j][i]=0
			scent.next_map[j][i]=0
		end
	end

	scent.player = game.player
	scent.playerMarked = false
end)

function ScentTask:reset_loop()
	self.i = 1
	self.j = 1
	self.player_marked = false
	if self.enemies then self.enemy = self.enemies:getFirst() end
end


function ScentTask:mark(pos, scent)
	self.next_map[pos[1]][pos[2]] = self.next_map[pos[1]][pos[2]]+scent
end

function ScentTask:iteration(dt)
		if self.ref_map[self.i][self.j].corridor then
			local sum = self.current_map[self.i][self.j] * Center_weight
			local count = Center_weight
			if self.i>1 and self.ref_map[self.i-1][self.j].corridor then
				sum = sum + self.current_map[self.i-1][self.j]
				count = count + 1
			end
			if self.j>1 and self.ref_map[self.i][self.j-1].corridor then
				sum = sum + self.current_map[self.i][self.j-1]
				count = count + 1
			end
			if self.i<self.hcells and self.ref_map[self.i+1][self.j].corridor then
				sum = sum + self.current_map[self.i+1][self.j]
				count = count + 1
			end
			if self.j<self.vcells and self.ref_map[self.i][self.j+1].corridor then
				sum = sum + self.current_map[self.i][self.j+1]
				count = count + 1
			end
			self.next_map[self.i][self.j] = self.next_map[self.i][self.j] + sum/count
			self.next_map[self.i][self.j] = self.next_map[self.i][self.j] * Scent_diffusion
		end
		self.i = self.i+1
		if self.i>self.hcells then
			self.i = 1
			self.j = self.j+1
			if self.j>self.vcells then return true end
		end

	return false
end

function ScentTask:finish_loop()
	local i,j
	local tmp = self.current_map
	self.current_map = self.next_map
	self.next_map = tmp
	self.playerMarked = false
	for j=1,self.hcells do
		for i=1,self.vcells do
			self.next_map[j][i]=0
		end
	end
end


function ScentTask:draw()
	local i,j
	for i=1,self.ref_map.hcells do
		for j=1,self.ref_map.vcells do
			if self.ref_map[i][j].corridor then

				local dx,dy =  self.ref_map.side, self.ref_map.side

				local fraction = self.current_map[i][j]*5
				if fraction < 0 then
					love.graphics.setColor(0,0,math.abs(fraction))
				else
					love.graphics.setColor(fraction,0,0)
				end
				love.graphics.rectangle("fill" , (i-1)*dx+1,(j-1)*dy+1,dx-1,dy-1 )

			end
		end
	end
end

--------------------------------------------------

Enemies = List()
EnemyTask=class(GenericVisitor,function(self, game)
	self.enemies = List()
	self.scents = game.scentTask
--~ 	self.actuatorsmap = game.actuatorList.actmap
--~ 	self.actuatorList = game.actuatorList
	self.game = game
end)

function EnemyTask:reset_loop()
	self.enemy = self.enemies:getFirst()
end

function EnemyTask:iteration(dt)
	if self.enemy then
		self:updateEnemy()
		self.enemy = self.enemies:getNext()
	end
	if self.enemy then
		return false
	else
		return true
	end
end

function EnemyTask:updateEnemy()
	local map = self.scents.ref_map
	local scentmap = self.scents.current_map
	local enemy = self.enemy
	local newdir = List()

	self.scents:mark(enemy.pos, Enemy_scent)

	if map[enemy.pos[1]][enemy.pos[2]].u>0 then
		newdir:pushFrontSorted(1,scentmap[enemy.pos[1]][enemy.pos[2]-1])
	end
	if map[enemy.pos[1]][enemy.pos[2]].d>0 then
		newdir:pushFrontSorted(2,scentmap[enemy.pos[1]][enemy.pos[2]+1])
	end
	if map[enemy.pos[1]][enemy.pos[2]].l>0 then
		newdir:pushFrontSorted(3,scentmap[enemy.pos[1]-1][enemy.pos[2]])
	end
	if map[enemy.pos[1]][enemy.pos[2]].r>0 then
		newdir:pushFrontSorted(4,scentmap[enemy.pos[1]+1][enemy.pos[2]])
	end

	elem = newdir:getLast()
	while elem and math.random()>Prob_move do
		elem = newdir:getPrev()
	end

	if not elem then elem=newdir:getFirst() end

	local randchoice = elem

	local lastscent = scentmap[enemy.pos[1]][enemy.pos[2]]
	local lastpos = { enemy.pos[1], enemy.pos[2] }
	local celldata = self.game.map[enemy.pos[1]][enemy.pos[2]]

	if randchoice == 1 and (celldata.u == 1 or celldata.u==2) then
		enemy.pos = { enemy.pos[1], enemy.pos[2]-1 }
	end

	if randchoice == 2 and (celldata.d == 1 or celldata.d==2) then
		enemy.pos = { enemy.pos[1], enemy.pos[2]+1 }
	end

	if randchoice == 3 and (celldata.l == 1 or celldata.l==2) then
		enemy.pos = { enemy.pos[1]-1, enemy.pos[2] }
	end

	if randchoice == 4 and (celldata.r == 1 or celldata.r==2) then
		enemy.pos = { enemy.pos[1]+1, enemy.pos[2] }
	end
	self.game.actuatorList.actuatorMap:move( enemy, lastpos, enemy.pos )
	-- todo: the player pos has to be retrieved from somewhere else
	if enemy.pos[1]==self.scents.player.pos[1] and enemy.pos[2]==self.scents.player.pos[2] then
		touched = touched + 1
		self.game.actuatorList.actuatorMap:leave( enemy )
		self.enemies:remove(enemy)

	end

end

function EnemyTask:launchEnemy()
	-- create a new enemy at the start position
	local epos, i
	for i=1,self.scents.ref_map.hcells do
		if self.scents.ref_map[i][1].corridor then
			epos = {i,1}
			break
		end
	end

	local enemy = Enemy(epos, self)

	self.enemies:pushBack(enemy)

	self.game.actuatorList.actuatorMap:enter(enemy)
end

Enemy = class( function( e, pos, task )
		e.pos = pos
		e.lastdir = 1
		e.task = task
end)

function Enemy:die()
	self.task.scents:mark(self.pos,Blow_scent)
	self.actuatorList.actmap:leave(self)
	self.task.enemies:remove(self)
end


--~ function EnemyTask:die()
--~ 	-- newscent(currentpos) - K2 (K2=1?)
--~ 	--enemy.Scents.next_map[pos[1]][pos[2]] = enemy.Scents.next_map[pos[1]][pos[2]]+Blow_scent
--~ 	self.scents:mark(enemy.pos, Blow_scent)
--~ 	self.enemies:remove(enemy)
--~ end


function EnemyTask:drawEnemies()
	local elem = self.enemies:getFirst()
	while elem do

		local dx,dy = self.scents.ref_map.side,self.scents.ref_map.side
		local i,j = elem.pos[1],elem.pos[2]

		love.graphics.setColor(0,200,0)
		love.graphics.rectangle("fill" , (i-1)*dx+1,(j-1)*dy+1,dx-1,dy-1 )

		elem = self.enemies:getNext()
	end
end

