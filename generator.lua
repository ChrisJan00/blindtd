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

-- procedural generator

function generateMapWRooms()
	local map={}
	local marks={}

	local i,j

	local room_prob = 0.04
	local step_door = 12

	-- closed: (cannot go through) 0
	-- open: (can go through) 1
	-- door open: 2
	-- door closed: 3
	-- door blocked: 4

--~ 	map.hcells = 20
--~ 	map.vcells = 20
	map.hcells = Map.hcells
	map.vcells = Map.vcells

	for i=1,map.hcells do
		map[i]={}
		marks[i]={}

		for j=1,map.vcells do
			map[i][j]={
				u = 0,
				d = 0,
				l = 0,
				r = 0,
				corridor = false
			}
			marks[i][j]=0
		end
	end

	local x,y = math.random(map.hcells),math.random(map.vcells)
	local stack={}
	local ndx
	stack[1] = {x,y,0,0}


	-- directions: 1 up, 2 down, 3 left, 4 right

	while table.getn(stack) > 0 do
		ndx = math.random(table.getn(stack))
		x,y = stack[ndx][1],stack[ndx][2]
		local fromdir = stack[ndx][3]
		local step=stack[ndx][4]
		table.remove(stack, ndx)

		if marks[x][y]<2 then

			if (math.random()<room_prob) then
			-- make room
				local roombox = {x,y,x,y}
				local roomcandidate  = {x,y,x,y}
				local checkroom = true
				local maxW,maxH = 5,5
				local taboo={false,false,false,false}

				marks[x][y]=0



				-- grow room
				while checkroom and roombox[3]-roombox[1]+1<maxW and roombox[4]-roombox[2]+1<maxH do
					-- choose direction to grow
					local dirgrow = math.random(4)
					if (taboo[1] and taboo[2] and taboo[3] and taboo[4]) then
						checkroom = false
						break
					end

					while taboo[dirgrow] do
						dirgrow = dirgrow%4+1
					end

					-- grow
					if dirgrow==1 and roombox[1]>1 then roomcandidate[1]=roombox[1]-1 end
					if dirgrow==2 and roombox[2]>1 then roomcandidate[2]=roombox[2]-1 end
					if dirgrow==3 and roombox[3]<map.hcells then roomcandidate[3]=roombox[3]+1 end
					if dirgrow==4 and roombox[4]<map.vcells then roomcandidate[4]=roombox[4]+1 end
					taboo[dirgrow]=true
					-- check
					checkroom = true
					for i=roomcandidate[1],roomcandidate[3] do
						for j=roomcandidate[2],roomcandidate[4] do
							if marks[i][j] >0 then checkroom = false end
						end
					end
					if not checkroom then
						-- reject
						roomcandidate[dirgrow] = roombox[dirgrow]
						if not (taboo[1] and taboo[2] and taboo[3] and taboo[4]) then checkroom=true end
					elseif roombox[dirgrow] ~= roomcandidate[dirgrow] then
						-- accept
						taboo={false,false,false,false}
						roombox[dirgrow] = roomcandidate[dirgrow]
					end
				end

				-- now that we have a room, place it in the map
				for i=roombox[1],roombox[3] do
					for j=roombox[2],roombox[4] do
						marks[i][j]=3
						map[i][j].corridor=true
						map[i][j].u = 1
						if j>1 then map[i][j-1].d=1 end
						map[i][j].d = 1
						if j<map.vcells then map[i][j+1].u=1 end
						map[i][j].l = 1
						if i>1 then map[i-1][j].r=1 end
						map[i][j].r = 1
						if i<map.hcells then map[i+1][j].l=1 end
					end
				end

				-- open


			map[x][y].corridor = true
			if fromdir==1 then

				map[x][y-1].d = 2
				map[x][y].u = 2
				marks[x][y-1]=3
			end
			if fromdir ==2 then

				map[x][y+1].u=2
				map[x][y].d=2
				marks[x][y+1]=3
			end
			if fromdir == 3 then

				map[x-1][y].r = 2
				map[x][y].l = 2
				marks[x-1][y]=3
			end
			if fromdir == 4 then

				map[x+1][y].l = 2
				map[x][y].r = 2
				marks[x+1][y]=3
			end

				-- horizontal walls
				for i=roombox[1],roombox[3] do
					local top,bot = roombox[2],roombox[4]
					marks[i][top]=5
					marks[i][bot]=5
					if top>1 and not map[i][top - 1].corridor then
						map[i][top].u = 0
						map[i][top-1].d = 0
						if marks[i][top-1]==0 then
							marks[i][top-1]=1
							table.insert(stack,{i,top-1,2,step+1})
						elseif marks[i][top-1]==1 then
							marks[i][top-1]=2
						end
					elseif top==1 then map[i][top].u = 0 end
					if bot<map.vcells and not map[i][bot + 1].corridor then
						map[i][bot].d = 0
						map[i][bot+1].u = 0
						if marks[i][bot+1]==0 then
							marks[i][bot+1]=1
							table.insert(stack,{i,bot+1,1,step+1})
						elseif  marks[i][bot+1]==1 then marks[i][bot+1]=2 end
					elseif bot==map.vcells then map[i][bot].d = 0 end
				end

				-- vertical walls
				for j=roombox[2],roombox[4] do
					local lt,rt = roombox[1],roombox[3]
					marks[lt][j]=5
					marks[rt][j]=5
					if lt>1 and not map[lt - 1][j].corridor then
						map[lt][j].l = 0
						map[lt-1][j].r = 0
						if marks[lt-1][j]==0 then
							marks[lt-1][j]=1
							table.insert(stack,{lt-1,j,4,step+1})
						elseif  marks[lt-1][j]==1 then marks[lt-1][j]=2 end
					elseif lt==1 then map[lt][j].l = 0 end
					if rt<map.hcells and not map[rt + 1][j].corridor then
						map[rt][j].r = 0
						map[rt+1][j].l = 0
						if marks[rt+1][j]==0 then
							marks[rt+1][j]=1
							table.insert(stack,{rt+1,j,3,step+1})
						elseif  marks[rt+1][j]==1 then marks[rt+1][j]=2 end
					elseif rt==map.hcells then map[rt][j].r = 0 end
				end

			else

			marks[x][y]=4

			-- open
			local doortype = 1
			if step%step_door == 0 then doortype=2 end

			map[x][y].corridor = true
			if fromdir==1 then
				if marks[x][y-1]==5 then doortype=2 else doortype=1 end
				map[x][y-1].d = doortype
				map[x][y].u = doortype
				marks[x][y-1]=3
			end
			if fromdir ==2 then
				if marks[x][y+1]==5 then doortype=2 else doortype=1 end
				map[x][y+1].u=doortype
				map[x][y].d=doortype
				marks[x][y+1]=3
			end
			if fromdir == 3 then
				if marks[x-1][y]==5 then doortype=2 else doortype=1 end
				map[x-1][y].r = doortype
				map[x][y].l = doortype
				marks[x-1][y]=3
			end
			if fromdir == 4 then
				if marks[x+1][y]==5 then doortype=2 else doortype=1 end
				map[x+1][y].l = doortype
				map[x][y].r = doortype
				marks[x+1][y]=3
			end

			-- push up
			if y>1 then
				if marks[x][y-1]==0 then
					marks[x][y-1]=1
					table.insert(stack,{x,y-1,2,step+1})
				elseif marks[x][y-1]==1 then
					marks[x][y-1]=2
				end
			end

			-- push down
			if y<map.vcells then
				if marks[x][y+1]==0 then
					marks[x][y+1]=1
					table.insert(stack,{x,y+1,1,step+1})
				elseif marks[x][y+1]==1 then
					marks[x][y+1]=2
				end
			end

			-- push left
			if x>1 then
				if marks[x-1][y]==0 then
					marks[x-1][y]=1
					table.insert(stack,{x-1,y,4,step+1})
				elseif marks[x-1][y]==1 then
					marks[x-1][y]=2
				end
			end

			-- push right
			if x<map.hcells then
				if marks[x+1][y]==0 then
					marks[x+1][y]=1
					table.insert(stack,{x+1,y,3,step+1})
				elseif marks[x+1][y]==1 then
					marks[x+1][y]=2
				end
			end
			end
		end
	end


	-- now, avoid dead ends in diagonal with other tunnels

	-- find them all
	stack={}
	for i=1,map.hcells do
		for j=1,map.vcells do
			if marks[i][j]==4 then
				table.insert(stack,{i,j})
			end
		end
	end

	-- process them randomly, one at a time
	while table.getn(stack)>0 do
		ndx = math.random(table.getn(stack))
		x,y = stack[ndx][1],stack[ndx][2]
		table.remove(stack,ndx)

		-- check if it is still a u turn
		local checksum = 0
		if map[x][y].u ~= 0 then checksum = checksum + 1 end
		if map[x][y].d ~= 0 then checksum = checksum + 1 end
		if map[x][y].l ~= 0 then checksum = checksum + 1 end
		if map[x][y].r ~= 0 then checksum = checksum + 1 end
		if map[x][y].corridor and checksum==1 then

		-- up
		if map[x][y].u~=0 then
			if y<map.vcells and ((x>1 and map[x-1][y+1].corridor) or (x<map.hcells and map[x+1][y+1].corridor)) then
				map[x][y-1].d = 0
				map[x][y].u = 0
				map[x][y].corridor = false
			elseif y<map.vcells-1 and map[x][y+2].corridor then
				map[x][y].d = 2
				map[x][y+1].u = 2
				map[x][y+1].d=1
				map[x][y+2].u=1
				map[x][y+1].corridor = true
			end


		-- down
		elseif map[x][y].d~=0 then
			if y>1 and ((x>1 and map[x-1][y-1].corridor) or (x<map.hcells and map[x+1][y-1].corridor)) then
				map[x][y+1].u = 0
				map[x][y].d = 0
				map[x][y].corridor = false
			elseif y>2 and map[x][y-2].corridor then
				map[x][y].u =2
				map[x][y-1].d = 2
				map[x][y-1].u=1
				map[x][y-2].d=1
				map[x][y-1].corridor = true
			end


		-- left
		elseif map[x][y].l~=0 then
			if x<map.hcells and ((y>1 and map[x+1][y-1].corridor) or (y<map.vcells and map[x+1][y+1].corridor)) then
				map[x-1][y].r = 0
				map[x][y].l = 0
				map[x][y].corridor = false
			elseif x<map.hcells-1 and map[x+2][y].corridor then
				map[x][y].r = 2
				map[x+1][y].l = 2
				map[x+1][y].r=1
				map[x+2][y].l=1
				map[x+1][y].corridor = true
			end


		-- right
		elseif map[x][y].r~=0 then
			if x>1 and ((y>1 and map[x-1][y-1].corridor) or (y<map.vcells and map[x-1][y+1].corridor)) then
				map[x+1][y].l = 0
				map[x][y].r = 0
				map[x][y].corridor = false
			elseif x>2 and map[x-2][y].corridor then
				map[x][y].l =2
				map[x-1][y].r = 2
				map[x-1][y].l=1
				map[x-2][y].r=1
				map[x-1][y].corridor = true
			end
		end

		end
	end

	return map

