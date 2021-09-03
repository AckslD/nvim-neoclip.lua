local M = {}

local settings = {
    history = 1000,
    db_path = nil,
    filter = nil,
    preview = true,
    default_register = '"',
    content_spec_column = false,
    on_paste = {
        set_reg = false,
    },
    keys = {
        i = {
            select = '<cr>',
            paste = '<c-p>',
            paste_behind = '<c-k>',
        },
        n = {
            select = '<cr>',
            paste = 'p',
            paste_behind = 'P',
        },
    },
}

M.get = function()
    return settings
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
end

M.setup = function(opts)
    setup(opts, settings)
end

return M
