local M = {}

M.join = function(t1, t2)
    local new_t = {}
    for _, e in ipairs(t1) do
        table.insert(new_t, e)
    end
    for _, e in ipairs(t2) do
        table.insert(new_t, e)
    end
    return new_t
end

--- @param initial_lines string[]
--- @param filetype string
--- @param on_close fun(new_lines: string[]): nil
M.open_editor_temp_window = function (initial_lines, filetype, on_close)
    local temp_buffer = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(temp_buffer, 0, -1, false, initial_lines)
    vim.api.nvim_buf_set_option(temp_buffer, 'filetype', filetype or '')
    -- Requires a 'BufWriteCmd' or "FileWriteCmd" autocmd to write
    vim.api.nvim_buf_set_option(temp_buffer, "buftype", "acwrite")
    -- Allows the user to call :write
    vim.api.nvim_buf_set_name(temp_buffer, "neoclip-temp")

    local function make_ideal_win_config()
        -- Default values are in case neovim is running in headless mode (e.g. during tests)
        local stats = vim.api.nvim_list_uis()[1] or { width = 10, height = 10 }
        local width = stats.width
        local height = stats.height
        local winWidth = math.ceil(width * 0.8)
        local winHeight = math.ceil(height * 0.8)
        return {
            relative = "editor",
            style = "minimal",
            border = "single",
            width = winWidth,
            height = winHeight,
            col = math.ceil((width - winWidth) / 2),
            row = math.ceil((height - winHeight) / 2) - 1,
        }
    end

    local win = vim.api.nvim_open_win(temp_buffer, true, make_ideal_win_config())

    -- Makes sure the window stays at a proper size when vim is resized
    vim.api.nvim_create_autocmd("VimResized", {
        buffer = temp_buffer,
        callback = function()
            vim.api.nvim_win_set_config(win, make_ideal_win_config())
        end,
    })

    -- "BufWriteCmd" and "FileWriteCmd" prevents the file from actually being written to a file
    vim.api.nvim_create_autocmd({"BufWriteCmd", "FileWriteCmd"}, {
        buffer = temp_buffer,
        callback = function ()
            vim.api.nvim_buf_set_option(temp_buffer, "modified", false)
        end,
    })

    vim.api.nvim_create_autocmd({"WinClosed", "WinLeave"}, {
        buffer = temp_buffer,
        callback = function()
            local lines = vim.api.nvim_buf_get_lines(temp_buffer, 0, -1, false)
            vim.api.nvim_buf_delete(temp_buffer, { force = true })
            on_close(lines)
        end,
    })
end

return M
