
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

if not love then
	require 'class'
	require 'linkedlists'

	--love.timer.getTime()
	love = { timer = { } }
	function love.timer.getTime()
		return os.clock()
	end
end

--~ Tasks = {}

--~ Tasks.types = {
--~ 	urgent = 1,
--~ 	timed = 2,
--~ 	untimed = 3,
--~ }
Task = class( function(task, visitorInstance)
--~ 	if not iterationPeriod then iterationPeriod = 10000 end -- large
	task.active = true
	task.estimated_delay = 0
	task.finished = false
	task.visitor = visitorInstance
	task.ready = false
	task.time_alpha = 0.9
	task.period = 10000
	task.timer = 0
	task.dt = 0
	task.stopwatch = love.timer.getTime()
end)

--~ function Tasks.create( visitorInstance, ttype, iterationPeriod )
--~ 	if not iterationPeriod then iterationPeriod = 10000 end -- large
--~ 	local task={
--~ 		active = true,
--~ 		estimated_delay = 0,
--~ 		finished = false,
--~ 		visitor = visitorInstance,
--~ 		ready = false,
--~ 		time_alpha = 0.9,
--~ 		tasktype = ttype,
--~ 		period = iterationPeriod,
--~ 		timer = 0,
--~ 		dt = 0,
--~ 	}
--~ 	task.stopwatch = love.timer.getTime()
--~ 	return task
--~ end

function Task:iteration(max_delay)
	if not self.ready then
		self.visitor.reset_loop()
		self.finished = false
		self.ready = true
		self.active = true
	end

	local elapsed=0
	local starttime = love.timer.getTime()
	local startwatch = starttime
	while (elapsed + self.estimated_delay < max_delay) and (not self.finished) do

		self.finished = self.visitor.iterate(self.dt)

		local stopwatch = love.timer.getTime()
		self.estimated_delay = self.time_alpha * self.estimated_delay + (1-self.time_alpha)*(stopwatch-startwatch)
		elapsed = stopwatch-starttime
		startwatch = stopwatch
	end
	if self.estimated_delay >= max_delay then
		-- timed out!
		self.estimated_delay = self.estimated_delay * self.time_alpha
	end

	if self.finished then
		self.visitor.finish_loop()
		self.active = false
	end
end

function Task:checkActive()
	local stopwatch = love.timer.getTime()
	self.dt = stopwatch - self.stopwatch
	self.stopwatch = stopwatch

	return self.active
end

UrgentTask = class(Task)
UntimedTask = class(Task)
TimedTask = class(Task, function(timedtask,visitorInstance,iterationPeriod)
	timedtask._base.init(timedtask,visitorInstance)
	timedtask.period = iterationPeriod or 10000
end)


function TimedTask:checkActive()
	-- calling superclass method does not work, copypasting the code
--~ 	self._base:checkActive()

	local stopwatch = love.timer.getTime()
	self.dt = stopwatch - self.stopwatch
	self.stopwatch = stopwatch

	self.timer = self.timer - self.dt
	if self.timer <= 0 then
		if self.ready and not self.finished then print("Time Out!") end
		self.active = true
		self.ready = false
		self.timer = self.period
	end

	return self.active
end

--- Scheduler
Scheduler = class( function(scheduler)
	scheduler.urgentTasks = List()
	scheduler.timedTasks = List()
	scheduler.untimedTasks = List()
	scheduler.sleepingTasks = List()
end )

function Scheduler:addTimedTask(visitor, period)
--~ 	local newtask = Tasks.create( visitor, Tasks.types.timed, period)
	self.sleepingTasks:pushBack(TimedTask(visitor,period))
end

function Scheduler:addUntimedTask(visitor)
--~ 	local newtask = Tasks.create( visitor, Tasks.types.untimed)
	self.untimedTasks:pushBack(UntimedTask(visitor))
end

function Scheduler:addUrgentTask(visitor)
--~ 	local newtask = Tasks.create( visitor, Tasks.types.urgent)
	self.urgentTasks:pushBack(UrgentTask(visitor))
