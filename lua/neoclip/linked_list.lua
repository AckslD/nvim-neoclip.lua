local M = {}

--- Clear the list
local clear = function(self)
    self.size = 0
    self.head = nil
    self.tail = nil
end

--- Push a new value to the end of the list
local push = function(self, value)
    if not self.tail then
        self.tail = {
            value = value,
        }
        self.head = self.tail
    else
        local current_tail = self.tail
        self.tail = {
            prev = current_tail,
            value = value,
        }
        current_tail.next = self.tail
    end
    self.size = self.size + 1
end

--- Pop the first entry in the list
local pop = function(self)
    if not self.head then
        return
    end
    local value = self.head.value
    self:remove(self.head)
    return value
end

--- The length of the list
local len = function(self)
    return self.size
end

--- Returns the list as a plain table in _reversed_ order, starting from tail
-- @param opts optional table with keys:
--     reversed: which if `true` returns the values in reversed order
local values = function(self, opts)
    local reversed = opts and opts.reversed
    local values = {}
    local node
    if reversed then
        node = self.tail
    else
        node = self.head
    end
    while node do
        table.insert(values, node.value)
        if reversed then
            node = node.prev
        else
            node = node.next
        end
    end
    return values
end

--- Removes a node in the list
-- XXX does not check if node is actually in the list, use responsibly!
-- If the node is not in the list, the size will later be wrong.
-- @param node should be a node in the list (not a value). For example self.head.
local remove = function(self, node)
    self.size = self.size - 1
    if self.head == node then
        self.head = node.next
    end
    if self.tail == node then
        self.tail = node.prev
    end
    if node.prev then
        node.prev.next = node.next
    end
    if node.next then
        node.next.prev = node.prev
    end
end

--- Creates a new double-linked list
M.new = function()
    return {
        size = 0,
        -- methods
        clear = clear,
        push = push,
        pop = pop,
        len = len,
        values = values,
        remove = remove,
    }
end

return M
