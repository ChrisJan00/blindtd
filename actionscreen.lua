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

ActionScreenMapCacher = class(GenericVisitor,function(self, map, rect, container)
		self.image = ImageCache()
		self.map = map
		self.ready = false
		self.container = container
		self.rect = rect
	end)

function ActionScreenMapCacher:reset_loop()
	self.i = 0
	self.j = 1
end

function ActionScreenMapCacher:iteration(dt)
	if self.i == 0 then
		self.image:drawRectangle(0,0,self.rect[3],self.rect[4],{0,0,48,255})
		self.i = 1
		return false
	end

	if self.ready then return true end

	love.graphics.setLineWidth(2)
	local dx,dy = self.rect[3]/self.map.hcells, self.rect[4]/self.map.vcells


	if self.map[self.i][self.j].corridor then
		self.image:drawRectangle((self.i-1)*dx+1,(self.j-1)*dy+1,self.i*dx-2,self.j*dy-2,{0,0,0,255} )
	else
		self.image:drawRectangle((self.i-1)*dx+1,(self.j-1)*dy+1,self.i*dx-2,self.j*dy-2,{0,48,48,255} )
	end
	if self.map[self.i][self.j].corridor then
		-- walls
		if self.map[self.i][self.j].u==0 then
			self.image:drawStraightLine((self.i-1)*dx-1,(self.j-1)*dy-1,self.i*dx,(self.j-1)*dy-1,{0,160,160,255})
		end
		if self.map[self.i][self.j].l==0 then
			self.image:drawStraightLine((self.i-1)*dx-1,(self.j-1)*dy-1,(self.i-1)*dx-1,self.j*dy,{0,160,160,255})
		end
		if self.map[self.i][self.j].d==0 then
			self.image:drawStraightLine((self.i-1)*dx-1,self.j*dy-1,self.i*dx,self.j*dy-1,{0,160,160,255})
		end
		if self.map[self.i][self.j].r==0 then
			self.image:drawStraightLine(self.i*dx-1,(self.j-1)*dy-1,self.i*dx-1,self.j*dy,{0,160,160,255})
		end
	end

	self.i = self.i + 1
	if self.i>self.map.hcells then
		self.i = 1
		self.j = self.j + 1
		if self.j>self.map.vcells then
			self.ready = true
		end
	end

	return self.ready
end

function ActionScreenMapCacher:finish_loop()
	self.container.imageMap = self.image
	self.image = nil
end

-----------------------------------------------------------------

ActionScreen = class(UIElement, function(self, rect, game)
	self._base.init(self, rect)
	self.game = game
	self.game.scheduler:addUntimedTask(ActionScreenMapCacher(self.game.map,self.rect,self))
	self.dx = self.rect[3]/self.game.map.hcells
	self.dy = self.rect[4]/self.game.map.vcells

	self.scentVisible = true
	self.enemiesVisible = true
	self.actuatorsVisible = true
	self.playerVisible = true
end)

function ActionScreen:update(dt)
end



function ActionScreen:draw()
	if self.imageMap then
		self.imageMap:blit(self.rect[1],self.rect[2])
	end

	if self.scentVisible then
		self.game.scentTask:draw()
	end

	if self.enemiesVisible then
		self.game.enemyTask:drawEnemies()
	end

	if self.actuatorsVisible then
		self.game.actuatorList:draw()
	end

	if self.playerVisible then
		love.graphics.setColor(188,168,0)
		love.graphics.rectangle("fill" , (self.game.player.pos[1]-1)*self.dx+1+self.rect[1],(self.game.player.pos[2]-1)*self.dy+1+self.rect[2],self.dx-1,self.dy-1 )
	end
end


function ActionScreen:mousePressed(rel_x, rel_y, button)

	local cx = math.floor(rel_x/self.dx)+1
	local cy = math.floor(rel_y/self.dy)+1
	local lx = rel_x % self.dx
	local ly = rel_y % self.dy


	if self.game.map[cx][cy].corridor and button == "l" then
		self.game.player:moveTo({cx,cy})
	end

end

function ActionScreen:mouseReleased(rel_x, rel_y, button)
end

function ActionScreen:mouseEntered(rel_x, rel_y)
end

function ActionScreen:mouseExited(rel_x, rel_y)
end

function ActionScreen:mouseOver(rel_x, rel_y)
end
