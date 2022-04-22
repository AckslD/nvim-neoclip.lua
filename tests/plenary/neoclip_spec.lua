local function escape_keys(keys)
    return vim.api.nvim_replace_termcodes(keys, true, false, true)
end

local function feedkeys(keys)
    vim.api.nvim_feedkeys(escape_keys(keys), 'xmt', true)
end

local function assert_scenario(scenario)
    if scenario.initial_buffer then
        vim.api.nvim_buf_set_lines(0, 0, -1, true, vim.fn.split(scenario.initial_buffer, '\n'))
    end
    if scenario.setup then scenario.setup() end
    if scenario.feedkeys then
        for _, raw_keys in ipairs(scenario.feedkeys) do
            if type(raw_keys) == 'string' then
                feedkeys(raw_keys)
            else
                if raw_keys.before then raw_keys.before() end
                feedkeys(raw_keys.keys)
                if raw_keys.after then raw_keys.after() end
            end
        end
    end
    if scenario.interlude then scenario.interlude() end
    if scenario.assert then scenario.assert() end
    if scenario.expected_buffer then
        local current_buffer = vim.fn.join(vim.api.nvim_buf_get_lines(0, 0, -1, true), '\n')
        assert.are.equal(current_buffer, scenario.expected_buffer)
    end
end

local function unload(name)
    for pkg, _ in pairs(package.loaded) do
        if vim.fn.match(pkg, name) ~= -1 then
            package.loaded[pkg] = nil
        end
    end
end

