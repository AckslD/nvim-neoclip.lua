local M = {}

local settings = require('neoclip.settings').get()

local storage = {}

M.get = function()
    return storage
end

M.insert = function(contents)
    if #storage >= settings.history then
        table.remove(storage, #storage)
    end
    table.insert(storage, 1, contents)
end

return M
