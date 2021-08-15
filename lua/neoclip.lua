local M = {}

M.settings = {
    history = 1000,
    operators = {'y', 'c', 'd'},
    include_visual = true,
    filter = nil,
    picker = nil,
}
M.storage = {}
M.stopped = false

local function error(msg)
    vim.cmd(string.format('echoerr "%s"', msg))
end

local function find_installed_picker()
    local pickers = {
        "telescope",
    }
    for _, picker in ipairs(pickers) do
        local has_picker, _ = pcall(require, picker)
        if has_picker then
            return picker
        end
    end
    error("no supported picker installed. Supported ones are: " .. vim.inspect(pickers))
end

local function setup_settings(opts)
    if opts == nil then
        opts = {}
    end
    for key, value in pairs(opts) do
        M.settings[key] = value
    end
    if M.settings.picker == nil then
        M.settings.picker = find_installed_picker()
    end
end

local function setup_auto_command()
    vim.cmd([[
        augroup neoclip
            autocmd!
            autocmd TextYankPost * :lua require("neoclip").handle_yank_post()
        augroup end
    ]])
end

local function insert_to_storage(contents)
    if #M.storage >= M.settings.history then
        table.remove(M.storage, 1)
    end
    table.insert(M.storage, contents)
end

local function should_add(event)
    if M.settings.filter ~= nil then
        local data = {
            event = event,
            filetype = vim.bo.filetype,
            path = vim.api.but_get_name(0),
        }
        return M.settings.filter(data)
    else
        return true
    end
end

local function get_type(regtype)
    if regtype == 'v' then
        return 'c'
    elseif regtype == 'V' then
        return 'l'
    else
        return 'b'
    end
end

M.handle_yank_post = function()
    if M.stopped then
        return
    end
    local event = vim.v.event
    if should_add(event) then
        insert_to_storage({
            type = get_type(event.regtype),
            contents = event.regcontents,
        })
    end
end

M.stop = function()
    M.stopped = true
end

M.start = function()
    M.stopped = false
end

M.toggle = function()
    M.stopped = not M.stopped
end

M.handle_choice = function(register_name, entry)
    vim.fn.setreg(register_name, entry.contents, entry.type)
end

local function register_telescope()
    local has_telescope, telescope = pcall(require, "telescope")
    if not has_telescope then
      error("To use telescope as picker it needs to be installed (https://github.com/nvim-telescope/telescope.nvim)")
      return
    end
    M.pick = function(register_name)
        if register_name == nil then
            register_name = '"'
        end
        telescope.extensions.neoclip[register_name]()
    end
    vim.schedule(function()
        telescope.load_extension('neoclip')
    end)
end


local picker_registrations = {
    telescope = register_telescope,
}

local function setup_picker()
    if picker_registrations[M.settings.picker] == nil then
        error("Unknown picker: " .. M.settings.picker)
    end
    picker_registrations[M.settings.picker]()
end

M.setup = function(opts)
    setup_settings(opts)
    setup_auto_command()
    setup_picker()
end

return M
