local M = {}

local settings = require('neoclip.settings')

M.stopped = false

local function setup_auto_command()
    local commands = {
        'augroup neoclip',
        'autocmd!',
        'autocmd TextYankPost * :lua require("neoclip.handlers").handle_yank_post()',
        'autocmd VimLeavePre * :lua require("neoclip.handlers").on_exit()',
    }
    if vim.fn.exists('##RecordingLeave') and settings.enable_macro_history then
        table.insert(
            commands,
            'autocmd RecordingLeave * :lua require("neoclip.handlers").handle_macro_post()'
        )
    end
    table.insert(
        commands,
        'augroup end'
    )
    vim.cmd(table.concat(commands, '\n'))
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

M.clear_history = function()
    require('neoclip.storage').clear()
end

M.setup = function(opts)
    settings.setup(opts)
    setup_auto_command()
end

return M
