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

if not love then
	require 'class'
	require 'linkedlists'
end

UIList = class(function(self)
	self.list=List()
end)

function UIList:addElement(element)
	self.list:pushBack(element)
	element.wasPressed = false
end

function UIList:removeElement(element)
	self.list:remove(element)
end

function UIList:update(dt)
	local elem = self.list:getFirst()
	while elem do
		elem:update(dt)
		elem = self.list:getNext()
	end
end

function UIList:draw()
	local elem = self.list:getFirst()
	while elem do
		elem:draw()
		elem = self.list:getNext()
	end
end

function UIList:mousePressed(x,y,button)
	local elem = self.list:getFirst()
	while elem do
		local rel_x = x - elem.rect[1]
		local rel_y = y - elem.rect[2]
		if rel_x >= 0 and rel_x <= elem.rect[3] and rel_y>=0 and rel_y<=elem.rect[4] then
			elem.wasPressed = true
			elem:mousePressed(rel_x,rel_y,button)
		end
		elem = self.list:getNext()
	end
end

function UIList:mouseReleased(x,y,button)
	local elem = self.list:getFirst()
	while elem do
		if elem.wasPressed then
			elem.wasPressed = false
			local rel_x = x - elem.rect[1]
			local rel_y = y - elem.rect[2]
			elem:mouseReleased(rel_x,rel_y,button)
		end
		elem = self.list:getNext()
	end
end

------------------------------------------------------------
UIElement = class( function(self, rect)
	self.rect = rect or {10,10,300,50}
end)

function UIElement:update(dt)
end

function UIElement:draw()
end

function UIElement:mousePressed(rel_x, rel_y, button)
end

function UIElement:mouseReleased(rel_x, rel_y, button)
end

------------------------------------------------------------
MessageBox = class( UIElement, function(self, rect)
	self._base.init(self, rect)
	self.lines = {}
	self.fontheight = love.graphics.getFont():getHeight()
	if self.fontheight<5 then self.fontheight=5 end
	self.borderWidth = 4
	local barArea = self.rect[4]-2*self.borderWidth
	self.maxlinecount = barArea*barArea/self.fontheight/20
	if self.maxlinecount<10 then self.maxlinecount=10 end
	self.fontshade = {}
	-- after 1 second, brightness is 0.8 of the maximum
	self.shadingSpeed = -math.log(0.8)
	self.scroll = 0
	self.barWidth = 10
	self.scrollAreaLength=1
	self.dragging = false
	self.originalY = 0
end)

function split(str, delim, maxNb)
    -- Eliminate bad cases...
    if string.find(str, delim) == nil then
        return { str }
    end
    if maxNb == nil or maxNb < 1 then
        maxNb = 0    -- No limit
    end
    local result = {}
    local pat = "(.-)" .. delim .. "()"
    local nb = 0
    local lastPos
    for part, pos in string.gfind(str, pat) do
        nb = nb + 1
        result[nb] = part
        lastPos = pos
        if nb == maxNb then break end
    end
    -- Handle the last field
    if nb ~= maxNb then
        result[nb + 1] = string.sub(str, lastPos)
    end
    return result
end

function MessageBox:addLine(line)
	local font = love.graphics.getFont()
	local availableSpace = self.rect[3]-3*self.borderWidth - self.barWidth
	local firstline = line
	local secondline = ""

	local sep="x"
	local sepPos = string.len(line)

	while font:getWidth(firstline) > availableSpace do
		sep = "x"
		while sep~=" " do
			sepPos = sepPos-1
			if sepPos<=1 then break end
			sep = string.sub(line,sepPos,sepPos)
		end
		firstline = string.sub(line,1,sepPos-1)
		secondline = string.sub(line,sepPos+1)
	end

	table.insert(self.lines,firstline)
	table.insert(self.fontshade,1)
	if table.getn(self.lines)>self.maxlinecount then
		table.remove(self.lines,1)
		table.remove(self.fontshade,1)
	end

	if string.len(secondline)>0 then
		self:addLine(secondline)
	end
end

function MessageBox:addText(newText)
	for i,line in ipairs(split(newText,"\n")) do
		self:addLine(line)
	end

	self.scrollAreaLength = self.fontheight*table.getn(self.lines)
	if not self.dragging then
		self.scroll = self.scrollAreaLength - self.rect[4] + self.borderWidth*2
		if self.scroll < 0 then self.scroll = 0 end
	end

end

function MessageBox:update(dt)
	for i,shade in ipairs(self.fontshade) do
		self.fontshade[i] = self.fontshade[i] * math.exp(-self.shadingSpeed * dt)
	end

	if self.dragging then
		local newY = love.mouse.getY()
		self.scroll = self.scroll + (newY - self.originalY) * self.scrollAreaLength / (self.rect[4]-2*self.borderWidth)
		if self.scroll<0 then self.scroll=0 end
		local maxScroll = self.scrollAreaLength - (self.rect[4]-2*self.borderWidth)
		if maxScroll <0 then maxScroll=0 end
		if self.scroll > maxScroll then self.scroll=maxScroll end
		self.originalY = newY
	end
end

