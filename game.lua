

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
	love.filesystem.load("map.lua")()
	love.filesystem.load("routefinder.lua")()

	mymap = generateMapWRooms()
	mycachedmap = {}

	love.graphics.setBackgroundColor(0,0,48)
	love.graphics.setColor(0,160,160)
	love.graphics.setLine(2)

	-- 1 edit
	-- 2 move guy
	-- 3 speed test
	-- 4 scheduler test
	gamemode = 5
	step_counter = 0
	step_size = 0.08
	tabledelay = 0
	listdelay = 0

	scheduler = Scheduler()
	pathcont={ path={} }
	mypath={}
	mytext=""
	scheduler:addUntimedTask(MapCacher(mymap,mycachedmap))
	fps = 0
	show_fps = false

	-- set a random initial position
	local i
	for i=1,mymap.hcells do
		if mymap[i][mymap.vcells].corridor then currentpos = {i,mymap.vcells}
		break
		end
	end

	player = { pos=currentpos }

--~ 	initScent(mymap)
	scentTask = ScentTask(mymap, player)
	scheduler:addTimedTask(scentTask,0.08)
--~  	launchEnemy(scentTask)
	enemyTask = EnemyTask(scentTask)
	scheduler:addTimedTask(enemyTask,0.08)
	enemy_timer = 3
end

function Game.update(dt)
	fps = fps*0.99 + 0.01 * 1.0 / dt

	if gamemode == 3 then
		local fx,fy,tx,ty
		while true do
			fx = math.random(mymap.hcells)
			fy = math.random(mymap.vcells)
			tx = math.random(mymap.hcells)
			ty = math.random(mymap.vcells)
			if fx~=tx and fy~=ty and mymap[fx][fy].corridor and mymap[tx][ty].corridor then break end
		end

			local starttimet = love.timer.getTime()
			local routedelayt =  love.timer.getTime() - starttimet
			tabledelay = 0.99*tabledelay + 0.01*routedelayt
			local starttimel = love.timer.getTime()
			mypath = findRoute( {fx,fy}, {tx,ty}, mymap )
			local routedelayl =  love.timer.getTime() - starttimel
			listdelay = 0.99*listdelay + 0.01*routedelayl
	end

	if gamemode == 4 then
		-- 60 FPS
		scheduler:iteration(1.0/40.0)

		if table.getn(pathcont.path)>0 then
			for i,v in ipairs(pathcont.path) do
				table.insert(mypath,v)
			end
			pathcont.path = {}
		end

		local do_step = false
		local nsteps = 1
		if step_counter>0 then
			step_counter = step_counter - dt
		end
		if step_counter<=0 then
			do_step = true
			nsteps = math.floor(math.abs(step_counter/step_size))+1
			step_counter = step_size
		end

		if mypath and do_step then
			if table.getn(mypath)>0 then
				if nsteps>table.getn(mypath) then nsteps=table.getn(mypath) end
				currentpos = mypath[nsteps]
				local i
				for i=1,nsteps do
					table.remove(mypath,1)
				end
			end
		end

		player.pos = currentpos

	end

	if gamemode == 5 then
		-- 60 FPS
		scheduler:iteration(1.0/40.0)

		if table.getn(pathcont.path)>0 then
			for i,v in ipairs(pathcont.path) do
				table.insert(mypath,v)
			end
			pathcont.path = {}
		end

		local do_step = false
		local nsteps = 1
		if step_counter>0 then
			step_counter = step_counter - dt
		end
		if step_counter<=0 then
			do_step = true
			nsteps = math.floor(math.abs(step_counter/step_size))+1
			step_counter = step_size
		end

		if mypath and do_step then
			if table.getn(mypath)>0 then
				if nsteps>table.getn(mypath) then nsteps=table.getn(mypath) end
				currentpos = mypath[nsteps]
				local i
				for i=1,nsteps do
					--scentTask:markPlayer(mypath[1])
					scentTask:mark(mypath[1],Player_scent)
					table.remove(mypath,1)
				end
			end
		end

		player.pos = currentpos

		-- scent test
