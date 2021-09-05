local M = {}

local has_sqlite, sqlite = pcall(require, "sqlite")
if not has_sqlite then
    print "Couldn't find sqlite.lua. Cannot use persistent history"
    return nil
end

local function dirname(str)
    return string.match(str, '(.*[/\\])')
end

local function make_db_dir(db_path)
    os.execute('mkdir -p ' .. dirname(db_path))
end

local function get_db(db_path)
    make_db_dir(db_path)
    local db = sqlite.new(db_path)
    db:open()
    db:create('neoclip', {
        id = true,
        ensure = true,
        regtype = 'text',
        contents = 'luatable',
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

M.get = function(db_path)
    local db = get_db(db_path)
    return db:select('neoclip')
end

M.update = function(opts)
    local db = get_db(opts.db_path)
    db:delete('neoclip')
    db:insert('neoclip', opts.storage)
end

return M
