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

-- actuators

Actuators_map = {}

function initActuators()
	local i,j
	for i=1,20 do
	Actuators_map[i]={}
	for j=1,20 do
	Actuators.map[i][j]=List()
	end
	end
end

function addActuator(ref)
	local cell = ref.cellslist:getFirst()
	while cell do
		Actuators_map[cell[1]][cell[2]]:pushBack(ref)
		cell = ref.cellslist:getNext()
	end
end

function removeActuator(ref)
	local cell = ref.cellslist:getFirst()
	while cell do
		Actuators_map[cell[1]][cell[2]]:remove(ref)
		cell = ref.cellslist:getNext()
	end
end

function activateActuator( who )
	local ref = Actuators_map[who.pos[1]][who.pos[2]]:getFirst()
	while ref do
		ref:activate( who )
		ref = Actuators_map[who.pos[1]][who.pos[2]]:getNext()
	end
end

-------------------

-- actuator class
-- add in single position
-- add in radius "absolute" (manhattan distance)
-- add in radius "absolute" (euclidean distance)
-- add in walking distance ( what happens with the doors?
  -- when a door is found, mark the next cells specially (with a reference to the offending door)...
  -- but what if
  --  A
  --  d d
  --  x
  -- "x" will be active if at least one of the doors is open.
-- well, we can add the actuator in these cells no matter what, and then in the activate method check if there is a valid way actually, using A*

Actuator = class(function(act)
end
)

function Actuator:set(pos,radius)
end

function Actuator:activate( who )
end

--------------------------
-- there is a map where each cell is a list of references to an actuator instance
-- when an entity steps in the cell, all referenced actuators are called

-- the actuator has a list of cells in which it is present, so when it has to be erased it nows who to call
-- it has a callback method that applies the effect of the actuator when it is called
-- examples:  door -> open
-- gun -> fire bullet
-- mine -> explode
-- bomb -> this has a timer, does not react to presence of the entity but explodes after certain time
-- electronic blast -> stuns the enemies, disables doors nearby
-- laser blast -> kills one enemy, but then it has to be activated again
