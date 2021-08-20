local M = {}

local settings = {
    history = 1000,
    filter = nil,
    preview = true,
    content_spec_column = false,
}

M.get = function()
    return settings
end

M.setup = function(opts)
    if opts == nil then
        opts = {}
    end
    for key, value in pairs(opts) do
        settings[key] = value
    end
end

return M
