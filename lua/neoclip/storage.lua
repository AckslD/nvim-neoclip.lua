local M = {}

local settings = require('neoclip.settings').get()

local storage = {}
if settings.db_path ~= nil then
    storage = require('neoclip.db').get(settings.db_path)
end

M.get = function()
    return storage
end

M.insert = function(contents)
    if #storage >= settings.history then
        table.remove(storage, #storage)
    end
    table.insert(storage, 1, contents)
end

M.clear = function()
    while #storage > 0 do
        table.remove(M.storage, 1)
    end
end

M.on_exit = function()
    if settings.db_path ~= nil then
        require('neoclip.db').update({
            db_path = settings.db_path,
            storage = storage,
        })
    end
end

return M
