local M = {}

local has_sqlite, sqlite = pcall(require, "sqlite")
if not has_sqlite then
    print "Couldn't find sqlite.lua. Cannot use persistent history"
    return nil
end

local function get_db(db_path)
    local db = sqlite.new(db_path)
    db:open()
    db:create('neoclip', {
        id = true,
        ensure = true,
        regtype = 'text',
        contents = 'text',
        filetype = 'text',
    })
    return db
end

local function copy(t)
    local new = {}
    for k, v in pairs(t) do
        if type(v) == 'table' then
            new[k] = copy(v)
        else
            new[k] = v
        end
    end
    return new
end

local function map(t, f)
    local new_t = copy(t)
    for k, v in pairs(new_t) do
        new_t[k] = f(v)
    end
    return new_t
end

local function to_sqlite(storage)
    local tbl = map(storage, function(v)
        v.contents = table.concat(v.contents, '\n')
        return v
    end)
    return tbl
end

local function from_sqlite(tbl)
    local storage = map(tbl, function(v)
        v.contents = vim.fn.split(v.contents, '\n')
        return v
    end)
    return storage
end

M.get = function(db_path)
    local db = get_db(db_path)
    return from_sqlite(db:select('neoclip'))
end

M.update = function(opts)
    local db = get_db(opts.db_path)
    db:delete('neoclip')
    -- TODO can arrays be used in sqlite columns? If so, then to_sqlite could be removed
    db:insert('neoclip', to_sqlite(opts.storage))
end

return M
