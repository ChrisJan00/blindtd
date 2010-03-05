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
if not love then
	require 'class'
end

List = class( function(list)
	list.first = {next=nil, prev=nil, ref=nil, val=nil}
	list.last = {next=nil, prev=nil, ref=nil, val=nil}
	list.current = list.first
	list.n = 0
end )

function List:discard()
	local next = self.first.next
	local elem = self.first
	while elem do
		elem.next = nil
		elem.prev = nil
		elem.ref = nil
		elem.value = nil
		elem = next
		if elem then
			next = elem.next
		end
	end
	self.first = {next=nil, prev=nil, ref=nil, val=nil}
	self.last = {next=nil, prev=nil, ref=nil, val=nil}
	self.current = self.first
	self.n = 0
end

-- push and pop functions
function List:pushFront(obj, value)
	if not value then value=0 end
	local new = { next = nil, prev = nil, ref = obj, val = value }
	if self.n>0 then
		self.first.prev = new
		new.next = self.first
	else
		self.last = new
	end

	self.first = new
	self.n = self.n + 1
end

function List:pushBack(obj, value)
	if not value then value=0 end
	local new = { next = nil, prev = nil, ref = obj, val = value }
	if self.n>0 then
		self.last.next = new
		new.prev = self.last
	else
		self.first = new
	end

	self.last = new
	self.n = self.n + 1
end

function List:popFront()
	if self.n==0 then return nil end
	local retval = self.first.ref
	local newfirst = self.first.next
	self.first.next = nil
	if newfirst then
		self.first = newfirst
		newfirst.prev = nil
		self.n = self.n - 1
	else
		self:discard()
	end
	return retval
end

function List:popBack()
	if self.n==0 then return nil end
	local retval = self.last.ref
	local newlast = self.last.prev
	self.last.prev = nil
	if newlast then
		self.last = newlast
		newlast.next = nil
		self.n = self.n - 1
	else
		self:discard()
	end
	return retval
end

-- read functions
function List:getFirst()
	if self.n==0 then return nil end
	self.current = self.first
	return self.current.ref
end

function List:getNext()
	if not self.current.next then return nil end
	self.current = self.current.next
	return self.current.ref
end

function List:getPrev()
	if not self.current.prev then return nil end
	self.current = self.current.prev
	return self.current.ref
end

function List:getLast()
	if self.n==0 then return nil end
	self.current = self.last
	return self.current.ref
end

function List:getCurrent()
	return self.current.ref
end

-- remove current (use in combination with get*)
function List:removeCurrent()
	if self.n == 0 then return end
	if self.n == 1 then
		self:discard()
		return
	end

	if self.current.next and self.current.prev then
		self.current.next.prev = self.current.prev
		self.current.prev.next = self.current.next
		self.current.ref = nil
		self.n = self.n - 1
		return
	end

	-- first
	if self.current == self.first then
		self.first = self.first.next
		self.first.prev = nil
		self.current.next = nil
		self.current.ref = nil
		self.n = self.n - 1
		return
	end

	-- last
	if self.current == self.last then
		self.last = self.last.prev
		self.last.next = nil
		self.current.prev = nil
		self.current.ref = nil
		self.n = self.n - 1
		return
	end
end

-- insert after current
function List:insert(obj, value)
	if not value then value=0 end

	if self.n<2 or self.current==self.last then
		self:pushBack(obj,value)
		return
	end

	local new = { next = self.current.next, prev = self.current, ref = obj, val = value }
	self.current.next = new
	new.next.prev = new
	self.n = self.n + 1
end

--- sorting
function List:pushFrontSorted(obj, value)
	if not value then value=0 end
	if self.n==0 then
		self:pushFront(obj,value)
		return
	end
	if self.first.val > value then
		self:pushFront(obj,value)
		return
	end

	local elem = self:getFirst( list )
	while elem and self.current.val < value do elem=self:getNext() end
	if not elem then
		self:pushBack(obj,value)
	else
		self:getPrev()
		self:insert(obj,value)
	end
end

function List:pushBackSorted(obj, value)
	if not value then value=0 end
	if self.n == 0 then
		self:pushBack(obj,value)
		return
	end
	if self.last.val < value then
		self:pushBack(obj,value)
		return
	end

	local elem = self:getLast( list )
	while elem and self.current.val > value do elem=self:getPrev() end
	if not elem then
		self:pushFront(obj,value)
	else
		self:insert(obj,value)
	end
end

-- changes the value of the current object and sorts again
function List:changeValue(value)
	if not value then value=0 end
	if self.current.val == value then return end

	local savedref = self.current.ref
	local oldval = self.current.val
	local newval = value
	local oldprev = self.current.prev

	self:removeCurrent()

	if newval>oldval then
		-- move up
		elem = self:getNext()
		while elem and self.current.val < value do elem = self:getNext() end
		if not elem then
			self:pushBack(savedref,value)
		else
			self:getPrev()
			self:insert(savedref,value)
		end
	else
		-- move down
		local elem = self:getPrev( list )
		while elem and self.current.val > value do elem=self:getPrev() end
		if not elem then
			self:pushFront(savedref,value)
		else
			self:insert(savedref,value)
		end
	end

	-- not sure about this...
	self.current = oldprev
end

--~ -- Example of use (make the condition true to test)
if false then
	list = List()
	list:pushBack("abc")
	list:pushBack("cde")
	list:pushBack("def")

	-- print
	elem = list:getFirst()
	while elem do
		print(elem)
		elem = list:getNext()
	end


	-- reset
	print()
	list:discard()

	-- sort while inserting
	list:pushFrontSorted("iii",3)
	list:pushFrontSorted("ooo",4)
	list:pushFrontSorted("aaa",1)

	-- print in reverse order (from high to low)
	elem = list:popBack()
	while elem do
		print(elem)
		elem = list:popBack()
	end

	list:discard()
end
