local M = {}

M.make_prompt_title = function(register_names)
    return string.format("Pick new entry for registers %s", table.concat(register_names, ','))
end

return M