function MessageBox:draw()

	-- frame
	love.graphics.setLineWidth(2)
	love.graphics.setColor(0,0,200)
	love.graphics.rectangle( "line", self.rect[1], self.rect[2], self.rect[3], self.rect[4] )

	-- text
	love.graphics.setScissor( self.rect[1]+self.borderWidth, self.rect[2]+self.borderWidth, self.rect[3]-self.borderWidth*3-self.barWidth, self.rect[4]-self.borderWidth )
	for i,line in ipairs(self.lines) do
		love.graphics.setColor(100*self.fontshade[i],255*self.fontshade[i],200+55*self.fontshade[i])
		love.graphics.setColorMode("modulate")
		love.graphics.print(line,self.rect[1]+self.borderWidth,self.rect[2]+self.borderWidth+self.fontheight*i-self.scroll)
	end
	love.graphics.setScissor()

	-- scrollbar
	love.graphics.setColor(0,0,200)
	local scrollPos = self.rect[2]+self.borderWidth+self.scroll/self.scrollAreaLength*(self.rect[4]-2*self.borderWidth)
	local scrollLength = (self.rect[4]-2*self.borderWidth)/self.scrollAreaLength*(self.rect[4]-2*self.borderWidth)
	if scrollLength > self.rect[4]-2*self.borderWidth then scrollLength = self.rect[4]-2*self.borderWidth end
	love.graphics.rectangle( "fill", self.rect[1]+self.rect[3]-self.barWidth-self.borderWidth, scrollPos, self.barWidth, scrollLength )

end

function MessageBox:mousePressed(rel_x,rel_y,button)
	if button ~= "l" then return end
	if rel_x < self.rect[3]-self.barWidth-self.borderWidth or rel_x > self.rect[3]-self.borderWidth then return end
	-- clicked over the bar?
	local scrollPos = self.scroll/self.scrollAreaLength*(self.rect[4]-2*self.borderWidth)+self.borderWidth
	local scrollLength = (self.rect[4]-2*self.borderWidth)/self.scrollAreaLength*(self.rect[4]-2*self.borderWidth)
	local scrollEnd = scrollPos+scrollLength
	if rel_y < scrollPos then
		-- scroll one up
		self.scroll = self.scroll - self.fontheight
		if self.scroll<0 then self.scroll = 0 end
	end
	if rel_y > scrollEnd then
		self.scroll = self.scroll + self.fontheight
		local maxScroll = self.scrollAreaLength - (self.rect[4]-2*self.borderWidth)
		if maxScroll <0 then maxScroll=0 end
		if self.scroll > maxScroll then self.scroll=maxScroll end
	end

	self.dragging = true
	self.originalY = self.rect[2]+rel_y
end

function MessageBox:mouseReleased(rel_x,rel_y,button)
	self.dragging = false
end

------------------------------------------------------------
UIButton = class( UIElement, function(self, rect, text)
	self._base.init(self, rect)
	self.radius = 0
	self.segments = 8
	self.color = {0,100,200}
	self.textColor = {0,0,0}
	self.text = text or ""
end)

function UIButton:setRadius(newRadius)
	self.radius = newRadius
	local maxRadius = math.min(self.rect[3],self.rect[4])/2
	if self.radius > maxRadius then self.radius = maxRadius end
	if self.radius > 0 then
		local minAngle = math.asin(2/self.radius)
		if minAngle<math.pi/20 then minAngle = math.pi/20 end
		self.segments = 360/minAngle
		if self.segments<8 then self.segments=8 end
	end
end

function UIButton:update(dt)
end

function UIButton:draw()
	if self.radius > 0 then
		love.graphics.setColor(self.color[1],self.color[2],self.color[3])
		love.graphics.circle("fill", self.rect[1]+self.radius, self.rect[2]+self.radius, self.radius)
		love.graphics.circle("fill", self.rect[1]+self.rect[3]-self.radius, self.rect[2]+self.radius, self.radius)
		love.graphics.circle("fill", self.rect[1]+self.radius, self.rect[2]+self.rect[4]-self.radius, self.radius)
		love.graphics.circle("fill", self.rect[1]+self.rect[3]-self.radius, self.rect[2]+self.rect[4]-self.radius, self.radius)
		love.graphics.rectangle("fill", self.rect[1], self.rect[2]+self.radius, self.rect[3], self.rect[4]-self.radius*2)
		love.graphics.rectangle("fill", self.rect[1]+self.radius, self.rect[2], self.rect[3]-2*self.radius, self.rect[4])
	else
		love.graphics.setColor(self.color[1],self.color[2],self.color[3])
		love.graphics.rectangle("fill",self.rect[1],self.rect[2],self.rect[3],self.rect[4])
	end

	if string.len(self.text)>0 then
		love.graphics.setColorMode("modulate")
		love.graphics.setColor(self.textColor[1],self.textColor[2],self.textColor[3])
		local textWidth = love.graphics.getFont():getWidth(self.text)
		local textHeight = love.graphics.getFont():getHeight()
		love.graphics.print(self.text, self.rect[1]+self.rect[3]/2-textWidth/2, self.rect[2]+self.rect[4]/2+textHeight/2-3)
	end
end

function UIButton:mousePressed(rel_x, rel_y, button)
end

function UIElement:mouseReleased(rel_x, rel_y, button)
end
---------------------------

--~ print(math.sin(math.pi/4))
