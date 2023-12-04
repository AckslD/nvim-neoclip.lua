local M = {}

local neoclip = require('neoclip')
local storage = require('neoclip.storage')
local settings = require('neoclip.settings').get()

local function should_add(event)
    if event.regcontents == nil then
      return false
    end
    if settings.length_limit then
        local length = #event.regcontents - 1
        for _,line in ipairs(event.regcontents) do
            length = length + #line
            if length > settings.length_limit then
                return false
            end
        end
    end
    if settings.filter ~= nil then
        local data = {
            event = event,
            filetype = vim.bo.filetype,
            buffer_name = vim.api.nvim_buf_get_name(0),
        }
        if not settings.filter(data) then
            return false
        end
    end
    return true
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
        }, 'yanks')
    end
end

M.handle_macro_post = function()
    if neoclip.stopped then
        return
    end
    local event = vim.v.event
    storage.insert({
        regtype = 'c',
        contents = {event.regcontents},
        filetype = nil,
    }, 'macros')
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

local function temporary_reg_usage(entry, callback)
    local register_name = '"'
    local current_contents = vim.fn.getreg(register_name)
    local current_regtype = vim.fn.getregtype(register_name)
    set_register(register_name, entry)
    callback(register_name)
    vim.fn.setreg(register_name, current_contents, current_regtype)
end

-- TODO can this be done without setting the register?
M.paste = function(entry, op)
    temporary_reg_usage(entry, function(register_name)
        vim.cmd(string.format('normal! "%s%s', register_name, op))
    end)
end

-- TODO can this be done without setting the register?
M.replay = function(entry)
    temporary_reg_usage(entry, function(register_name)
        vim.cmd(string.format('normal! @%s', register_name))
    end)
end

M.delete = function(typ, entry)
    storage.delete(typ, entry)
end

return M
