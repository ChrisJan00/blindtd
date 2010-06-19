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

FloatingLabel = class(UIElement, function(self, rect, game)
	self._base.init(self, rect)
	self.texts={"test","one","two"}
	self.text = "test"
	self.point = {self.rect[1]+3, self.rect[2]+3}
	self.radius = 4
	self.timer = 0
end)

function FloatingLabel:update(dt)
end

function FloatingLabel:draw()
	-- draw a circle in the point of interest
	love.graphics.setColor(188,168,0)
	love.graphics.setLineWidth(1)
	love.graphics.circle("line",self.point[1], self.point[2], self.radius)

	local p2 = { self.point[1]+self.radius*2,self.point[2]+self.radius*2 }
	-- then a diagonal line
	love.graphics.line(self.point[1]+self.radius-1,self.point[2]+self.radius-1,p2[1],p2[2])
	-- then a horizontal line
	local font = love.graphics.getFont()
	local len = font:getWidth(self.text)
	love.graphics.line(p2[1],p2[2],p2[1]+len+2,p2[2])

	-- then the text hanging from the line
	love.graphics.setColorMode("modulate")
	love.graphics.print(self.text, p2[1]+2, p2[2]+love.graphics.getFont():getHeight()-2)
end

function FloatingLabel:mousePressed(rel_x, rel_y, button)
end

function FloatingLabel:mouseReleased(rel_x, rel_y, button)
end

function FloatingLabel:mouseEntered(rel_x, rel_y)
end

function FloatingLabel:mouseExited(rel_x, rel_y)
end

function FloatingLabel:mouseOver(rel_x, rel_y)
end
