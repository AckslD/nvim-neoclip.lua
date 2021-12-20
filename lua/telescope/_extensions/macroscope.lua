local telescope = require("telescope")
local get_exports = require("neoclip.telescope").get_exports

return telescope.register_extension {
    exports = get_exports('macros'),
}
