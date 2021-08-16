local M = {}

local neoclip = require('neoclip')
local storage = require('neoclip.storage')
local settings = require('neoclip.settings').get()

local function should_add(event)
    if settings.filter ~= nil then
        local data = {
            event = event,
            filetype = vim.bo.filetype,
            path = vim.api.but_get_name(0),
        }
        return settings.filter(data)
    else
        return true
    end
end

local function get_type(regtype)
    if regtype == 'v' then
        return 'c'
    elseif regtype == 'V' then
        return 'l'
    else
        return 'b'
    end
end

M.handle_yank_post = function()
    if neoclip.stopped then
        return
    end
    local event = vim.v.event
    if should_add(event) then
        storage.insert({
            type = get_type(event.regtype),
            contents = event.regcontents,
        })
    end
end

M.handle_choice = function(register_name, entry)
    vim.fn.setreg(register_name, entry.contents, entry.type)
end

return M
