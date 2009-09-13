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
			mapString = mapString .. "{\n" .. "u = " .. map[i][j].u .. ",\n" ..
			"d = " .. map[i][j].d .. ",\n" ..
			"l = " .. map[i][j].l .. ",\n" ..
			"r = " .. map[i][j].r .. ",\n" ..
			"corridor = " .. corridor .. ",\n},"
		end
		mapString = mapString .. "},"
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
