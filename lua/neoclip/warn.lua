local M = {}

M.warn = function(msg)
    msg = vim.fn.escape(msg, '"')
    vim.cmd(string.format('echohl WarningMsg | echo "Warning: %s" | echohl None', msg))
end

return M
