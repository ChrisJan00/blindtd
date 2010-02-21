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


-- Double Linked Lists

List = {}

-- create list
function List.newList()
	local list = {}
	list.first = {next=nil, prev=nil, ref=nil, val=nil}
	list.last = {next=nil, prev=nil, ref=nil, val=nil}
	list.current = list.first
	list.n = 0
	return list
end

function List.discard(list)
	local next = list.first.next
	local this = list.first
	while this do
		this.next = nil
		this.prev = nil
		this.ref = nil
		this.value = nil
		this = next
		if this then
			next = this.next
		end
	end
	list.first = {next=nil, prev=nil, ref=nil, val=nil}
	list.last = {next=nil, prev=nil, ref=nil, val=nil}
	list.current = list.first
	list.n = 0
end

-- push and pop functions
function List.pushFront(list, obj, value)
	if not value then value=0 end
	local new = { next = nil, prev = nil, ref = obj, val = value }
	if list.n>0 then
		list.first.prev = new
		new.next = list.first
	else
		list.last = new
	end

	list.first = new
	list.n = list.n + 1
end

function List.pushBack(list, obj, value)
	if not value then value=0 end
	local new = { next = nil, prev = nil, ref = obj, val = value }
	if list.n>0 then
		list.last.next = new
		new.prev = list.last
	else
		list.first = new
	end

	list.last = new
	list.n = list.n + 1
end

function List.popFront(list)
	if list.n==0 then return nil end
	local retval = list.first.ref
	local newfirst = list.first.next
	list.first.next = nil
	if newfirst then
		list.first = newfirst
		newfirst.prev = nil
		list.n = list.n - 1
	else
		List.discard(list)
	end
	return retval
end

function List.popBack(list)
	if list.n==0 then return nil end
	local retval = list.last.ref
	local newlast = list.last.prev
	list.last.prev = nil
	if newlast then
		list.last = newlast
		newlast.next = nil
		list.n = list.n - 1
	else
		List.discard(list)
	end
	return retval
end

-- read functions
function List.getFirst(list)
	if list.n==0 then return nil end
	list.current = list.first
	return list.current.ref
end

function List.getNext(list)
	if not list.current.next then return nil end
	list.current = list.current.next
	return list.current.ref
end

function List.getPrev(list)
	if not list.current.prev then return nil end
	list.current = list.current.prev
	return list.current.ref
end

function List.getLast(list)
	if list.n==0 then return nil end
	list.current = list.last
	return list.current.ref
end

function List.getCurrent(list)
	return list.current.ref
end

-- remove current (use in combination with get*)
function List.removeCurrent(list)
	if list.n == 0 then return end
	if list.n == 1 then
		List.discard(list)
		return
	end

	if list.current.next and list.current.prev then
		list.current.next.prev = list.current.prev
		list.current.prev.next = list.current.next
--~ 		list.current = list.current.next
		list.current.ref = nil
		list.n = list.n - 1
		return
	end

	-- first
	if list.current == list.first then
		list.first = list.first.next
		list.first.prev = nil
		list.current.next = nil
--~ 		list.current = list.first
		list.current.ref = nil
		list.n = list.n - 1
		return
	end

	-- last
	if list.current == list.last then
		list.last = list.last.prev
		list.last.next = nil
		list.current.prev = nil
--~ 		list.current = list.last
		list.current.ref = nil
		list.n = list.n - 1
		return
	end
end

-- insert after current
function List.insert(list, obj, value)
	if not value then value=0 end

	if list.n<2 or list.current==list.last then
		List.pushBack(list,obj,value)
		return
	end

	local new = { next = list.current.next, prev = list.current, ref = obj, val = value }
	list.current.next = new
	new.next.prev = new
	list.n = list.n + 1
end

--- sorting
function List.pushFrontSorted(list, obj, value)
	if not value then value=0 end
	if list.n==0 then
		List.pushFront(list,obj,value)
		return
	end
	if list.first.val > value then
		List.pushFront(list,obj,value)
		return
	end

	local elem = List.getFirst( list )
	while elem and list.current.val < value do elem=List.getNext(list) end
	if not elem then
		List.pushBack(list,obj,value)
	else
		List.getPrev(list)
		List.insert(list,obj,value)
	end
end

function List.pushBackSorted(list, obj, value)
	if not value then value=0 end
	if list.n == 0 then
		List.pushBack(list,obj,value)
		return
	end
	if list.last.val < value then
		List.pushBack(list,obj,value)
		return
	end

	local elem = List.getLast( list )
	while elem and list.current.val > value do elem=List.getPrev(list) end
	if not elem then
		List.pushFront(list,obj,value)
	else
		List.insert(list,obj,value)
	end
end

-- changes the value of the current object and sorts again
function List.changeValue(list, value)
	if not value then value=0 end
	if list.current.val == value then return end

	local savedref = list.current.ref
	local oldval = list.current.val
	local newval = value
	local oldprev = list.current.prev

	List.removeCurrent(list)

	if newval>oldval then
		-- move up
		elem = List.getNext(list)
		while elem and list.current.val < value do elem = List.getNext(list) end
		if not elem then
			List.pushBack(list,savedref,value)
		else
			List.getPrev(list)
			List.insert(list,savedref,value)
		end
	else
		-- move down
		local elem = List.getPrev( list )
		while elem and list.current.val > value do elem=List.getPrev(list) end
		if not elem then
			List.pushFront(list,savedref,value)
		else
			List.insert(list,savedref,value)
		end
	end

	-- not sure about this...
	list.current = oldprev
end

--~ -- Example of use (make the condition true to test)
if false then
	list = List.newList()
	List.pushBack(list,"abc")
	List.pushBack(list,"cde")
	List.pushBack(list,"def")

	-- print
	elem = List.getFirst(list)
	while elem do
		print(elem)
		elem = List.getNext(list)
	end

	-- reset
	print()
	List.discard(list)

	-- sort while inserting
	List.pushFrontSorted(list,"iii",3)
	List.pushFrontSorted(list,"ooo",4)
	List.pushFrontSorted(list,"aaa",1)

	-- print in reverse order (from high to low)
	elem = List.popBack(list)
	while elem do
		print(elem)
		elem = List.popBack(list)
	end

	List.discard(list)
end
