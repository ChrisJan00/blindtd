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

Radar = class( UIElement, function(self, rect)
	self._base.init(self, rect)
	self.angle = 0
	-- degrees per second
	self.angularSpeed = 90
	self.speedEstimation = 0
	-- degrees
	self.arc = 40
	self.radius = math.max(rect[3],rect[4])
	self.triangleCoords = {0,0,0,0,0,0}
	self.constant = math.log(1/255)/360
	self.alpha=0
	self.image = ImageCache(self.rect[3],self.rect[4])
end)

function Radar:update(dt)
	local cx,cy = self.rect[1]+self.rect[3]/2, self.rect[2]+self.rect[4]/2
	local oldangle = self.angle
	self.angle = self.angle + self.angularSpeed * dt
	self.speedEstimation = 0.95 * self.speedEstimation + 0.05*self.angularSpeed*dt
	self.alpha = math.exp(self.speedEstimation * self.constant)
	self.triangleCoords = {
		cx,cy,
		cx + math.cos(self.angle*math.pi/180)*self.radius, cy-math.sin(self.angle*math.pi/180)*self.radius,
		cx + math.cos(oldangle*math.pi/180)*self.radius, cy-math.sin(oldangle*math.pi/180)*self.radius
	}

end

-- todo:  the setAlpha method is very slow (because it evaluates a function for every pixel), dropping the framerate by 2.
-- since what we have at the end of the day is just a radial gradient that rotates around itself, we could actually pregenerate
-- the image using the proper formula and just blit it rotated each time.  ( I guess, subclassing ImageCache for that purpose)

-- still missing the actual enemies
-- the enemies would have an internal timer for the alpha value, instead of relying in this effect (because of the speed)

function Radar:draw()

	love.graphics.setScissor(self.rect[1],self.rect[2],self.rect[3],self.rect[4])

	love.graphics.setColor(0,0,0)
	love.graphics.rectangle("fill",self.rect[1],self.rect[2],self.rect[3],self.rect[4])

	love.graphics.setColorMode("replace")
	self.image:blit(self.rect[1],self.rect[2])
	love.graphics.setColorMode("modulate")


	love.graphics.setColor(128,255,128)
	love.graphics.triangle("fill",self.triangleCoords[1],self.triangleCoords[2],self.triangleCoords[3],self.triangleCoords[4],self.triangleCoords[5],self.triangleCoords[6])

	self.image:grab(self.rect[1],self.rect[2],self.rect[3],self.rect[4])
	self.image:setAlpha(255*self.alpha)

	love.graphics.setScissor()
end

function Radar:mousePressed(rel_x, rel_y, button)
end

function Radar:mouseReleased(rel_x, rel_y, button)
end
