

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

Game = {}

function Game.load()
	love.filesystem.require("map.lua")
	love.filesystem.require("routefinder.lua")
	examplemap()
	Map = generateMap()

	love.graphics.setBackgroundColor(0,0,48)
	love.graphics.setColor(0,160,160)
	love.graphics.setLine(2)
	
	-- 1 edit
	-- 2 move guy
	gamemode = 2
end

function Game.update(dt)
end


function Game.draw()
	drawmap(Map)
	drawpath(mypath)
	drawscanlines()
end

function drawpath( p )
	local i,v
	if not p then return end
	local dx,dy = Cell.width,Cell.height
	for i,v in ipairs(p) do 
		love.graphics.setColor(188,168,0)
		love.graphics.rectangle( love.draw_fill , (v[1]-1)*dx+1,(v[2]-1)*dy+1,dx-1,dy-1 ) 
	end
end
 
function drawscanlines()
	local i
	local shalf = math.floor( screensize[2]/2)
	love.graphics.setColor(0,0,0,128)
	love.graphics.setLine(1,love.line_rough )
	for i=1,shalf do
		love.graphics.line(0,i*2-1,screensize[1],i*2-1)
	end
end


function Game.keypressed(key)
	if key == love.key_escape then
		love.system.exit()
	end
	
	if key == love.key_s then
		saveMap( Map )
	end
	
	if key == love.key_l then
		openMap( maps.lines )
	end
	
	if key == love.key_e then
		gamemode = gamemode + 1
		if gamemode > 2 then gamemode = 1 end
	end
end


function Game.keyreleased(key)
end


function Game.mousepressed(x, y, button)
	-- find where
	-- 1. which cell
--~ 	local dx = math.floor(screensize[1]/Map.hcells)
--~ 	local dy = math.floor(screensize[2]/Map.vcells)
--~ 	-- force square
--~ 	dx = dy 
	local dx,dy = Cell.width,Cell.height
	local cx = math.floor(x/dx)+1
	local cy = math.floor(y/dy)+1
	local lx = x%dx
	local ly = y%dy
	
	

	if cx>Map.hcells or cy>Map.vcells then
		-- outside of map: ignore
		return
	end
	
	if gamemode == 1 then
	
		if love.keyboard.isDown(love.key_lshift) and button == love.mouse_left then
			Map[cx][cy].corridor = not Map[cx][cy].corridor
			return
		end
		
		if lx>ly and (dx-lx)>ly then -- upper wall
			-- switch wall
			if button == love.mouse_left then
				if Map[cx][cy].u == 0 then
					Map[cx][cy].u = 1
					if cy>1 then
						Map[cx][cy-1].d = 1
					end
				else
					Map[cx][cy].u = 0
					if cy>1 then
						Map[cx][cy-1].d = 0
					end
				end
			end
			
			-- switch door
			if button == love.mouse_right then
				if Map[cx][cy].u == 2 then
					Map[cx][cy].u = 3
					if cy>1 then
						Map[cx][cy-1].d = 3
					end
				else
					Map[cx][cy].u = 2
					if cy>1 then
						Map[cx][cy-1].d = 2
					end
				end
			end
		end
		
		
		if lx>ly and (dx-lx)<=ly then -- right wall
			-- switch wall
			if button == love.mouse_left then
				if Map[cx][cy].r == 0 then
					Map[cx][cy].r = 1
					if cx<Map.hcells then
						Map[cx+1][cy].l = 1
					end
				else
					Map[cx][cy].r = 0
					if cx<Map.hcells then
						Map[cx+1][cy].l = 0
					end
				end
			end
			
			-- switch door
			if button == love.mouse_right then
				if Map[cx][cy].r == 2 then
					Map[cx][cy].r = 3
					if cx<Map.hcells then
						Map[cx+1][cy].l = 3
					end
				else
					Map[cx][cy].r = 2
					if cx<Map.hcells then
						Map[cx+1][cy].l = 2
					end
				end
			end
		end
		
		if lx<ly and  lx<=(dy-ly) then -- left wall
			-- switch wall
			if button == love.mouse_left then
				if Map[cx][cy].l == 0 then
					Map[cx][cy].l = 1
					if cx>1 then
						Map[cx-1][cy].r = 1
					end
				else
					Map[cx][cy].l = 0
					if cx>1 then
						Map[cx-1][cy].r = 0
					end
				end
			end
			
			-- switch door
			if button == love.mouse_right then
				if Map[cx][cy].l == 2 then
					Map[cx][cy].l = 3
					if cx>1 then
						Map[cx-1][cy].r = 3
					end
				else
					Map[cx][cy].l = 2
					if cx>1 then
						Map[cx-1][cy].r = 2
					end
				end
			end
		end
		if lx<ly and lx>(dy-ly) then -- down wall
			-- switch wall
			if button == love.mouse_left then
				if Map[cx][cy].d == 0 then
					Map[cx][cy].d = 1
					if cy<Map.vcells then
						Map[cx][cy+1].u = 1
					end
				else
					Map[cx][cy].d = 0
					if cy<Map.vcells then
						Map[cx][cy+1].u = 0
					end
				end
			end
			
			-- switch door
			if button == love.mouse_right then
				if Map[cx][cy].d == 2 then
					Map[cx][cy].d = 3
					if cy<Map.vcells then
						Map[cx][cy+1].u = 3
					end
				else
					Map[cx][cy].d = 2
					if cy<Map.vcells then
						Map[cx][cy+1].u = 2
					end
				end
			end
		end
	
	end
	
	if gamemode == 2 and Map[cx][cy].corridor and button == love.mouse_left then
		if not currentpos then currentpos = {cx,cy} end
		mypath = find_route( currentpos, {cx,cy}, Map )
		currentpos = {cx,cy}
	end
end



function Game.mousereleased(x, y, button)
end

