
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


-- returns manhattan distance
function distanceMh(a,b)
	local dx = b[1]-a[1]
	local dy = b[2]-a[2]
	return (math.abs(dx)+math.abs(dy))
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

-- The algorithm (in one single function)
function findRoute(from, to, map)
	local routeslist = List()
	local visitedlist = List()
	local found = false

	local visited_marks = {}
	local i
	for i=1,map.hcells do
		visited_marks[i]={}
	end

	-- push starting pos
	routeslist:pushFront({{from[1],from[2]},{from[1],from[2]},0},distanceMh(from,to))
	visited_marks[from[1]][from[2]]=1

	while routeslist.n>0 do
		local item = routeslist:popFront()
		visitedlist:pushBack(item)
		local elem = {item[1][1],item[1][2]}
		local steps = item[3]

		-- if we reached destination, break
		if elem[1]==to[1] and elem[2]==to[2] then
			found = true
			break
		end

		-- up
		if elem[2]>1 and (map[elem[1]][elem[2]].u==1 or map[elem[1]][elem[2]].u==2)
			and not visited_marks[elem[1]][elem[2]-1] then
			local newdist = distanceMh({elem[1],elem[2]-1},to)+steps
			routeslist:pushFrontSorted({{elem[1],elem[2]-1},{elem[1],elem[2]},steps+1},newdist)
			visited_marks[elem[1]][elem[2]-1]=1
		end
		-- down
		if elem[2]<map.vcells and (map[elem[1]][elem[2]].d==1 or map[elem[1]][elem[2]].d==2)
			and not visited_marks[elem[1]][elem[2]+1] then
			local newdist = distanceMh({elem[1],elem[2]+1},to)+steps
			routeslist:pushFrontSorted({{elem[1],elem[2]+1},{elem[1],elem[2]},steps+1},newdist)
			visited_marks[elem[1]][elem[2]+1]=1
		end
		-- left
		if elem[1]>1 and (map[elem[1]][elem[2]].l==1 or map[elem[1]][elem[2]].l==2)
			and not visited_marks[elem[1]-1][elem[2]] then
			local newdist = distanceMh({elem[1]-1,elem[2]},to)+steps
			routeslist:pushFrontSorted({{elem[1]-1,elem[2]},{elem[1],elem[2]},steps+1},newdist)
			visited_marks[elem[1]-1][elem[2]]=1
		end
		-- right
		if elem[1]<map.hcells and (map[elem[1]][elem[2]].r==1 or map[elem[1]][elem[2]].r==2)
			and not visited_marks[elem[1]+1][elem[2]] then
			local newdist = distanceMh({elem[1]+1,elem[2]},to)+steps
			routeslist:pushFrontSorted({{elem[1]+1,elem[2]},{elem[1],elem[2]},steps+1},newdist)
			visited_marks[elem[1]+1][elem[2]]=1
		end
	end

	routeslist:discard()

	-- if we reached destination, reconstruct path backwards
	if not found then
		return nil
	end

	local path = {}
	-- the last pushed item is the destination
 	local item = visitedlist:popBack()
	local nextpoint = {item[2][1],item[2][2]}
	table.insert(path,{to[1],to[2]})
	table.insert(path,1,{nextpoint[1],nextpoint[2]})
	while not (nextpoint[1]==from[1] and nextpoint[2]==from[2]) do
		-- search next point in the list
		while not (item[1][1]==nextpoint[1] and item[1][2]==nextpoint[2]) do
			item = visitedlist:getPrev()
			if not item then item = visitedlist:getLast() end
		end
		-- push it to the path
		nextpoint = {item[2][1],item[2][2]}
		table.insert(path,1,{nextpoint[1],nextpoint[2]})
		-- we can skip it the next time we are searching
--~ 		visitedlist:removeCurrent()
	end

	visitedlist:discard()

	return path
end


-- scheduler-friendly version

RouteFinder = class(GenericVisitor,function(rf,from,to,map,pathcontainer)
	rf.from = from
	rf.to = to
	rf.map = map
	rf.pathcontainer = pathcontainer
end)

