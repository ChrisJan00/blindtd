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

function love.load()

	-- Dependencies
	love.filesystem.load("class.lua")()
	love.filesystem.load("linkedlists.lua")()
	love.filesystem.load("scheduler.lua")()
	love.filesystem.load("game.lua")()
	love.filesystem.load("map_functions.lua")()
	love.filesystem.load("generator.lua")()

	-- Maps
	maps = {}
--~ 	loadMap("lines")
	-- Initialization
	start_time = love.timer.getTime()

	math.randomseed(os.time())

	-- Init graphics mode
       screensize = { 640, 480 }
       love.window.setMode(screensize[1],screensize[2])

	-- Audio system
	love.audio.setVolume(.3)

	-- Text
--~ 	love.graphics.setFont("default")
	love.graphics.setFont(love.graphics.newFont(16))

	Game.load()

end

function love.update(dt)

	Game.update(dt)

end


function love.draw()
	Game.draw()
end


function love.keypressed(key)
	Game.keypressed(key)
end


function love.keyreleased(key)
	Game.keyreleased(key)
end


function love.mousepressed(x, y, button)
	Game.mousepressed(x,y,button)

end



function love.mousereleased(x, y, button)

	Game.mousereleased(x,y, button)

end



