
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

-- A* algorithm.. not really, the A* algorithm uses a heuristic estimation to guess the right way to try first.
-- this algorithm just tries all paths until it reaches the destination.  Not really optimal, but it does the job.

-- find the first ocurrence of element with value "value"
function table_indexOf(table, value)
	for i,v in ipairs(table) do if v==value then return i end end
	return nil
end

-- find the first ocurrence of element which func(element.value) computes true
function table_indexOfFn(table, func)
	for i,v in ipairs(table) do if func(v) then return i end end
	return nil
end

-- returns the square of the distance
function distanceSq(a,b)
	local dx = b[1]-a[1]
	local dy = b[2]-a[2]
	return (dx*dx+dy*dy)
end

-- sorts the elements of the given table between given indices
function sort_subtable( list, startIndex, endIndex, func)
	local tmp = {}
	for i=startIndex,endIndex do table.insert(tmp,list[i]) end
	table.sort(tmp,func)
	for i=startIndex,endIndex do list[i]=tmp[i-startIndex+1] end
end

-- returns a list with the ordinals of a random permutation of length len
function permutation( len )
	used = {}
	seq = {}
	for i=1,len do
		used[i]=0
	end
	for i=1,len do
		newnum = math.random(len-i+1)
		j=0
		while newnum>0 do
			j=j+1
			if used[j]==0 then
				newnum = newnum-1
			end
		end
		used[j]=1
		seq[i]=j
	end
	return seq
end

function find_route(from, to, map)
	local routeslist = {}
	local push_ndx = 1
	local pop_ndx = 1
	local found = false
	
	-- push starting pos
	routeslist[push_ndx] = {{from[1],from[2]},{from[1],from[2]},distanceSq(from,to)}
	push_ndx = push_ndx + 1
	
	while push_ndx ~= pop_ndx do
		  -- pop new element
		  local elem = {routeslist[pop_ndx][1][1],routeslist[pop_ndx][1][2]}
		  pop_ndx = pop_ndx + 1
		  
		  -- if we reached destination, break
		  if elem[1]==to[1] and elem[2]==to[2] then 
			found = true
			break 
		end
		
			local push_order = permutation(4)
			
		  -- generate neighbours
		  while table.getn(push_order) > 0 do
		  local nexttopush = push_order[1]
		  table.remove(push_order,1)
		  
		  -- up
		  if nexttopush==1 and elem[2]>1 and (map[elem[1]][elem[2]].u==1 or map[elem[1]][elem[2]].u==2) 
			and not table_indexOfFn(routeslist,function(x) return (x[1][1]==elem[1] and x[1][2]==elem[2]-1) end ) then
			routeslist[push_ndx] = {{elem[1],elem[2]-1},{elem[1],elem[2]},distanceSq({elem[1],elem[2]-1},to)}
			push_ndx = push_ndx + 1
		  end	
		-- down
		  if nexttopush==2 and elem[2]<map.vcells and (map[elem[1]][elem[2]].d==1 or map[elem[1]][elem[2]].d==2) 
			and not table_indexOfFn(routeslist,function(x) return (x[1][1]==elem[1] and x[1][2]==elem[2]+1) end ) then
			routeslist[push_ndx] = {{elem[1],elem[2]+1},{elem[1],elem[2]},distanceSq({elem[1],elem[2]+1},to)}
			push_ndx = push_ndx + 1
		  end
		-- left
		  if nexttopush==3 and elem[1]>1 and (map[elem[1]][elem[2]].l==1 or map[elem[1]][elem[2]].l==2) 
			and not table_indexOfFn(routeslist,function(x) return (x[1][1]==elem[1]-1 and x[1][2]==elem[2]) end ) then
			routeslist[push_ndx] = {{elem[1]-1,elem[2]},{elem[1],elem[2]},distanceSq({elem[1]-1,elem[2]},to)}
			push_ndx = push_ndx + 1
		  end
		-- right
		  if nexttopush==4 and elem[1]<map.hcells and (map[elem[1]][elem[2]].r==1 or map[elem[1]][elem[2]].r==2) 
			and not table_indexOfFn(routeslist,function(x) return (x[1][1]==elem[1]+1 and x[1][2]==elem[2]) end ) then
			routeslist[push_ndx] = {{elem[1]+1,elem[2]},{elem[1],elem[2]},distanceSq({elem[1]+1,elem[2]},to)}
			push_ndx = push_ndx + 1
		  end
		  
		end
	  
		-- sort remaining elements by distance
		sort_subtable( routeslist, pop_ndx, push_ndx, function(x,y) return (x[3]<y[3]) end )
		
	end
	
	-- if we reached destination, reconstruct path backwards
	if not found then
		return nil
	end

	local path = {}
	local nextpoint = {routeslist[pop_ndx-1][2][1],routeslist[pop_ndx-1][2][2]}
	table.insert(path,{to[1],to[2]})
	table.insert(path,1,{nextpoint[1],nextpoint[2]})
	while not (nextpoint[1]==from[1] and nextpoint[2]==from[2]) do
		local i = table_indexOfFn( routeslist, function(x) return (x[1][1]==nextpoint[1] and x[1][2]==nextpoint[2]) end )
		nextpoint = {routeslist[i][2][1],routeslist[i][2][2]}
		table.insert(path,1,{nextpoint[1],nextpoint[2]})
	end
	
	return path
end
