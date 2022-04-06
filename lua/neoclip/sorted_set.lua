local M = {}

local ll = require('neoclip.linked_list')

local hash = function(entry)
    return vim.inspect({
        regtype = entry.regtype,
        contents = entry.contents,
    })
end

local remove_by_key = function(self, key)
    local node = self.entries[key]
    self.ll:remove(node)
    self.entries[key] = nil
end

local _insert = function(self, entry, opts)
    local key = hash(entry)
    if self.entries[key] then
        if opts and opts.keep_position then
            return
        end
        remove_by_key(self, key)
    end
    self.ll:push(entry)
    self.entries[key] = self.ll.tail
end

-- remove and return the last inserted entry
local pop = function(self)
    local entry = self.ll:pop()
    if entry then
        self.entries[hash(entry)] = nil
    end
    return entry
end

--- insert a new entry
-- @param entry the new entry
-- @param opts optional table with keys:
--    * keep_position: if true then duplicate entries are not moved forward
local insert = function(self, entry, opts)
    _insert(self, entry, opts)
    while self.max_size and self.ll:len() > self.max_size do
        pop(self)
    end
end

--- adds the entries from a plain table
local update = function(self, entries)
    for _, entry in ipairs(entries) do
        self:insert(entry, {keep_position = true})
    end
end

--- removes an entry by value
local remove = function(self, entry)
    remove_by_key(self, hash(entry))
end

--- returns a plain table with then entries
local values = function(self, opts)
    return self.ll:values(opts)
end

--- number of entries in the set
local len = function(self)
    return self.ll:len()
end

--- clear the set
local clear = function(self)
    self.ll:clear()
    self.entries = {}
end

M.new = function(max_size)
    return {
        max_size = max_size,
        ll = ll:new(),
        entries = {},
        -- methods
        insert = insert,
        update = update,
        remove = remove,
        values = values,
        len = len,
        clear = clear,
    }
end

return M
