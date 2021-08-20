local telescope = require('telescope')
local finders = require("telescope.finders")
local pickers = require("telescope.pickers")
local config = require("telescope.config").values
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local entry_display = require "telescope.pickers.entry_display"
local previewers = require('telescope.previewers')

local handlers = require('neoclip.handlers')
local storage = require('neoclip.storage').get()
local settings = require('neoclip.settings').get()

local function get_set_register_handler(register_name)
    return function(prompt_bufnr)
        local entry = action_state.get_selected_entry()
        actions.close(prompt_bufnr)
        handlers.set_register(register_name, entry)
    end
end

local function get_paste_handler(register_name, op)
    return function(prompt_bufnr)
        local entry = action_state.get_selected_entry()
        -- TODO if we can know the bufnr "behind" telescope we wouldn't need to close
        -- and have it optional
        actions.close(prompt_bufnr)
        handlers.paste(register_name, entry, op)
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

local function get_export(register_name)
    return function(opts)
        local previewer = false
        if settings.preview then
            previewer = previewers.new_buffer_previewer({
                define_preview = function(self, entry, status)
                    vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, true, entry.contents)
                    vim.bo[self.state.bufnr].filetype = entry.filetype
                end,
                dyn_title = function(self, entry)
                    return spec_from_entry(entry)
                end
            })
        end
        pickers.new(opts, {
            prompt_title = string.format("Pick new entry for register '%s'", register_name),
            finder = finders.new_table({
                results = storage,
                entry_maker = entry_maker,
            }),
            previewer = previewer,
            sorter = config.generic_sorter(opts),
            attach_mappings = function(_, map)
                for _, mode in ipairs({'i', 'n'}) do
                    map(mode, settings.keys[mode].select, get_set_register_handler(register_name))
                    map(mode, settings.keys[mode].paste, get_paste_handler(register_name, 'p'))
                    map(mode, settings.keys[mode].paste_behind, get_paste_handler(register_name, 'P'))
                end
                return true
            end,
        }):find()
    end
end

local function register_names()
    local names = {'"'}
    for i = 1, 9 do -- [0-9]
        table.insert(names, string.format('%d', i))
    end
    for c = 97, 122 do -- [a-z]
        table.insert(names, string.char(c))
    end
    return names
end

local function get_exports()
    local exports = {}
    for _, register_name in ipairs(register_names()) do
        local export = get_export(register_name)
        if register_name == '"' then
            exports['default'] = export
            exports['neoclip'] = export
        else
            exports[register_name] = export
        end
    end
    return exports
end

return telescope.register_extension {
    exports = get_exports(),
}