--~ 		switchScent()

--~ 		if currentpos then
--~ 			playerScent(currentpos)
--~ 		end

--~ 		moveEnemies()
--~ 		updateScent()

		if enemy_timer > 0 then enemy_timer = enemy_timer - dt
		if enemy_timer <=0 then enemyTask:launchEnemy()
		enemy_timer = 10 end end

	end

end


function Game.draw()
--~ 	Map.draw(mymap)
	if mycachedmap.cached_map then
		mycachedmap.cached_map:blit()
	end

	if gamemode == 2 then
		drawchar(currentpos)
	end

	if gamemode == 3 then
		drawpath(mypath)
		love.graphics.setColor(255,255,255,255)
		local cutdelay = math.floor(tabledelay*10000)/10000
		love.graphics.print(cutdelay, 482,20)
		local cutdelay = math.floor(listdelay*10000)/10000
		love.graphics.print(cutdelay, 482,40)
	end

	if gamemode == 4 then
		--drawpath(mypath)
		drawchar(currentpos)
	end

	if gamemode == 5 then
		-- scent test
--~ 		drawScent()

--~ 		drawScent(mymap,scentTask.current_map)
		scentTask:draw()
--~ 		drawEnemies()
		enemyTask:drawEnemies()

		--drawpath(mypath)
		drawchar(player.pos)
	end


	drawtext()
	drawscanlines()

	if show_fps then
		love.graphics.print(fps, 482, 20)
	end

end

function drawchar( c )

	if not c then return end
	local dx,dy = mymap.side,mymap.side

	love.graphics.setColor(188,168,0)
	love.graphics.rectangle("fill" , (c[1]-1)*dx+1,(c[2]-1)*dy+1,dx-1,dy-1 )
end

function drawpath( p )
	local i,v
	if not p then return end
	local mymap=mymap
	local dx,dy = mymap.side,mymap.side
	for i,v in ipairs(p) do
		love.graphics.setColor(188,168,i*255/table.getn(p))
		love.graphics.rectangle( "fill" , (v[1]-1)*dx+1,(v[2]-1)*dy+1,dx-1,dy-1 )
	end
end

function drawscanlines()
	if not cached_scanlines then
		cached_scanlines = ImageCache()
		local i
		local shalf = math.floor( screensize[2]/2 )
		for i=1,shalf do
			cached_scanlines:drawStraightLine(0,i*2,screensize[1],i*2,{0,0,0,128},1)
		end
	end
	cached_scanlines:blit()
end

function myprint(t)
	mytext=mytext..t.."\n"
end

function drawtext()
	love.graphics.setColor(200,200,200)
	love.graphics.print(mytext, 480, 10)
end


function Game.keypressed(key)
	if key == "escape" then
		love.event.push('q')
	end

end


function Game.keyreleased(key)
end


function Game.mousepressed(x, y, button)

	local dx,dy = mymap.side,mymap.side
	local cx = math.floor(x/dx)+1
	local cy = math.floor(y/dy)+1
	local lx = x%dx
	local ly = y%dy

	if cx>mymap.hcells or cy>mymap.vcells then
		-- outside of map: ignore
		return
	end


	if gamemode == 4 and mymap[cx][cy].corridor and button == "l" then
		if not currentpos then currentpos = {cx,cy} end
		local dest = currentpos
		if table.getn(mypath)>0 then dest = mypath[table.getn(mypath)] end
		scheduler:addUntimedTask(RouteFinder(dest, {cx,cy}, mymap, pathcont))
	end

	if gamemode == 5 and mymap[cx][cy].corridor and button == "l" then
		if not currentpos then currentpos = {cx,cy} end
		local dest = currentpos
		if table.getn(mypath)>0 then dest = mypath[table.getn(mypath)] end
		scheduler:addUntimedTask(RouteFinder(dest, {cx,cy}, mymap, pathcont))
	end
end



function Game.mousereleased(x, y, button)
end

