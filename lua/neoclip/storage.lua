local M = {}

local settings = require('neoclip.settings').get()

local storage = {}

M.get = function()
    return storage
end

M.insert = function(contents)
    if #storage >= settings.history then
        table.remove(M.storage, 1)
    end
    table.insert(storage, contents)
end

return M
