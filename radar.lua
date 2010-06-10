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

Radar = class( UIElement, function(self, rect, game)
	self._base.init(self, rect)
	self.angle = 0
	self.oldangle = 0
	-- degrees per second
	self.angularSpeed = 90
	self.fade = self.angularSpeed * math.log(1/255)/360
--~ 	self.speedEstimation = 0
	-- degrees
--~ 	self.arc = 40
--~ 	self.radius = math.max(rect[3],rect[4])
--~ 	self.triangleCoords = {0,0,0,0,0,0}
	self.constant = math.log(1/255)/360
--~ 	self.alpha=0
	self.game = game
	self:prepareImage()
	self.list = List()

end)

-- ToDo: the radar should be a task!!!

function Radar:prepareImage()

	-- prepare dimension
	self.side = math.floor( 0.5 + math.sqrt(2) * math.max(self.rect[3],self.rect[4]) )
	local side2 = math.pow(2,(math.floor(math.log(self.side)/math.log(2))+1))
	local imagedata = love.image.newImageData(side2,side2)

	-- render cue
	local y,x
	local c = self.side/2
	local r,g,b = 128,255,128
	local k = math.log(1/255)/360
	for y=0,self.side do
		for x=0,self.side do
			local angle = math.atan((y-c)/(x-c)) * 180 / math.pi
			if x<c then angle = 180+angle end
			if angle<0 then angle = 360+angle end
			if y==c then
				if x<c then angle=180 end
				if x>=c then angle=0 end
			end
			angle = 360-angle
			local a = 255 * math.exp(k*angle)
			if a<15 then a=15 end
			imagedata:setPixel(x,y,r,g,b,a)
		end
	end

	-- store internally
	self.image = love.graphics.newImage(imagedata)

	-- also, compute dimensions for the individual elements
	self.dx = self.rect[3]/self.game.map.hcells
	self.dy = self.rect[4]/self.game.map.vcells
	self.elemradius = math.min(self.dx,self.dy)/2
end

function Radar:update(dt)
	local cx,cy = self.rect[1]+self.rect[3]/2, self.rect[2]+self.rect[4]/2
	self.oldangle = self.angle
	self.angle = self.angle + self.angularSpeed * dt
	if self.angle >= 360 then self.angle = self.angle - 360 end

	local center = {self.rect[1]+self.rect[3]/2,self.rect[2]+self.rect[4]/2}
	local tx,ty = -self.side/2,-self.side/2
	local cosine = math.cos(self.angle*math.pi/180)
	local sine = math.sin(self.angle*math.pi/180)
	local rx,ry = (cosine*tx-sine*ty),(sine*tx+cosine*ty)
	self.corner = {rx+center[1],ry+center[2]}

	local elem = self.list:getFirst()
	while elem do
		self:updateElem(elem, dt)
		elem = self.list:getNext()
	end
end

function Radar:updateElem( elem , dt)
	-- dead? remove
	if not elem.ref.alive then
		list:removeCurrent()
		return
	end

	local x,y = elem.ref.pos[1]-self.game.map.hcells/2, elem.ref.pos[2]-self.game.map.vcells/2

	local angle = math.atan(y/x) * 180 / math.pi
	if x<0 then angle = 180+angle end
	if angle<0 then angle = 360+angle end
	if y==0 then
		if x<0 then angle=180 end
		if x>=0 then angle=0 end
	end
	elem.angle = angle
	local oldangle = self.oldangle
	if self.angle < self.oldangle then oldangle = oldangle - 360 end
	if (self.angle >= elem.angle and oldangle < elem.angle) or
	   (self.angle+360 >= elem.angle and oldangle+360 < elem.angle) then
		elem.alpha = 255
		elem.pos = {elem.ref.pos[1],elem.ref.pos[2]}
	end

	elem.alpha = elem.alpha * math.exp(self.fade * dt)
end

function Radar:addElement( who )
	local elem = {
		ref = who,
		pos = {who.pos[1],who.pos[2]},
		angle = 0,
		alpha = 0,
	}
	self.list:pushBack(elem)
end


--~ end
function Radar:draw()

	love.graphics.setScissor(self.rect[1],self.rect[2],self.rect[3],self.rect[4])

	love.graphics.setColor(0,0,0)
	love.graphics.rectangle("fill",self.rect[1],self.rect[2],self.rect[3],self.rect[4])

	love.graphics.setColorMode("replace")
	love.graphics.draw(self.image,self.corner[1],self.corner[2],self.angle*math.pi/180)
	love.graphics.setColorMode("modulate")

	local elem = self.list:getFirst()
	while elem do
		self:drawElement(elem)
		elem = self.list:getNext()
	end

	love.graphics.setScissor()
end

function Radar:drawElement(elem)
	love.graphics.setColor(200,255,200,elem.alpha)
--~ 	love.graphics.setColor(200,255,200)
	love.graphics.circle("fill",self.rect[1]+(elem.pos[1]-0.5)*self.dx,self.rect[2]+(elem.pos[2]-0.5)*self.dy, self.elemradius)
	love.graphics.circle("fill",self.rect[1]+(elem.pos[1]-0.5)*self.dx,self.rect[2]+(elem.pos[2]-0.5)*self.dy, self.elemradius*0.6)
end

function Radar:mousePressed(rel_x, rel_y, button)
end

function Radar:mouseReleased(rel_x, rel_y, button)
end
