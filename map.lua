
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
Map.cell_w = math.floor(screensize[1]/Map.hcells)
Map.cell_h= math.floor(screensize[2]/Map.vcells)
-- force square
Map.cell_w = Map.cell_h 


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

function drawmap(map)
	love.graphics.setLine(2, love.line_rough)
	local i,j
--~ 	local dx=screensize[1]/Map.hcells
--~ 	local dy=screensize[2]/Map.vcells
	local dx,dy = Map.cell_w,Map.cell_h
--~ 	dx = dy
	for i=1,Map.hcells do
		for j=1,Map.vcells do
			if  not map[i][j].corridor then
				love.graphics.setColor(0,48,48)
				love.graphics.rectangle( love.draw_fill , (i-1)*dx+1,(j-1)*dy+1,dx-1,dy-1 ) 
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
				
				-- closed doors
				if map[i][j].u==3 then
					love.graphics.setColor(160,0,160)
					love.graphics.line((i-1)*dx,(j-1)*dy,i*dx,(j-1)*dy)
				end
				if map[i][j].l==3 then
					love.graphics.setColor(160,0,160)
					love.graphics.line((i-1)*dx,(j-1)*dy,(i-1)*dx,j*dy)
				end
				if map[i][j].d==3 then
					love.graphics.setColor(160,0,160)
					love.graphics.line((i-1)*dx,j*dy,i*dx,j*dy)
				end
				if map[i][j].r==3 then
					love.graphics.setColor(160,0,160)
					love.graphics.line(i*dx,(j-1)*dy,i*dx,j*dy)
				end
				
				-- blocked doors
				if map[i][j].u==4 then
					love.graphics.setColor(200,0,0)
					love.graphics.line((i-1)*dx,(j-1)*dy,i*dx,(j-1)*dy)
				end
				if map[i][j].l==4 then
					love.graphics.setColor(200,0,0)
					love.graphics.line((i-1)*dx,(j-1)*dy,(i-1)*dx,j*dy)
				end
				if map[i][j].d==4 then
					love.graphics.setColor(200,0,0)
					love.graphics.line((i-1)*dx,j*dy,i*dx,j*dy)
				end
				if map[i][j].r==4 then
					love.graphics.setColor(200,0,0)
					love.graphics.line(i*dx,(j-1)*dy,i*dx,j*dy)
				end
				
				-- open doors
				if map[i][j].u==2 then
					love.graphics.setColor(160,0,160)
					love.graphics.line((i-1)*dx,(j-1)*dy,(i-3/4)*dx,(j-1)*dy)
					love.graphics.line((i-1/4)*dx,(j-1)*dy,i*dx,(j-1)*dy)
				end
				if map[i][j].l==2 then
					love.graphics.setColor(160,0,160)
					love.graphics.line((i-1)*dx,(j-1)*dy,(i-1)*dx,(j-3/4)*dy)
					love.graphics.line((i-1)*dx,(j-1/4)*dy,(i-1)*dx,j*dy)
				end
				if map[i][j].d==2 then
					love.graphics.setColor(160,0,160)
					love.graphics.line((i-1)*dx,j*dy,(i-3/4)*dx,j*dy)
					love.graphics.line((i-1/4)*dx,j*dy,i*dx,j*dy)
				end
				if map[i][j].r==2 then
					love.graphics.setColor(160,0,160)
					love.graphics.line(i*dx,(j-1)*dy,i*dx,(j-3/4)*dy)
					love.graphics.line(i*dx,(j-1/4)*dy,i*dx,j*dy)
				end
			end
		end
	end
end
