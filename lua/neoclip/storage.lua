local M = {}

local ss = require('neoclip.sorted_set')
local settings = require('neoclip.settings').get()

local storage = {
    yanks = ss.new(settings.history),
    macros = ss.new(settings.history),
}

local update_from_tbl = function(tbl)
    storage.yanks:update(tbl.yanks)
    storage.macros:update(tbl.macros)
end

local update_from_db = function()
    local db = require('neoclip.db').read()
    update_from_tbl(db)
end

if settings.enable_persistent_history then
    update_from_db()
end

M.as_tbl = function(opts)
    return {
        yanks = storage.yanks:values(opts),
        macros = storage.macros:values(opts),
    }
end

local pre_get = function()
    if settings.enable_persistent_history and settings.continuous_sync then
        M.pull()
    end
end

local post_change = function()
    if settings.enable_persistent_history and settings.continuous_sync then
        M.push()
    end
end

M.get = function()
    pre_get()
    return M.as_tbl({reversed = true})
end

M.insert = function(contents, typ)
    storage[typ]:insert(contents)
    post_change()
end

M.set_as_most_recent = function (typ, entry)
    M.delete(typ, entry)
    M.insert(entry, typ)
end

local clear = function()
    for _, entries in pairs(storage) do
        entries:clear()
    end
end

M.clear = function()
    clear()
    post_change()
end

M.delete = function(typ, entry)
    storage[typ]:remove(entry)
    post_change()
end

M.replace = function (typ, entry, newEntry)
    storage[typ]:replace(entry, newEntry)
    post_change()
end

M.push = function()
    require('neoclip.db').write(M.as_tbl())
end

M.pull = function()
    clear()
    update_from_db()
end

M.on_exit = function()
    if settings.enable_persistent_history then
        M.push()
    end
end

return M