describe("neoclip", function()
    after_each(function()
        require('neoclip.storage').clear()
        unload('neoclip')
        unload('telescope')
        vim.api.nvim_buf_set_lines(0, 0, -1, true, {})
    end)
    it("storage", function()
        assert_scenario{
            setup = function()
                require('neoclip').setup()
            end,
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
                assert_equal_tables(
                    {
                        {
                            contents = {"a block", ""},
                            filetype = "",
                            regtype = "c"
                        },
                        {
                            contents = {"multiple lines", "multiple lines", "multiple lines", "some chars"},
                            filetype = "",
                            regtype = "l"
                        },
                        {
                            contents = {"multiple lines"},
                            filetype = "",
                            regtype = "l"
                        },
                        {
                            contents = {"another line"},
                            filetype = "",
                            regtype = "l"
                        },
                    },
                    require('neoclip.storage').get().yanks
                )
            end,
        }
    end)
    it("storage max", function()
        assert_scenario{
            initial_buffer = [[
a
b
c
d
]],
            setup = function()
                require('neoclip').setup({
                    history = 2,
                })
            end,
            feedkeys = {
                "jyy",
                "jyy",
                "jyy",
                "jyy",
            },
            assert = function()
                assert_equal_tables(
                    {
                        {
                            contents = {"d"},
                            filetype = "",
                            regtype = "l"
                        },
                        {
                            contents = {"c"},
                            filetype = "",
                            regtype = "l"
                        },
                    },
                    require('neoclip.storage').get().yanks
                )
            end,
        }
    end)
    it("duplicates", function()
        assert_scenario{
            initial_buffer = [[some line]],
            setup = function()
                require('neoclip').setup()
            end,
            feedkeys = {
                "yy",
                "yy",
                "Y",
            },
            assert = function()
                assert_equal_tables(
                    {
                        {
                            contents = {"some line"},
                            filetype = "",
                            regtype = "c"
                        },
                        {
                            contents = {"some line"},
                            filetype = "",
                            regtype = "l"
                        },
                    },
                    require('neoclip.storage').get().yanks
                )
            end,
        }
    end)
    it("continuous_sync push", function()
        local called = false
        assert_scenario{
            initial_buffer = [[some line]],
            setup = function()
                require('neoclip').setup({
                    enable_persistent_history = true,
                    continuous_sync = true,
                })
                -- mock the push
                require('neoclip.storage').push = function()
                    called = true
                end
            end,
            feedkeys = {
                "yy",
            },
            assert = function()
                assert(called)
            end,
        }
    end)
    it("continuous_sync pull", function()
        local called = false
        assert_scenario{
            initial_buffer = [[some line]],
            setup = function()
                require('neoclip').setup({
                    enable_persistent_history = true,
                    continuous_sync = true,
                })
                -- mock the pull
                require('neoclip.storage').pull = function()
                    called = true
                end
            end,
            feedkeys = {
                {
                    keys=[[:lua require('telescope').extensions.neoclip.neoclip()<CR>]],
                    after = function()
                        vim.wait(100, function() end)
                    end,
                },
                "<Esc>",
            },
            assert = function()
                assert(called)
            end,
        }
    end)
    it("persistent history", function()
        assert_scenario{
            initial_buffer = [[some line]],
            setup = function()
                require('neoclip').setup({
                    enable_persistent_history = true,
                    db_path = '/tmp/nvim/databases/neoclip.sqlite3',
                })
                vim.fn.system('rm /tmp/nvim/databases/neoclip.sqlite3')
            end,
            feedkeys = {"yy"},
            interlude = function()
                -- emulate closing and starting neovim
                vim.cmd('doautocmd VimLeavePre')
                unload('neoclip')
                require('neoclip.settings').get().enable_persistent_history = true
                require('neoclip.settings').get().db_path = '/tmp/nvim/databases/neoclip.sqlite3'
            end,
            assert = function()
                assert_equal_tables(
                    {
                        {
                            contents = {"some line"},
                            filetype = "",
                            regtype = "l"
                        },
                    },
                    require('neoclip.storage').get().yanks
                )
                assert(vim.fn.filereadable('/tmp/nvim/databases/neoclip.sqlite3'))
            end,
        }
    end)
    it("persistant history", function()
        assert_scenario{
            initial_buffer = [[some line]],
            setup = function()
                require('neoclip').setup({
                    enable_persistant_history = true,
                })
            end,
            assert = function()
                assert.are.equal(require('neoclip.settings').get().enable_persistent_history, true)
            end,
        }
    end)
    it("filter (whitespace)", function()
        assert_scenario{
            initial_buffer = '\nsome line\n\n\t\n',
            setup = function()
                local function is_whitespace(line)
                    return vim.fn.match(line, [[^\s*$]]) ~= -1
                end

                local function all(tbl, check)
                    for _, entry in ipairs(tbl) do
                        if not check(entry) then
                            return false
                        end
                    end
                    return true
                end

                require('neoclip').setup({
                    filter = function(data)
                        return not all(data.event.regcontents, is_whitespace)
                    end,
                })
            end,
            feedkeys = {
                "yy",
                "jyy",
                "jyy",
                "jyy",
            },
            assert = function()
                assert_equal_tables(
                    {
                        {
                            contents = {"some line"},
                            filetype = "",
                            regtype = "l"
                        },
                    },
                    require('neoclip.storage').get().yanks
                )
            end,
        }
    end)
    it("basic telescope usage", function()
        assert_scenario{
            initial_buffer = [[some line
another line]],
            feedkeys = {
                "yy",
                "jyy",
                {
                    keys=[[:lua require('telescope').extensions.neoclip.neoclip()<CR>]],
                    after = function()
                        vim.wait(100, function() end)
                    end,
                },
                "k<CR>",
                "p",
            },
            assert = function()
                assert.are.equal(vim.fn.getreg('"'), 'some line\n')
            end,
            expected_buffer = [[some line
another line
some line]],
        }
    end)
    it("paste directly", function()
        assert_scenario{
            initial_buffer = [[some line
another line]],
            feedkeys = {
                "yy",
                "jyy",
                {
                    keys=[[:lua require('telescope').extensions.neoclip.neoclip()<CR>]],
                    after = function()
                        vim.wait(100, function() end)
                    end,
                },
                "kp",
            },
            assert = function()
                assert.are.equal(vim.fn.getreg('"'), 'another line\n')
            end,
            expected_buffer = [[some line
another line
some line]],
        }
    end)
    it("set reg on paste", function()
        assert_scenario{
            setup = function()
                require('neoclip').setup({
                    on_paste = {
                        set_reg = true,
                    }
                })
            end,
            initial_buffer = [[some line
another line]],
            feedkeys = {
                "yy",
                "jyy",
                {
                    keys=[[:lua require('telescope').extensions.neoclip.neoclip()<CR>]],
                    after = function()
                        vim.wait(100, function() end)
                    end,
                },
                "kp",
            },
            assert = function()
                assert.are.equal(vim.fn.getreg('"'), 'some line\n')
            end,
            expected_buffer = [[some line
another line
some line]],
        }
    end)
    it("default register", function()
        assert_scenario{
            setup = function()
                require('neoclip').setup({
                    default_register = 'a',
                })
            end,
            initial_buffer = [[some line]],
            feedkeys = {
                "yy",
                {
                    keys=[[:lua require('telescope').extensions.neoclip.default()<CR>]],
                    after = function()
                        vim.wait(100, function() end)
                    end,
                },
                "<CR>",
            },
            assert = function()
                assert.are.equal(vim.fn.getreg('a'), 'some line\n')
            end,
        }
    end)
    it("multiple default registers", function()
        assert_scenario{
            setup = function()
                require('neoclip').setup({
                    default_register = {'a', 'b'},
                })
            end,
            initial_buffer = [[some line]],
            feedkeys = {
                "yy",
                {
                    keys=[[:lua require('telescope').extensions.neoclip.neoclip()<CR>]],
                    after = function()
                        vim.wait(100, function() end)
                    end,
                },
                "<CR>",
            },
            assert = function()
                assert.are.equal(vim.fn.getreg('a'), 'some line\n')
                assert.are.equal(vim.fn.getreg('b'), 'some line\n')
            end,
        }
    end)
    it("macro", function()
        assert_scenario{
            setup = function()
                require('neoclip').setup()
            end,
            feedkeys = {
                "qq",
                "yy",
                "q",
            },
            assert = function()
                assert_equal_tables(
                    {
                        {
                            contents = {"yy"},
                            regtype = "c"
                        },
                    },
                    require('neoclip.storage').get().macros
                )
            end,
        }
    end)
    it("macro disabled", function()
        assert_scenario{
            setup = function()
                require('neoclip').setup({
                    enable_macro_history = false,
                })
            end,
            feedkeys = {
                "qq",
                "yy",
                "q",
            },
            assert = function()
                assert.are.equal(vim.fn.getreg('q'), 'yy')
                assert_equal_tables(
                    {},
                    require('neoclip.storage').get().macros
                )
            end,
        }
    end)
    it("set reg on replay", function()
        assert_scenario{
            setup = function()
                require('neoclip').setup({
                    on_replay = {
                        set_reg = true,
                    }
                })
            end,
            initial_buffer = [[some line
another line]],
            feedkeys = {
                "qq",
                "yyp",
                "q",
                "qq",
                "j",
                "q",
                {
                    keys=[[:lua require('telescope').extensions.macroscope.default()<CR>]],
                    after = function()
                        vim.wait(100, function() end)
                    end,
                },
                "kq",
            },
            assert = function()
                assert.are.equal(vim.fn.getreg('q'), 'yyp')
            end,
            expected_buffer = [[some line
some line
another line
another line]],
        }
    end)
    it("macro default register", function()
        assert_scenario{
            setup = function()
                require('neoclip').setup({
                    default_register_macros = 'a',
                })
            end,
            initial_buffer = [[some line]],
            feedkeys = {
                "qq",
                "yy",
                "q",
                {
                    keys=[[:lua require('telescope').extensions.macroscope.macroscope()<CR>]],
                    after = function()
                        vim.wait(100, function() end)
                    end,
                },
                "<CR>",
            },
            assert = function()
                assert.are.equal(vim.fn.getreg('a'), 'yy')
            end,
        }
    end)
    it("multiple default registers", function()
        assert_scenario{
            setup = function()
                require('neoclip').setup({
                    default_register_macros = {'a', 'b'},
                })
            end,
            initial_buffer = [[some line]],
            feedkeys = {
                "qq",
                "yy",
                "q",
                {
                    keys=[[:lua require('telescope').extensions.macroscope.macroscope()<CR>]],
                    after = function()
                        vim.wait(100, function() end)
                    end,
                },
                "<CR>",
            },
            assert = function()
                assert.are.equal(vim.fn.getreg('a'), 'yy')
                assert.are.equal(vim.fn.getreg('b'), 'yy')
            end,
        }
    end)
    it("extra", function()
        assert_scenario{
            initial_buffer = [[some line
another line]],
            feedkeys = {
                "yy",
                "jyy",
                {
                    keys=[[:lua require('telescope').extensions.neoclip.neoclip({extra='a,b,c'})<CR>]],
                    after = function()
                        vim.wait(100, function() end)
                    end,
                },
                "k<CR>",
                "p",
            },
            assert = function()
                for _, reg in ipairs({'"', 'a', 'b', 'c'}) do
                    assert.are.equal(vim.fn.getreg(reg), 'some line\n')
                end
            end,
            expected_buffer = [[some line
another line
some line]],
        }
    end)
    it("keybinds", function()
        local keys = {
            telescope = {
                i = {
                    select = '<c-a>',
                    paste = '<c-b>',
                    paste_behind = '<c-c>',
                    replay = '<c-d>',
                    delete = '<c-e>',
                    custom = {
                        ['<c-f>'] = function(opts)
                            return opts
                        end
                    },
                },
                n = {
                    select = 'a',
                    paste = 'b',
                    paste_behind = 'c',
                    replay = 'd',
                    delete = 'e',
                    custom = {
                        f = function(opts)
                            return opts
                        end
                    },
                },
            },
            fzf = {
                select = '<c-a>',
                paste = '<c-b>',
                paste_behind = '<c-c>',
                custom = {
                    ['<c-e>'] = function(opts)
                        return opts
                    end
                },
            },
        }

        assert_scenario{
            setup = function()
                require('neoclip').setup({
                    keys = keys,
                })
            end,
            assert = function()
                assert_equal_tables(require('neoclip.settings').get().keys, keys)
            end,
        }
    end)
    it("keybinds (deprecated)", function()
        local keys = {
            i = {
                select = '<c-a>',
            },
        }

        assert_scenario{
            setup = function()
                require('neoclip').setup({
                    keys = keys,
                })
            end,
            assert = function()
                assert.are.equal(require('neoclip.settings').get().keys.telescope.i.select, '<c-a>')
            end,
        }
    end)
    it("length limit", function()
        assert_scenario{
            setup = function()
                require('neoclip').setup({
                    length_limit = 7,
                })
            end,
            initial_buffer = [[1234
567
89
123456789
]],
            feedkeys = {
                "yy",
                "yj",
                "y2j",
                "3j",
                "y7l",
                "y8l",
                "yy",
            },
            assert = function()
                assert_equal_tables(
                    {
                        {
                            contents = {"1234567"},
                            filetype = "",
                            regtype = "c"
                        },
                        {
                            contents = {"1234", "567"},
                            filetype = "",
                            regtype = "l"
                        },
                        {
                            contents = {"1234"},
                            filetype = "",
                            regtype = "l"
                        },
                    },
                    require('neoclip.storage').get().yanks
                )
            end,
        }
    end)
end)

-- TODO why does this needs it's own thing?
describe("neoclip", function()
    after_each(function()
        require('neoclip.storage').clear()
        unload('neoclip')
        unload('telescope')
        vim.api.nvim_buf_set_lines(0, 0, -1, true, {})
    end)
    it("replay directly", function()
        assert_scenario{
            initial_buffer = [[some line
another line]],
            feedkeys = {
                "qq",
                "yyp",
                "q",
                "qq",
                "j",
                "q",
                {
                    keys=[[:lua require('telescope').extensions.macroscope.default()<CR>]],
                    after = function()
                        vim.wait(100, function() end)
                    end,
                },
                "kq",
            },
            assert = function()
                assert.are.equal(vim.fn.getreg('q'), 'j')
            end,
            expected_buffer = [[some line
some line
another line
another line]],
        }
    end)
end)
