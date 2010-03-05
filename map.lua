
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


-- todo: create scheduled version of map cacher using this class also


Map={}

function Map.draw(map)
	if not current_map or current_map ~= map then
		current_map = map
		cached_map = ImageCache()
		Map.drawMap(cached_map, map)
	end
	cached_map:blit()
end

function Map.drawMap(where,map)
	love.graphics.setLineWidth(2)
	local i,j

	local dx,dy=map.side,map.side

	for i=1,map.hcells do
		for j=1,map.vcells do
			if  not map[i][j].corridor then
				where:drawRectangle((i-1)*dx+1,(j-1)*dy+1,i*dx-2,j*dy-2,{0,48,48,255} )
			end
			if map[i][j].corridor then
				-- walls
				if map[i][j].u==0 then
					where:drawStraightLine((i-1)*dx-1,(j-1)*dy-1,i*dx,(j-1)*dy-1,{0,160,160,255})
				end
				if map[i][j].l==0 then
					where:drawStraightLine((i-1)*dx-1,(j-1)*dy-1,(i-1)*dx-1,j*dy,{0,160,160,255})
				end
				if map[i][j].d==0 then
					where:drawStraightLine((i-1)*dx-1,j*dy-1,i*dx,j*dy-1,{0,160,160,255})
				end
				if map[i][j].r==0 then
					where:drawStraightLine(i*dx-1,(j-1)*dy-1,i*dx-1,j*dy,{0,160,160,255})
				end

--~ 				-- closed doors
--~ 				if map[i][j].u==3 then
--~ 					love.graphics.setColor(160,0,160)
--~ 					love.graphics.line((i-1)*dx,(j-1)*dy,i*dx,(j-1)*dy)
--~ 				end
--~ 				if map[i][j].l==3 then
--~ 					love.graphics.setColor(160,0,160)
--~ 					love.graphics.line((i-1)*dx,(j-1)*dy,(i-1)*dx,j*dy)
--~ 				end
--~ 				if map[i][j].d==3 then
--~ 					love.graphics.setColor(160,0,160)
--~ 					love.graphics.line((i-1)*dx,j*dy,i*dx,j*dy)
--~ 				end
--~ 				if map[i][j].r==3 then
--~ 					love.graphics.setColor(160,0,160)
--~ 					love.graphics.line(i*dx,(j-1)*dy,i*dx,j*dy)
--~ 				end

--~ 				-- blocked doors
--~ 				if map[i][j].u==4 then
--~ 					love.graphics.setColor(200,0,0)
--~ 					love.graphics.line((i-1)*dx,(j-1)*dy,i*dx,(j-1)*dy)
--~ 				end
--~ 				if map[i][j].l==4 then
--~ 					love.graphics.setColor(200,0,0)
--~ 					love.graphics.line((i-1)*dx,(j-1)*dy,(i-1)*dx,j*dy)
--~ 				end
--~ 				if map[i][j].d==4 then
--~ 					love.graphics.setColor(200,0,0)
--~ 					love.graphics.line((i-1)*dx,j*dy,i*dx,j*dy)
--~ 				end
--~ 				if map[i][j].r==4 then
--~ 					love.graphics.setColor(200,0,0)
--~ 					love.graphics.line(i*dx,(j-1)*dy,i*dx,j*dy)
--~ 				end

--~ 				-- open doors
--~ 				if map[i][j].u==2 then
--~ 					love.graphics.setColor(160,0,160)
--~ 					love.graphics.line((i-1)*dx,(j-1)*dy,(i-3/4)*dx,(j-1)*dy)
--~ 					love.graphics.line((i-1/4)*dx,(j-1)*dy,i*dx,(j-1)*dy)
--~ 				end
--~ 				if map[i][j].l==2 then
--~ 					love.graphics.setColor(160,0,160)
--~ 					love.graphics.line((i-1)*dx,(j-1)*dy,(i-1)*dx,(j-3/4)*dy)
--~ 					love.graphics.line((i-1)*dx,(j-1/4)*dy,(i-1)*dx,j*dy)
--~ 				end
--~ 				if map[i][j].d==2 then
--~ 					love.graphics.setColor(160,0,160)
--~ 					love.graphics.line((i-1)*dx,j*dy,(i-3/4)*dx,j*dy)
--~ 					love.graphics.line((i-1/4)*dx,j*dy,i*dx,j*dy)
--~ 				end
--~ 				if map[i][j].r==2 then
--~ 					love.graphics.setColor(160,0,160)
--~ 					love.graphics.line(i*dx,(j-1)*dy,i*dx,(j-3/4)*dy)
--~ 					love.graphics.line(i*dx,(j-1/4)*dy,i*dx,j*dy)
--~ 				end
			end
		end
	end
end

MapCacher = class(GenericVisitor,function(cache, map, container)
		cache.cached_map = ImageCache()
		cache.current_map = map
		cache.ready = false
		cache.container = container
	end)

function MapCacher:reset_loop()
	self.i = 1
	self.j = 1
end

function MapCacher:iteration(dt)
	if self.ready then return true end

	love.graphics.setLineWidth(2)
	local dx,dy=self.current_map.side,self.current_map.side


	if  not self.current_map[self.i][self.j].corridor then
		self.cached_map:drawRectangle((self.i-1)*dx+1,(self.j-1)*dy+1,self.i*dx-2,self.j*dy-2,{0,48,48,255} )
	end
	if self.current_map[self.i][self.j].corridor then
		-- walls
		if self.current_map[self.i][self.j].u==0 then
			self.cached_map:drawStraightLine((self.i-1)*dx-1,(self.j-1)*dy-1,self.i*dx,(self.j-1)*dy-1,{0,160,160,255})
		end
		if self.current_map[self.i][self.j].l==0 then
			self.cached_map:drawStraightLine((self.i-1)*dx-1,(self.j-1)*dy-1,(self.i-1)*dx-1,self.j*dy,{0,160,160,255})
		end
		if self.current_map[self.i][self.j].d==0 then
			self.cached_map:drawStraightLine((self.i-1)*dx-1,self.j*dy-1,self.i*dx,self.j*dy-1,{0,160,160,255})
		end
		if self.current_map[self.i][self.j].r==0 then
			self.cached_map:drawStraightLine(self.i*dx-1,(self.j-1)*dy-1,self.i*dx-1,self.j*dy,{0,160,160,255})
		end
	end

	self.i = self.i + 1
	if self.i>self.current_map.hcells then
		self.i = 1
		self.j = self.j + 1
		if self.j>self.current_map.vcells then
			self.ready = true
		end
	end

	return self.ready
end

function MapCacher:finish_loop()
	self.container.cached_map = self.cached_map
	self.cached_map = nil
end
