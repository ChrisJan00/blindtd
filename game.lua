

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

	love.graphics.setBackgroundColor(0,0,48)
	love.graphics.setColor(0,160,160)
	love.graphics.setLine(2)

	-- 1 edit
	-- 2 move guy
	-- 3 speed test
	-- 4 scheduler test
	gamemode = 4
	step_counter = 0
	step_size = 0.08
	tabledelay = 0
	listdelay = 0

	scheduler = Scheduler()
	pathcont={ path={} }
	mypath={}
	mytext=""
end

function Game.update(dt)

	if gamemode == 2 then
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
	end

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
		scheduler:iteration(1.0/60.0)

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
	end

end


function Game.draw()
	Map.draw(mymap)

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
		drawpath(mypath)
	end

	drawtext()
	drawscanlines()

end

function drawchar( c )

	if not c then return end
	local dx,dy = map.side,map.side

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

	-- todo: cache generation should go somewhere else (load method?)
	if not cached_scanlines then
		-- pad the image?
		local scanlines_data = love.image.newImageData(screensize[1],screensize[2])
		local i,j
		local shalf = math.floor( screensize[2]/2 )
		for j=1,shalf do
			for i=1,screensize[1] do
				scanlines_data:setPixel(i,j*2,0,0,0,128)
			end
		end
		cached_scanlines = love.graphics.newImage( scanlines_data )
	end
	love.graphics.draw(cached_scanlines,0,0)
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
		love.system.exit()
	end

	if key == "s" then
		savemymap( mymap )
	end

	if key == "e" then
		gamemode = gamemode + 1
		if gamemode > 2 then gamemode = 1 end
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

	if gamemode == 1 then

		if love.keyboard.isDown("lshift") and button == "l" then
			mymap[cx][cy].corridor = not mymap[cx][cy].corridor
			return
		end

		if lx>ly and (dx-lx)>ly then -- upper wall
			-- switch wall
			if button == "l" then
				if mymap[cx][cy].u == 0 then
					mymap[cx][cy].u = 1
					if cy>1 then
						mymap[cx][cy-1].d = 1
					end
				else
					mymap[cx][cy].u = 0
					if cy>1 then
						mymap[cx][cy-1].d = 0
					end
				end
			end

			-- switch door
			if button == "r" then
				if mymap[cx][cy].u == 2 then
					mymap[cx][cy].u = 3
					if cy>1 then
						mymap[cx][cy-1].d = 3
					end
				else
					mymap[cx][cy].u = 2
					if cy>1 then
						mymap[cx][cy-1].d = 2
					end
				end
			end
		end


		if lx>ly and (dx-lx)<=ly then -- right wall
			-- switch wall
			if button == "l" then
				if mymap[cx][cy].r == 0 then
					mymap[cx][cy].r = 1
					if cx<mymap.hcells then
						mymap[cx+1][cy].l = 1
					end
				else
					mymap[cx][cy].r = 0
					if cx<mymap.hcells then
						mymap[cx+1][cy].l = 0
					end
				end
			end

			-- switch door
			if button == "r" then
				if mymap[cx][cy].r == 2 then
					mymap[cx][cy].r = 3
					if cx<mymap.hcells then
						mymap[cx+1][cy].l = 3
					end
				else
					mymap[cx][cy].r = 2
					if cx<mymap.hcells then
						mymap[cx+1][cy].l = 2
					end
				end
			end
		end

		if lx<ly and  lx<=(dy-ly) then -- left wall
			-- switch wall
			if button == "l" then
				if mymap[cx][cy].l == 0 then
					mymap[cx][cy].l = 1
					if cx>1 then
						mymap[cx-1][cy].r = 1
					end
				else
					mymap[cx][cy].l = 0
					if cx>1 then
						mymap[cx-1][cy].r = 0
					end
				end
			end

			-- switch door
			if button == "r" then
				if mymap[cx][cy].l == 2 then
					mymap[cx][cy].l = 3
					if cx>1 then
						mymap[cx-1][cy].r = 3
					end
				else
					mymap[cx][cy].l = 2
					if cx>1 then
						mymap[cx-1][cy].r = 2
					end
				end
			end
		end
		if lx<ly and lx>(dy-ly) then -- down wall
			-- switch wall
			if button == "l" then
				if mymap[cx][cy].d == 0 then
					mymap[cx][cy].d = 1
					if cy<mymap.vcells then
						mymap[cx][cy+1].u = 1
					end
				else
					mymap[cx][cy].d = 0
					if cy<mymap.vcells then
						mymap[cx][cy+1].u = 0
					end
				end
			end

			-- switch door
			if button == "r" then
				if mymap[cx][cy].d == 2 then
					mymap[cx][cy].d = 3
					if cy<mymap.vcells then
						mymap[cx][cy+1].u = 3
					end
				else
					mymap[cx][cy].d = 2
					if cy<mymap.vcells then
						mymap[cx][cy+1].u = 2
					end
				end
			end
		end

	end

	if gamemode == 2 and mymap[cx][cy].corridor and button == "l" then
		if not currentpos then currentpos = {cx,cy} end
		mypath = findRoute( currentpos, {cx,cy}, mymap )
	end

	if gamemode == 4 and mymap[cx][cy].corridor and button == "l" then
		if not currentpos then currentpos = {cx,cy} end
		local dest = currentpos
		if table.getn(mypath)>0 then dest = mypath[table.getn(mypath)] end
		scheduler:addUntimedTask(RouteFinder(dest, {cx,cy}, mymap, pathcont))
	end
end



function Game.mousereleased(x, y, button)
end

