local telescope = require('telescope')
local finders = require("telescope.finders")
local pickers = require("telescope.pickers")
local config = require("telescope.config").values
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local entry_display = require "telescope.pickers.entry_display"

local handle_choice = require('neoclip.handlers').handle_choice
local storage = require('neoclip.storage').get()

local function get_handler(register_name)
    return function(prompt_bufnr)
        local entry = action_state.get_selected_entry()
        actions.close(prompt_bufnr)
        handle_choice(register_name, entry)
    end
end

local displayer = entry_display.create {
    separator = " ",
    items = {
        { width = 65 },
        { remaining = true },
    },
}

local spec_per_type = {
    c = 'charwise',
    l = 'linewise',
    b = 'blockwise',
}

local function make_display(entry)
    local spec = spec_per_type[entry.type]
    local num_lines = #entry.contents
    if num_lines > 1 then
        spec = string.format('%s (%d lines)', spec, num_lines)
    end
    return displayer {
        entry.contents[1],
        {spec, "Comment"},
    }
end

local function get_export(register_name)
    return function(opts)
        pickers.new(opts, {
            prompt_title = string.format("Pick new entry for register '%s'", register_name),
            finder = finders.new_table({
                results = storage,
                entry_maker = function(entry)
                    return {
                        display = make_display,
                        contents = entry.contents,
                        type = entry.type,
                        ordinal = table.concat(entry.contents, '\n'),
                        -- TODO seem to be needed
                        name = 'name',
                        value = 'value', -- TODO what to put value to, affects sorting?
                    }
                end,
            }),
            previewer = false,
            sorter = config.generic_sorter(opts),
            attach_mappings = function(_, map)
                map('i', '<cr>', get_handler(register_name))
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