function RouteFinder:reset_loop()
	self.routeslist = List()
	self.visitedlist = List()
	self.found = false
	self.path = {}

	self.visited_marks = {}
	local i
	for i=1,self.map.hcells do
		self.visited_marks[i]={}
	end

	-- push starting pos
	self.routeslist:pushFront({{self.from[1],self.from[2]},{self.from[1],self.from[2]},0},distanceMh(self.from,self.to))
	self.visited_marks[self.from[1]][self.from[2]]=1
end

-- The algorithm
function RouteFinder:iteration(dt)
	local from = self.from
	local to = self.to
	if not self.found and self.routeslist.n>0 then
		local map = self.map

		local item = self.routeslist:popFront()
		self.visitedlist:pushBack(item)
		local elem = {item[1][1],item[1][2]}
		local steps = item[3]

		-- if we reached destination, break
		if elem[1]==to[1] and elem[2]==to[2] then
			self.found = true
		else

			-- up
			if elem[2]>1 and (map[elem[1]][elem[2]].u==1 or map[elem[1]][elem[2]].u==2)
				and not self.visited_marks[elem[1]][elem[2]-1] then
				local newdist = distanceMh({elem[1],elem[2]-1},to)+steps
				self.routeslist:pushFrontSorted({{elem[1],elem[2]-1},{elem[1],elem[2]},steps+1},newdist)
				self.visited_marks[elem[1]][elem[2]-1]=1
			end
			-- down
			if elem[2]<map.vcells and (map[elem[1]][elem[2]].d==1 or map[elem[1]][elem[2]].d==2)
				and not self.visited_marks[elem[1]][elem[2]+1] then
				local newdist = distanceMh({elem[1],elem[2]+1},to)+steps
				self.routeslist:pushFrontSorted({{elem[1],elem[2]+1},{elem[1],elem[2]},steps+1},newdist)
				self.visited_marks[elem[1]][elem[2]+1]=1
			end
			-- left
			if elem[1]>1 and (map[elem[1]][elem[2]].l==1 or map[elem[1]][elem[2]].l==2)
				and not self.visited_marks[elem[1]-1][elem[2]] then
				local newdist = distanceMh({elem[1]-1,elem[2]},to)+steps
				self.routeslist:pushFrontSorted({{elem[1]-1,elem[2]},{elem[1],elem[2]},steps+1},newdist)
				self.visited_marks[elem[1]-1][elem[2]]=1
			end
			-- right
			if elem[1]<map.hcells and (map[elem[1]][elem[2]].r==1 or map[elem[1]][elem[2]].r==2)
				and not self.visited_marks[elem[1]+1][elem[2]] then
				local newdist = distanceMh({elem[1]+1,elem[2]},to)+steps
				self.routeslist:pushFrontSorted({{elem[1]+1,elem[2]},{elem[1],elem[2]},steps+1},newdist)
				self.visited_marks[elem[1]+1][elem[2]]=1
			end
		end
	elseif self.found then
		if table.getn(self.path)==0 then
			-- the last pushed item is the destination
			self.item = self.visitedlist:popBack()
			self.nextpoint = {self.item[2][1],self.item[2][2]}
			table.insert(self.path,{to[1],to[2]})
			table.insert(self.path,1,{self.nextpoint[1],self.nextpoint[2]})
		end

		if not (self.nextpoint[1]==from[1] and self.nextpoint[2]==from[2]) then
			-- search next point in the list
			while not (self.item[1][1]==self.nextpoint[1] and self.item[1][2]==self.nextpoint[2]) do
				self.item = self.visitedlist:getPrev()
				if not self.item then self.item = self.visitedlist:getLast() end
			end
			-- push it to the path
			self.nextpoint = {self.item[2][1],self.item[2][2]}
			table.insert(self.path,1,{self.nextpoint[1],self.nextpoint[2]})
			-- we can skip it the next time we are searching
			-- self.visitedlist:removeCurrent()
		end
	end

	if table.getn(self.path)>0 and self.path[1][1]==self.from[1] and self.path[1][2]==self.from[2] then
		return true
	else
		return false
	end
end

function RouteFinder:finish_loop()
	self.routeslist:discard()
	self.visitedlist:discard()
	self.pathcontainer.path = self.path
end
