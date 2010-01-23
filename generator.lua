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
	
--~ 	for i=1,map.hcells do for j=1,map.vcells do
--~ 		if map[i][j].u==0 and map[i][j].d==0 and map[i][j].l==0 and map[i][j].r==0 then map[i][j].corridor=false else map[i][j].corridor=true end
--~ 	end end

--~ 	for i=1,map.hcells do for j=1,map.vcells do
--~  		print(i.." "..j..","..map[i][j].u..map[i][j].d..map[i][j].l..map[i][j].r)
--~  	end end
	
	return map

end
