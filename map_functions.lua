
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


function saveMap( map )
	local mapString = "Map = {\n" ..
		"hcells = " .. map.hcells .. ",\nvcells = " .. map.vcells .. ",\n"

	local corridor -- for translating true/false to string

	for i=1, map.hcells do
		mapString = mapString .. "{\n"
		for j=1, map.vcells do
			if map[i][j].corridor then
				corridor = "true"
			else
				corridor = "false"
			end
			mapString = mapString .. " {\n" .. "  u = " .. map[i][j].u .. ",\n" ..
			"  d = " .. map[i][j].d .. ",\n" ..
			"  l = " .. map[i][j].l .. ",\n" ..
			"  r = " .. map[i][j].r .. ",\n" ..
			"  corridor = " .. corridor .. ",\n},"
		end
		mapString = mapString .. " },\n"
	end
	mapString = mapString .. "\n}"
	local date = os.date("%Y-%m-%d-%H-%M-%S")
	local file = love.filesystem.newFile( "mapSave-" .. date .. ".lua", love.file_write)
	love.filesystem.open(file)
	love.filesystem.write(file, mapString)
	love.filesystem.close(file)
end

function loadMap( mapName )
	love.filesystem.require("maps/" .. mapName .. ".lua")
end

function openMap( map )
	Map = map
end
