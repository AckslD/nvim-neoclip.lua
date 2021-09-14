local M = {}

local neoclip = require('neoclip')
local storage = require('neoclip.storage')
local settings = require('neoclip.settings').get()

local function should_add(event)
    if settings.filter ~= nil then
        local data = {
            event = event,
            filetype = vim.bo.filetype,
            buffer_name = vim.api.nvim_buf_get_name(0),
        }
        return settings.filter(data)
    else
        return true
    end
end

local function get_regtype(regtype)
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
            regtype = get_regtype(event.regtype),
            contents = event.regcontents,
            filetype = vim.bo.filetype,
        })
    end
end

M.on_exit = function()
    storage.on_exit()
end

local function set_register(register_name, entry)
    vim.fn.setreg(register_name, entry.contents, entry.regtype)
end

M.set_registers = function(register_names, entry)
    for _, register_name in ipairs(register_names) do
        set_register(register_name, entry)
    end
end

M.paste = function(entry, op)
    local register_name = '"'
    local current_contents = vim.fn.getreg(register_name)
    local current_regtype = vim.fn.getregtype(register_name)
    set_register(register_name, entry)
    -- TODO can this be done without setting the register
    vim.cmd(string.format('normal! "%s%s', register_name, op))
    vim.fn.setreg(register_name, current_contents, current_regtype)
end

return M