end

-------------------------------------------------------------------------------------------------------

function generateMap()
	local map={}
	local marks={}

	local i,j

	-- closed: (cannot go through) 0
	-- open: (can go through) 1
	-- door open: 2
	-- door closed: 3
	-- door blocked: 4

	map.hcells = 20
	map.vcells = 20

	for i=1,map.hcells do
		map[i]={}
		marks[i]={}

		for j=1,map.vcells do
			map[i][j]={
				u = 0,
				d = 0,
				l = 0,
				r = 0,
				corridor = false
			}
			marks[i][j]=0
		end
	end

	local x,y = math.random(map.hcells),math.random(map.vcells)
	local stack={}
	local ndx
	stack[1] = {x,y,0}


	-- directions: 1 up, 2 down, 3 left, 4 right

	while table.getn(stack) > 0 do
		ndx = math.random(table.getn(stack))
		x,y = stack[ndx][1],stack[ndx][2]
		local fromdir = stack[ndx][3]
		table.remove(stack, ndx)

		if marks[x][y]~=2 then
			marks[x][y]=4

			-- open
			map[x][y].corridor = true
			if fromdir==1 then
				map[x][y-1].d = 1
				map[x][y].u = 1
				marks[x][y-1]=3
			end
			if fromdir ==2 then
				map[x][y+1].u=1
				map[x][y].d=1
				marks[x][y+1]=3
			end
			if fromdir == 3 then
				map[x-1][y].r = 1
				map[x][y].l = 1
				marks[x-1][y]=3
			end
			if fromdir == 4 then
				map[x+1][y].l = 1
				map[x][y].r = 1
				marks[x+1][y]=3
			end

			-- push up
			if y>1 then
				if marks[x][y-1]==0 then
					marks[x][y-1]=1
					table.insert(stack,{x,y-1,2})
				elseif marks[x][y-1]==1 then
					marks[x][y-1]=2
				end
			end

			-- push down
			if y<map.vcells then
				if marks[x][y+1]==0 then
					marks[x][y+1]=1
					table.insert(stack,{x,y+1,1})
				elseif marks[x][y+1]==1 then
					marks[x][y+1]=2
				end
			end

			-- push left
			if x>1 then
				if marks[x-1][y]==0 then
					marks[x-1][y]=1
					table.insert(stack,{x-1,y,4})
				elseif marks[x-1][y]==1 then
					marks[x-1][y]=2
				end
			end

			-- push right
			if x<map.hcells then
				if marks[x+1][y]==0 then
					marks[x+1][y]=1
					table.insert(stack,{x+1,y,3})
				elseif marks[x+1][y]==1 then
					marks[x+1][y]=2
				end
			end

		end
	end


	-- now, avoid dead ends in diagonal with other tunnels

	-- find them all
	stack={}
	for i=1,map.hcells do
		for j=1,map.vcells do
			if marks[i][j]==4 then
				table.insert(stack,{i,j})
			end
		end
	end

	-- process them randomly, one at a time
	while table.getn(stack)>0 do
		ndx = math.random(table.getn(stack))
		x,y = stack[ndx][1],stack[ndx][2]
		table.remove(stack,ndx)

		-- check if it is still a u turn
		local checksum = 0
		if map[x][y].u ~= 0 then checksum = checksum + 1 end
		if map[x][y].d ~= 0 then checksum = checksum + 1 end
		if map[x][y].l ~= 0 then checksum = checksum + 1 end
		if map[x][y].r ~= 0 then checksum = checksum + 1 end
		if map[x][y].corridor and checksum==1 then

		-- up
		if map[x][y].u~=0 then
			if y<map.vcells and ((x>1 and map[x-1][y+1].corridor) or (x<map.hcells and map[x+1][y+1].corridor)) then
				map[x][y-1].d = 0
				map[x][y].u = 0
				map[x][y].corridor = false
			elseif y<map.vcells-1 and map[x][y+2].corridor then
				map[x][y].d = 1
				map[x][y+1].u = 1
				map[x][y+1].d=1
				map[x][y+2].u=1
				map[x][y+1].corridor = true
			end


		-- down
		elseif map[x][y].d~=0 then
			if y>1 and ((x>1 and map[x-1][y-1].corridor) or (x<map.hcells and map[x+1][y-1].corridor)) then
				map[x][y+1].u = 0
				map[x][y].d = 0
				map[x][y].corridor = false
			elseif y>2 and map[x][y-2].corridor then
				map[x][y].u = 1
				map[x][y-1].d = 1
				map[x][y-1].u=1
				map[x][y-2].d=1
				map[x][y-1].corridor = true
			end


		-- left
		elseif map[x][y].l~=0 then
			if x<map.hcells and ((y>1 and map[x+1][y-1].corridor) or (y<map.vcells and map[x+1][y+1].corridor)) then
				map[x-1][y].r = 0
				map[x][y].l = 0
				map[x][y].corridor = false
			elseif x<map.hcells-1 and map[x+2][y].corridor then
				map[x][y].r = 1
				map[x+1][y].l = 1
				map[x+1][y].r=1
				map[x+2][y].l=1
				map[x+1][y].corridor = true
			end


		-- right
		elseif map[x][y].r~=0 then
			if x>1 and ((y>1 and map[x-1][y-1].corridor) or (y<map.vcells and map[x-1][y+1].corridor)) then
				map[x+1][y].l = 0
				map[x][y].r = 0
				map[x][y].corridor = false
			elseif x>2 and map[x-2][y].corridor then
				map[x][y].l = 1
				map[x-1][y].r = 1
				map[x-1][y].l=1
				map[x-2][y].r=1
				map[x-1][y].corridor = true
			end
		end

		end
	end

	return map

end
