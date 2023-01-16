local ss = require('neoclip.sorted_set')

local foo = {
    regtype = 'c',
    contents = {'foo'},
    filetype = 'lua',
}

local bar = {
    regtype = 'c',
    contents = {'bar'},
    filetype = 'lua',
}

local baz = {
    regtype = 'c',
    contents = {'baz'},
    filetype = 'lua',
}

local foo_python = {
    regtype = 'c',
    contents = {'foo'},
    filetype = 'python',
}

local foo_linewise = {
    regtype = 'l',
    contents = {'foo'},
    filetype = 'lua',
}

describe("storage", function()
    it("add single", function()
        local s = ss.new()
        local entry = {
            regtype = 'c',
            contents = {'foo', 'bar'},
            filetype = 'lua',
        }
        s:insert(entry)

        assert_equal_tables(s:values(), {entry})
    end)
    it("ordering", function()
        local s = ss.new()
        s:insert(foo)
        s:insert(bar)

        assert_equal_tables(s:values(), {foo, bar})
    end)
    it("reversed", function()
        local s = ss.new()
        s:insert(foo)
        s:insert(bar)

        assert_equal_tables(s:values({reversed = true}), {bar, foo})
    end)
    it("uniqueness", function()
        local s = ss.new()
        s:insert(foo)
        s:insert(foo_python)
        s:insert(foo_linewise)

        assert_equal_tables(s:values(), {foo_python, foo_linewise})
    end)
    it("max size", function()
        local max_size = 2
        local s = ss.new(max_size)
        local a = {
            regtype = 'c',
            contents = {'a'},
            filetype = 'lua',
        }
        local b = {
            regtype = 'c',
            contents = {'b'},
            filetype = 'python',
        }
        local c = {
            regtype = 'c',
            contents = {'c'},
            filetype = 'python',
        }
        s:insert(a)
        s:insert(b)
        s:insert(c)

        assert_equal_tables(s:values(), {b, c})
    end)
    it("remove", function()
        local s = ss.new()
        s:insert(foo)
        s:insert(bar)
        assert_equal_tables(s:values(), {foo, bar})
        s:remove(foo)
        assert_equal_tables(s:values(), {bar})
        s:insert(foo)
        assert_equal_tables(s:values(), {bar, foo})
        s:remove(foo)
        assert_equal_tables(s:values(), {bar})
    end)
    it("clear", function()
        local s = ss.new()
        s:insert(foo)
        s:insert(bar)
        s:clear()
        assert_equal_tables(s:values(), {})
        s:insert(foo)
        assert_equal_tables(s:values(), {foo})
    end)
    it("replace", function()
        local s = ss.new()
        s:insert(bar)

        local a = {
            regtype = 'c',
            contents = {'a'},
            filetype = 'lua',
        }
        local b = {
            regtype = 'c',
            contents = {'b'},
            filetype = 'lua',
        }
        local c = {
            regtype = 'c',
            contents = {'c'},
            filetype = 'lua',
        }

        -- Replace with one item
        s:replace(bar, foo)
        assert_equal_tables(s:values(), {foo})

        s:insert(bar)
        s:insert(baz)
        assert_equal_tables(s:values(), {foo, bar, baz})

        -- Replace at head
        s:replace(foo, a)
        assert_equal_tables(s:values(), {a, bar, baz})

        -- Replace at tail
        s:replace(baz, c)
        assert_equal_tables(s:values(), {a, bar, c})

        -- Replace at middle
        s:replace(bar, b)
        assert_equal_tables(s:values(), {a, b, c})

        -- Replace item that was previously replaced
        s:replace(b, bar)
        assert_equal_tables(s:values(), {a, bar, c})

        -- Replace item with entry that already exists
        s:replace(c, a)
        assert_equal_tables(s:values(), {bar, a})

        -- Replace item with itself
        s:replace(a, a)
        assert_equal_tables(s:values(), {bar, a})
    end)
end)
