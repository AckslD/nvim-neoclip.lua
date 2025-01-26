local M = {}

M.make_prompt_title = function(register_names)
    return string.format("Pick new entry for registers %s", table.concat(register_names, ','))
end

M.dedent_picker_display = function(value)
  return string.gsub(value, "^%s+", "")
end

return M
