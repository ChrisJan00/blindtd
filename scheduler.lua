
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
	--love.timer.getTime()
	love = { timer = { } }
	function love.timer.getTime()
		return os.clock()
	end
 	dofile("linkedlists.lua")
end

Scheduler = {}
Tasks = {}

Tasks.types = {
	urgent = 1,
	timed = 2,
	untimed = 3,
}

function Tasks.create( visitorInstance, ttype, iterationPeriod )
	if not iterationPeriod then iterationPeriod = 10000 end -- large
	local task={
		active = true,
		estimated_delay = 0,
		finished = false,
		visitor = visitorInstance,
		ready = false,
		time_alpha = 0.9,
		tasktype = ttype,
		period = iterationPeriod,
		timer = 0,
		dt = 0,
	}
	task.stopwatch = love.timer.getTime()
	return task
end

function Tasks.iteration(max_delay, task)
	if not task.ready then
		task.visitor.reset_loop()
		task.finished = false
		task.ready = true
		task.active = true
	end

	local elapsed=0
	local starttime = love.timer.getTime()
	local startwatch = starttime
	while (elapsed + task.estimated_delay < max_delay) and (not task.finished) do

		task.finished = task.visitor.iterate(task.dt)

		local stopwatch = love.timer.getTime()
		task.estimated_delay = task.time_alpha * task.estimated_delay + (1-task.time_alpha)*(stopwatch-startwatch)
		elapsed = stopwatch-starttime
		startwatch = stopwatch
	end
	if task.estimated_delay >= max_delay then
		-- timed out!
		task.estimated_delay = task.estimated_delay * task.time_alpha
	end

	if task.finished then
		task.visitor.finish_loop()
		task.active = false
	end
end

function Tasks.checkActive(task)
	local stopwatch = love.timer.getTime()
	task.dt = stopwatch - task.stopwatch
	task.stopwatch = stopwatch

	if task.tasktype == Tasks.types.timed then
		task.timer = task.timer - task.dt
		if task.timer <= 0 then
			if task.ready and not task.finished then print("Time Out!") end
			task.active = true
			task.ready = false
			task.timer = task.period
		end
	end
	return task.active
end


--- Scheduler
function Scheduler.newScheduler()
	local scheduler = {}
	scheduler.urgentTasks = List.newList()
	scheduler.timedTasks = List.newList()
	scheduler.untimedTasks = List.newList()
	scheduler.sleepingTasks = List.newList()
	return scheduler
end

function Scheduler.addTimedTask(scheduler, visitor, period)
	--scheduler.task = task
	local newtask = Tasks.create( visitor, Tasks.types.timed, period)
	List.pushBack(scheduler.sleepingTasks,newtask)
end

function Scheduler.addUntimedTask(scheduler, visitor)
	local newtask = Tasks.create( visitor, Tasks.types.untimed)
	List.pushBack(scheduler.untimedTasks, newtask)
end

function Scheduler.addUrgentTask(scheduler, visitor)
	local newtask = Tasks.create( visitor, Tasks.types.urgent)
	List.pushBack(scheduler.urgentTasks, newtask)
end

