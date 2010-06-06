
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

Task = class( function(task, visitorInstance)
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
	task.activity_stopwatch = task.stopwatch
end)

function Task:iteration(max_delay)
	if not self.ready then
		self.visitor:reset_loop()
		self.finished = false
		self.ready = true
		self.active = true
	end

	local elapsed=0
	local starttime = love.timer.getTime()
	local startwatch = starttime

	while (elapsed + self.estimated_delay < max_delay) and (not self.finished) do

		self.finished = self.visitor:iteration(self.dt)

		local stopwatch = love.timer.getTime()
		self.dt = stopwatch - self.stopwatch
		self.stopwatch = stopwatch

		self.estimated_delay = self.time_alpha * self.estimated_delay + (1-self.time_alpha)*(stopwatch-startwatch)
		elapsed = stopwatch-starttime
		startwatch = stopwatch
	end
	if self.estimated_delay >= max_delay then
		-- timed out!
		self.estimated_delay = self.estimated_delay * self.time_alpha
	end

	if self.finished then
		self.visitor:finish_loop()
		self.active = false
	end
end

function Task:checkActive()
	self.activity_stopwatch = love.timer.getTime()
	return self.active
end

UrgentTask = class(Task)
UntimedTask = class(Task)
SerialTask = class(Task)
TimedTask = class(Task, function(timedtask,visitorInstance,iterationPeriod)
	timedtask._base.init(timedtask,visitorInstance)
	timedtask.period = iterationPeriod or 10000
end)


function TimedTask:checkActive()
	local stopwatch = love.timer.getTime()
	self.timer = self.timer - (stopwatch - self.activity_stopwatch)
	self.activity_stopwatch = stopwatch
	if self.timer <= 0 then
		if self.ready and not self.finished then
			-- skip iteration
--~ 			print("Time Out!")
		else
			self.active = true
			self.ready = false
			self.timer = self.period
		end
	end

	return self.active
end

--- Scheduler
Scheduler = class( function(scheduler)
	scheduler.urgentTasks = List()
	scheduler.timedTasks = List()
	scheduler.untimedTasks = List()
	scheduler.sleepingTasks = List()
	scheduler.serialTasks = List()
end )

function Scheduler:addTimedTask(visitor, period)
	self.sleepingTasks:pushBack(TimedTask(visitor,period))
end

function Scheduler:addUntimedTask(visitor)
	self.untimedTasks:pushBack(UntimedTask(visitor))
end

function Scheduler:addUrgentTask(visitor)
	self.urgentTasks:pushBack(UrgentTask(visitor))
end

function Scheduler:addSerialTask(visitor)
	self.serialTasks:pushBack(SerialTask(visitor))
end

function Scheduler:cancel(visitor)
	task = self.urgentTasks:getFirst()
	while task do
		if task.visitor == visitor then
			self.urgentTasks:removeCurrent()
			return
		end
		task = self.urgentTasks:getNext()
	end

	task = self.timedTasks:getFirst()
	while task do
		if task.visitor == visitor then
			self.timedTasks:removeCurrent()
			return
		end
		task = self.timedTasks:getNext()
	end

	task = self.sleepingTasks:getFirst()
	while task do
		if task.visitor == visitor then
			self.sleepingTasks:removeCurrent()
			return
		end
		task = self.sleepingTasks:getNext()
	end

	task = self.untimedTasks:getFirst()
	while task do
		if task.visitor == visitor then
			self.untimedTasks:removeCurrent()
			return
		end
		task = self.untimedTasks:getNext()
	end

	task = self.serialTasks:getFirst()
	while task do
		if task.visitor == visitor then
			self.serialTasks:removeCurrent()
			return
		end
		task = self.serialTasks:getNext()
	end
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

		-- see how many tasks are alive
		local taskcount = self.timedTasks.n + self.untimedTasks.n + self.serialTasks.n
		if taskcount == 0 then
			break
		end

		-- Serial tasks
		if self.serialTasks.n > 0 then
			task = self.serialTasks:getFirst()
			if task then
				local available_time = max_delay - (love.timer.getTime() - startclock)
				local time_slot = available_time / taskcount

				if task:checkActive() then
					task:iteration(time_slot)
				else
					self.serialTasks:removeCurrent()
				end
				taskcount = taskcount - 1
			end
		end

		-- Timed tasks
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

-- subclass this for the scheduler
GenericVisitor = class(function(vis) end)

function GenericVisitor:reset_loop()
end

function GenericVisitor:iteration(dt)
	return true
end

function GenericVisitor:finish_loop()
end

----------------------------------------------------
-- Example of usage
---------------------------------------------------------
if false then
	--- run test
	Visitor=class(GenericVisitor,function(vis)
		vis.j=0
	end)

	function Visitor:reset_loop()
		self.i = 0
		self.lim = 10
		self.j = self.j + 1
	end

	function Visitor:iteration(dt)
		local i,j
		local A={}
		local M=100
		for i=1,M do
			A[i]={}
			for j=1,M do
				A[i][M+1-j] = "chiska"
			end
		end

		self.i = self.i + 1
		print(self.j.." timed "..self.i)
		if self.i==self.lim then return true end
		return false
	end

	-- no need to overload these
	--function Visitor:finish_loop()
	--end

	Visitor2=class(GenericVisitor)
	function Visitor2:reset_loop()
		self.i = 0
		self.lim = 20
	end

	function Visitor2:iteration(dt)
		local i,j
		local A={}
		local M=200
		for i=1,M do
			A[i]={}
			for j=1,M do
				A[i][M+1-j] = "chiska"
			end
		end

		self.i = self.i + 1
		print("untimed "..self.i)
		if self.i==self.lim then return true end
		return false
	end


	Visitor3=class(GenericVisitor)
	function Visitor3:reset_loop()
		self.i = 0
		self.lim = 100
	end

	function Visitor3:iteration(dt)
		self.i = self.i + 1
		print("urgent "..self.i)
		if self.i==self.lim then return true end
		return false
	end


	sched = Scheduler()
	timedvisitor = Visitor()
	sched:addTimedTask(timedvisitor, 1)
	sched:addUntimedTask( Visitor2() )
	sched:addUrgentTask( Visitor3() )

	local totallimit = 1000
	while timedvisitor.j<10 do
		sched:iteration( 0.1)
	end
end
