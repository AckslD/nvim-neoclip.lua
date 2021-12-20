local M = {}

local settings = {
    history = 1000,
    enable_persistant_history = false,
    db_path = vim.fn.stdpath("data") .. "/databases/neoclip.sqlite3",
    filter = nil,
    preview = true,
    default_register = '"',
    content_spec_column = false,
    on_paste = {
        set_reg = false,
    },
    keys = {
        telescope = {
            i = {
                select = '<cr>',
                paste = '<c-p>',
                paste_behind = '<c-k>',
                custom = {},
            },
            n = {
                select = '<cr>',
                paste = 'p',
                paste_behind = 'P',
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
        -- TODO check PR number
        warn('Using settings.keys without specifying \'telescope\' or \'fzf\' will not be supported in the future, see #29.')
        keys.telescope = keys
    end
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
    check_keys()
end

M.setup = function(opts)
    setup(opts, settings)
end

return M
