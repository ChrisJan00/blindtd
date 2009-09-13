
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

-- A* algorithm

-- find the first ocurrence of element with value "value"
function table_indexOf(table, value)
	for i,v in ipairs(table) do if v==value then return i end end
	return nil
end

-- find the first ocurrence of element wich fund(element.value) computes true
function table_indexOfFn(table, func)
	for i,v in ipairs(table) do if func(v) then return i end end
	return nil
end

function find_route(from, to, map)
	local routeslist = {}
	local push_ndx = 1
	local pop_ndx = 1
	local found = false
	
	-- push starting pos
	routeslist[push_ndx] = {{from[1],from[2]},{from[1],from[2]}}
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
		  
		  -- generate neighbours
		  -- up
		  if elem[2]>1 and (map[elem[1]][elem[2]].u==1 or map[elem[1]][elem[2]].u==2) 
			and not table_indexOfFn(routeslist,function(x) return (x[1][1]==elem[1] and x[1][2]==elem[2]-1) end ) then
			routeslist[push_ndx] = {{elem[1],elem[2]-1},{elem[1],elem[2]}}
			push_ndx = push_ndx + 1
		  end	
		-- down
		  if elem[2]<map.vcells and (map[elem[1]][elem[2]].d==1 or map[elem[1]][elem[2]].d==2) 
			and not table_indexOfFn(routeslist,function(x) return (x[1][1]==elem[1] and x[1][2]==elem[2]+1) end ) then
			routeslist[push_ndx] = {{elem[1],elem[2]+1},{elem[1],elem[2]}}
			push_ndx = push_ndx + 1
		  end
		-- left
		  if elem[1]>1 and (map[elem[1]][elem[2]].l==1 or map[elem[1]][elem[2]].l==2) 
			and not table_indexOfFn(routeslist,function(x) return (x[1][1]==elem[1]-1 and x[1][2]==elem[2]) end ) then
			routeslist[push_ndx] = {{elem[1]-1,elem[2]},{elem[1],elem[2]}}
			push_ndx = push_ndx + 1
		  end
		-- right
		  if elem[1]<map.hcells and (map[elem[1]][elem[2]].r==1 or map[elem[1]][elem[2]].r==2) 
			and not table_indexOfFn(routeslist,function(x) return (x[1][1]==elem[1]+1 and x[1][2]==elem[2]) end ) then
			routeslist[push_ndx] = {{elem[1]+1,elem[2]},{elem[1],elem[2]}}
			push_ndx = push_ndx + 1
		  end
	  
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
