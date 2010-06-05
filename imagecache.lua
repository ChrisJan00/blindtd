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

-- love must be present

ImageCache = class(function(c,w,h)
	c.width = w or love.graphics.getWidth()
	c.height = h or love.graphics.getHeight()
	-- some displays want imagedata dimensions to be power of two...
	c.widthP2 = math.pow(2,(math.floor(math.log(c.width)/math.log(2))+1))
	c.heightP2 = math.pow(2,(math.floor(math.log(c.height)/math.log(2))+1))
	c.imagedata = love.image.newImageData(c.widthP2,c.heightP2)
	c.image = love.graphics.newImage(c.imagedata)
	c.modified = false
end)

-- this is a shallow copy.  For a deep copy use "drawImage"
function ImageCache:copy(source)
	self.width = source.width
	self.height = source.height
	self.widthP2 = source.widthP2
	self.heightP2 = source.heightP2
	self.imagedata = source.imagedata
	self.image = source.image
	self.modified = source.modified
end

function ImageCache:blit(x,y)
	if self.modified then
		self.image = love.graphics.newImage( self.imagedata )
		self.modified = false
	end
	local px = x or 0
	local py = y or 0
	love.graphics.setColorMode("replace")
	love.graphics.draw(self.image,px,py)
end

function ImageCache:erase()
	self.imagedata = love.image.newImageData(self.width,self.height)
	self.modified = true
end

function ImageCache:sortCoords(ox1,oy1,ox2,oy2)
	local x1,y1,x2,y2 = ox1,oy1,ox2,oy2
	if y2<y1 then
		local tmp = y1
		y1 =y2
		y2 = tmp
	end
	if x2<x1 then
		local tmp = x1
		x1 = x2
		x2 = tmp
	end
	if y1<0 then y1=0 end
	if y2>=self.height then y2=self.height-1 end
	if x1<0 then x1=0 end
	if x2>=self.width then x2=self.width-1 end
	return x1,y1,x2,y2
end

function ImageCache:getColor(color)
	if not color then
		return love.graphics.getColor()
	else
		return color[1],color[2],color[3],color[4]
	end
end

function ImageCache:eraseRegion(x1,y1,x2,y2)
	self:drawRectangle(x1,y1,x2,y2,{0,0,0,0})
end

function ImageCache:drawStraightLine( x1, y1, x2, y2, color, width)
	self.modified = true
	if not width then width = love.graphics.getLineWidth() end
	local borderleft = math.floor((width-1)/2)
	local borderright = math.floor(width/2)

	if y1==y2 then
		-- horizontal line
		self:drawRectangle(x1,y1-borderleft,x2,y2+borderright,color)
	else
		-- vertical line
		self:drawRectangle(x1-borderleft,y1,x2+borderright,y2,color)
	end
end

function ImageCache:drawRectangle(x1, y1, x2, y2, color)
	self.modified = true
	local r,g,b,a = self:getColor(color)
	local i,j
	local lx1,ly1,lx2,ly2 = self:sortCoords(x1,y1,x2,y2)
	local dy = ly2-ly1+1
	local dx = lx2-lx1+1
	for j=1,dy do
		for i=1,dx do
			self.imagedata:setPixel(i-1+lx1,j-1+ly1,r,g,b,a)
		end
	end
end

function ImageCache:drawDot(x,y,color)
	self.modified=true
	local r,g,b,a = self:getColor(color)
	if y<0 then y=0 end
	if y>=self.height then y=self.height-1 end
	if x<0 then x=0 end
	if x>=self.width then x=self.width-1 end
	self.imagedata:setPixel(x,y,r,g,b,a)
end

function ImageCache:drawImage(source,x,y)
	local sx1,sy1,dx,dy = 0,0,source.width,source.height
	local x1,y1 = x,y
	if x<0 then
		sx1 = -x
		x1 = 0
		dx = dx + x
	end
	if y<0 then
		sy1 = -y
		y1 = 0
		dy = dy + y
	end
	if x1+dx>self.width then
		dx = self.width-x1
	end
	if y1+dy>self.height then
		dy = self.height-y1
	end
	if dx<=0 or dy<=0 then return end

	local r,g,b,a
	local r1,g1,b1,a1
	local r2,g2,b2,a2

	self.modified=true
	for j=1,dy do
		for i=1,dx do
			r,g,b,a = source.imagedata:getPixel(sx1+i-1,sy1+j-1)
			r1,g1,b1,a1 = self.imagedata:getPixel(x1+i-1,y1+j-1)
			a = a/255
			a1 = a1/255
			a2 = (1-a)*a1+a
			if a2==0 then
				r2,g2,b2 = r1,g1,b1
			else
				r2 = ((1-a)*r1*a1+a*r)/a2
				g2 = ((1-a)*g1*a1+a*g)/a2
				b2 = ((1-a)*b1*a1+a*b)/a2
			end
			self.imagedata:setPixel(x1+i-1,y1+j-1,r2,g2,b2,a2*255)
		end
	end

end

function ImageCache:fromFile(filename)
	self.imagedata = love.image.newImageData(filename)
	self.width = self.imagedata:getWidth()
	self.height = self.imagedata:getHeight()
	self.modified=true
end

function ImageCache:cutRegion(x1,y1,x2,y2)
	local lx1,ly1,lx2,ly2 = self:sortCoords(x1,y1,x2,y2)
	local dy = y2-y1+1
	local dx = x2-x1+1
	local newImage = ImageCache(dx,dy)

	local i,j
	local r,g,b,a
	for j=1,dy do
		for i=1,dx do
			r,g,b,a = self.imagedata:getPixel(i-1+x1,j-1+y1)
			newImage.imagedata:setPixel(i-1,j-1,r,g,b,a)
		end
	end
	newImage.modified = true
	return newImage
end