end

function Scheduler:iteration(max_delay)
	local startclock = love.timer.getTime()
	local task

	-- Urgent tasks (must be finished now!)
	while self.urgentTasks.n>0 do
		task = self.urgentTasks:getFirst()
		local time_slot = (max_delay - (love.timer.getTime() - startclock))/self.urgentTasks.n
		if time_slot < 0 then time_slot = max_delay end
		while task do
			if task:checkActive() then
				task:iteration(time_slot)
			else
				self.urgentTasks:removeCurrent()
			end
			task = self.urgentTasks:getNext()
		end
	end

	-- non-urgent tasks
	local estimated_delay = 0
	while love.timer.getTime()-startclock+estimated_delay < max_delay do
		local iterclock = love.timer.getTime()

		-- wake up sleeping tasks
		task = self.sleepingTasks:getFirst()
		while task do
			if task:checkActive() then
				self.timedTasks:pushBack(task)
				self.sleepingTasks:removeCurrent()
			end
			task = self.sleepingTasks:getNext()
		end

		-- Timed tasks
		local taskcount = self.timedTasks.n + self.untimedTasks.n
		if self.timedTasks.n > 0 then
			task = self.timedTasks:getFirst()
			while task do
				local available_time = max_delay - (love.timer.getTime() - startclock)
				local time_slot = available_time / taskcount

				if task:checkActive() then
					task:iteration(time_slot)
				else
					self.sleepingTasks:pushBack(task)
					self.timedTasks:removeCurrent()
				end
				task = self.timedTasks:getNext()
				taskcount = taskcount - 1
			end
		end

		-- Untimed tasks
		if self.untimedTasks.n > 0 then
			task = self.untimedTasks:getFirst()
			while task do
				local available_time = max_delay - (love.timer.getTime() - startclock)
				local time_slot = available_time / taskcount

				if task:checkActive() then
					task:iteration(time_slot)
				else
					self.untimedTasks:removeCurrent()
				end
				task = self.untimedTasks:getNext()
				taskcount = taskcount - 1
			end
		end
		estimated_delay = love.timer.getTime()-iterclock
	end
end


----------------------------------------------------
-- Example of usage
---------------------------------------------------------
if false then
--- run test
Visitor={}
function Visitor.reset_loop()
	Visitor.i = 0
	Visitor.lim = 10
	Visitor.j = Visitor.j + 1
end

function Visitor.iterate(dt)
	local i,j
	local A={}
	local M=100
	for i=1,M do
		A[i]={}
		for j=1,M do
			A[i][M+1-j] = "chiska"
		end
	end

	Visitor.i = Visitor.i + 1
	print(Visitor.j.." timed "..Visitor.i)
	if Visitor.i==Visitor.lim then return true end
	return false
end

function Visitor.finish_loop()
end

Visitor.j = 0

Visitor2={}
function Visitor2.reset_loop()
	Visitor2.i = 0
	Visitor2.lim = 20
end

function Visitor2.iterate(dt)
	local i,j
	local A={}
	local M=200
	for i=1,M do
		A[i]={}
		for j=1,M do
			A[i][M+1-j] = "chiska"
		end
	end

	Visitor2.i = Visitor2.i + 1
	print("untimed "..Visitor2.i)
	if Visitor2.i==Visitor2.lim then return true end
	return false
end

function Visitor2.finish_loop()
end

Visitor3={}
function Visitor3.reset_loop()
	Visitor3.i = 0
	Visitor3.lim = 100
end

function Visitor3.iterate(dt)

	Visitor3.i = Visitor3.i + 1
	print("urgent "..Visitor3.i)
	if Visitor3.i==Visitor3.lim then return true end
	return false
end

function Visitor3.finish_loop()
end

sched = Scheduler()
sched:addTimedTask(Visitor, 1)
sched:addUntimedTask( Visitor2)
sched:addUrgentTask( Visitor3)

local totallimit = 1000
while Visitor.j<10 do
	sched:iteration( 0.1)
end
end
