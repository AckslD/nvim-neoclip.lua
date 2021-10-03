local M = {}

local settings = require('neoclip.settings').get()

local storage = {}
if settings.enable_persistant_history then
    storage = require('neoclip.db').get()
end

M.get = function()
    return storage
end

M.insert = function(contents)
    while #storage >= settings.history do
        table.remove(storage, #storage)
    end
    table.insert(storage, 1, contents)
end

M.clear = function()
    while #storage > 0 do
        table.remove(storage, 1)
    end
end

M.on_exit = function()
    if settings.enable_persistant_history then
        require('neoclip.db').update(storage)
    end
end

return M