function Scheduler.iteration(scheduler, max_delay)
	local startclock = love.timer.getTime()
	local task

	-- Urgent tasks (must be finished now!)
	while scheduler.urgentTasks.n>0 do
		task = List.getFirst(scheduler.urgentTasks)
		local time_slot = (max_delay - (love.timer.getTime() - startclock))/scheduler.urgentTasks.n
		if time_slot < 0 then time_slot = max_delay end
		while task do
			if Tasks.checkActive(task) then
				Tasks.iteration(time_slot,task)
			else
				List.removeCurrent(scheduler.urgentTasks)
			end
			task = List.getNext(scheduler.urgentTasks)
		end
	end

	-- non-urgent tasks
	local estimated_delay = 0
	while love.timer.getTime()-startclock+estimated_delay < max_delay do
		local iterclock = love.timer.getTime()

		-- wake up sleeping tasks
		task = List.getFirst(scheduler.sleepingTasks)
		while task do
			if Tasks.checkActive(task) then
				List.pushBack(scheduler.timedTasks, task)
				List.removeCurrent(scheduler.sleepingTasks)
			end
			task = List.getNext(scheduler.sleepingTasks)
		end

		-- Timed tasks
		local taskcount = scheduler.timedTasks.n + scheduler.untimedTasks.n
		if scheduler.timedTasks.n > 0 then
			task = List.getFirst(scheduler.timedTasks)
			while task do
				local available_time = max_delay - (love.timer.getTime() - startclock)
				local time_slot = available_time / taskcount

				if Tasks.checkActive(task) then
					Tasks.iteration(time_slot, task)
				else
					List.pushBack(scheduler.sleepingTasks, task)
					List.removeCurrent(scheduler.timedTasks)
				end
				task = List.getNext(scheduler.timedTasks)
				taskcount = taskcount - 1
			end
		end

		-- Untimed tasks
		if scheduler.untimedTasks.n > 0 then
			task = List.getFirst(scheduler.untimedTasks)
			while task do
				local available_time = max_delay - (love.timer.getTime() - startclock)
				local time_slot = available_time / taskcount

				if Tasks.checkActive(task) then
					Tasks.iteration(time_slot, task)
				else
					List.removeCurrent(scheduler.untimedTasks)
				end
				task = List.getNext(scheduler.untimedTasks)
				taskcount = taskcount - 1
			end
		end
		estimated_delay = love.timer.getTime()-iterclock
	end
end


----------------------------------------------------
-- Example of usage
---------------------------------------------------------

--~ --- run test
--~ Visitor={}
--~ function Visitor.reset_loop()
--~ 	Visitor.i = 0
--~ 	Visitor.lim = 10
--~ 	Visitor.j = Visitor.j + 1
--~ end

--~ function Visitor.iterate(dt)
--~ 	local i,j
--~ 	local A={}
--~ 	local M=100
--~ 	for i=1,M do
--~ 		A[i]={}
--~ 		for j=1,M do
--~ 			A[i][M+1-j] = "chiska"
--~ 		end
--~ 	end

--~ 	Visitor.i = Visitor.i + 1
--~ 	print(Visitor.j.." a "..Visitor.i)
--~ 	if Visitor.i==Visitor.lim then return true end
--~ 	return false
--~ end

--~ function Visitor.finish_loop()
--~ end

--~ Visitor.j = 0

--~ Visitor2={}
--~ function Visitor2.reset_loop()
--~ 	Visitor2.i = 0
--~ 	Visitor2.lim = 20
--~ end

--~ function Visitor2.iterate(dt)
--~ 	local i,j
--~ 	local A={}
--~ 	local M=200
--~ 	for i=1,M do
--~ 		A[i]={}
--~ 		for j=1,M do
--~ 			A[i][M+1-j] = "chiska"
--~ 		end
--~ 	end

--~ 	Visitor2.i = Visitor2.i + 1
--~ 	print(" b "..Visitor2.i)
--~ 	if Visitor2.i==Visitor2.lim then return true end
--~ 	return false
--~ end

--~ function Visitor2.finish_loop()
--~ end

--~ Visitor3={}
--~ function Visitor3.reset_loop()
--~ 	Visitor3.i = 0
--~ 	Visitor3.lim = 100
--~ end

--~ function Visitor3.iterate(dt)

--~ 	Visitor3.i = Visitor3.i + 1
--~ 	print(" c "..Visitor3.i)
--~ 	if Visitor3.i==Visitor3.lim then return true end
--~ 	return false
--~ end

--~ function Visitor3.finish_loop()
--~ end

--~ sched = Scheduler.newScheduler()
--~ Scheduler.addTimedTask(sched, Visitor, 1)
--~ Scheduler.addUntimedTask(sched, Visitor2)
--~ Scheduler.addUrgentTask(sched, Visitor3)

--~ local totallimit = 1000
--~ while Visitor.j<10 do
--~ 	Scheduler.iteration(sched, 0.1)
--~ end


