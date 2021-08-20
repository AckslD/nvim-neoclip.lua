local function assert_scenario(scenario)
    if scenario.initial_buffer then
        vim.api.nvim_buf_set_lines(0, 0, -1, true, vim.fn.split(scenario.initial_buffer, '\n'))
    end
    if scenario.setup then
        scenario.setup()
    end
    if scenario.feedkeys then
        for _, raw_keys in ipairs(scenario.feedkeys) do
            local keys = vim.api.nvim_replace_termcodes(raw_keys, true, false, true)
            vim.api.nvim_feedkeys(keys, 'xm', true)
        end
    end
    if scenario.assert then
        scenario.assert()
    end
    if scenario.expected_buffer then
        local current_buffer = vim.fn.join(vim.api.nvim_buf_get_lines(0, 0, -1, true), '\n')
        assert.are.equal(current_buffer, scenario.expected_buffer)
    end
end

describe("neoclip", function()
    before_each(function()
        vim.api.nvim_buf_set_lines(0, 0, -1, true, {})
        require('neoclip').setup()
        require('neoclip.storage').clear()
    end)
    it("storage", function()
        assert_scenario{
            initial_buffer = [[
some line
another line
multiple lines
multiple lines
multiple lines
multiple lines
some chars
a block
a block
]],
            feedkeys = {
                "jyy",
                "jyy",
                "jV3jy",
                "4jv$y",
                "j<C-v>j$",

            },
            assert = function()
                assert(vim.deep_equal({
                    macros = {},
                    yanks = {
                        {
                            contents = { "a block", "" },
                            filetype = "",
                            regtype = "c"
                        },
                        {
                            contents = { "multiple lines", "multiple lines", "multiple lines", "some chars" },
                            filetype = "",
                            regtype = "l"
                        },
                        {
                            contents = { "multiple lines" },
                            filetype = "",
                            regtype = "l"
                        },
                        {
                            contents = { "another line" },
                            filetype = "",
                            regtype = "l"
                        },
                    },
                }, require('neoclip.storage').get()))
            end,
        }
    end)
end)
