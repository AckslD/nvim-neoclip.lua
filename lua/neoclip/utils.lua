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

return M
