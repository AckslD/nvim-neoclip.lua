local M = {}

local settings = {
    history = 1000,
    enable_persistent_history = false,
    db_path = vim.fn.stdpath("data") .. "/databases/neoclip.sqlite3",
    filter = nil,
    preview = true,
    default_register = '"',
    default_register_macros = 'q',
    enable_macro_history = true,
    content_spec_column = false,
    on_paste = {
        set_reg = false,
    },
    on_replay = {
        set_reg = false,
    },
    keys = {
        telescope = {
            i = {
                select = '<cr>',
                paste = '<c-p>',
                paste_behind = '<c-k>',
                replay = '<c-q>',
                custom = {},
            },
            n = {
                select = '<cr>',
                paste = 'p',
                paste_behind = 'P',
                replay = 'q',
                custom = {},
            },
        },
        fzf = {
            select = 'default',
            paste = 'ctrl-p',
            paste_behind = 'ctrl-k',
            custom = {},
        },
    },
}

M.get = function()
    return settings
end

local function warn(msg)
    vim.cmd(string.format('echohl WarningMsg | echo "Neoclip Warning: %s" | echohl None', msg))
end

local function check_keys()
    local keys = settings.keys
    if keys.i ~= nil or keys.n ~= nil then
        warn('Using settings.keys without specifying \'telescope\' or \'fzf\' will not be supported in the future, see #29.')
        keys.telescope = keys
    end
end

local function check_persistant()
    if settings.enable_persistant_history ~= nil then
        warn([[
            Using settings.enable_persistant_history will not be supported in the future, see #44.
            Use settings.enable_persistent_history instead.
        ]])
        settings.enable_persistent_history = settings.enable_persistant_history
    end
end

local function check_deprecated_entries()
    check_keys()
    check_persistant()
end

local function setup(opts, subsettings)
    if opts == nil then
        opts = {}
    end
    for key, value in pairs(opts) do
        if type(subsettings[key]) == 'table' then
            setup(value, subsettings[key])
        else
            subsettings[key] = value
        end
    end
    check_deprecated_entries()
end

M.setup = function(opts)
    setup(opts, settings)
end

return M
