local M = {}

local finders = require("telescope.finders")
local pickers = require("telescope.pickers")
local config = require("telescope.config").values
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local entry_display = require "telescope.pickers.entry_display"
local previewers = require('telescope.previewers')

local handlers = require('neoclip.handlers')
local storage = require('neoclip.storage')
local settings = require('neoclip.settings').get()
local utils = require('neoclip.utils')
local picker_utils = require('neoclip.picker_utils')

local function get_set_register_handler(register_names)
    return function(prompt_bufnr)
        local entry = action_state.get_selected_entry()
        actions.close(prompt_bufnr)
        handlers.set_registers(register_names, entry)
    end
end

local function get_paste_handler(register_names, op)
    return function(prompt_bufnr)
        local entry = action_state.get_selected_entry()
        -- TODO if we can know the bufnr "behind" telescope we wouldn't need to close
        -- and have it optional
        actions.close(prompt_bufnr)
        if settings.on_paste.set_reg then
            handlers.set_registers(register_names, entry)
        end
        handlers.paste(entry, op)
    end
end

local function get_replay_recording_handler(register_names)
    return function(prompt_bufnr)
        local entry = action_state.get_selected_entry()
        -- TODO if we can know the bufnr "behind" telescope we wouldn't need to close
        -- and have it optional
        actions.close(prompt_bufnr)
        if settings.on_replay.set_reg then
            handlers.set_registers(register_names, entry)
        end
        handlers.replay(entry)
    end
end

local function get_custom_action_handler(register_names, action, typ)
    return function(prompt_bufnr)
        local entry = action_state.get_selected_entry()
        actions.close(prompt_bufnr)
        action({
            register_names=register_names,
            typ = typ,
            entry = {
                contents=entry.contents,
                filetype=entry.filetype,
                regtype=entry.regtype,
            }
        })
    end
end

local function get_delete_handler(typ)
    return function(prompt_bufnr)
        local current_picker = action_state.get_current_picker(prompt_bufnr)
        current_picker:delete_selection(function(selection)
            handlers.delete(typ, selection)
        end)
    end
end

local displayer = entry_display.create {
    separator = " ",
    items = {
        { width = 60 },
        { remaining = true },
    },
}

local spec_per_regtype = {
    c = 'charwise',
    l = 'linewise',
    b = 'blockwise',
}

local function spec_from_entry(entry)
    local spec = spec_per_regtype[entry.regtype]
    local num_lines = #entry.contents
    if num_lines > 1 then
        spec = string.format('%s (%d lines)', spec, num_lines)
    end
    return spec
end

local function make_display(entry)
    local to_display = {entry.contents[1]}
    if settings.content_spec_column then
        table.insert(to_display, {spec_from_entry(entry), "Comment"})
    end
    return displayer(to_display)
end

local function entry_maker(entry)
    return {
        display = make_display,
        contents = entry.contents,
        regtype = entry.regtype,
        filetype = entry.filetype,
        ordinal = table.concat(entry.contents, '\n'),
        -- TODO seem to be needed
        name = 'name',
        value = 'value', -- TODO what to put value to, affects sorting?
    }
end

local special_registers = {
    unnamed = '"',
    star = '*',
    plus = '+',
}

local function parse_extra(extra)
    local registers = {}
    for _, r in ipairs(vim.fn.split(extra, ',')) do
        if special_registers[r] == nil then
            table.insert(registers, r)
        else
            table.insert(registers, special_registers[r])
        end
    end
    return registers
end

local function map_if_set(map, mode, keys, desc, handler)
    if not keys then
        return
    end

    if type(keys) ~= 'table' then
        keys = { keys }
    end

    for _, key in pairs(keys) do
        map(mode, key, setmetatable({desc}, {
            __call = function(_, ...)
                return handler(...)
            end,
        }))
    end
end

local function get_export(register_names, typ)
    if type(register_names) == 'string' then
        register_names = {register_names}
    end
    return function(opts)
        local previewer = false
        if settings.preview then
            previewer = previewers.new_buffer_previewer({
                define_preview = function(self, entry, status)
                    vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, true, entry.contents)
                    if entry.filetype ~= nil then
                        vim.bo[self.state.bufnr].filetype = entry.filetype
                    end
                end,
                dyn_title = function(self, entry)
                    return spec_from_entry(entry)
                end
            })
        end
        if opts ~= nil and opts.extra ~= nil then
            register_names = utils.join(register_names, parse_extra(opts.extra))
        end
        local results = storage.get({reversed = true})[typ]
        pickers.new(opts, {
            prompt_title = picker_utils.make_prompt_title(register_names),
            prompt_prefix = settings.prompt or nil,
            finder = finders.new_table({
                results = results,
                entry_maker = entry_maker,
            }),
            previewer = previewer,
            sorter = config.generic_sorter(opts),
            attach_mappings = function(_, map)
                for _, mode in ipairs({'i', 'n'}) do
                    local keys = settings.keys.telescope[mode]
                    map_if_set(map, mode, keys.select, 'select', get_set_register_handler(register_names))
                    map_if_set(map, mode, keys.paste, 'paste', get_paste_handler(register_names, 'p'))
                    map_if_set(map, mode, keys.paste_behind, 'paste_behind', get_paste_handler(register_names, 'P'))
                    map_if_set(map, mode, keys.replay, 'replay', get_replay_recording_handler(register_names))
                    map_if_set(map, mode, keys.delete, 'delete', get_delete_handler(typ))
                    if keys.custom ~= nil then
                        for key, action in pairs(keys.custom) do
                            map(mode, key, get_custom_action_handler(register_names, action, typ))
                        end
                    end
                end
                return true
            end,
        }):find()
    end
end

local function register_names()
    local names = {}
    for name, reg in pairs(special_registers) do
        names[reg] = name
    end
    for i = 1, 9 do -- [0-9]
        local reg = string.format('%d', i)
        names[reg] = reg
    end
    for c = 97, 122 do -- [a-z]
        local reg = string.char(c)
        names[reg] = reg
    end
    return names
end

M.get_exports = function(typ)
    local exports = {}
    for reg, name in pairs(register_names()) do
        local export = get_export(reg, typ)
        exports[name] = export
    end
    local command_name
    local reg
    if typ == 'macros' then
        reg = settings.default_register_macros
        command_name = 'macroscope'
    else
        reg = settings.default_register
        command_name = 'neoclip'
    end
    local default = get_export(reg, typ)
    exports['default'] = default
    exports[command_name] = default
    return exports
end

return M
