local M = {}

local settings = require('neoclip.settings').get()

local storage = {
    yanks = {},
    macros = {},
}
if settings.enable_persistent_history then
    storage = require('neoclip.db').get()
end

M.get = function()
    return storage
end

M.insert = function(contents, typ)
    local entries = storage[typ]
    while #entries >= settings.history do
        table.remove(entries, #entries)
    end
    table.insert(entries, 1, contents)
end

M.clear = function()
    for _, entries in pairs(storage) do
        while #entries > 0 do
            table.remove(entries, 1)
        end
    end
end

M.on_exit = function()
    if settings.enable_persistent_history then
        require('neoclip.db').update(storage)
    end
end

return M
