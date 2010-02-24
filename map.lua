
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


Map={}

Map.hcells = 20
Map.vcells = 20

Cell = {
	width = math.floor(screensize[1]/Map.hcells),
	height = math.floor(screensize[2]/Map.vcells)
}
-- force square
Cell.width = Cell.height


function examplemap()
local i,j
-- example: 10x10 map
-- closed: (cannot go through) 0
-- open: (can go through) 1
-- door open: 2
-- door closed: 3
-- door blocked: 4
for i=1,Map.hcells do
	Map[i]={}
  for j=1,Map.vcells do
	Map[i][j]={
		u = 0,
		d = 0,
		l = 0,
		r = 0,
		corridor = true
	}
  end
end

--~ 	Map[5][5].u = 1
--~ 	Map[5][4].d = 1
--~ 	Map[6][6].d = 2
--~ 	Map[6][7].u = 2
--~ 	Map[7][7].r = 3
--~ 	Map[8][7].l = 3
--~ 	Map[8][8].l = 4
--~ 	Map[8][7].r = 4
end

function getColor(color)
	if not color then
		return love.graphics.getColor() 
	else
		return color[1],color[2],color[3],color[4]
	end
end

function drawStraightLine(where, x1, y1, x2, y2, color, width)

	if not width then width = love.graphics.getLineWidth() end
	local borderleft = math.floor((width-1)/2)
	local borderright = math.floor(width/2)
	
	if y1==y2 then
		-- horizontal line
		drawRectangle(where, x1,y1-borderleft,x2,y2+borderright,color)
	else
		-- vertical line
		drawRectangle(where,x1-borderleft,y1,x2+borderright,y2,color)
	end
end

function drawRectangle(where, x1, y1, x2, y2, color)
	local r,g,b,a = getColor(color)
	local i,j
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
	if y2>=screensize[2] then y2=screensize[2]-1 end
	if x1<0 then x1=0 end
	if x2>=screensize[1] then x2=screensize[1]-1 end
	local dy = y2-y1+1
	local dx = x2-x1+1
	for j=1,dy do
		for i=1,dx do
			where:setPixel(i-1+x1,j-1+y1,r,g,b,a)
		end
	end
end

function drawDot(where,x,y,color)
	local r,g,b,a = getColor(color)
	if y<0 then y=0 end
	if y>=screensize[2] then y=screensize[2]-1 end
	if x<0 then x=0 end
	if x>=screensize[1] then x=screensize[1]-1 end
	where:setPixel(x,y,r,g,b,a)
end

function cacheMap(map)
	if not current_map or current_map ~= map then
		-- update cache
		current_map = map
		local cached_map_data = love.image.newImageData(screensize[1],screensize[2])
		drawMap(cached_map_data, map)
		cached_map = love.graphics.newImage( cached_map_data )
	end
end

function drawCachedMap(map)
	if not cached_map then cacheMap(map) end
	love.graphics.draw(cached_map,0,0)
--~ drawmap(map)
end

function drawMap(where,map)
	love.graphics.setLineWidth(2)
	local i,j

	local dx,dy = Cell.width,Cell.height

	for i=1,map.hcells do
		for j=1,map.vcells do
			if  not map[i][j].corridor then
				drawRectangle(where , (i-1)*dx+1,(j-1)*dy+1,i*dx-2,j*dy-2,{0,48,48,255} )
			end
			if map[i][j].corridor then
				-- walls
				if map[i][j].u==0 then
					drawStraightLine(where , (i-1)*dx-1,(j-1)*dy-1,i*dx,(j-1)*dy-1,{0,160,160,255})
				end
				if map[i][j].l==0 then
					drawStraightLine(where , (i-1)*dx-1,(j-1)*dy-1,(i-1)*dx-1,j*dy,{0,160,160,255})
				end
				if map[i][j].d==0 then
					drawStraightLine(where , (i-1)*dx-1,j*dy-1,i*dx,j*dy-1,{0,160,160,255})
				end
				if map[i][j].r==0 then
					drawStraightLine(where , i*dx-1,(j-1)*dy-1,i*dx-1,j*dy,{0,160,160,255})
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

function drawmap(map)
	love.graphics.setLineWidth(2)
	local i,j
--~ 	local dx=screensize[1]/Map.hcells
--~ 	local dy=screensize[2]/Map.vcells
	local dx,dy = Cell.width,Cell.height
--~ 	dx = dy
	for i=1,Map.hcells do
		for j=1,Map.vcells do
			if  not map[i][j].corridor then
				love.graphics.setColor(0,48,48)
				love.graphics.rectangle( "fill" , (i-1)*dx+1,(j-1)*dy+1,dx-1,dy-1 )
			end
			if map[i][j].corridor then
				-- walls
				if map[i][j].u==0 then
					love.graphics.setColor(0,160,160)
					love.graphics.line((i-1)*dx,(j-1)*dy,i*dx,(j-1)*dy)
				end
				if map[i][j].l==0 then
					love.graphics.setColor(0,160,160)
					love.graphics.line((i-1)*dx,(j-1)*dy,(i-1)*dx,j*dy)
				end
				if map[i][j].d==0 then
					love.graphics.setColor(0,160,160)
					love.graphics.line((i-1)*dx,j*dy,i*dx,j*dy)
				end
				if map[i][j].r==0 then
					love.graphics.setColor(0,160,160)
					love.graphics.line(i*dx,(j-1)*dy,i*dx,j*dy)
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
