local M = {}

local settings = {
    history = 1000,
    enable_persistent_history = false,
    length_limit = 1048576,
    continuous_sync = false,
    db_path = vim.fn.stdpath("data") .. "/databases/neoclip.sqlite3",
    filter = nil,
    preview = true,
    default_register = '"',
    default_register_macros = 'q',
    enable_macro_history = true,
    content_spec_column = false,
    disable_keycodes_parsing = false,
    on_select = {
        move_to_front = false,
        close_telescope = true,
    },
    on_paste = {
        set_reg = false,
        move_to_front = false,
        close_telescope = true,
    },
    on_replay = {
        set_reg = false,
        move_to_front = false,
        close_telescope = true,
    },
    on_custom_action = {
        close_telescope = true,
    },
    keys = {
        telescope = {
            i = {
                select = '<cr>',
                paste = '<c-p>',
                paste_behind = '<c-k>',
                paste_visual = '<c-v>',
                replay = '<c-q>',
                delete = '<c-d>',
                edit = '<c-e>',
                custom = {},
            },
            n = {
                select = '<cr>',
                paste = 'p',
                paste_behind = 'P',
                paste_visual = 'v',
                replay = 'q',
                delete = 'd',
                edit = 'e',
                custom = {},
            },
        },
        fzf = {
            select = 'default',
            paste = 'ctrl-p',
            paste_behind = 'ctrl-k',
            paste_visual = 'ctrl-v',
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
        warn(''..
            'Using settings.enable_persistant_history will not be supported in the future, see #44. '..
            'Use settings.enable_persistent_history instead.'
        )
        settings.enable_persistent_history = settings.enable_persistant_history
    end
end

local function check_deprecated_entries()
    check_keys()
    check_persistant()
end

local function is_dict_like (tbl)
    local islist = vim.islist or vim.tbl_islist
    return type(tbl) == 'table' and not islist(tbl)
end

local function setup(opts, subsettings)
    if opts == nil then
        opts = {}
    end
    for key, value in pairs(opts) do
        if is_dict_like(subsettings[key]) then
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
